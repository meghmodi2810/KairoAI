
"""
================================================================================
ISL LANDMARK MODEL GENERATOR
================================================================================
This script converts a CNN image dataset to MediaPipe landmarks and trains
a DNN model for Indian Sign Language recognition.

YOUR APP EXPECTS:
- Input:  126 floats (2 hands × 21 landmarks × 3 coords)
- Output: 35 classes (A-Z + 0-8)x

USAGE:
1. Set DATASET_PATH to your image dataset folder
2. Dataset structure should be:
   Indian/
   ├── A/
   │   ├── img001.jpg
   │   ├── img002.jpg
   │   └── ...
   ├── B/
   │   └── ...
   └── ...

3. Run: python create_landmark_model.py

4. Output: isl_model.tflite (copy to android/app/src/main/assets/)

Author: KairoAI
================================================================================
"""

import os
import cv2
import numpy as np
import mediapipe as mp
from tqdm import tqdm
import json

# ============================================================================
# CONFIGURATION - MODIFY THESE
# ============================================================================

# Path to your CNN image dataset (folders with class names containing images)
DATASET_PATH = "./Indian"  # Change this to your dataset path

# Output paths
OUTPUT_CSV = "landmark_dataset.csv"
OUTPUT_MODEL = "isl_model.tflite"
OUTPUT_H5 = "isl_model.h5"
OUTPUT_LABELS = "labels.json"

# Model configuration (MUST MATCH YOUR APP)
INPUT_SIZE = 126      # 2 hands × 21 landmarks × 3 coords
NUM_CLASSES = 35      # A-Z (26) + 0-8 (9) = 35

# Training configuration
EPOCHS = 100
BATCH_SIZE = 32
VALIDATION_SPLIT = 0.2

# Labels (MUST MATCH YOUR APP's signLabels in MainActivity.kt)
LABELS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8'
]

# ============================================================================
# STEP 1: EXTRACT LANDMARKS FROM IMAGES
# ============================================================================

def setup_mediapipe():
    """Initialize MediaPipe Hands detector"""
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=True,
        max_num_hands=2,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )
    return hands


def normalize_landmarks(landmarks_list):
    """
    Normalize landmarks exactly as your app does in MainActivity.kt:
    - Subtract wrist position (make relative to wrist)
    - Divide by hand size (scale invariance)
    
    This MUST match the normalization in processDetectedHand() in your app!
    """
    normalized = []
    
    for hand_landmarks in landmarks_list:
        if hand_landmarks is None:
            # Pad with zeros for missing hand
            normalized.extend([0.0] * 63)
            continue
        
        # Get wrist position (landmark 0)
        wrist_x = hand_landmarks[0][0]
        wrist_y = hand_landmarks[0][1]
        wrist_z = hand_landmarks[0][2]
        
        # Calculate hand size (distance from wrist to middle finger MCP)
        mcp_x = hand_landmarks[9][0]  # Middle finger MCP
        mcp_y = hand_landmarks[9][1]
        mcp_z = hand_landmarks[9][2]
        
        hand_size = np.sqrt(
            (mcp_x - wrist_x) ** 2 + 
            (mcp_y - wrist_y) ** 2 + 
            (mcp_z - wrist_z) ** 2
        )
        
        # Avoid division by zero
        if hand_size < 0.001:
            hand_size = 0.001
        
        # Normalize each landmark
        for lm in hand_landmarks:
            norm_x = (lm[0] - wrist_x) / hand_size
            norm_y = (lm[1] - wrist_y) / hand_size
            norm_z = (lm[2] - wrist_z) / hand_size
            normalized.extend([norm_x, norm_y, norm_z])
    
    return normalized


def extract_landmarks_from_image(hands, image_path):
    """
    Extract hand landmarks from an image using MediaPipe.
    Returns 126 normalized floats or None if no hand detected.
    """
    # Read image
    image = cv2.imread(image_path)
    if image is None:
        return None
    
    # Convert BGR to RGB (MediaPipe expects RGB)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Process with MediaPipe
    results = hands.process(image_rgb)
    
    # Check if any hands detected
    if not results.multi_hand_landmarks:
        return None
    
    # Extract landmarks for up to 2 hands
    hands_data = []
    for hand_landmarks in results.multi_hand_landmarks[:2]:
        hand_data = []
        for lm in hand_landmarks.landmark:
            hand_data.append([lm.x, lm.y, lm.z])
        hands_data.append(hand_data)
    
    # Pad with None if only 1 hand detected
    while len(hands_data) < 2:
        hands_data.append(None)
    
    # Normalize landmarks
    normalized = normalize_landmarks(hands_data)
    
    # Ensure we have exactly 126 values
    if len(normalized) != INPUT_SIZE:
        return None
    
    return normalized


def extract_dataset_landmarks():
    """Extract landmarks from all images in the dataset"""
    print("\n" + "="*60)
    print("STEP 1: EXTRACTING LANDMARKS FROM IMAGES")
    print("="*60)
    
    if not os.path.exists(DATASET_PATH):
        print(f"\n❌ ERROR: Dataset not found at '{DATASET_PATH}'")
        print("Please set DATASET_PATH to your image dataset folder.")
        return None, None
    
    hands = setup_mediapipe()
    
    X = []  # Landmarks
    y = []  # Labels
    
    # Get all class folders
    class_folders = sorted([f for f in os.listdir(DATASET_PATH) 
                           if os.path.isdir(os.path.join(DATASET_PATH, f))])
    
    print(f"\n📂 Found {len(class_folders)} class folders")
    print(f"   Classes: {class_folders}")
    
    # Create label mapping
    label_to_idx = {}
    for folder in class_folders:
        # Try to match folder name to our labels
        folder_upper = folder.upper()
        if folder_upper in LABELS:
            label_to_idx[folder] = LABELS.index(folder_upper)
        elif folder in LABELS:
            label_to_idx[folder] = LABELS.index(folder)
        else:
            print(f"⚠️  Warning: Folder '{folder}' doesn't match any label, skipping...")
            continue
    
    print(f"\n📋 Label mapping: {label_to_idx}")
    
    stats = {'total': 0, 'success': 0, 'failed': 0}
    class_counts = {}
    
    # Process each class folder
    for folder, label_idx in label_to_idx.items():
        folder_path = os.path.join(DATASET_PATH, folder)
        images = [f for f in os.listdir(folder_path) 
                  if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))]
        
        class_counts[folder] = {'total': len(images), 'success': 0}
        
        print(f"\n🔄 Processing '{folder}' ({len(images)} images)...")
        
        for img_name in tqdm(images, desc=f"   {folder}", leave=False):
            img_path = os.path.join(folder_path, img_name)
            stats['total'] += 1
            
            landmarks = extract_landmarks_from_image(hands, img_path)
            
            if landmarks is not None:
                X.append(landmarks)
                y.append(label_idx)
                stats['success'] += 1
                class_counts[folder]['success'] += 1
            else:
                stats['failed'] += 1
    
    # Print statistics
    print("\n" + "-"*60)
    print("EXTRACTION STATISTICS")
    print("-"*60)
    print(f"Total images processed: {stats['total']}")
    print(f"✅ Successfully extracted: {stats['success']} ({stats['success']/stats['total']*100:.1f}%)")
    print(f"❌ Failed (no hand detected): {stats['failed']} ({stats['failed']/stats['total']*100:.1f}%)")
    
    print("\nPer-class statistics:")
    for folder, counts in class_counts.items():
        success_rate = counts['success'] / counts['total'] * 100 if counts['total'] > 0 else 0
        print(f"   {folder}: {counts['success']}/{counts['total']} ({success_rate:.1f}%)")
    
    if len(X) == 0:
        print("\n❌ ERROR: No landmarks extracted! Check your dataset.")
        return None, None
    
    # Save to CSV
    print(f"\n💾 Saving landmarks to '{OUTPUT_CSV}'...")
    save_landmarks_csv(X, y)
    
    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32)


def save_landmarks_csv(X, y):
    """Save landmarks to CSV file"""
    import csv
    
    with open(OUTPUT_CSV, 'w', newline='') as f:
        writer = csv.writer(f)
        
        # Header
        header = [f'lm{i}_{c}' for i in range(42) for c in ['x', 'y', 'z']] + ['label']
        writer.writerow(header)
        
        # Data
        for landmarks, label in zip(X, y):
            row = list(landmarks) + [LABELS[label]]
            writer.writerow(row)
    
    print(f"   Saved {len(X)} samples to {OUTPUT_CSV}")


# ============================================================================
# STEP 2: CREATE AND TRAIN THE MODEL
# ============================================================================

def create_model():
    """
    Create a DNN model for landmark-based classification.
    Architecture optimized for hand landmark input.
    """
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers
    
    model = keras.Sequential([
        # Input layer
        layers.Input(shape=(INPUT_SIZE,), name='landmark_input'),
        
        # First dense block
        layers.Dense(256, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.4),
        
        # Second dense block
        layers.Dense(128, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.4),
        
        # Third dense block
        layers.Dense(64, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.3),
        
        # Output layer
        layers.Dense(NUM_CLASSES, activation='softmax', name='output')
    ])
    
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    return model


def train_model(X, y):
    """Train the model on extracted landmarks"""
    import tensorflow as tf
    from tensorflow import keras
    from sklearn.model_selection import train_test_split
    
    print("\n" + "="*60)
    print("STEP 2: TRAINING THE MODEL")
    print("="*60)
    
    # Split data
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=VALIDATION_SPLIT, random_state=42, stratify=y
    )
    
    print(f"\n📊 Dataset split:")
    print(f"   Training samples: {len(X_train)}")
    print(f"   Validation samples: {len(X_val)}")
    print(f"   Input shape: {X_train.shape}")
    print(f"   Number of classes: {len(np.unique(y))}")
    
    # Check class distribution
    unique, counts = np.unique(y_train, return_counts=True)
    print(f"\n📈 Class distribution in training set:")
    for idx, count in zip(unique, counts):
        print(f"   {LABELS[idx]}: {count} samples")
    
    # Create model
    print("\n🏗️  Creating model...")
    model = create_model()
    model.summary()
    
    # Callbacks
    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor='val_accuracy',
            patience=15,
            restore_best_weights=True,
            verbose=1
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=0.00001,
            verbose=1
        ),
        keras.callbacks.ModelCheckpoint(
            OUTPUT_H5,
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]
    
    # Train
    print("\n🚀 Training model...")
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1
    )
    
    # Evaluate
    print("\n" + "-"*60)
    print("TRAINING RESULTS")
    print("-"*60)
    
    val_loss, val_accuracy = model.evaluate(X_val, y_val, verbose=0)
    print(f"\n✅ Final Validation Accuracy: {val_accuracy*100:.2f}%")
    print(f"   Final Validation Loss: {val_loss:.4f}")
    
    # Best accuracy during training
    best_val_acc = max(history.history['val_accuracy'])
    best_epoch = history.history['val_accuracy'].index(best_val_acc) + 1
    print(f"   Best Validation Accuracy: {best_val_acc*100:.2f}% (epoch {best_epoch})")
    
    return model


# ============================================================================
# STEP 3: CONVERT TO TFLITE
# ============================================================================

def convert_to_tflite(model):
    """Convert trained model to TFLite format"""
    import tensorflow as tf
    
    print("\n" + "="*60)
    print("STEP 3: CONVERTING TO TFLITE")
    print("="*60)
    
    # Convert
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save
    with open(OUTPUT_MODEL, 'wb') as f:
        f.write(tflite_model)
    
    model_size = len(tflite_model) / 1024
    print(f"\n✅ TFLite model saved: {OUTPUT_MODEL}")
    print(f"   Model size: {model_size:.2f} KB")
    
    # Verify the model
    print("\n🔍 Verifying TFLite model...")
    interpreter = tf.lite.Interpreter(model_path=OUTPUT_MODEL)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"   Input shape: {input_details[0]['shape']}")
    print(f"   Output shape: {output_details[0]['shape']}")
    print(f"   Input dtype: {input_details[0]['dtype']}")
    
    # Test inference
    test_input = np.random.randn(1, INPUT_SIZE).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    
    print(f"   Test inference output shape: {output.shape}")
    print(f"   Sum of probabilities: {output.sum():.4f} (should be ~1.0)")
    
    # Save labels
    with open(OUTPUT_LABELS, 'w') as f:
        json.dump({'labels': LABELS}, f, indent=2)
    print(f"\n✅ Labels saved: {OUTPUT_LABELS}")
    
    return OUTPUT_MODEL


# ============================================================================
# MAIN
# ============================================================================

def main():
    print("\n" + "="*60)
    print("   ISL LANDMARK MODEL GENERATOR")
    print("   For KairoAI App")
    print("="*60)
    
    print(f"\n⚙️  Configuration:")
    print(f"   Dataset path: {DATASET_PATH}")
    print(f"   Input size: {INPUT_SIZE} (2 hands × 21 landmarks × 3 coords)")
    print(f"   Output classes: {NUM_CLASSES}")
    print(f"   Labels: {LABELS}")
    
    # Step 1: Extract landmarks
    X, y = extract_dataset_landmarks()
    
    if X is None or y is None:
        print("\n❌ Failed to extract landmarks. Exiting.")
        return
    
    # Step 2: Train model
    model = train_model(X, y)
    
    # Step 3: Convert to TFLite
    tflite_path = convert_to_tflite(model)
    
    # Final instructions
    print("\n" + "="*60)
    print("✅ DONE!")
    print("="*60)
    print(f"""
📁 Generated files:
   • {OUTPUT_CSV} - Landmark dataset (for reference/debugging)
   • {OUTPUT_H5} - Keras model (for further training)
   • {OUTPUT_MODEL} - TFLite model (for your app)
   • {OUTPUT_LABELS} - Label mapping

📱 To use in your app:
   1. Copy '{OUTPUT_MODEL}' to:
      android/app/src/main/assets/isl_model.tflite
   
   2. Rebuild your Flutter app:
      flutter clean
      flutter run

🎯 The model is now trained on REAL MediaPipe landmarks,
   which matches exactly what your app sends during inference!
""")


if __name__ == "__main__":
    main()
