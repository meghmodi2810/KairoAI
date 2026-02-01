"""
================================================================================
TEST ISL MODEL WITH MEDIAPIPE
================================================================================
This script tests the trained TFLite model using live MediaPipe hand detection.
If this works, it should work the same way in your Android Kotlin app!

Why? Because:
1. MediaPipe generates IDENTICAL landmark data across all platforms (Python, Android, iOS)
2. TFLite is cross-platform and works identically on Android
3. The normalization logic is the same

Press 'q' to quit, 's' to save a screenshot

Author: KairoAI
================================================================================
"""

import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf

# ============================================================================
# CONFIGURATION
# ============================================================================

MODEL_PATH = "android\\app\\src\\main\\assets\\isl_model.tflite"
INPUT_SIZE = 126  # 2 hands × 21 landmarks × 3 coords
NUM_CLASSES = 35

LABELS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4',
    '5', '6', '7', '8', '9'
]

# ============================================================================
# NORMALIZATION (MUST MATCH YOUR ANDROID APP!)
# ============================================================================

def normalize_landmarks(hand_landmarks_list):
    """
    Normalize landmarks exactly as done during training.
    This MUST match your Android app's normalization in MainActivity.kt!
    
    The normalization:
    1. Makes landmarks relative to wrist (landmark 0)
    2. Scales by hand size for scale invariance
    """
    normalized = []
    
    for hand_landmarks in hand_landmarks_list:
        if hand_landmarks is None:
            # Pad with zeros for missing hand (same as training)
            normalized.extend([0.0] * 63)
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
    
    return normalized


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
        print(f"   Input dtype: {self.input_details[0]['dtype']}")
    
    def predict(self, landmarks):
        """Run inference on normalized landmarks"""
        # Prepare input
        input_data = np.array([landmarks], dtype=np.float32)
        
        # Run inference
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        
        # Get output
        output = self.interpreter.get_tensor(self.output_details[0]['index'])
        
        # Get prediction
        predicted_idx = np.argmax(output[0])
        confidence = output[0][predicted_idx]
        
        return LABELS[predicted_idx], confidence, output[0]


# ============================================================================
# MAIN TEST LOOP
# ============================================================================

def main():
    print("\n" + "="*60)
    print("   ISL MODEL TEST WITH MEDIAPIPE")
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
        print("❌ ERROR: Could not open webcam!")
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
            print("❌ Failed to grab frame")
            break
        
        frame_count += 1
        
        # Flip for mirror view
        frame = cv2.flip(frame, 1)
        
        # Convert to RGB for MediaPipe
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        results = hands.process(rgb_frame)
        
        # Prepare display
        display_frame = frame.copy()
        prediction_text = "No hand detected"
        confidence = 0.0
        
        if results.multi_hand_landmarks:
            # Draw hand landmarks
            for hand_landmarks in results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(
                    display_frame,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing_styles.get_default_hand_landmarks_style(),
                    mp_drawing_styles.get_default_hand_connections_style()
                )
            
            # Prepare landmarks for classification
            hand_landmarks_list = []
            
            # Get up to 2 hands
            for i, hand_landmarks in enumerate(results.multi_hand_landmarks):
                if i < 2:
                    hand_landmarks_list.append(hand_landmarks)
            
            # Pad to 2 hands if needed
            while len(hand_landmarks_list) < 2:
                hand_landmarks_list.append(None)
            
            # Normalize landmarks (same as training!)
            normalized = normalize_landmarks(hand_landmarks_list)
            
            # Classify
            if len(normalized) == INPUT_SIZE:
                predicted_label, confidence, probs = classifier.predict(normalized)
                prediction_text = f"{predicted_label}"
                
                # Get top 3 predictions
                top_indices = np.argsort(probs)[-3:][::-1]
                top_preds = [(LABELS[i], probs[i]) for i in top_indices]
        
        # Draw prediction on frame
        # Background box
        cv2.rectangle(display_frame, (10, 10), (350, 130), (0, 0, 0), -1)
        cv2.rectangle(display_frame, (10, 10), (350, 130), (0, 255, 0), 2)
        
        # Main prediction
        cv2.putText(display_frame, f"Sign: {prediction_text}", 
                    (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
        
        # Confidence
        if confidence > 0:
            cv2.putText(display_frame, f"Confidence: {confidence*100:.1f}%", 
                        (20, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            
            # Confidence bar
            bar_width = int(confidence * 300)
            cv2.rectangle(display_frame, (20, 100), (20 + bar_width, 120), (0, 255, 0), -1)
            cv2.rectangle(display_frame, (20, 100), (320, 120), (255, 255, 255), 1)
        
        # Instructions
        cv2.putText(display_frame, "Press 'q' to quit, 's' to save", 
                    (10, display_frame.shape[0] - 20), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1)
        
        # Show frame
        cv2.imshow('ISL Model Test - MediaPipe', display_frame)
        
        # Handle keyboard
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            print("\n👋 Exiting...")
            break
        elif key == ord('s'):
            filename = f"screenshot_{frame_count}.jpg"
            cv2.imwrite(filename, display_frame)
            print(f"📸 Saved: {filename}")
    
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
        print("❌ No hand detected in image")
        return
    
    # Prepare landmarks
    hand_landmarks_list = []
    for i, hand_landmarks in enumerate(results.multi_hand_landmarks):
        if i < 2:
            hand_landmarks_list.append(hand_landmarks)
    while len(hand_landmarks_list) < 2:
        hand_landmarks_list.append(None)
    
    # Normalize and classify
    normalized = normalize_landmarks(hand_landmarks_list)
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
    import sys
    
    if len(sys.argv) > 1:
        # Test with image file
        test_with_image(sys.argv[1])
    else:
        # Live webcam test
        main()
