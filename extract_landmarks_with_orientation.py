"""
================================================================================
ISL LANDMARK EXTRACTOR WITH HAND ORIENTATION (PALM/BACK DETECTION)
================================================================================
This script extracts hand landmarks AND determines whether each hand is showing
its palm (front) or back (dorsum). This is crucial for ISL where:
- V and 2 have the same hand shape but differ in orientation
- Many two-handed signs use one palm-facing and one back-facing hand

ORIENTATION DETECTION:
- Uses MediaPipe's handedness (Left/Right) combined with palm normal direction
- Palm normal is computed from wrist, index MCP, and pinky MCP landmarks
- If the palm normal points toward camera -> PALM (front)
- If the palm normal points away from camera -> BACK (dorsum)

OUTPUT CSV FORMAT:
- 126 landmark coordinates (2 hands × 21 landmarks × 3 coords)
- 2 orientation features (hand1_orientation, hand2_orientation)
  - 1.0 = PALM (front facing)
  - 0.0 = BACK (dorsum facing)
  - -1.0 = No hand detected
- 2 handedness features (hand1_is_left, hand2_is_left)
  - 1.0 = Left hand
  - 0.0 = Right hand
  - -1.0 = No hand detected
- Total: 130 features + 1 label = 131 columns

Author: KairoAI
================================================================================
"""

import os
import cv2
import numpy as np
import mediapipe as mp
import json
import csv
from pathlib import Path

# ============================================================================
# CONFIGURATION
# ============================================================================

DATASET_PATH = "./Indian"
OUTPUT_CSV = "landmark_dataset_with_orientation.csv"
OUTPUT_LABELS = "labels_orientation.json"

# Model configuration
INPUT_SIZE_LANDMARKS = 126  # 2 hands × 21 landmarks × 3 coords
INPUT_SIZE_ORIENTATION = 4   # 2 hands × (orientation + handedness)
INPUT_SIZE_TOTAL = INPUT_SIZE_LANDMARKS + INPUT_SIZE_ORIENTATION  # 130 features

NUM_CLASSES = 35

LABELS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4',
    '5', '6', '7', '8', '9'
]

# Signs that require orientation distinction
ORIENTATION_SENSITIVE_SIGNS = {
    'V': 'Usually palm facing viewer',
    '2': 'Usually back of hand facing viewer',
}

# ============================================================================
# MEDIAPIPE SETUP
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
    return hands, mp_hands


def compute_palm_normal(hand_landmarks):
    """
    Compute the palm normal vector to determine hand orientation.
    
    Uses three key landmarks to define the palm plane:
    - Wrist (landmark 0)
    - Index finger MCP (landmark 5)
    - Pinky MCP (landmark 17)
    
    The cross product of vectors from wrist to index MCP and wrist to pinky MCP
    gives the palm normal direction.
    
    Returns:
        normal_z: The Z component of palm normal
                  Positive = palm facing camera (FRONT)
                  Negative = back of hand facing camera (BACK)
    """
    # Get key landmark positions
    wrist = np.array([
        hand_landmarks.landmark[0].x,
        hand_landmarks.landmark[0].y,
        hand_landmarks.landmark[0].z
    ])
    
    index_mcp = np.array([
        hand_landmarks.landmark[5].x,
        hand_landmarks.landmark[5].y,
        hand_landmarks.landmark[5].z
    ])
    
    pinky_mcp = np.array([
        hand_landmarks.landmark[17].x,
        hand_landmarks.landmark[17].y,
        hand_landmarks.landmark[17].z
    ])
    
    # Create vectors from wrist to index MCP and pinky MCP
    vec_to_index = index_mcp - wrist
    vec_to_pinky = pinky_mcp - wrist
    
    # Compute cross product to get palm normal
    # For a right hand with palm facing camera: cross product points toward camera (positive Z in image space)
    # For a left hand with palm facing camera: cross product points away from camera
    palm_normal = np.cross(vec_to_index, vec_to_pinky)
    
    # Normalize
    norm = np.linalg.norm(palm_normal)
    if norm > 0:
        palm_normal = palm_normal / norm
    
    return palm_normal


def determine_hand_orientation(hand_landmarks, handedness_label):
    """
    Determine if the hand is showing palm (front) or back (dorsum).
    
    The interpretation of palm normal depends on whether it's a left or right hand:
    - Right hand: negative normal_z means palm facing camera
    - Left hand: positive normal_z means palm facing camera
    
    Args:
        hand_landmarks: MediaPipe hand landmarks
        handedness_label: "Left" or "Right" from MediaPipe
    
    Returns:
        orientation: 1.0 for PALM (front), 0.0 for BACK (dorsum)
    """
    palm_normal = compute_palm_normal(hand_landmarks)
    
    # The Z component tells us the direction
    # MediaPipe uses a coordinate system where:
    # - X increases to the right (in image)
    # - Y increases downward (in image)
    # - Z increases toward the camera (depth, closer = smaller Z in landmark.z, but normal computation differs)
    
    # For right hand palm facing camera: the cross product (index x pinky) points AWAY (negative Z in our normal)
    # For left hand palm facing camera: the cross product points TOWARD camera (positive Z)
    
    if handedness_label == "Right":
        # Right hand: negative Z normal = palm facing camera
        is_palm_facing = palm_normal[2] < 0
    else:  # Left hand
        # Left hand: positive Z normal = palm facing camera
        is_palm_facing = palm_normal[2] > 0
    
    return 1.0 if is_palm_facing else 0.0


def determine_hand_orientation_v2(hand_landmarks, handedness_label):
    """
    Alternative method using thumb and pinky positions relative to palm center.
    
    When viewing palm:
    - Right hand: thumb is on the LEFT side of the hand
    - Left hand: thumb is on the RIGHT side of the hand
    
    When viewing back of hand:
    - Right hand: thumb is on the RIGHT side
    - Left hand: thumb is on the LEFT side
    """
    # Get thumb tip and pinky tip x-coordinates
    thumb_tip_x = hand_landmarks.landmark[4].x
    pinky_tip_x = hand_landmarks.landmark[20].x
    
    # Get palm center (average of MCP joints)
    palm_center_x = np.mean([
        hand_landmarks.landmark[5].x,   # Index MCP
        hand_landmarks.landmark[9].x,   # Middle MCP
        hand_landmarks.landmark[13].x,  # Ring MCP
        hand_landmarks.landmark[17].x   # Pinky MCP
    ])
    
    # Check if thumb is to the left or right of palm center
    thumb_is_left_of_center = thumb_tip_x < palm_center_x
    
    if handedness_label == "Right":
        # Right hand palm facing: thumb appears on LEFT
        is_palm_facing = thumb_is_left_of_center
    else:  # Left hand
        # Left hand palm facing: thumb appears on RIGHT
        is_palm_facing = not thumb_is_left_of_center
    
    return 1.0 if is_palm_facing else 0.0


def normalize_landmarks(hands_data):
    """
    Normalize landmarks to be position and scale invariant.
    Matches the normalization used in Android app.
    """
    normalized = []
    
    for hand_data in hands_data:
        if hand_data is None:
            normalized.extend([0.0] * 63)
            continue
        
        # Get wrist position
        wrist = hand_data[0]
        wrist_x, wrist_y, wrist_z = wrist
        
        # Calculate hand size (wrist to middle finger MCP)
        mcp = hand_data[9]
        hand_size = np.sqrt(
            (mcp[0] - wrist_x) ** 2 +
            (mcp[1] - wrist_y) ** 2 +
            (mcp[2] - wrist_z) ** 2
        )
        
        if hand_size < 0.001:
            hand_size = 0.001
        
        # Normalize each landmark
        for lm in hand_data:
            norm_x = (lm[0] - wrist_x) / hand_size
            norm_y = (lm[1] - wrist_y) / hand_size
            norm_z = (lm[2] - wrist_z) / hand_size
            normalized.extend([norm_x, norm_y, norm_z])
    
    return normalized


def extract_landmarks_from_image(hands, image_path):
    """
    Extract hand landmarks AND orientation from an image.
    
    Returns:
        landmarks: 126 normalized landmark values (or None if no hand)
        orientations: list of (orientation, is_left) tuples for each hand
    """
    image = cv2.imread(str(image_path))
    if image is None:
        return None, None
    
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    
    if not results.multi_hand_landmarks:
        return None, None
    
    # Extract landmarks and orientations for each hand
    hands_data = []
    orientations = []
    
    for idx, hand_landmarks in enumerate(results.multi_hand_landmarks[:2]):
        # Get handedness for this hand
        if results.multi_handedness and idx < len(results.multi_handedness):
            handedness = results.multi_handedness[idx]
            handedness_label = handedness.classification[0].label  # "Left" or "Right"
            is_left = 1.0 if handedness_label == "Left" else 0.0
        else:
            handedness_label = "Right"  # Default assumption
            is_left = 0.0
        
        # Extract landmark coordinates
        hand_data = []
        for lm in hand_landmarks.landmark:
            hand_data.append([lm.x, lm.y, lm.z])
        hands_data.append(hand_data)
        
        # Determine orientation using both methods and combine
        orientation_v1 = determine_hand_orientation(hand_landmarks, handedness_label)
        orientation_v2 = determine_hand_orientation_v2(hand_landmarks, handedness_label)
        
        # Use v2 as primary (more reliable with 2D image perspective)
        orientation = orientation_v2
        
        orientations.append((orientation, is_left))
    
    # Pad with None/defaults if only 1 hand detected
    while len(hands_data) < 2:
        hands_data.append(None)
    while len(orientations) < 2:
        orientations.append((-1.0, -1.0))  # -1 indicates no hand
    
    # Normalize landmarks
    normalized = normalize_landmarks(hands_data)
    
    if len(normalized) != INPUT_SIZE_LANDMARKS:
        return None, None
    
    return normalized, orientations


def extract_dataset():
    """Extract landmarks with orientation from entire dataset"""
    print("\n" + "=" * 70)
    print("ISL LANDMARK EXTRACTION WITH HAND ORIENTATION")
    print("=" * 70)
    
    if not os.path.exists(DATASET_PATH):
        print(f"\n❌ ERROR: Dataset not found at '{DATASET_PATH}'")
        return None, None, None
    
    hands, mp_hands = setup_mediapipe()
    
    all_landmarks = []
    all_orientations = []
    all_labels = []
    
    # Get class folders
    class_folders = sorted([f for f in os.listdir(DATASET_PATH)
                           if os.path.isdir(os.path.join(DATASET_PATH, f))])
    
    print(f"\n📂 Found {len(class_folders)} class folders")
    
    # Create label mapping
    label_to_idx = {}
    for folder in class_folders:
        folder_upper = folder.upper()
        if folder_upper in LABELS:
            label_to_idx[folder] = LABELS.index(folder_upper)
        elif folder in LABELS:
            label_to_idx[folder] = LABELS.index(folder)
    
    stats = {'total': 0, 'success': 0, 'failed': 0}
    orientation_stats = {'palm': 0, 'back': 0, 'two_hands': 0}
    
    for folder, label_idx in label_to_idx.items():
        folder_path = os.path.join(DATASET_PATH, folder)
        images = [f for f in os.listdir(folder_path)
                  if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))]
        
        print(f"\n🔄 Processing '{folder}' ({len(images)} images)...")
        
        success_count = 0
        for i, img_name in enumerate(images):
            img_path = os.path.join(folder_path, img_name)
            stats['total'] += 1
            
            try:
                landmarks, orientations = extract_landmarks_from_image(hands, img_path)
                
                if landmarks is not None:
                    all_landmarks.append(landmarks)
                    all_orientations.append(orientations)
                    all_labels.append(label_idx)
                    stats['success'] += 1
                    success_count += 1
                    
                    # Track orientation statistics
                    if orientations[0][0] == 1.0:
                        orientation_stats['palm'] += 1
                    elif orientations[0][0] == 0.0:
                        orientation_stats['back'] += 1
                    
                    if orientations[1][0] != -1.0:  # Second hand detected
                        orientation_stats['two_hands'] += 1
                else:
                    stats['failed'] += 1
            except Exception as e:
                stats['failed'] += 1
                print(f"      Error processing {img_name}: {e}")
            
            if (i + 1) % 100 == 0:
                print(f"   Processed {i+1}/{len(images)}...")
        
        print(f"   ✓ {success_count}/{len(images)} images extracted")
    
    hands.close()
    
    # Print statistics
    print("\n" + "=" * 70)
    print("EXTRACTION STATISTICS")
    print("=" * 70)
    print(f"Total images processed: {stats['total']}")
    print(f"✅ Successfully extracted: {stats['success']} ({stats['success']/max(1,stats['total'])*100:.1f}%)")
    print(f"❌ Failed (no hand detected): {stats['failed']}")
    print(f"\n📊 Orientation Statistics:")
    print(f"   Palm (front) facing: {orientation_stats['palm']}")
    print(f"   Back (dorsum) facing: {orientation_stats['back']}")
    print(f"   Two-handed images: {orientation_stats['two_hands']}")
    
    return all_landmarks, all_orientations, all_labels


def save_to_csv(landmarks, orientations, labels):
    """Save extracted data to CSV with orientation features"""
    print(f"\n💾 Saving to '{OUTPUT_CSV}'...")
    
    with open(OUTPUT_CSV, 'w', newline='') as f:
        writer = csv.writer(f)
        
        # Create header
        # Landmark columns: hand1_lm0_x, hand1_lm0_y, hand1_lm0_z, ..., hand2_lm20_x, hand2_lm20_y, hand2_lm20_z
        header = []
        for hand_idx in range(2):
            for lm_idx in range(21):
                for coord in ['x', 'y', 'z']:
                    header.append(f'hand{hand_idx+1}_lm{lm_idx}_{coord}')
        
        # Orientation columns
        header.extend([
            'hand1_orientation',  # 1.0=palm, 0.0=back, -1.0=no hand
            'hand1_is_left',      # 1.0=left, 0.0=right, -1.0=no hand
            'hand2_orientation',
            'hand2_is_left',
            'label'
        ])
        
        writer.writerow(header)
        
        # Write data
        for lm, orient, label_idx in zip(landmarks, orientations, labels):
            row = list(lm)  # 126 landmark values
            
            # Add orientation features (4 values)
            row.append(orient[0][0])  # hand1 orientation
            row.append(orient[0][1])  # hand1 is_left
            row.append(orient[1][0])  # hand2 orientation
            row.append(orient[1][1])  # hand2 is_left
            
            # Add label
            row.append(LABELS[label_idx])
            
            writer.writerow(row)
    
    print(f"   ✅ Saved {len(landmarks)} samples")
    print(f"   📄 Total columns: {INPUT_SIZE_TOTAL + 1} (130 features + 1 label)")
    
    # Save labels mapping
    with open(OUTPUT_LABELS, 'w') as f:
        json.dump({
            'labels': LABELS,
            'num_classes': NUM_CLASSES,
            'feature_size': INPUT_SIZE_TOTAL,
            'landmark_size': INPUT_SIZE_LANDMARKS,
            'orientation_features': ['hand1_orientation', 'hand1_is_left', 'hand2_orientation', 'hand2_is_left'],
            'orientation_values': {
                'orientation': {'palm_front': 1.0, 'back_dorsum': 0.0, 'no_hand': -1.0},
                'handedness': {'left': 1.0, 'right': 0.0, 'no_hand': -1.0}
            }
        }, f, indent=2)
    
    print(f"   ✅ Labels saved to '{OUTPUT_LABELS}'")


def visualize_orientation_detection(image_path, output_path=None):
    """
    Visualize the orientation detection on a single image for debugging.
    """
    hands, mp_hands = setup_mediapipe()
    mp_drawing = mp.solutions.drawing_utils
    
    image = cv2.imread(image_path)
    if image is None:
        print(f"Could not read image: {image_path}")
        return
    
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    
    if not results.multi_hand_landmarks:
        print("No hands detected")
        return
    
    # Draw landmarks and orientation info
    annotated_image = image.copy()
    
    for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
        # Draw landmarks
        mp_drawing.draw_landmarks(
            annotated_image,
            hand_landmarks,
            mp_hands.HAND_CONNECTIONS
        )
        
        # Get handedness
        if results.multi_handedness and idx < len(results.multi_handedness):
            handedness = results.multi_handedness[idx]
            handedness_label = handedness.classification[0].label
            confidence = handedness.classification[0].score
        else:
            handedness_label = "Unknown"
            confidence = 0.0
        
        # Determine orientation
        orientation = determine_hand_orientation_v2(hand_landmarks, handedness_label)
        orientation_text = "PALM" if orientation == 1.0 else "BACK"
        
        # Get wrist position for text placement
        wrist = hand_landmarks.landmark[0]
        h, w, _ = image.shape
        text_x = int(wrist.x * w)
        text_y = int(wrist.y * h) - 20
        
        # Draw info
        info_text = f"{handedness_label} - {orientation_text}"
        cv2.putText(annotated_image, info_text, (text_x, text_y),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    
    hands.close()
    
    if output_path:
        cv2.imwrite(output_path, annotated_image)
        print(f"Saved visualization to: {output_path}")
    else:
        cv2.imshow("Orientation Detection", annotated_image)
        cv2.waitKey(0)
        cv2.destroyAllWindows()
    
    return annotated_image


def test_orientation_detection():
    """Test orientation detection on a few sample images"""
    print("\n" + "=" * 70)
    print("TESTING ORIENTATION DETECTION")
    print("=" * 70)
    
    hands, _ = setup_mediapipe()
    
    # Find some sample images
    test_signs = ['V', '2', 'A', 'B']  # Test with signs that differ by orientation
    
    for sign in test_signs:
        sign_path = os.path.join(DATASET_PATH, sign)
        if not os.path.exists(sign_path):
            continue
        
        images = [f for f in os.listdir(sign_path)
                  if f.lower().endswith(('.jpg', '.jpeg', '.png'))][:3]
        
        print(f"\n📝 Sign '{sign}':")
        palm_count = 0
        back_count = 0
        
        for img_name in images:
            img_path = os.path.join(sign_path, img_name)
            landmarks, orientations = extract_landmarks_from_image(hands, img_path)
            
            if landmarks is not None:
                orient = orientations[0][0]
                if orient == 1.0:
                    palm_count += 1
                elif orient == 0.0:
                    back_count += 1
        
        print(f"   Palm facing: {palm_count}, Back facing: {back_count}")
    
    hands.close()


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Extract ISL landmarks with orientation')
    parser.add_argument('--test', action='store_true', help='Test orientation detection on samples')
    parser.add_argument('--visualize', type=str, help='Visualize orientation on a single image')
    parser.add_argument('--output', type=str, help='Output path for visualization')
    
    args = parser.parse_args()
    
    if args.test:
        test_orientation_detection()
    elif args.visualize:
        visualize_orientation_detection(args.visualize, args.output)
    else:
        # Main extraction
        print("\n🚀 Starting landmark extraction with orientation detection...")
        
        landmarks, orientations, labels = extract_dataset()
        
        if landmarks:
            save_to_csv(landmarks, orientations, labels)
            
            print("\n" + "=" * 70)
            print("✅ EXTRACTION COMPLETE!")
            print("=" * 70)
            print(f"\nOutput files:")
            print(f"   📄 {OUTPUT_CSV} - Landmark data with orientation")
            print(f"   📄 {OUTPUT_LABELS} - Label mapping and feature info")
            print(f"\nNext steps:")
            print(f"   1. Train model with: python train_with_orientation.py")
            print(f"   2. Update Android app to pass orientation features")
        else:
            print("\n❌ Extraction failed!")
