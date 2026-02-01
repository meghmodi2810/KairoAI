"""
Extract hand landmarks from ISL dataset using MediaPipe
This creates a lightweight dataset suitable for Android deployment
Includes palm/back facing detection for each hand
"""

import cv2
import mediapipe as mp
import numpy as np
import os
from pathlib import Path
import pickle

# Initialize MediaPipe Hand detector
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Paths
DATASET_PATH = "./Indian"
OUTPUT_PATH = "./landmarks"
os.makedirs(OUTPUT_PATH, exist_ok=True)

def is_palm_facing_camera(hand_landmarks, handedness_label):
    """
    Determine if the palm is facing the camera or the back of hand is showing.
    
    Uses the cross product of vectors from wrist to thumb base and wrist to pinky base.
    Combined with handedness to determine palm vs back.
    
    Returns: 1.0 if palm facing camera, 0.0 if back of hand facing camera
    """
    # Key landmarks
    wrist = hand_landmarks.landmark[0]
    thumb_cmc = hand_landmarks.landmark[1]  # Thumb base
    pinky_mcp = hand_landmarks.landmark[17]  # Pinky base
    
    # Create vectors from wrist to thumb and wrist to pinky
    vec_thumb = np.array([thumb_cmc.x - wrist.x, thumb_cmc.y - wrist.y, thumb_cmc.z - wrist.z])
    vec_pinky = np.array([pinky_mcp.x - wrist.x, pinky_mcp.y - wrist.y, pinky_mcp.z - wrist.z])
    
    # Cross product gives us the normal vector of the palm plane
    cross = np.cross(vec_thumb, vec_pinky)
    
    # The z-component of the cross product tells us palm orientation
    # For a right hand: positive z means palm facing camera
    # For a left hand: negative z means palm facing camera
    if handedness_label == "Right":
        return 1.0 if cross[2] > 0 else 0.0
    else:  # Left hand
        return 1.0 if cross[2] < 0 else 0.0


def normalize_hand_landmarks(hand_landmarks):
    """
    Normalize landmarks relative to wrist and hand size.
    MUST match the normalization in test_with_mediapipe.py and Android app!
    
    Returns: list of 63 normalized values (21 landmarks × 3 coords)
    """
    # Extract raw coordinates
    coords = []
    for lm in hand_landmarks.landmark:
        coords.append([lm.x, lm.y, lm.z])
    coords = np.array(coords)
    
    # Get wrist position (landmark 0)
    wrist = coords[0]
    
    # Make relative to wrist
    relative_coords = coords - wrist
    
    # Calculate hand size (distance from wrist to middle finger MCP - landmark 9)
    hand_size = np.linalg.norm(relative_coords[9])
    
    # Avoid division by zero
    if hand_size < 0.001:
        hand_size = 0.001
    
    # Normalize by hand size
    normalized_coords = relative_coords / hand_size
    
    return normalized_coords.flatten().tolist()


def extract_landmarks(image_path):
    """
    Extract hand landmarks from a single image.
    
    Output format (130 features total):
    - Hand 1 landmarks: 63 normalized coords (21 landmarks × 3)
    - Hand 2 landmarks: 63 normalized coords (21 landmarks × 3)
    - Hand 1 handedness: 1 value (0=Left, 1=Right)
    - Hand 1 palm_facing: 1 value (0=Back, 1=Palm)
    - Hand 2 handedness: 1 value (0=Left, 1=Right)
    - Hand 2 palm_facing: 1 value (0=Back, 1=Palm)
    
    Total: 126 landmarks + 4 handedness/palm features = 130
    """
    try:
        image = cv2.imread(str(image_path))
        if image is None:
            return None
        
        # Convert to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Detect hands
        results = hands.process(image_rgb)
        
        if not results.multi_hand_landmarks:
            return None
        
        # Prepare storage for up to 2 hands
        all_landmarks = []  # Will hold 126 values (63 per hand)
        all_handedness = []  # Will hold 4 values (2 per hand)
        
        # Process detected hands (up to 2)
        for idx in range(2):
            if idx < len(results.multi_hand_landmarks):
                hand_landmarks = results.multi_hand_landmarks[idx]
                
                # Normalize and extract landmarks (63 values)
                normalized = normalize_hand_landmarks(hand_landmarks)
                all_landmarks.extend(normalized)
                
                # Get handedness (Left=0, Right=1)
                handedness_label = results.multi_handedness[idx].classification[0].label
                handedness_value = 1.0 if handedness_label == "Right" else 0.0
                
                # Get palm facing (Back=0, Palm=1)
                palm_facing = is_palm_facing_camera(hand_landmarks, handedness_label)
                
                all_handedness.extend([handedness_value, palm_facing])
            else:
                # Pad with zeros for missing hand
                all_landmarks.extend([0.0] * 63)
                all_handedness.extend([0.0, 0.0])
        
        # Combine: landmarks first, then handedness features
        # This makes it easier to process in Android
        features = all_landmarks + all_handedness
        
        assert len(features) == 130, f"Expected 130 features, got {len(features)}"
        
        return np.array(features, dtype=np.float32)
    
    except Exception as e:
        print(f"Error processing {image_path}: {e}")
        return None


def process_dataset():
    """Process entire dataset and extract landmarks"""
    
    if not os.path.exists(DATASET_PATH):
        print(f"ERROR: Dataset not found at {DATASET_PATH}")
        print("Expected structure: ./Indian/<class_name>/<images>")
        return
    
    # Get all classes
    classes = sorted([d for d in os.listdir(DATASET_PATH) 
                     if os.path.isdir(os.path.join(DATASET_PATH, d))])
    
    print(f"Found {len(classes)} classes: {classes}")
    
    all_landmarks = []
    all_labels = []
    
    # Stats for palm detection verification
    palm_count = 0
    back_count = 0
    
    for class_idx, class_name in enumerate(classes):
        class_path = os.path.join(DATASET_PATH, class_name)
        image_files = [f for f in os.listdir(class_path) 
                       if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        
        print(f"\nProcessing class {class_idx + 1}/{len(classes)}: {class_name} ({len(image_files)} images)")
        
        processed_count = 0
        for image_file in image_files:
            image_path = os.path.join(class_path, image_file)
            landmarks = extract_landmarks(image_path)
            
            if landmarks is not None:
                all_landmarks.append(landmarks)
                all_labels.append(class_idx)
                processed_count += 1
                
                # Track palm/back stats
                if landmarks[127] == 1.0:  # Hand 1 palm facing
                    palm_count += 1
                else:
                    back_count += 1
        
        print(f"  ✓ Successfully processed {processed_count}/{len(image_files)} images")
    
    if not all_landmarks:
        print("ERROR: No landmarks extracted! Check dataset path and images.")
        return
    
    # Convert to numpy arrays
    X = np.array(all_landmarks, dtype=np.float32)
    y = np.array(all_labels, dtype=np.int32)
    
    print(f"\n{'='*60}")
    print(f"Dataset Summary:")
    print(f"  Total samples: {len(X)}")
    print(f"  Feature shape: {X.shape}")
    print(f"  Labels shape: {y.shape}")
    print(f"  Classes: {len(classes)}")
    print(f"")
    print(f"Palm Detection Stats:")
    print(f"  Palm facing camera: {palm_count} ({100*palm_count/len(X):.1f}%)")
    print(f"  Back facing camera: {back_count} ({100*back_count/len(X):.1f}%)")
    print(f"")
    print(f"Feature layout (130 total):")
    print(f"  [0-62]   Hand 1: 21 landmarks × 3 coords (normalized)")
    print(f"  [63-125] Hand 2: 21 landmarks × 3 coords (normalized)")
    print(f"  [126]    Hand 1 handedness (0=Left, 1=Right)")
    print(f"  [127]    Hand 1 palm_facing (0=Back, 1=Palm)")
    print(f"  [128]    Hand 2 handedness (0=Left, 1=Right)")
    print(f"  [129]    Hand 2 palm_facing (0=Back, 1=Palm)")
    print(f"{'='*60}")
    
    # Save landmarks and labels
    landmarks_file = os.path.join(OUTPUT_PATH, "landmarks.pkl")
    labels_file = os.path.join(OUTPUT_PATH, "labels.pkl")
    classes_file = os.path.join(OUTPUT_PATH, "classes.pkl")
    
    with open(landmarks_file, 'wb') as f:
        pickle.dump(X, f)
    
    with open(labels_file, 'wb') as f:
        pickle.dump(y, f)
    
    with open(classes_file, 'wb') as f:
        pickle.dump(classes, f)
    
    print(f"\n✓ Landmarks saved to {landmarks_file}")
    print(f"✓ Labels saved to {labels_file}")
    print(f"✓ Classes saved to {classes_file}")


if __name__ == "__main__":
    print("Starting landmark extraction with palm/back detection...")
    print("Features: Normalized landmarks + Handedness + Palm facing")
    print("")
    process_dataset()
    hands.close()
    print("\nDone!")
