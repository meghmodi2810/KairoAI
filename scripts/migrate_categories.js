#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

let admin;
try {
  admin = require('firebase-admin');
} catch (_) {
  console.error('Missing dependency: firebase-admin');
  console.error('Install it before running: npm install firebase-admin');
  process.exit(1);
}

const { FieldValue } = require('firebase-admin/firestore');

const categories = [
  {
    id: 'alphabet',
    name: 'Alphabet',
    description: 'Learn individual alphabet signs (A-Z)',
    iconEmoji: 'ABC',
    color: '#4A90D9',
    order: 0,
  },
  {
    id: 'number',
    name: 'Number',
    description: 'Learn individual number signs (0-9)',
    iconEmoji: '123',
    color: '#5DBE6E',
    order: 1,
  },
  {
    id: 'alpha-numeric',
    name: 'Alpha Numeric',
    description: 'Learn alphabet and number signs together',
    iconEmoji: 'A1',
    color: '#9B59B6',
    order: 2,
  },
];

function argValue(name) {
  const index = process.argv.indexOf(name);
  if (index === -1) return null;
  return process.argv[index + 1] || null;
}

function normalizeCategoryId(value) {
  if (!value) return null;
  const compact = String(value)
    .trim()
    .toLowerCase()
    .replace(/_/g, '-')
    .replace(/\s+/g, '-');

  if (compact === 'alphabet' || compact === 'alphabets') return 'alphabet';
  if (compact === 'number' || compact === 'numbers' || compact === 'numeric') {
    return 'number';
  }
  if (
    compact === 'alpha-numeric' ||
    compact === 'alphanumeric' ||
    compact === 'alpha-numerics' ||
    compact === 'both'
  ) {
    return 'alpha-numeric';
  }
  return null;
}

function normalizeSignLabel(value) {
  const normalized = String(value || '').trim().toUpperCase();
  if (normalized === '0' || normalized === 'O' || normalized === 'O / 0') {
    return 'O';
  }
  return normalized;
}

function isAmbiguousZeroOrO(value) {
  return normalizeSignLabel(value) === 'O';
}

function isAlphabetSign(value) {
  return /^[A-Z]$/.test(normalizeSignLabel(value));
}

function isNumberSign(value) {
  const label = normalizeSignLabel(value);
  return label === 'O' || /^[1-9]$/.test(label);
}

function classifyCategoryFromSigns(signLabels, fallbackCategoryId) {
  const fallback = normalizeCategoryId(fallbackCategoryId);
  const labels = signLabels.map(normalizeSignLabel).filter(Boolean);
  if (labels.length === 0) return fallback || 'alpha-numeric';

  let hasAlphabet = false;
  let hasNumber = false;
  let hasNonAmbiguous = false;

  for (const label of labels) {
    if (isAmbiguousZeroOrO(label)) continue;
    hasNonAmbiguous = true;
    if (isAlphabetSign(label)) hasAlphabet = true;
    else if (isNumberSign(label)) hasNumber = true;
  }

  if (!hasNonAmbiguous) return fallback || 'alpha-numeric';
  if (hasAlphabet && hasNumber) return 'alpha-numeric';
  if (hasAlphabet) return 'alphabet';
  if (hasNumber) return 'number';
  return fallback || 'alpha-numeric';
}

function signLabelFromData(data, fallbackId) {
  return (
    data.word ||
    data.character ||
    data.label ||
    data.sign ||
    fallbackId ||
    ''
  );
}

async function getLessonSignLabels(lessonRef, lessonData) {
  const signsSnapshot = await lessonRef.collection('signs').get();
  if (!signsSnapshot.empty) {
    return signsSnapshot.docs
      .map((doc) => signLabelFromData(doc.data(), doc.id))
      .filter(Boolean);
  }

  const embeddedSigns = Array.isArray(lessonData.signs)
    ? lessonData.signs
    : [];
  return embeddedSigns
    .map((sign) => signLabelFromData(sign || {}, ''))
    .filter(Boolean);
}

function currentCategoryForLesson(doc, data) {
  return doc.ref.parent.parent ? doc.ref.parent.parent.id : data.categoryId;
}

async function initializeFirestore() {
  const serviceAccountPath = argValue('--service-account');
  const projectId = argValue('--project');

  const options = {};
  if (serviceAccountPath) {
    const absolutePath = path.resolve(serviceAccountPath);
    const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
    options.credential = admin.credential.cert(serviceAccount);
  } else {
    options.credential = admin.credential.applicationDefault();
  }
  if (projectId) options.projectId = projectId;

  admin.initializeApp(options);
  return admin.firestore();
}

async function upsertCanonicalCategories(db, apply) {
  for (const category of categories) {
    const ref = db.collection('categories').doc(category.id);
    const snapshot = await ref.get();
    if (!apply) {
      console.log(`[dry-run] upsert category ${category.id}`);
      continue;
    }

    if (snapshot.exists) {
      await ref.set(
        {
          name: category.name,
          description: category.description,
          iconEmoji: category.iconEmoji,
          color: category.color,
          order: category.order,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      await ref.set({
        ...category,
        totalLessons: 0,
        totalSigns: 0,
        isLocked: false,
        requiredLevel: 1,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }
}

async function buildLessonPlan(db) {
  const snapshot = await db.collectionGroup('lessons').get();
  const plan = [];
  const lessonIdToCategory = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const currentCategoryId = currentCategoryForLesson(doc, data);
    const signLabels = await getLessonSignLabels(doc.ref, data);
    const targetCategoryId = classifyCategoryFromSigns(
      signLabels,
      currentCategoryId,
    );
    const targetPath = `categories/${targetCategoryId}/lessons/${doc.id}`;
    const hasTypeField = Object.prototype.hasOwnProperty.call(data, 'type');
    const staleCategoryField = data.categoryId !== targetCategoryId;
    const needsMove = doc.ref.path !== targetPath;

    if (
      lessonIdToCategory.has(doc.id) &&
      lessonIdToCategory.get(doc.id) !== targetCategoryId
    ) {
      console.warn(
        `WARNING: lesson id ${doc.id} maps to multiple target categories.`,
      );
    }
    lessonIdToCategory.set(doc.id, targetCategoryId);

    plan.push({
      id: doc.id,
      ref: doc.ref,
      data,
      currentCategoryId,
      targetCategoryId,
      targetRef: db.doc(targetPath),
      signLabels,
      hasTypeField,
      staleCategoryField,
      needsMove,
    });
  }

  return { plan, lessonIdToCategory };
}

async function applyLessonPlan(db, plan, apply) {
  let moved = 0;
  let cleaned = 0;
  let unchanged = 0;

  for (const item of plan) {
    if (!item.needsMove && !item.hasTypeField && !item.staleCategoryField) {
      unchanged += 1;
      continue;
    }

    if (!apply) {
      const action = item.needsMove ? 'move' : 'clean';
      console.log(
        `[dry-run] ${action} ${item.ref.path} -> ${item.targetRef.path}`,
      );
      if (item.hasTypeField) {
        console.log(`          remove lesson type field from ${item.id}`);
      }
      if (item.staleCategoryField) {
        console.log(
          `          categoryId ${item.data.categoryId || '(empty)'} -> ${item.targetCategoryId}`,
        );
      }
      if (item.signLabels.length > 0) {
        console.log(`          signs: ${item.signLabels.join(', ')}`);
      }
      if (item.needsMove) moved += 1;
      else cleaned += 1;
      continue;
    }

    if (!item.needsMove) {
      await item.ref.update({
        categoryId: item.targetCategoryId,
        type: FieldValue.delete(),
        migratedAt: FieldValue.serverTimestamp(),
      });
      cleaned += 1;
      continue;
    }

    const targetSnapshot = await item.targetRef.get();
    if (targetSnapshot.exists) {
      throw new Error(
        `Refusing to overwrite existing lesson at ${item.targetRef.path}`,
      );
    }

    const newLessonData = {
      ...item.data,
      categoryId: item.targetCategoryId,
      migratedAt: FieldValue.serverTimestamp(),
    };
    delete newLessonData.type;

    const signsSnapshot = await item.ref.collection('signs').get();
    const batch = db.batch();
    batch.set(item.targetRef, newLessonData);
    for (const signDoc of signsSnapshot.docs) {
      batch.set(item.targetRef.collection('signs').doc(signDoc.id), {
        ...signDoc.data(),
        lessonId: item.id,
      });
      batch.delete(signDoc.ref);
    }
    batch.delete(item.ref);
    await batch.commit();
    moved += 1;
  }

  return { moved, cleaned, unchanged };
}

async function updateLearnerReferences(db, lessonIdToCategory, apply) {
  const usersSnapshot = await db.collection('users').get();
  let progressUpdated = 0;
  let activationUpdated = 0;

  for (const userDoc of usersSnapshot.docs) {
    const progressSnapshot = await userDoc.ref.collection('progress').get();
    for (const progressDoc of progressSnapshot.docs) {
      const targetCategoryId = lessonIdToCategory.get(progressDoc.id);
      if (!targetCategoryId) continue;
      const data = progressDoc.data();
      if (data.categoryId === targetCategoryId) continue;

      progressUpdated += 1;
      if (apply) {
        await progressDoc.ref.update({ categoryId: targetCategoryId });
      } else {
        console.log(
          `[dry-run] progress ${userDoc.id}/${progressDoc.id}: ${data.categoryId || '(empty)'} -> ${targetCategoryId}`,
        );
      }
    }

    const userData = userDoc.data();
    const experience = userData.postLoginExperienceV1 || {};
    const activationLessonId = experience.activationLessonId;
    const activationTarget = lessonIdToCategory.get(activationLessonId);
    if (
      activationLessonId &&
      activationTarget &&
      experience.activationCategoryId !== activationTarget
    ) {
      activationUpdated += 1;
      if (apply) {
        await userDoc.ref.update({
          'postLoginExperienceV1.activationCategoryId': activationTarget,
        });
      } else {
        console.log(
          `[dry-run] activation ${userDoc.id}: ${experience.activationCategoryId || '(empty)'} -> ${activationTarget}`,
        );
      }
    }
  }

  return { progressUpdated, activationUpdated };
}

async function recalculateCategoryTotals(db, apply) {
  const totals = [];
  for (const category of categories) {
    const categoryRef = db.collection('categories').doc(category.id);
    const lessonsSnapshot = await categoryRef.collection('lessons').get();
    let totalSigns = 0;

    for (const lessonDoc of lessonsSnapshot.docs) {
      const signsSnapshot = await lessonDoc.ref.collection('signs').get();
      if (!signsSnapshot.empty) {
        totalSigns += signsSnapshot.size;
      } else {
        const embeddedSigns = lessonDoc.data().signs;
        totalSigns += Array.isArray(embeddedSigns) ? embeddedSigns.length : 0;
      }
    }

    totals.push({
      categoryId: category.id,
      totalLessons: lessonsSnapshot.size,
      totalSigns,
    });

    if (apply) {
      await categoryRef.set(
        {
          totalLessons: lessonsSnapshot.size,
          totalSigns,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      console.log(
        `[dry-run] totals ${category.id}: ${lessonsSnapshot.size} lessons, ${totalSigns} signs`,
      );
    }
  }
  return totals;
}

async function deleteOldCategories(db, apply) {
  const snapshot = await db.collection('categories').get();
  let deleted = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const rawId = String(doc.id).trim().toLowerCase();
    const rawName = String(data.name || '').trim().toLowerCase();
    const isOldDuplicate =
      rawId === 'alphabets' ||
      rawId === 'numbers' ||
      rawName === 'alphabets' ||
      rawName === 'numbers';

    if (!isOldDuplicate) continue;

    const lessonsSnapshot = await doc.ref.collection('lessons').limit(1).get();
    if (!lessonsSnapshot.empty) {
      skipped += 1;
      console.warn(
        `${apply ? 'skip' : '[dry-run] skip'} delete ${doc.id}: still has lessons`,
      );
      continue;
    }

    deleted += 1;
    if (apply) {
      await doc.ref.delete();
    } else {
      console.log(`[dry-run] delete old category ${doc.id}`);
    }
  }

  return { deleted, skipped };
}

async function main() {
  const apply = process.argv.includes('--apply');
  const dryRun = process.argv.includes('--dry-run') || !apply;

  if (apply && process.argv.includes('--dry-run')) {
    throw new Error('Use only one of --dry-run or --apply.');
  }

  console.log(dryRun ? 'Running category migration dry-run.' : 'Applying category migration.');
  const db = await initializeFirestore();

  await upsertCanonicalCategories(db, apply);
  const { plan, lessonIdToCategory } = await buildLessonPlan(db);
  const lessonSummary = await applyLessonPlan(db, plan, apply);
  const learnerSummary = await updateLearnerReferences(
    db,
    lessonIdToCategory,
    apply,
  );
  const totals = await recalculateCategoryTotals(db, apply);
  const deleteSummary = await deleteOldCategories(db, apply);

  console.log('\nMigration summary');
  console.log(`Lessons moved: ${lessonSummary.moved}`);
  console.log(`Lessons cleaned in place: ${lessonSummary.cleaned}`);
  console.log(`Lessons unchanged: ${lessonSummary.unchanged}`);
  console.log(`Progress docs updated: ${learnerSummary.progressUpdated}`);
  console.log(`Activation refs updated: ${learnerSummary.activationUpdated}`);
  console.log(`Old categories deleted: ${deleteSummary.deleted}`);
  console.log(`Old categories skipped: ${deleteSummary.skipped}`);
  for (const total of totals) {
    console.log(
      `${total.categoryId}: ${total.totalLessons} lessons, ${total.totalSigns} signs`,
    );
  }

  if (dryRun) {
    console.log('\nNo writes were made. Re-run with --apply to migrate.');
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
