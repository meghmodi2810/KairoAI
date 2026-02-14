"""
KairoAI Model Evaluation Script
================================
This script evaluates the trained ISL sign language classification model
and generates all metrics required for the research paper.

Run this script after training your model to get:
- Accuracy, Precision, Recall, F1-Score
- Confusion Matrix
- Per-class performance metrics
- Training history plots
- Confusion pair analysis
- All placeholder values for the research paper

Usage:
    python evaluate_model.py

Requirements:
    pip install tensorflow numpy pandas scikit-learn matplotlib seaborn
"""

import os
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    precision_recall_fscore_support
)
from sklearn.model_selection import train_test_split
import json
from datetime import datetime

# ============================================================================
# CONFIGURATION - Update these paths to match your project
# ============================================================================

CONFIG = {
    # Path to your trained model (.h5 or .keras or SavedModel directory)
    "model_path": "isl_model_advanced.tflite",
    
    # Path to your landmark CSV dataset
    "csv_path": "landmark_dataset_with_orientation.csv",
    
    # Path to training history JSON (if saved during training)
    "history_path": "model/training_history.json",
    
    # Output directory for evaluation results
    "output_dir": "evaluation_results",
    
    # Class names (A-Z and 1-9)
    "class_names": list("ABCDEFGHIJKLMNOPQRSTUVWXYZ") + [str(i) for i in range(1, 10)],
    
    # Test split ratio (should match what you used during training)
    "test_split": 0.2,
    
    # Validation split ratio
    "val_split": 0.2,
    
    # Random seed for reproducibility
    "random_seed": 42,
    
    # Number of features in your model input
    "num_features": 130,  # 63 landmarks * 2 hands + 4 orientation features
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def create_output_dir():
    """Create output directory if it doesn't exist."""
    if not os.path.exists(CONFIG["output_dir"]):
        os.makedirs(CONFIG["output_dir"])
    print(f"✓ Output directory: {CONFIG['output_dir']}")

def load_dataset():
    """Load and preprocess the landmark dataset from CSV."""
    print("\n" + "="*60)
    print("LOADING DATASET")
    print("="*60)
    
    if not os.path.exists(CONFIG["csv_path"]):
        print(f"✗ CSV file not found: {CONFIG['csv_path']}")
        print("  Please update CONFIG['csv_path'] with correct path")
        return None, None, None
    
    df = pd.read_csv(CONFIG["csv_path"])
    print(f"✓ Loaded CSV with {len(df)} samples")
    print(f"  Columns: {list(df.columns[:5])}... (total: {len(df.columns)})")
    
    # Assume last column is the label
    X = df.iloc[:, :-1].values
    y_labels = df.iloc[:, -1].values
    
    # Convert labels to indices
    label_to_idx = {label: idx for idx, label in enumerate(CONFIG["class_names"])}
    y = np.array([label_to_idx.get(str(label).upper(), -1) for label in y_labels])
    
    # Filter out invalid labels
    valid_mask = y >= 0
    X = X[valid_mask]
    y = y[valid_mask]
    
    print(f"✓ Valid samples: {len(X)}")
    print(f"  Feature dimensions: {X.shape[1]}")
    print(f"  Number of classes: {len(np.unique(y))}")
    
    # Class distribution
    unique, counts = np.unique(y, return_counts=True)
    print(f"\n  Class distribution:")
    for cls, cnt in zip(unique[:5], counts[:5]):
        print(f"    {CONFIG['class_names'][cls]}: {cnt} samples")
    print(f"    ... (showing first 5 of {len(unique)} classes)")
    
    return X, y, df

def load_model():
    """Load the trained model (supports both Keras and TFLite formats)."""
    print("\n" + "="*60)
    print("LOADING MODEL")
    print("="*60)
    
    if not os.path.exists(CONFIG["model_path"]):
        print(f"✗ Model file not found: {CONFIG['model_path']}")
        print("  Please update CONFIG['model_path'] with correct path")
        return None
    
    model_path = CONFIG["model_path"]
    
    # Check if it's a TFLite model
    if model_path.endswith('.tflite'):
        print(f"✓ Loading TFLite model from: {model_path}")
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Get model info
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        # Get model file size
        model_size = os.path.getsize(model_path) / 1024  # KB
        
        print(f"\n  TFLite Model Summary:")
        print(f"    Input shape: {input_details[0]['shape']}")
        print(f"    Input dtype: {input_details[0]['dtype']}")
        print(f"    Output shape: {output_details[0]['shape']}")
        print(f"    Model size: {model_size:.1f} KB")
        
        # Return interpreter wrapped in a dict for identification
        return {"type": "tflite", "interpreter": interpreter, 
                "input_details": input_details, "output_details": output_details}
    else:
        # Load Keras model
        model = keras.models.load_model(model_path)
        print(f"✓ Keras model loaded from: {model_path}")
        
        print(f"\n  Model Summary:")
        total_params = model.count_params()
        print(f"    Total parameters: {total_params:,}")
        print(f"    Model size: ~{total_params * 4 / 1024:.1f} KB (float32)")
        
        return {"type": "keras", "model": model}


def predict_with_model(model_dict, X):
    """Make predictions using either Keras or TFLite model."""
    if model_dict["type"] == "tflite":
        interpreter = model_dict["interpreter"]
        input_details = model_dict["input_details"]
        output_details = model_dict["output_details"]
        
        predictions = []
        total = len(X)
        print_interval = max(1, total // 10)  # Print progress every 10%
        
        for i in range(total):
            # Prepare input
            input_data = X[i:i+1].astype(np.float32)
            interpreter.set_tensor(input_details[0]['index'], input_data)
            
            # Run inference
            interpreter.invoke()
            
            # Get output
            output = interpreter.get_tensor(output_details[0]['index'])
            predictions.append(output[0])
            
            # Progress indicator
            if (i + 1) % print_interval == 0 or i == total - 1:
                print(f"    Progress: {i+1}/{total} ({(i+1)/total*100:.0f}%)", end='\r')
        
        print()  # New line after progress
        return np.array(predictions)
    else:
        # Keras model
        return model_dict["model"].predict(X, verbose=0)

def split_data(X, y):
    """Split data into train, validation, and test sets."""
    print("\n" + "="*60)
    print("SPLITTING DATA")
    print("="*60)
    
    # First split: train+val vs test
    X_trainval, X_test, y_trainval, y_test = train_test_split(
        X, y, 
        test_size=CONFIG["test_split"], 
        random_state=CONFIG["random_seed"],
        stratify=y
    )
    
    # Second split: train vs val
    X_train, X_val, y_train, y_val = train_test_split(
        X_trainval, y_trainval,
        test_size=CONFIG["val_split"],
        random_state=CONFIG["random_seed"],
        stratify=y_trainval
    )
    
    print(f"✓ Data split complete:")
    print(f"    Training set:   {len(X_train):,} samples ({len(X_train)/len(X)*100:.1f}%)")
    print(f"    Validation set: {len(X_val):,} samples ({len(X_val)/len(X)*100:.1f}%)")
    print(f"    Test set:       {len(X_test):,} samples ({len(X_test)/len(X)*100:.1f}%)")
    
    return X_train, X_val, X_test, y_train, y_val, y_test

# ============================================================================
# EVALUATION FUNCTIONS
# ============================================================================

def evaluate_model(model_dict, X_train, X_val, X_test, y_train, y_val, y_test):
    """Evaluate model on all datasets and compute metrics."""
    print("\n" + "="*60)
    print("EVALUATING MODEL")
    print("="*60)
    
    results = {}
    
    datasets = [
        ("Training", X_train, y_train),
        ("Validation", X_val, y_val),
        ("Test", X_test, y_test)
    ]
    
    for name, X, y in datasets:
        print(f"\n  Evaluating on {name} set ({len(X)} samples)...")
        
        # Get predictions using the appropriate method
        y_pred_proba = predict_with_model(model_dict, X)
        y_pred = np.argmax(y_pred_proba, axis=1)
        
        # Calculate metrics
        accuracy = accuracy_score(y, y_pred) * 100
        precision = precision_score(y, y_pred, average='macro', zero_division=0) * 100
        recall = recall_score(y, y_pred, average='macro', zero_division=0) * 100
        f1 = f1_score(y, y_pred, average='macro', zero_division=0) * 100
        
        results[name.lower()] = {
            "accuracy": accuracy,
            "precision": precision,
            "recall": recall,
            "f1_score": f1,
            "y_true": y,
            "y_pred": y_pred,
            "y_pred_proba": y_pred_proba
        }
        
        print(f"    ✓ {name} Accuracy:  {accuracy:.2f}%")
        print(f"    ✓ {name} Precision: {precision:.2f}%")
        print(f"    ✓ {name} Recall:    {recall:.2f}%")
        print(f"    ✓ {name} F1-Score:  {f1:.2f}%")
    
    return results

def generate_confusion_matrix(y_true, y_pred, save_path=None):
    """Generate and plot confusion matrix."""
    print("\n" + "="*60)
    print("GENERATING CONFUSION MATRIX")
    print("="*60)
    
    cm = confusion_matrix(y_true, y_pred)
    
    # Plot confusion matrix
    plt.figure(figsize=(16, 14))
    sns.heatmap(
        cm, 
        annot=True, 
        fmt='d', 
        cmap='Blues',
        xticklabels=CONFIG["class_names"],
        yticklabels=CONFIG["class_names"],
        annot_kws={"size": 8}
    )
    plt.title('Confusion Matrix - 35 Class ISL Sign Classification', fontsize=14)
    plt.xlabel('Predicted Label', fontsize=12)
    plt.ylabel('True Label', fontsize=12)
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"✓ Confusion matrix saved to: {save_path}")
    
    plt.close()
    
    return cm

def analyze_per_class_performance(y_true, y_pred):
    """Analyze per-class precision, recall, and F1-score."""
    print("\n" + "="*60)
    print("PER-CLASS PERFORMANCE ANALYSIS")
    print("="*60)
    
    precision, recall, f1, support = precision_recall_fscore_support(
        y_true, y_pred, average=None, zero_division=0
    )
    
    # Create DataFrame for easy viewing
    class_metrics = pd.DataFrame({
        'Class': CONFIG["class_names"],
        'Precision': precision * 100,
        'Recall': recall * 100,
        'F1-Score': f1 * 100,
        'Support': support
    })
    
    # Sort by F1-Score
    class_metrics_sorted = class_metrics.sort_values('F1-Score', ascending=False)
    
    print("\n  Top 10 Best Performing Classes:")
    print("  " + "-"*55)
    print(f"  {'Class':<8} {'Precision':>10} {'Recall':>10} {'F1-Score':>10} {'Support':>8}")
    print("  " + "-"*55)
    for _, row in class_metrics_sorted.head(10).iterrows():
        print(f"  {row['Class']:<8} {row['Precision']:>10.1f}% {row['Recall']:>10.1f}% {row['F1-Score']:>10.1f}% {int(row['Support']):>8}")
    
    print("\n  Bottom 10 Worst Performing Classes:")
    print("  " + "-"*55)
    print(f"  {'Class':<8} {'Precision':>10} {'Recall':>10} {'F1-Score':>10} {'Support':>8}")
    print("  " + "-"*55)
    for _, row in class_metrics_sorted.tail(10).iterrows():
        print(f"  {row['Class']:<8} {row['Precision']:>10.1f}% {row['Recall']:>10.1f}% {row['F1-Score']:>10.1f}% {int(row['Support']):>8}")
    
    return class_metrics

def analyze_confusion_pairs(cm):
    """Identify the most confused sign pairs."""
    print("\n" + "="*60)
    print("CONFUSION PAIR ANALYSIS")
    print("="*60)
    
    confusion_pairs = []
    n_classes = len(CONFIG["class_names"])
    
    for i in range(n_classes):
        for j in range(n_classes):
            if i != j and cm[i, j] > 0:
                # Confusion rate: how often class i is misclassified as class j
                total_i = cm[i, :].sum()
                if total_i > 0:
                    confusion_rate = cm[i, j] / total_i * 100
                    confusion_pairs.append({
                        'From': CONFIG["class_names"][i],
                        'To': CONFIG["class_names"][j],
                        'Count': cm[i, j],
                        'Rate': confusion_rate
                    })
    
    # Sort by confusion count
    confusion_df = pd.DataFrame(confusion_pairs)
    confusion_df = confusion_df.sort_values('Count', ascending=False)
    
    # Aggregate bidirectional confusion
    bidirectional = {}
    for _, row in confusion_df.iterrows():
        pair = tuple(sorted([row['From'], row['To']]))
        if pair not in bidirectional:
            bidirectional[pair] = {'count': 0, 'rate': 0}
        bidirectional[pair]['count'] += row['Count']
        bidirectional[pair]['rate'] += row['Rate']
    
    bidirectional_list = [
        {'Pair': f"{p[0]} ↔ {p[1]}", 'Total_Count': v['count'], 'Combined_Rate': v['rate']}
        for p, v in bidirectional.items()
    ]
    bidirectional_df = pd.DataFrame(bidirectional_list)
    bidirectional_df = bidirectional_df.sort_values('Total_Count', ascending=False)
    
    print("\n  Top 10 Most Confused Sign Pairs (Bidirectional):")
    print("  " + "-"*45)
    print(f"  {'Pair':<12} {'Total Errors':>15} {'Combined Rate':>15}")
    print("  " + "-"*45)
    for _, row in bidirectional_df.head(10).iterrows():
        print(f"  {row['Pair']:<12} {int(row['Total_Count']):>15} {row['Combined_Rate']:>14.1f}%")
    
    return bidirectional_df

def plot_training_history(history_path=None, save_dir=None):
    """Plot training history curves."""
    print("\n" + "="*60)
    print("PLOTTING TRAINING HISTORY")
    print("="*60)
    
    if history_path and os.path.exists(history_path):
        with open(history_path, 'r') as f:
            history = json.load(f)
        print(f"✓ Loaded training history from: {history_path}")
    else:
        print(f"✗ Training history not found at: {history_path}")
        print("  To save training history during training, add this code:")
        print("  ")
        print("  history = model.fit(...)")
        print("  with open('training_history.json', 'w') as f:")
        print("      json.dump(history.history, f)")
        return None
    
    # Plot accuracy
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Accuracy plot
    axes[0].plot(history.get('accuracy', []), label='Training Accuracy', linewidth=2)
    axes[0].plot(history.get('val_accuracy', []), label='Validation Accuracy', linewidth=2)
    axes[0].set_title('Model Accuracy Over Epochs', fontsize=12)
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    
    # Loss plot
    axes[1].plot(history.get('loss', []), label='Training Loss', linewidth=2)
    axes[1].plot(history.get('val_loss', []), label='Validation Loss', linewidth=2)
    axes[1].set_title('Model Loss Over Epochs', fontsize=12)
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_dir:
        save_path = os.path.join(save_dir, 'training_curves.png')
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"✓ Training curves saved to: {save_path}")
    
    plt.close()
    
    # Print final metrics
    if 'accuracy' in history:
        final_train_acc = history['accuracy'][-1] * 100
        final_val_acc = history.get('val_accuracy', [0])[-1] * 100
        print(f"\n  Final Training Accuracy: {final_train_acc:.2f}%")
        print(f"  Final Validation Accuracy: {final_val_acc:.2f}%")
        print(f"  Train-Val Gap: {abs(final_train_acc - final_val_acc):.2f}%")
    
    return history

def generate_research_paper_metrics(results, class_metrics, confusion_pairs):
    """Generate formatted metrics for research paper placeholders."""
    print("\n" + "="*60)
    print("RESEARCH PAPER METRICS (Copy these to replace placeholders)")
    print("="*60)
    
    report = []
    report.append("\n" + "="*70)
    report.append("TABLE 15: Final Model Performance Metrics")
    report.append("="*70)
    report.append(f"| Metric | Training Set | Validation Set | Test Set |")
    report.append(f"|--------|--------------|----------------|----------|")
    report.append(f"| Accuracy | {results['training']['accuracy']:.1f}% | {results['validation']['accuracy']:.1f}% | {results['test']['accuracy']:.1f}% |")
    report.append(f"| Precision (Macro) | {results['training']['precision']:.1f}% | {results['validation']['precision']:.1f}% | {results['test']['precision']:.1f}% |")
    report.append(f"| Recall (Macro) | {results['training']['recall']:.1f}% | {results['validation']['recall']:.1f}% | {results['test']['recall']:.1f}% |")
    report.append(f"| F1-Score (Macro) | {results['training']['f1_score']:.1f}% | {results['validation']['f1_score']:.1f}% | {results['test']['f1_score']:.1f}% |")
    
    report.append("\n" + "="*70)
    report.append("TABLE 17: Per-Class Performance (Top and Bottom)")
    report.append("="*70)
    
    # Top 5 classes
    top_classes = class_metrics.nlargest(5, 'F1-Score')
    report.append("\nHighest Performing Classes (F1 > threshold):")
    report.append("| Class | Precision | Recall | F1-Score | Support |")
    report.append("|-------|-----------|--------|----------|---------|")
    for _, row in top_classes.iterrows():
        report.append(f"| {row['Class']} | {row['Precision']:.1f}% | {row['Recall']:.1f}% | {row['F1-Score']:.1f}% | {int(row['Support'])} |")
    
    # Bottom 5 classes
    bottom_classes = class_metrics.nsmallest(5, 'F1-Score')
    report.append("\nLowest Performing Classes:")
    report.append("| Class | Precision | Recall | F1-Score | Support |")
    report.append("|-------|-----------|--------|----------|---------|")
    for _, row in bottom_classes.iterrows():
        report.append(f"| {row['Class']} | {row['Precision']:.1f}% | {row['Recall']:.1f}% | {row['F1-Score']:.1f}% | {int(row['Support'])} |")
    
    report.append("\n" + "="*70)
    report.append("TABLE 18: Most Confused Sign Pairs")
    report.append("="*70)
    report.append("| Sign Pair | Confusion Count | Combined Rate |")
    report.append("|-----------|-----------------|---------------|")
    for _, row in confusion_pairs.head(6).iterrows():
        report.append(f"| {row['Pair']} | {int(row['Total_Count'])} | {row['Combined_Rate']:.1f}% |")
    
    report.append("\n" + "="*70)
    report.append("KEY METRICS SUMMARY")
    report.append("="*70)
    report.append(f"Test Accuracy: {results['test']['accuracy']:.1f}%")
    report.append(f"Test Precision: {results['test']['precision']:.1f}%")
    report.append(f"Test Recall: {results['test']['recall']:.1f}%")
    report.append(f"Test F1-Score: {results['test']['f1_score']:.1f}%")
    report.append(f"Train-Val Accuracy Gap: {abs(results['training']['accuracy'] - results['validation']['accuracy']):.1f}%")
    
    # Print and save report
    report_text = "\n".join(report)
    print(report_text)
    
    return report_text

def save_full_report(results, class_metrics, confusion_pairs, cm, output_dir):
    """Save complete evaluation report to file."""
    print("\n" + "="*60)
    print("SAVING FULL REPORT")
    print("="*60)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Save metrics to JSON
    metrics_json = {
        "timestamp": timestamp,
        "training": {k: v for k, v in results['training'].items() if k not in ['y_true', 'y_pred', 'y_pred_proba']},
        "validation": {k: v for k, v in results['validation'].items() if k not in ['y_true', 'y_pred', 'y_pred_proba']},
        "test": {k: v for k, v in results['test'].items() if k not in ['y_true', 'y_pred', 'y_pred_proba']},
    }
    
    json_path = os.path.join(output_dir, f'evaluation_metrics_{timestamp}.json')
    with open(json_path, 'w') as f:
        json.dump(metrics_json, f, indent=2)
    print(f"✓ Metrics JSON saved to: {json_path}")
    
    # Save class metrics to CSV
    class_csv_path = os.path.join(output_dir, f'per_class_metrics_{timestamp}.csv')
    class_metrics.to_csv(class_csv_path, index=False)
    print(f"✓ Per-class metrics saved to: {class_csv_path}")
    
    # Save confusion pairs to CSV
    pairs_csv_path = os.path.join(output_dir, f'confusion_pairs_{timestamp}.csv')
    confusion_pairs.to_csv(pairs_csv_path, index=False)
    print(f"✓ Confusion pairs saved to: {pairs_csv_path}")
    
    # Save confusion matrix as CSV
    cm_csv_path = os.path.join(output_dir, f'confusion_matrix_{timestamp}.csv')
    cm_df = pd.DataFrame(cm, index=CONFIG["class_names"], columns=CONFIG["class_names"])
    cm_df.to_csv(cm_csv_path)
    print(f"✓ Confusion matrix CSV saved to: {cm_csv_path}")
    
    # Generate and save full classification report
    report_path = os.path.join(output_dir, f'classification_report_{timestamp}.txt')
    with open(report_path, 'w') as f:
        f.write("="*70 + "\n")
        f.write("KAIROAI MODEL EVALUATION REPORT\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("="*70 + "\n\n")
        
        f.write("OVERALL METRICS\n")
        f.write("-"*70 + "\n")
        for dataset in ['training', 'validation', 'test']:
            f.write(f"\n{dataset.upper()} SET:\n")
            f.write(f"  Accuracy:  {results[dataset]['accuracy']:.2f}%\n")
            f.write(f"  Precision: {results[dataset]['precision']:.2f}%\n")
            f.write(f"  Recall:    {results[dataset]['recall']:.2f}%\n")
            f.write(f"  F1-Score:  {results[dataset]['f1_score']:.2f}%\n")
        
        f.write("\n\nDETAILED CLASSIFICATION REPORT (Test Set)\n")
        f.write("-"*70 + "\n")
        f.write(classification_report(
            results['test']['y_true'], 
            results['test']['y_pred'],
            target_names=CONFIG["class_names"],
            digits=3
        ))
    
    print(f"✓ Full classification report saved to: {report_path}")
    
    return json_path

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    """Main evaluation pipeline."""
    print("\n" + "="*70)
    print("   KAIROAI MODEL EVALUATION SCRIPT")
    print("   Indian Sign Language Classification Model")
    print("="*70)
    
    # Create output directory
    create_output_dir()
    
    # Load dataset
    X, y, df = load_dataset()
    if X is None:
        print("\n✗ Failed to load dataset. Please check the CSV path.")
        return
    
    # Load model
    model = load_model()
    if model is None:
        print("\n✗ Failed to load model. Please check the model path.")
        return
    
    # Split data
    X_train, X_val, X_test, y_train, y_val, y_test = split_data(X, y)
    
    # Evaluate model
    results = evaluate_model(model, X_train, X_val, X_test, y_train, y_val, y_test)
    
    # Generate confusion matrix
    cm_path = os.path.join(CONFIG["output_dir"], "confusion_matrix.png")
    cm = generate_confusion_matrix(results['test']['y_true'], results['test']['y_pred'], cm_path)
    
    # Analyze per-class performance
    class_metrics = analyze_per_class_performance(results['test']['y_true'], results['test']['y_pred'])
    
    # Analyze confusion pairs
    confusion_pairs = analyze_confusion_pairs(cm)
    
    # Plot training history
    plot_training_history(CONFIG["history_path"], CONFIG["output_dir"])
    
    # Generate research paper metrics
    report = generate_research_paper_metrics(results, class_metrics, confusion_pairs)
    
    # Save full report
    save_full_report(results, class_metrics, confusion_pairs, cm, CONFIG["output_dir"])
    
    print("\n" + "="*70)
    print("   EVALUATION COMPLETE!")
    print("="*70)
    print(f"\n  All results saved to: {CONFIG['output_dir']}/")
    print("\n  Files generated:")
    print("    • confusion_matrix.png - Visual confusion matrix")
    print("    • training_curves.png - Accuracy/Loss plots")
    print("    • evaluation_metrics_*.json - Metrics in JSON format")
    print("    • per_class_metrics_*.csv - Per-class performance")
    print("    • confusion_pairs_*.csv - Most confused pairs")
    print("    • classification_report_*.txt - Full sklearn report")
    print("\n  Use the printed metrics above to replace placeholders")
    print("  in RESEARCH_PAPER_RESULTS_DISCUSSION.md")
    print("="*70 + "\n")

if __name__ == "__main__":
    main()
