"""
================================================================================
TEST ISL MODEL WITH MEDIAPIPE + PALM/BACK DETECTION
================================================================================
This script tests the trained TFLite model using live MediaPipe hand detection.
Includes handedness and palm/back facing detection for improved accuracy.

Features (130 total):
- [0-62]   Hand 1: 21 landmarks × 3 coords (normalized)
- [63-125] Hand 2: 21 landmarks × 3 coords (normalized)
- [126]    Hand 1 handedness (0=Left, 1=Right)
- [127]    Hand 1 palm_facing (0=Back, 1=Palm)
- [128]    Hand 2 handedness (0=Left, 1=Right)
- [129]    Hand 2 palm_facing (0=Back, 1=Palm)

Press 'q' to quit, 's' to save a screenshot

Author: KairoAI
================================================================================
"""

import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
import sys
import os

# ============================================================================
# CONFIGURATION
# ============================================================================

MODEL_PATH = "android\\app\\src\\main\\assets\\isl_model.tflite"
INPUT_SIZE = 130  # 2 hands × 21 landmarks × 3 coords + 4 handedness/palm features
NUM_CLASSES = 35

LABELS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4',
    '5', '6', '7', '8', '9'
]

# ============================================================================
# PALM DETECTION
# ============================================================================

def is_palm_facing_camera(hand_landmarks, handedness_label):
    """
    Determine if the palm is facing the camera or the back of hand is showing.
    Uses the cross product of vectors from wrist to thumb base and wrist to pinky base.
    
    Returns: 1.0 if palm facing camera, 0.0 if back of hand facing camera
    """
    # Key landmarks
    wrist = hand_landmarks.landmark[0]
    thumb_cmc = hand_landmarks.landmark[1]   # Thumb base
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


# ============================================================================
# NORMALIZATION (MUST MATCH YOUR ANDROID APP!)
# ============================================================================

def normalize_landmarks(hand_landmarks_list, handedness_list):
    """
    Normalize landmarks exactly as done during training.
    This MUST match your Android app's normalization!
    
    Output format (130 features total):
    - Hand 1 landmarks: 63 normalized coords (21 landmarks × 3)
    - Hand 2 landmarks: 63 normalized coords (21 landmarks × 3)
    - Hand 1 handedness: 1 value (0=Left, 1=Right)
    - Hand 1 palm_facing: 1 value (0=Back, 1=Palm)
    - Hand 2 handedness: 1 value (0=Left, 1=Right)
    - Hand 2 palm_facing: 1 value (0=Back, 1=Palm)
    """
    normalized = []          # Will hold 126 landmark values
    handedness_features = [] # Will hold 4 handedness/palm values
    
    for idx, hand_landmarks in enumerate(hand_landmarks_list):
        if hand_landmarks is None:
            # Pad with zeros for missing hand
            normalized.extend([0.0] * 63)
            handedness_features.extend([0.0, 0.0])
            continue
        
        # Extract raw coordinates
        coords = []
        for lm in hand_landmarks.landmark:
            coords.append([lm.x, lm.y, lm.z])
        coords = np.array(coords)
        
        # Get wrist position (landmark 0)
        wrist = coords[0]
        
        # Make relative to wrist
        relative_coords = coords - wrist
        
        # Calculate hand size (distance from wrist to middle finger MCP)
        # This is landmark 9 in MediaPipe hand model
        hand_size = np.linalg.norm(relative_coords[9])
        
        # Avoid division by zero
        if hand_size < 0.001:
            hand_size = 0.001
        
        # Normalize by hand size
        normalized_coords = relative_coords / hand_size
        
        # Flatten and add to result
        normalized.extend(normalized_coords.flatten().tolist())
        
        # Get handedness features
        if handedness_list and idx < len(handedness_list) and handedness_list[idx] is not None:
            handedness_label = handedness_list[idx].classification[0].label
            handedness_value = 1.0 if handedness_label == "Right" else 0.0
            palm_facing = is_palm_facing_camera(hand_landmarks, handedness_label)
        else:
            handedness_value = 0.0
            palm_facing = 0.0
        
        handedness_features.extend([handedness_value, palm_facing])
    
    # Combine: landmarks first (126), then handedness features (4) = 130 total
    return normalized + handedness_features


# ============================================================================
# TFLITE INTERPRETER
# ============================================================================

class ISLClassifier:
    def __init__(self, model_path):
        print(f"📦 Loading TFLite model: {model_path}")
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        print(f"   Input shape: {self.input_details[0]['shape']}")
        print(f"   Output shape: {self.output_details[0]['shape']}")
        print(f"   Expected: [{INPUT_SIZE}] -> [{NUM_CLASSES}]")
    
    def predict(self, landmarks):
        """Run inference and return prediction"""
        # Prepare input
        input_data = np.array([landmarks], dtype=np.float32)
        
        # Run inference
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        
        # Get output
        output = self.interpreter.get_tensor(self.output_details[0]['index'])[0]
        
        # Get prediction
        predicted_idx = np.argmax(output)
        confidence = output[predicted_idx]
        predicted_label = LABELS[predicted_idx]
        
        return predicted_label, confidence, output


# ============================================================================
# MAIN TEST LOOP
# ============================================================================

def main():
    print("\n" + "="*60)
    print("   ISL MODEL TEST WITH PALM/BACK DETECTION")
    print("="*60)
    
    # Initialize MediaPipe Hands
    mp_hands = mp.solutions.hands
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )
    
    # Load TFLite model
    classifier = ISLClassifier(MODEL_PATH)
    
    # Open webcam
    print("\n📷 Opening webcam...")
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("❌ ERROR: Could not open webcam")
        return
    
    print("✅ Webcam opened successfully")
    print("\n🎮 Controls:")
    print("   Press 'q' to quit")
    print("   Press 's' to save screenshot")
    print("\n" + "="*60)
    
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("❌ Failed to read frame")
            break
        
        frame_count += 1
        
        # Flip frame horizontally for mirror view
        frame = cv2.flip(frame, 1)
        
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        results = hands.process(rgb_frame)
        
        # Default display
        display_text = "No hand detected"
        confidence_text = ""
        hand_info_text = ""
        color = (128, 128, 128)
        
        if results.multi_hand_landmarks:
            # Draw landmarks on frame
            for hand_landmarks in results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(
                    frame,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing_styles.get_default_hand_landmarks_style(),
                    mp_drawing_styles.get_default_hand_connections_style()
                )
            
            # Prepare landmarks for classification (up to 2 hands)
            hand_landmarks_list = list(results.multi_hand_landmarks[:2])
            handedness_list = list(results.multi_handedness[:2]) if results.multi_handedness else []
            
            # Pad to 2 hands
            while len(hand_landmarks_list) < 2:
                hand_landmarks_list.append(None)
            while len(handedness_list) < 2:
                handedness_list.append(None)
            
            # Normalize landmarks (same as training!)
            normalized = normalize_landmarks(hand_landmarks_list, handedness_list)
            
            # Classify
            predicted_label, confidence, probs = classifier.predict(normalized)
            
            # Update display
            display_text = f"Sign: {predicted_label}"
            confidence_text = f"Confidence: {confidence*100:.1f}%"
            
            # Build hand info string
            hand_info_parts = []
            for i, (hl, hd) in enumerate(zip(hand_landmarks_list, handedness_list)):
                if hl is not None and hd is not None:
                    label = hd.classification[0].label
                    palm = "Palm" if normalized[126 + i*2 + 1] == 1.0 else "Back"
                    hand_info_parts.append(f"H{i+1}:{label[0]}/{palm}")
            hand_info_text = " | ".join(hand_info_parts) if hand_info_parts else ""
            
            # Color based on confidence
            if confidence > 0.8:
                color = (0, 255, 0)  # Green - high confidence
            elif confidence > 0.5:
                color = (0, 255, 255)  # Yellow - medium confidence
            else:
                color = (0, 165, 255)  # Orange - low confidence
            
            # Show top 3 predictions every 30 frames
            if frame_count % 30 == 0:
                top3_idx = np.argsort(probs)[-3:][::-1]
                print(f"\n🔮 Top 3 predictions:")
                for idx in top3_idx:
                    print(f"   {LABELS[idx]}: {probs[idx]*100:.1f}%")
                if hand_info_text:
                    print(f"   Hand info: {hand_info_text}")
        
        # Draw UI
        # Background rectangle for text
        cv2.rectangle(frame, (10, 10), (400, 120), (0, 0, 0), -1)
        cv2.rectangle(frame, (10, 10), (400, 120), color, 2)
        
        # Main prediction
        cv2.putText(frame, display_text, (20, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 2)
        
        # Confidence
        cv2.putText(frame, confidence_text, (20, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
        
        # Hand info (handedness + palm/back)
        cv2.putText(frame, hand_info_text, (20, 105),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)
        
        # Instructions at bottom
        cv2.putText(frame, "Press 'q' to quit | 's' to screenshot", (10, frame.shape[0] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        # Show frame
        cv2.imshow('ISL Model Test - Palm Detection', frame)
        
        # Handle key presses
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            print("\n👋 Quitting...")
            break
        elif key == ord('s'):
            filename = f"screenshot_{frame_count}.png"
            cv2.imwrite(filename, frame)
            print(f"📸 Screenshot saved: {filename}")
    
    cap.release()
    cv2.destroyAllWindows()
    hands.close()
    
    print("\n✅ Test complete!")


def test_with_image(image_path):
    """Test with a single image file"""
    print(f"\n📷 Testing with image: {image_path}")
    
    # Initialize MediaPipe
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=True,
        max_num_hands=2,
        min_detection_confidence=0.5
    )
    
    # Load model
    classifier = ISLClassifier(MODEL_PATH)
    
    # Load and process image
    image = cv2.imread(image_path)
    if image is None:
        print(f"❌ Could not load image: {image_path}")
        return
    
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_image)
    
    if not results.multi_hand_landmarks:
        print("❌ No hands detected in image")
        return
    
    # Prepare landmarks
    hand_landmarks_list = list(results.multi_hand_landmarks[:2])
    handedness_list = list(results.multi_handedness[:2]) if results.multi_handedness else []
    
    while len(hand_landmarks_list) < 2:
        hand_landmarks_list.append(None)
    while len(handedness_list) < 2:
        handedness_list.append(None)
    
    # Show hand info
    print("\n🖐️ Detected hands:")
    for i, (hl, hd) in enumerate(zip(hand_landmarks_list, handedness_list)):
        if hl is not None and hd is not None:
            label = hd.classification[0].label
            palm_facing = is_palm_facing_camera(hl, label)
            palm_str = "Palm facing camera" if palm_facing == 1.0 else "Back of hand"
            print(f"   Hand {i+1}: {label} hand - {palm_str}")
    
    # Normalize and classify
    normalized = normalize_landmarks(hand_landmarks_list, handedness_list)
    predicted_label, confidence, probs = classifier.predict(normalized)
    
    print(f"\n✅ Prediction: {predicted_label}")
    print(f"   Confidence: {confidence*100:.1f}%")
    
    # Top 5 predictions
    top_indices = np.argsort(probs)[-5:][::-1]
    print("\n📊 Top 5 predictions:")
    for i in top_indices:
        print(f"   {LABELS[i]}: {probs[i]*100:.1f}%")
    
    hands.close()


if __name__ == "__main__":
    # Check if model exists
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Model not found: {MODEL_PATH}")
        print("   Run landmark_model.py first to generate the model.")
        sys.exit(1)
    
    if len(sys.argv) > 1:
        # Test with specific image
        test_with_image(sys.argv[1])
    else:
        # Run live webcam test
        main()
