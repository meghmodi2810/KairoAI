"""
================================================================================
TEST ISL MODEL WITH MEDIAPIPE - WEBCAM REAL-TIME INFERENCE
================================================================================
This script tests the trained model (isl_model_full.tflite) using MediaPipe
for hand landmark detection and orientation calculation.

Features:
- Real-time webcam hand detection
- Extracts 130 features (126 landmarks + 4 orientation)
- Runs TFLite inference
- Displays prediction with confidence

Controls:
- Press 'q' to quit
- Press 's' to save screenshot
- Press 'c' to toggle confidence threshold

Author: KairoAI
================================================================================
"""

import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
import json
import os
from collections import deque

# ============================================================================
# CONFIGURATION
# ============================================================================

MODEL_PATH = "isl_model_full.tflite"
LABELS_PATH = "labels_full.json"

# Fallback paths if full model not found
FALLBACK_MODEL = "isl_model.tflite"
FALLBACK_LABELS = "labels.json"

# Display settings
CONFIDENCE_THRESHOLD = 0.5
SMOOTHING_WINDOW = 5  # Number of frames to average predictions
SHOW_LANDMARKS = True
SHOW_ORIENTATION = True

# Colors (BGR)
COLOR_PALM = (0, 255, 0)      # Green for palm
COLOR_BACK = (0, 165, 255)    # Orange for back of hand
COLOR_TEXT = (255, 255, 255)  # White
COLOR_BOX = (50, 50, 50)      # Dark gray

# Labels (fallback if json not found)
DEFAULT_LABELS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4',
    '5', '6', '7', '8', '9'
]


# ============================================================================
# HAND ORIENTATION CALCULATOR
# ============================================================================

class HandOrientationCalculator:
    """
    Calculate whether palm or back of hand is facing the camera.
    Uses the cross product of vectors on the hand plane.
    """
    
    # Landmark indices
    WRIST = 0
    INDEX_MCP = 5
    PINKY_MCP = 17
    MIDDLE_MCP = 9
    
    @staticmethod
    def calculate_orientation(landmarks, handedness):
        """
        Calculate hand orientation.
        Returns: (is_palm_facing: float, is_left_hand: float)
        - is_palm_facing: 1.0 = palm facing camera, 0.0 = back facing camera
        - is_left_hand: 1.0 = left hand, 0.0 = right hand
        """
        if landmarks is None:
            return -1.0, -1.0
        
        # Get key points
        wrist = np.array([
            landmarks[HandOrientationCalculator.WRIST].x,
            landmarks[HandOrientationCalculator.WRIST].y,
            landmarks[HandOrientationCalculator.WRIST].z
        ])
        
        index_mcp = np.array([
            landmarks[HandOrientationCalculator.INDEX_MCP].x,
            landmarks[HandOrientationCalculator.INDEX_MCP].y,
            landmarks[HandOrientationCalculator.INDEX_MCP].z
        ])
        
        pinky_mcp = np.array([
            landmarks[HandOrientationCalculator.PINKY_MCP].x,
            landmarks[HandOrientationCalculator.PINKY_MCP].y,
            landmarks[HandOrientationCalculator.PINKY_MCP].z
        ])
        
        # Calculate vectors on the palm plane
        v1 = index_mcp - wrist  # Wrist to index
        v2 = pinky_mcp - wrist  # Wrist to pinky
        
        # Cross product gives normal to palm plane
        normal = np.cross(v1, v2)
        
        # Z component of normal indicates palm orientation
        # Positive = palm facing camera, Negative = back facing
        z_component = normal[2]
        
        # Determine handedness
        is_left = 1.0 if handedness == "Left" else 0.0
        
        # For left hand, the normal direction is reversed
        if is_left:
            z_component = -z_component
        
        # Convert to 0/1 (back/palm)
        is_palm_facing = 1.0 if z_component > 0 else 0.0
        
        return is_palm_facing, is_left


# ============================================================================
# LANDMARK PROCESSOR
# ============================================================================

class LandmarkProcessor:
    """Process MediaPipe hand landmarks into model input features."""
    
    def __init__(self, input_size=130):
        self.input_size = input_size
        self.has_orientation = input_size == 130
        
    def normalize_landmarks(self, landmarks):
        """
        Normalize landmarks relative to wrist position and hand size.
        Returns 63 values (21 landmarks × 3 coords) for one hand.
        """
        if landmarks is None:
            return [0.0] * 63
        
        coords = []
        for lm in landmarks:
            coords.extend([lm.x, lm.y, lm.z])
        
        coords = np.array(coords, dtype=np.float32)
        
        # Normalize relative to wrist (first landmark)
        wrist = coords[:3].copy()
        for i in range(21):
            coords[i*3:i*3+3] -= wrist
        
        # Scale by hand size (distance from wrist to middle finger MCP)
        middle_mcp = coords[9*3:9*3+3]  # Landmark 9
        hand_size = np.linalg.norm(middle_mcp)
        
        if hand_size > 0.001:
            coords /= hand_size
        
        return coords.tolist()
    
    def process_hands(self, results):
        """
        Process MediaPipe results into model input.
        Returns: (features, hand_info)
        - features: numpy array of shape (input_size,)
        - hand_info: dict with orientation info for display
        """
        features = [0.0] * self.input_size
        hand_info = {
            'hand1': None,
            'hand2': None,
            'hand1_orientation': None,
            'hand2_orientation': None
        }
        
        if results.multi_hand_landmarks is None:
            return np.array(features, dtype=np.float32), hand_info
        
        hands_data = []
        
        for i, (hand_landmarks, handedness) in enumerate(
            zip(results.multi_hand_landmarks, results.multi_handedness)
        ):
            hand_label = handedness.classification[0].label
            landmarks = hand_landmarks.landmark
            
            # Normalize landmarks
            normalized = self.normalize_landmarks(landmarks)
            
            # Calculate orientation
            is_palm, is_left = HandOrientationCalculator.calculate_orientation(
                landmarks, hand_label
            )
            
            hands_data.append({
                'landmarks': normalized,
                'is_palm': is_palm,
                'is_left': is_left,
                'label': hand_label,
                'raw_landmarks': landmarks
            })
        
        # Sort by x position (left to right in image)
        if len(hands_data) > 0:
            hands_data.sort(
                key=lambda h: h['raw_landmarks'][0].x
            )
        
        # Fill features for hand 1
        if len(hands_data) >= 1:
            h1 = hands_data[0]
            features[0:63] = h1['landmarks']
            hand_info['hand1'] = h1['label']
            hand_info['hand1_orientation'] = 'Palm' if h1['is_palm'] == 1.0 else 'Back'
            
            if self.has_orientation:
                features[126] = h1['is_palm']
                features[127] = h1['is_left']
        
        # Fill features for hand 2
        if len(hands_data) >= 2:
            h2 = hands_data[1]
            features[63:126] = h2['landmarks']
            hand_info['hand2'] = h2['label']
            hand_info['hand2_orientation'] = 'Palm' if h2['is_palm'] == 1.0 else 'Back'
            
            if self.has_orientation:
                features[128] = h2['is_palm']
                features[129] = h2['is_left']
        elif self.has_orientation:
            features[128] = -1.0
            features[129] = -1.0
        
        return np.array(features, dtype=np.float32), hand_info


# ============================================================================
# PREDICTION SMOOTHER
# ============================================================================

class PredictionSmoother:
    """Smooth predictions over multiple frames to reduce flickering."""
    
    def __init__(self, window_size=5, num_classes=35):
        self.window_size = window_size
        self.num_classes = num_classes
        self.predictions = deque(maxlen=window_size)
        
    def add_prediction(self, probs):
        """Add a new prediction probability distribution."""
        self.predictions.append(probs)
        
    def get_smoothed_prediction(self):
        """Get averaged prediction over the window."""
        if len(self.predictions) == 0:
            return None, 0.0
        
        avg_probs = np.mean(list(self.predictions), axis=0)
        pred_class = np.argmax(avg_probs)
        confidence = avg_probs[pred_class]
        
        return pred_class, confidence
    
    def clear(self):
        """Clear prediction history."""
        self.predictions.clear()


# ============================================================================
# MAIN TESTER CLASS
# ============================================================================

class ISLModelTester:
    """Main class for testing the ISL model with webcam."""
    
    def __init__(self):
        self.model_path = MODEL_PATH
        self.labels = DEFAULT_LABELS
        self.input_size = 130
        
        # Try to load model and labels
        self._load_model()
        self._load_labels()
        
        # Initialize components
        self.processor = LandmarkProcessor(self.input_size)
        self.smoother = PredictionSmoother(SMOOTHING_WINDOW, len(self.labels))
        
        # Initialize MediaPipe
        self.mp_hands = mp.solutions.hands
        self.mp_draw = mp.solutions.drawing_utils
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        
        # State
        self.confidence_threshold = CONFIDENCE_THRESHOLD
        self.show_landmarks = SHOW_LANDMARKS
        
    def _load_model(self):
        """Load TFLite model."""
        # Try full model first
        if os.path.exists(MODEL_PATH):
            self.model_path = MODEL_PATH
        elif os.path.exists(FALLBACK_MODEL):
            print(f"⚠️  {MODEL_PATH} not found, using {FALLBACK_MODEL}")
            self.model_path = FALLBACK_MODEL
        else:
            raise FileNotFoundError(f"No model found! Train the model first.")
        
        print(f"📦 Loading model: {self.model_path}")
        
        self.interpreter = tf.lite.Interpreter(model_path=self.model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # Get input size from model
        self.input_size = self.input_details[0]['shape'][1]
        print(f"   Input size: {self.input_size}")
        
    def _load_labels(self):
        """Load labels from JSON."""
        labels_path = LABELS_PATH if os.path.exists(LABELS_PATH) else FALLBACK_LABELS
        
        if os.path.exists(labels_path):
            with open(labels_path, 'r') as f:
                config = json.load(f)
                self.labels = config.get('labels', DEFAULT_LABELS)
            print(f"   Labels loaded: {len(self.labels)} classes")
        else:
            print(f"   Using default labels: {len(self.labels)} classes")
    
    def predict(self, features):
        """Run inference on features."""
        input_data = features.reshape(1, -1).astype(np.float32)
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details[0]['index'])
        return output[0]
    
    def draw_info_box(self, frame, prediction, confidence, hand_info):
        """Draw prediction info box on frame."""
        h, w = frame.shape[:2]
        
        # Draw semi-transparent background
        overlay = frame.copy()
        cv2.rectangle(overlay, (10, 10), (300, 150), COLOR_BOX, -1)
        cv2.addWeighted(overlay, 0.7, frame, 0.3, 0, frame)
        
        # Draw prediction
        if prediction is not None and confidence >= self.confidence_threshold:
            label = self.labels[prediction]
            color = (0, 255, 0) if confidence > 0.8 else (0, 255, 255)
            
            cv2.putText(frame, f"Sign: {label}", (20, 50),
                       cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)
            cv2.putText(frame, f"Confidence: {confidence*100:.1f}%", (20, 85),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, COLOR_TEXT, 2)
        else:
            cv2.putText(frame, "No sign detected", (20, 50),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.8, (100, 100, 100), 2)
        
        # Draw hand info
        y_offset = 115
        if hand_info['hand1']:
            orient = hand_info['hand1_orientation'] or "?"
            cv2.putText(frame, f"Hand 1: {hand_info['hand1']} ({orient})", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.5, COLOR_TEXT, 1)
            y_offset += 20
            
        if hand_info['hand2']:
            orient = hand_info['hand2_orientation'] or "?"
            cv2.putText(frame, f"Hand 2: {hand_info['hand2']} ({orient})", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.5, COLOR_TEXT, 1)
        
        # Draw controls hint
        cv2.putText(frame, "Q: Quit | S: Screenshot | L: Toggle landmarks", 
                   (10, h - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (150, 150, 150), 1)
        
        return frame
    
    def draw_landmarks(self, frame, results, hand_info):
        """Draw hand landmarks with orientation-based coloring."""
        if results.multi_hand_landmarks is None:
            return frame
        
        for i, hand_landmarks in enumerate(results.multi_hand_landmarks):
            # Choose color based on orientation
            if i == 0 and hand_info['hand1_orientation']:
                color = COLOR_PALM if hand_info['hand1_orientation'] == 'Palm' else COLOR_BACK
            elif i == 1 and hand_info['hand2_orientation']:
                color = COLOR_PALM if hand_info['hand2_orientation'] == 'Palm' else COLOR_BACK
            else:
                color = (200, 200, 200)
            
            # Draw connections
            self.mp_draw.draw_landmarks(
                frame, hand_landmarks, self.mp_hands.HAND_CONNECTIONS,
                self.mp_draw.DrawingSpec(color=color, thickness=2, circle_radius=2),
                self.mp_draw.DrawingSpec(color=color, thickness=2)
            )
        
        return frame
    
    def run(self):
        """Main loop for webcam testing."""
        print("\n" + "=" * 60)
        print("ISL MODEL TEST WITH MEDIAPIPE")
        print("=" * 60)
        
        print("\n📷 Opening webcam...")
        cap = cv2.VideoCapture(0)
        
        if not cap.isOpened():
            print("❌ Error: Could not open webcam!")
            return
        
        # Set camera properties
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_FPS, 30)
        
        print("✅ Webcam opened successfully")
        print("\n🎮 Controls:")
        print("   Press 'q' to quit")
        print("   Press 's' to save screenshot")
        print("   Press 'l' to toggle landmarks")
        print("   Press 'c' to cycle confidence threshold")
        print("   Press 'r' to reset smoother")
        print("\n" + "=" * 60 + "\n")
        
        screenshot_count = 0
        
        while True:
            ret, frame = cap.read()
            if not ret:
                print("❌ Error reading frame")
                break
            
            # Flip for mirror effect
            frame = cv2.flip(frame, 1)
            
            # Convert to RGB for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process with MediaPipe
            results = self.hands.process(rgb_frame)
            
            # Extract features
            features, hand_info = self.processor.process_hands(results)
            
            # Run inference if hand detected
            prediction = None
            confidence = 0.0
            
            if hand_info['hand1'] is not None:
                probs = self.predict(features)
                self.smoother.add_prediction(probs)
                prediction, confidence = self.smoother.get_smoothed_prediction()
            else:
                self.smoother.clear()
            
            # Draw landmarks if enabled
            if self.show_landmarks:
                frame = self.draw_landmarks(frame, results, hand_info)
            
            # Draw info box
            frame = self.draw_info_box(frame, prediction, confidence, hand_info)
            
            # Show frame
            cv2.imshow('ISL Model Test', frame)
            
            # Handle key presses
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('q'):
                print("\n👋 Exiting...")
                break
            elif key == ord('s'):
                filename = f"screenshot_{screenshot_count}.png"
                cv2.imwrite(filename, frame)
                print(f"📸 Screenshot saved: {filename}")
                screenshot_count += 1
            elif key == ord('l'):
                self.show_landmarks = not self.show_landmarks
                print(f"🎯 Landmarks: {'ON' if self.show_landmarks else 'OFF'}")
            elif key == ord('c'):
                # Cycle threshold: 0.5 -> 0.7 -> 0.9 -> 0.3 -> 0.5
                thresholds = [0.3, 0.5, 0.7, 0.9]
                idx = thresholds.index(self.confidence_threshold) if self.confidence_threshold in thresholds else 0
                self.confidence_threshold = thresholds[(idx + 1) % len(thresholds)]
                print(f"📊 Confidence threshold: {self.confidence_threshold}")
            elif key == ord('r'):
                self.smoother.clear()
                print("🔄 Smoother reset")
        
        cap.release()
        cv2.destroyAllWindows()
        print("\n✅ Test complete!")


# ============================================================================
# BATCH TEST MODE
# ============================================================================

def test_on_images(image_folder):
    """Test model on a folder of images."""
    print("\n" + "=" * 60)
    print("BATCH IMAGE TEST")
    print("=" * 60)
    
    tester = ISLModelTester()
    
    results = []
    
    for filename in os.listdir(image_folder):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            filepath = os.path.join(image_folder, filename)
            
            # Load image
            frame = cv2.imread(filepath)
            if frame is None:
                continue
            
            # Process
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_results = tester.hands.process(rgb_frame)
            
            features, hand_info = tester.processor.process_hands(mp_results)
            
            if hand_info['hand1'] is not None:
                probs = tester.predict(features)
                pred_class = np.argmax(probs)
                confidence = probs[pred_class]
                
                results.append({
                    'file': filename,
                    'prediction': tester.labels[pred_class],
                    'confidence': confidence
                })
                
                print(f"   {filename}: {tester.labels[pred_class]} ({confidence*100:.1f}%)")
            else:
                print(f"   {filename}: No hand detected")
    
    return results


# ============================================================================
# MAIN
# ============================================================================

def main():
    import sys
    
    if len(sys.argv) > 1:
        # Batch mode on folder
        folder = sys.argv[1]
        if os.path.isdir(folder):
            test_on_images(folder)
        else:
            print(f"❌ Folder not found: {folder}")
    else:
        # Webcam mode
        tester = ISLModelTester()
        tester.run()


if __name__ == "__main__":
    main()
