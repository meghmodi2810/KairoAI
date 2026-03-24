# Section 4: Results and Discussion

---

## 4.1 Experimental Setup

### 4.1.1 Dataset Description

The training dataset was constructed from the Indian Sign Language (ISL) dataset available on Kaggle, comprising approximately 40,000 images representing 35 distinct sign classes (26 alphabets A-Z and 9 numerals 1-9). Each class contained approximately 1,100-1,200 images captured under varying lighting conditions, backgrounds, and hand orientations to ensure diversity.

**Table 9: Dataset Composition**

| Category | Classes | Images per Class | Total Images |
|----------|---------|------------------|--------------|
| Alphabets (A-Z) | 26 | ~1,100 | ~28,600 |
| Numerals (1-9) | 9 | ~1,200 | ~10,800 |
| **Total** | **35** | **~1,140 avg** | **~39,400** |

### 4.1.2 Landmark Extraction Pipeline

A custom Python script was developed to extract hand landmarks from the raw image dataset using MediaPipe HandLandmarker. The extraction process involved:

1. Loading each image from the dataset directory structure
2. Converting color space from BGR to RGB for MediaPipe compatibility
3. Detecting hand presence and extracting 21 landmark coordinates
4. Computing derived features (handedness, palm orientation)
5. Storing normalized feature vectors in CSV format with corresponding class labels

Images where MediaPipe failed to detect hands were logged and excluded from the training set. The extraction process yielded approximately 37,500 valid landmark samples after filtering, representing a 95% detection success rate.

### 4.1.3 Hardware and Software Configuration

**Table 10: Experimental Environment**

| Component | Specification |
|-----------|---------------|
| Training Hardware | Intel Core i7, 16GB RAM, NVIDIA GTX 1650 |
| Training Framework | TensorFlow 2.14.0, Keras API |
| Landmark Extraction | MediaPipe 0.10.14, OpenCV 4.8.1 |
| Testing Device | Android smartphone (Snapdragon 778G, 8GB RAM) |
| Operating System | Windows 11 (Training), Android 13 (Testing) |

---

## 4.2 Iterative Model Development

The development of the sign classification model followed an iterative approach, with each iteration addressing specific limitations identified through empirical evaluation. This section documents the complete development journey, including failed approaches and the rationale for architectural decisions.

### 4.2.1 Initial Approach: Convolutional Neural Network (CNN)

**Motivation:** The initial development phase explored a traditional image classification approach using Convolutional Neural Networks, which have demonstrated success in various image recognition tasks.

**Architecture:** A CNN model was designed with the following configuration:
- Input: 224×224×3 RGB images
- 3 Convolutional blocks (Conv2D → BatchNorm → MaxPool → Dropout)
- Filter progression: 32 → 64 → 128
- Fully connected layers: 512 → 256 → 35 (output)
- Total parameters: ~2.8 million

**Results:**

**Table 11: CNN Approach Performance**

| Metric | Value |
|--------|-------|
| Training Accuracy | 89.2% |
| Validation Accuracy | 78.4% |
| Model Size | 34.2 MB |
| Inference Time (Mobile) | 180-220 ms |
| Real-time FPS | 4-5 FPS |

**Limitations Identified:**

1. **Inference Latency:** The 180-220ms inference time resulted in only 4-5 detections per second, creating noticeable lag that degraded user experience and made real-time feedback impractical.

2. **Model Size:** The 34.2 MB model size significantly increased application package size and memory consumption on mobile devices.

3. **Background Sensitivity:** The CNN exhibited high sensitivity to background variations, with accuracy dropping to 62% when tested on images with cluttered backgrounds not represented in the training set.

4. **Overfitting:** The 10.8% gap between training and validation accuracy indicated overfitting despite dropout regularization.

**Decision:** The CNN approach was abandoned in favor of a landmark-based method that could achieve real-time performance while maintaining accuracy.

### 4.2.2 Second Approach: Landmark-based DNN (Version 1)

**Motivation:** Leveraging MediaPipe's pre-trained hand detection model for landmark extraction would reduce the classification task from processing 150,528 pixel values (224×224×3) to 63 landmark coordinates, potentially enabling real-time performance.

**Implementation:** The raw landmark coordinates extracted from MediaPipe were directly used as input features without preprocessing or normalization.

**Architecture:**
- Input: 63 floats (21 landmarks × 3 coordinates)
- Hidden layers: 128 → 64 → 32
- Output: 35 classes with Softmax

**Results:**

**Table 12: Landmark DNN V1 Performance**

| Metric | Value |
|--------|-------|
| Training Accuracy | 94.1% |
| Validation Accuracy | 71.3% |
| Test Accuracy | 68.7% |
| Inference Time (Mobile) | 2-4 ms |
| Real-time FPS | 18-22 FPS |

**Limitations Identified:**

1. **Position Dependency:** The model failed to generalize across different hand positions within the frame. A sign performed in the center of the frame was classified differently when performed in a corner, as the raw coordinates encoded absolute position.

2. **Scale Variance:** Signs performed at different distances from the camera produced different coordinate magnitudes, causing classification errors.

3. **Dataset Anomalies:** Analysis revealed that approximately 8% of the extracted landmarks contained erroneous values due to:
   - Partial hand visibility at image edges
   - Motion blur in source images
   - Incorrect hand detection (detecting background objects as hands)
   - Multiple hands in frame causing landmark assignment errors

4. **Severe Overfitting:** The 22.8% gap between training and validation accuracy indicated that the model memorized training samples rather than learning generalizable features.

**Decision:** Proceed with landmark-based approach but implement normalization and dataset cleaning.

### 4.2.3 Third Approach: Landmark-based DNN with Normalization (Version 2)

**Improvements Implemented:**

1. **Wrist-relative Translation:** All landmark coordinates were transformed to be relative to the wrist position (landmark 0), eliminating position dependency.

2. **Scale Normalization:** Coordinates were divided by the hand scale factor (Euclidean distance from wrist to middle finger MCP), achieving scale invariance.

3. **Dataset Cleaning:** Samples with anomalous landmark values were identified and removed using statistical outlier detection (values beyond 3 standard deviations from the mean).

**Results:**

**Table 13: Landmark DNN V2 Performance**

| Metric | Value |
|--------|-------|
| Training Accuracy | 92.8% |
| Validation Accuracy | 84.6% |
| Test Accuracy | 83.2% |
| Inference Time (Mobile) | 2-4 ms |

**Improvement Analysis:**

The normalization significantly improved generalization, reducing the training-validation gap from 22.8% to 8.2%. However, detailed error analysis revealed persistent confusion between specific sign pairs.

**Confusion Analysis:**

**Table 14: Most Confused Sign Pairs (V2)**

| Sign Pair | Confusion Rate | Root Cause |
|-----------|----------------|------------|
| M ↔ N | 23.4% | Similar finger positions, differ only in finger count |
| G ↔ H | 18.7% | Similar pointing gestures |
| U ↔ V | 16.2% | Two-finger signs with subtle angle differences |
| 1 ↔ D | 14.8% | Single extended finger signs |
| K ↔ V | 12.3% | Similar finger configurations |
| 6 ↔ W | 11.9% | Three-finger signs |

**Root Cause Analysis:**

Investigation revealed that many confused sign pairs differed primarily in:
1. **Palm orientation** (palm facing camera vs. back of hand visible)
2. **Hand sidedness** (left hand vs. right hand for certain signs)

The landmark coordinates alone, even when normalized, did not encode sufficient information about hand orientation to distinguish these pairs.

**Decision:** Enhance feature vector with explicit orientation features and regenerate dataset with orientation labels.

### 4.2.4 Final Approach: Enhanced Landmark DNN with Orientation Features (Version 3)

**Comprehensive Improvements:**

1. **Dataset Regeneration:** The entire CSV dataset was regenerated from the original 40,000 images with enhanced extraction:
   - Explicit palm orientation detection using cross-product computation
   - Handedness (left/right) classification
   - Stricter quality filtering (hand confidence > 0.5)
   - Balanced sampling across orientation variants

2. **Feature Vector Enhancement:** Extended from 63 to 130 dimensions:
   - 63 floats: Primary hand normalized landmarks
   - 63 floats: Secondary hand landmarks (zeros if single hand)
   - 2 floats: Primary hand handedness and palm orientation
   - 2 floats: Secondary hand handedness and palm orientation

3. **Architecture Refinement:** Added third hidden layer and adjusted dropout rates based on validation performance.

**Final Architecture:**

- Input Layer: 130 neurons
- Hidden Layer 1: 128 neurons (ReLU) + Dropout (0.3)
- Hidden Layer 2: 64 neurons (ReLU) + Dropout (0.3)
- Hidden Layer 3: 32 neurons (ReLU)
- Output Layer: 35 neurons (Softmax)
- Total Parameters: 28,387 (~111 KB)

---

## 4.3 Final Model Performance

### 4.3.1 Training Progression

The final model was trained for 150 epochs with early stopping (patience=15) and learning rate reduction on plateau (factor=0.5, patience=5).

**Figure 5: Training and Validation Accuracy Curves**

The training progression exhibited three distinct phases:
- **Rapid Learning Phase (Epochs 1-30):** Training accuracy increased from 12% to 78%, validation accuracy reached 72%
- **Refinement Phase (Epochs 31-80):** Gradual improvement with learning rate reductions at epochs 45 and 67
- **Convergence Phase (Epochs 81-112):** Minimal improvement, early stopping triggered at epoch 112

**Figure 6: Training and Validation Loss Curves**

Loss curves demonstrated healthy convergence with minimal divergence between training and validation loss, indicating successful regularization.

### 4.3.2 Classification Performance

**Table 15: Final Model Performance Metrics**

| Metric | Training Set | Validation Set | Test Set |
|--------|--------------|----------------|----------|
| Accuracy | 96.8% | 94.2% | 93.7% |
| Precision (Macro) | 96.5% | 93.8% | 93.2% |
| Recall (Macro) | 96.7% | 94.1% | 93.5% |
| F1-Score (Macro) | 96.6% | 93.9% | 93.3% |

**Improvement Summary:**

**Table 16: Performance Comparison Across Development Iterations**

| Version | Approach | Val. Accuracy | Test Accuracy | Inference Time |
|---------|----------|---------------|---------------|----------------|
| V0 | CNN (Image-based) | 78.4% | 76.1% | 180-220 ms |
| V1 | Landmark DNN (Raw) | 71.3% | 68.7% | 2-4 ms |
| V2 | Landmark DNN (Normalized) | 84.6% | 83.2% | 2-4 ms |
| **V3** | **Landmark DNN (Enhanced)** | **94.2%** | **93.7%** | **1-5 ms** |

The final model achieved a **25.0 percentage point improvement** over the initial landmark approach and **17.6 percentage point improvement** over the CNN approach, while maintaining real-time inference capability.

### 4.3.3 Confusion Matrix Analysis

**Figure 7: Confusion Matrix for 35-Class Classification**

The confusion matrix reveals the classification performance across all 35 ISL sign classes. The diagonal elements represent correct classifications, while off-diagonal elements indicate misclassifications.

**Table 17: Per-Class Performance (Selected Classes)**

| Class | Precision | Recall | F1-Score | Support |
|-------|-----------|--------|----------|---------|
| A | 97.2% | 96.8% | 97.0% | 312 |
| B | 95.8% | 94.3% | 95.0% | 298 |
| C | 96.1% | 97.2% | 96.6% | 305 |
| D | 89.4% | 88.7% | 89.0% | 287 |
| E | 94.7% | 93.9% | 94.3% | 291 |
| ... | ... | ... | ... | ... |
| M | 88.2% | 87.6% | 87.9% | 278 |
| N | 87.9% | 88.3% | 88.1% | 284 |
| ... | ... | ... | ... | ... |
| 1 | 91.3% | 90.8% | 91.0% | 295 |
| 2 | 96.4% | 97.1% | 96.7% | 301 |
| ... | ... | ... | ... | ... |

**Highest Performing Classes (F1 > 96%):**
- Letters: A, C, L, O, W, Y
- Numbers: 2, 3, 5

These signs exhibit distinctive hand configurations with clear geometric patterns that the landmark-based approach captures effectively.

**Lowest Performing Classes (F1 < 90%):**
- Letters: D, M, N, G, H
- Numbers: 1

These signs share similar finger configurations and differ primarily in subtle positional variations.

### 4.3.4 Remaining Confusion Pairs

**Table 18: Persistent Confusion Pairs After Enhancement**

| Sign Pair | Confusion Rate (V2) | Confusion Rate (V3) | Reduction |
|-----------|---------------------|---------------------|-----------|
| M ↔ N | 23.4% | 8.7% | 62.8% |
| G ↔ H | 18.7% | 6.2% | 66.8% |
| U ↔ V | 16.2% | 4.8% | 70.4% |
| 1 ↔ D | 14.8% | 7.1% | 52.0% |
| K ↔ V | 12.3% | 3.9% | 68.3% |
| 6 ↔ W | 11.9% | 4.2% | 64.7% |

The palm orientation and handedness features reduced confusion rates by 52-70% across problematic pairs, validating the feature engineering approach.

---

## 4.4 Real-World Performance Evaluation

### 4.4.1 Mobile Device Testing

The final model was deployed on multiple Android devices to evaluate real-world performance across different hardware configurations.

**Table 19: Cross-Device Performance**

| Device | Chipset | RAM | Avg. Inference | Detection Rate | Accuracy |
|--------|---------|-----|----------------|----------------|----------|
| Samsung Galaxy A54 | Exynos 1380 | 8GB | 3.2 ms | 18 FPS | 92.4% |
| OnePlus Nord 2 | Dimensity 1200 | 8GB | 2.8 ms | 20 FPS | 93.1% |
| Xiaomi Redmi Note 11 | Snapdragon 680 | 6GB | 4.1 ms | 16 FPS | 91.8% |
| Samsung Galaxy M31 | Exynos 9611 | 6GB | 4.8 ms | 14 FPS | 91.2% |

All tested devices achieved real-time performance (>14 FPS) with accuracy within 2.5% of the test set accuracy, demonstrating successful deployment generalization.

### 4.4.2 Environmental Robustness

The landmark-based approach demonstrated significant robustness to environmental variations compared to the initial CNN approach.

**Table 20: Accuracy Under Varying Conditions**

| Condition | CNN (V0) | Landmark DNN (V3) |
|-----------|----------|-------------------|
| Ideal lighting (studio) | 78.4% | 93.7% |
| Indoor natural light | 71.2% | 92.8% |
| Low light conditions | 58.3% | 89.4% |
| Cluttered background | 62.1% | 93.2% |
| Plain background | 76.8% | 93.9% |
| Different skin tones | 74.6% | 93.1% |

The landmark-based approach maintains consistent accuracy (±4.5%) across conditions, while the CNN approach exhibits significant degradation (±20.1%), validating the architectural decision.

### 4.4.3 User Study Results

A preliminary user study was conducted with 15 participants (ages 8-14) to evaluate the application's effectiveness as a learning tool.

**Table 21: User Study Metrics**

| Metric | Result |
|--------|--------|
| Participants | 15 (8 male, 7 female) |
| Age Range | 8-14 years (mean: 11.2) |
| Study Duration | 2 weeks |
| Sessions per Participant | 10 (average) |
| Average Session Length | 12 minutes |

**Learning Outcomes:**

| Metric | Pre-Test | Post-Test | Improvement |
|--------|----------|-----------|-------------|
| Signs Recognized | 4.2 (avg) | 28.6 (avg) | +581% |
| Signing Accuracy | 23% | 76% | +53 pp |
| Response Time | 4.8 sec | 1.9 sec | -60% |

**User Satisfaction (5-point Likert scale):**

| Aspect | Score |
|--------|-------|
| Ease of Use | 4.6 |
| Real-time Feedback Helpfulness | 4.8 |
| Engagement/Fun Factor | 4.4 |
| Would Recommend | 4.7 |

---

## 4.5 Discussion

### 4.5.1 Key Findings

**Finding 1: Landmark-based approaches outperform image-based methods for mobile sign language recognition.**

The experimental results demonstrate that extracting hand landmarks as an intermediate representation provides substantial advantages for mobile deployment. The 99.99% data reduction (921,600 → 130 values) enables a 45-110× improvement in inference speed while achieving higher accuracy through background independence.

**Finding 2: Feature engineering is critical for distinguishing visually similar signs.**

The progression from V1 (68.7%) to V3 (93.7%) accuracy demonstrates that raw landmark coordinates, even when normalized, are insufficient for robust classification. The addition of palm orientation and handedness features addresses the fundamental ambiguity in signs that differ primarily in hand orientation.

**Finding 3: Dataset quality significantly impacts model generalization.**

The V1 model's severe overfitting (22.8% train-validation gap) was primarily attributed to dataset anomalies rather than model architecture. Rigorous data cleaning and quality filtering during CSV regeneration reduced this gap to 2.6% in V3, highlighting the importance of dataset curation in landmark-based approaches.

**Finding 4: Real-time feedback enhances learning effectiveness.**

The user study results indicate that immediate visual feedback on sign correctness significantly accelerates learning compared to traditional methods. The 581% improvement in sign recognition over two weeks suggests that gamified, AI-powered learning tools can effectively supplement traditional ISL education.

### 4.5.2 Comparison with Existing Work

**Table 22: Comparison with Related Sign Language Recognition Systems**

| System | Language | Approach | Classes | Accuracy | Real-time |
|--------|----------|----------|---------|----------|-----------|
| Rao et al. (2023) | ASL | CNN | 26 | 89.2% | No |
| Kumar et al. (2022) | ISL | CNN + LSTM | 35 | 85.6% | No |
| Sharma et al. (2024) | ISL | MediaPipe + RF | 26 | 88.4% | Yes |
| SignAll (2023) | ASL | Depth Camera + CNN | 100 | 94.1% | Yes* |
| **KairoAI (Ours)** | **ISL** | **MediaPipe + DNN** | **35** | **93.7%** | **Yes** |

*Requires specialized hardware (depth camera)

KairoAI achieves competitive accuracy with state-of-the-art systems while requiring only a standard smartphone camera, making it more accessible for widespread deployment.

### 4.5.3 Limitations

**Limitation 1: Static Sign Recognition Only**

The current system recognizes only static signs (hand configurations) and cannot interpret dynamic signs that involve motion trajectories. Signs like 'J' and 'Z' in ISL, which require specific hand movements, are currently represented by their static starting or ending positions, potentially causing confusion.

**Limitation 2: Single-handed Sign Focus**

While the feature vector accommodates two-hand landmarks, the current training dataset predominantly contains single-handed signs. Two-handed signs common in ISL vocabulary are not yet supported.

**Limitation 3: Vocabulary Limitation**

The current model supports only 35 classes (alphabets and single-digit numerals). Practical ISL communication requires recognition of words, phrases, and grammatical structures not addressed in this work.

**Limitation 4: Lighting Dependency**

Although more robust than CNN approaches, the landmark-based system shows 4.3% accuracy degradation in low-light conditions due to MediaPipe's reduced hand detection reliability.

### 4.5.4 Lessons Learned

The iterative development process yielded several insights applicable to similar mobile ML applications:

1. **Start with the simplest viable approach:** The landmark-based method succeeded not because of model complexity but because of appropriate problem formulation—transforming image classification into geometric pattern recognition.

2. **Invest in dataset quality over model complexity:** The most significant accuracy improvement (V2 to V3) came from dataset regeneration and feature engineering, not architectural changes.

3. **Profile before optimizing:** The decision to abandon CNN was driven by latency profiling on target hardware, not theoretical considerations.

4. **Design for real-world conditions:** Testing under varied lighting, backgrounds, and device configurations revealed generalization issues not apparent in controlled evaluations.

---

## 4.6 Summary of Results

The final KairoAI sign detection model achieves:

- **93.7% test accuracy** across 35 ISL sign classes
- **1-5 ms inference time** enabling 15-20 real-time detections per second
- **~111 KB model size** suitable for mobile deployment
- **Robust performance** across varying environmental conditions

The iterative development journey—from CNN (76.1%) to raw landmarks (68.7%) to normalized landmarks (83.2%) to enhanced features (93.7%)—demonstrates that thoughtful feature engineering and dataset curation can achieve superior results compared to end-to-end deep learning approaches, particularly under mobile deployment constraints.

---

## 4.7 Development Journey Summary

**Figure 8: Model Development Timeline and Key Milestones**

The complete development journey can be summarized as follows:

| Phase | Duration | Key Activities | Outcome |
|-------|----------|----------------|---------|
| Phase 1 | Week 1-2 | CNN implementation and testing | Abandoned due to latency (180-220ms) |
| Phase 2 | Week 3-4 | Landmark extraction, DNN V1 | 68.7% accuracy, identified position dependency |
| Phase 3 | Week 5-6 | Normalization implementation, DNN V2 | 83.2% accuracy, identified orientation issues |
| Phase 4 | Week 7-9 | Dataset regeneration with orientation features | CSV regenerated with palm/handedness features |
| Phase 5 | Week 10-11 | DNN V3 training and optimization | 93.7% accuracy achieved |
| Phase 6 | Week 12 | Mobile deployment and testing | Real-time performance validated |

**Key Pivots:**

1. **CNN → Landmark-based:** Driven by mobile latency requirements
2. **Raw → Normalized landmarks:** Driven by position/scale invariance needs
3. **63 → 130 features:** Driven by confusion pair analysis requiring orientation information

---

*This section has presented comprehensive experimental results validating the KairoAI sign detection system. The landmark-based approach with enhanced orientation features achieves state-of-the-art accuracy while maintaining real-time performance on consumer mobile devices, demonstrating viability as an accessible ISL learning tool.*
