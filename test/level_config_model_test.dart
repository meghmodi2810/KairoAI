import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';

void main() {
  group('LevelConfigModel', () {
    test('normalizeThresholds sorts, deduplicates, and clamps negatives', () {
      final normalized = LevelConfigModel.normalizeThresholds(<int>[
        520,
        -20,
        120,
        120,
        0,
        860,
        280,
      ]);

      expect(normalized, <int>[0, 120, 280, 520, 860]);
    });

    test('normalizeThresholds inserts level-1 threshold when missing', () {
      final normalized = LevelConfigModel.normalizeThresholds(<int>[300, 150]);
      expect(normalized, <int>[0, 150, 300]);
    });

    test('levelForXp returns level based on configured thresholds', () {
      const model = LevelConfigModel(xpThresholds: <int>[0, 100, 250, 500]);

      expect(model.levelForXp(-5), 1);
      expect(model.levelForXp(0), 1);
      expect(model.levelForXp(99), 1);
      expect(model.levelForXp(100), 2);
      expect(model.levelForXp(300), 3);
      expect(model.levelForXp(500), 4);
      expect(model.levelForXp(1500), 4);
    });
  });
}
