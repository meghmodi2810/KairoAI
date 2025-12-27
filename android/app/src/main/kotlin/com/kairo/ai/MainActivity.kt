package com.kairo.ai

import android.Manifest
import android.content.pm.PackageManager
import android.content.res.AssetFileDescriptor
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import org.tensorflow.lite.Interpreter
import java.io.ByteArrayOutputStream
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.sqrt
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "KairoAI"
        private const val METHOD_CHANNEL = "com.kairo.ai/detection"
        private const val EVENT_CHANNEL = "com.kairo.ai/detection_stream"
        private const val CAMERA_PERMISSION_CODE = 100
        
        // Confidence threshold - predictions below this are ignored
        private const val MIN_CONFIDENCE_THRESHOLD = 0.15f  // Very low threshold to show all predictions
        
        // Prediction stability - how many consistent predictions needed
        private const val PREDICTION_STABILITY_COUNT = 1  // Immediate response (no stabilization)
    }
    
    // Event sink for streaming data to Flutter
    private var eventSink: EventChannel.EventSink? = null
    
    // Camera related
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null
    private lateinit var cameraExecutor: ExecutorService
    private var isDetectionActive = false
    private var useFrontCamera = true
    private var camera: Camera? = null
    
    // MediaPipe HandLandmarker
    private var handLandmarker: HandLandmarker? = null
    private var isHandLandmarkerReady = false
    
    // TensorFlow Lite Interpreter
    private var tfliteInterpreter: Interpreter? = null
    private var isTfliteReady = false
    
    // Sign language labels (35 classes to match ISL model output)
    // MUST MATCH the LABELS in landmark_model.py: A-Z (26) + 1-9 (9) = 35
    private val signLabels = listOf(
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4",
        "5", "6", "7", "8", "9"
    )
    
    // Handler for UI thread operations
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Frame processing control
    private var frameCounter = 0
    private val PROCESS_EVERY_N_FRAMES = 2  // Process more frames for responsiveness
    private var lastProcessTime = 0L
    private val MIN_PROCESS_INTERVAL_MS = 66L  // ~15 FPS for detection
    
    // Prediction stabilization
    private var lastPredictions = mutableListOf<String>()
    private var stablePrediction = ""
    private var stableConfidence = 0f
    
    // Frame data for Flutter (to show camera preview)
    private var lastFrameBitmap: Bitmap? = null
    private var isProcessingFrame = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🚀 KairoAI MainActivity initializing...")
        Log.d(TAG, "========================================")
        
        // Initialize camera executor with more capacity
        cameraExecutor = Executors.newFixedThreadPool(2)
        Log.d(TAG, "📷 Camera executor created with 2 threads")
        
        // Initialize ML models
        initializeHandLandmarker()
        initializeTFLite()
        
        // Setup MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            Log.d(TAG, "📱 Method called: ${call.method}")
            when (call.method) {
                "startDetection" -> {
                    startDetection()
                    result.success(mapOf(
                        "success" to true,
                        "handLandmarkerReady" to isHandLandmarkerReady,
                        "tfliteReady" to isTfliteReady
                    ))
                }
                "stopDetection" -> {
                    stopDetection()
                    result.success(true)
                }
                "switchCamera" -> {
                    switchCamera()
                    result.success(useFrontCamera)
                }
                "checkCameraPermission" -> {
                    result.success(checkCameraPermission())
                }
                "requestCameraPermission" -> {
                    requestCameraPermission()
                    result.success(true)
                }
                "isFrontCamera" -> {
                    result.success(useFrontCamera)
                }
                "getStatus" -> {
                    result.success(mapOf(
                        "isDetectionActive" to isDetectionActive,
                        "handLandmarkerReady" to isHandLandmarkerReady,
                        "tfliteReady" to isTfliteReady,
                        "useFrontCamera" to useFrontCamera
                    ))
                }
                "resetPrediction" -> {
                    resetPredictionState()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Setup EventChannel
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "✅ Flutter EventChannel connected")
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "❌ Flutter EventChannel disconnected")
            }
        })
        
        Log.d(TAG, "✅ KairoAI MainActivity initialized")
    }
    
    private fun resetPredictionState() {
        lastPredictions.clear()
        stablePrediction = ""
        stableConfidence = 0f
    }
    
    private fun initializeHandLandmarker() {
        try {
            Log.d(TAG, "🔄 Initializing MediaPipe HandLandmarker...")
            
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()
            
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumHands(2)  // Model expects 2 hands (126 = 2 * 21 * 3)
                .setMinHandDetectionConfidence(0.3f)  // Lower threshold for better detection
                .setMinHandPresenceConfidence(0.3f)   // Lower threshold for better detection
                .setMinTrackingConfidence(0.3f)       // Lower threshold for better detection
                .setRunningMode(com.google.mediapipe.tasks.vision.core.RunningMode.IMAGE)
                .build()
            
            handLandmarker = HandLandmarker.createFromOptions(this, options)
            isHandLandmarkerReady = true
            
            Log.d(TAG, "✅ MediaPipe HandLandmarker initialized successfully!")
            Log.d(TAG, "   Detection confidence: 0.3, Presence confidence: 0.3, Tracking: 0.3")
            Log.d(TAG, "   Max hands: 2, Running mode: IMAGE")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing HandLandmarker: ${e.message}")
            e.printStackTrace()
            isHandLandmarkerReady = false
        }
    }
    
    private fun initializeTFLite() {
        try {
            Log.d(TAG, "🔄 Initializing TFLite model...")
            
            val modelBuffer = loadModelFile("isl_model.tflite")
            val options = Interpreter.Options().apply {
                setNumThreads(4)
            }
            tfliteInterpreter = Interpreter(modelBuffer, options)
            isTfliteReady = true
            
            // Log model info
            val inputTensor = tfliteInterpreter?.getInputTensor(0)
            val outputTensor = tfliteInterpreter?.getOutputTensor(0)
            Log.d(TAG, "✅ TFLite model loaded!")
            Log.d(TAG, "   Input shape: ${inputTensor?.shape()?.contentToString()}")
            Log.d(TAG, "   Output shape: ${outputTensor?.shape()?.contentToString()}")
            Log.d(TAG, "   Number of labels defined: ${signLabels.size}")
            Log.d(TAG, "   Labels: ${signLabels.joinToString(", ")}")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading TFLite model: ${e.message}")
            Log.e(TAG, "   Ensure 'isl_model.tflite' exists in android/app/src/main/assets/")
            e.printStackTrace()
            isTfliteReady = false
        }
    }
    
    private fun loadModelFile(modelPath: String): MappedByteBuffer {
        val assetFileDescriptor: AssetFileDescriptor = assets.openFd(modelPath)
        val fileInputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = fileInputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
    
    private fun startDetection() {
        if (!checkCameraPermission()) {
            Log.e(TAG, "❌ Camera permission not granted")
            sendError("Camera permission not granted")
            return
        }
        
        if (!isHandLandmarkerReady) {
            Log.e(TAG, "❌ HandLandmarker not ready")
            sendError("Hand detection model not loaded")
            return
        }
        
        if (isDetectionActive) {
            Log.d(TAG, "⚠️ Detection already active")
            return
        }
        
        isDetectionActive = true
        frameCounter = 0
        lastProcessTime = 0L
        isProcessingFrame = false
        resetPredictionState()
        
        Log.d(TAG, "🎥 Starting native camera for detection...")
        
        // Test that executor is working
        cameraExecutor.execute {
            Log.d(TAG, "✅ CameraExecutor test task executed successfully on thread: ${Thread.currentThread().name}")
        }
        
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraForAnalysis()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting camera provider: ${e.message}")
                sendError("Failed to access camera")
                isDetectionActive = false
            }
        }, ContextCompat.getMainExecutor(this))
    }
    
    private fun bindCameraForAnalysis() {
        val provider = cameraProvider ?: run {
            Log.e(TAG, "❌ Camera provider is null")
            return
        }
        
        // Unbind all first
        provider.unbindAll()
        
        // Check if the desired camera is available
        val hasBackCamera = try {
            provider.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA)
        } catch (e: Exception) { false }
        
        val hasFrontCamera = try {
            provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
        } catch (e: Exception) { false }
        
        Log.d(TAG, "📷 Available cameras - Front: $hasFrontCamera, Back: $hasBackCamera")
        
        // Select camera based on availability
        val cameraSelector = when {
            useFrontCamera && hasFrontCamera -> CameraSelector.DEFAULT_FRONT_CAMERA
            !useFrontCamera && hasBackCamera -> CameraSelector.DEFAULT_BACK_CAMERA
            hasFrontCamera -> {
                useFrontCamera = true
                CameraSelector.DEFAULT_FRONT_CAMERA
            }
            hasBackCamera -> {
                useFrontCamera = false
                CameraSelector.DEFAULT_BACK_CAMERA
            }
            else -> {
                Log.e(TAG, "❌ No camera available")
                sendError("No camera available on device")
                return
            }
        }
        
        // Use moderate resolution for balance between quality and performance
        Log.d(TAG, "🎥 Setting up ImageAnalysis...")
        Log.d(TAG, "🔧 CameraExecutor status: ${if (::cameraExecutor.isInitialized) "initialized" else "NOT initialized"}")
        
        imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(android.util.Size(640, 480))  // Standard VGA for better detection
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()
            .also { analysis ->
                Log.d(TAG, "📷 Setting analyzer on cameraExecutor...")
                analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                    try {
                        Log.d(TAG, "📷 ANALYZER CALLBACK - frame ${imageProxy.width}x${imageProxy.height}, isDetectionActive=$isDetectionActive")
                        if (frameCounter == 0) {
                            Log.d(TAG, "📹 First frame: ${imageProxy.width}x${imageProxy.height}, format=${imageProxy.format}, rotation=${imageProxy.imageInfo.rotationDegrees}")
                        }
                        processFrame(imageProxy)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ ANALYZER CALLBACK ERROR: ${e.message}")
                        e.printStackTrace()
                        try { imageProxy.close() } catch (_: Exception) {}
                    }
                }
                Log.d(TAG, "✅ Analyzer set successfully")
            }
        
        try {
            camera = provider.bindToLifecycle(
                this,
                cameraSelector,
                imageAnalysis
            )
            
            Log.d(TAG, "✅ Camera bound for analysis: ${if (useFrontCamera) "FRONT" else "BACK"}")
            
            // Send initial status
            sendDetectionStatus("Detection started - Show your hand to the camera")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to bind camera: ${e.message}")
            e.printStackTrace()
            
            // Try the other camera if this one fails
            if (useFrontCamera && hasBackCamera) {
                useFrontCamera = false
                Log.d(TAG, "⚠️ Trying back camera instead...")
                bindCameraForAnalysis()
            } else if (!useFrontCamera && hasFrontCamera) {
                useFrontCamera = true
                Log.d(TAG, "⚠️ Trying front camera instead...")
                bindCameraForAnalysis()
            } else {
                sendError("Failed to start camera: ${e.message}")
                isDetectionActive = false
            }
        }
    }
    
    private fun processFrame(imageProxy: ImageProxy) {
        Log.d(TAG, "🔄 processFrame called - isDetectionActive=$isDetectionActive")
        
        if (!isDetectionActive) {
            Log.d(TAG, "⏹️ Frame skipped - detection not active")
            imageProxy.close()
            return
        }
        
        // Prevent concurrent processing
        if (isProcessingFrame) {
            imageProxy.close()
            return
        }
        
        // Frame rate control - only log occasionally
        val currentTime = System.currentTimeMillis()
        val timeSinceLastProcess = currentTime - lastProcessTime
        if (timeSinceLastProcess < MIN_PROCESS_INTERVAL_MS) {
            imageProxy.close()
            return
        }
        
        frameCounter++
        
        // Process every frame now for debugging
        // if (frameCounter % PROCESS_EVERY_N_FRAMES != 0) {
        //     imageProxy.close()
        //     return
        // }
        
        isProcessingFrame = true
        lastProcessTime = currentTime
        
        // Log every 10th frame to avoid flooding
        if (frameCounter % 10 == 1) {
            Log.d(TAG, "📸 Processing frame #$frameCounter (${imageProxy.width}x${imageProxy.height})")
        }
        
        try {
            val bitmap = convertToBitmap(imageProxy)
            if (bitmap != null) {
                Log.d(TAG, "✅ Bitmap created: ${bitmap.width}x${bitmap.height}")
                detectHands(bitmap)
                bitmap.recycle()
            } else {
                Log.w(TAG, "⚠️ Failed to convert frame to bitmap")
                sendNoHandDetected()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Frame processing error: ${e.message}")
            e.printStackTrace()
            sendNoHandDetected()
        } finally {
            isProcessingFrame = false
            imageProxy.close()
        }
    }
    
    private fun convertToBitmap(imageProxy: ImageProxy): Bitmap? {
        return try {
            val width = imageProxy.width
            val height = imageProxy.height
            
            val planes = imageProxy.planes
            
            // Get plane buffers and properties
            val yPlane = planes[0]
            val uPlane = planes[1]
            val vPlane = planes[2]
            
            val yBuffer = yPlane.buffer
            val uBuffer = uPlane.buffer
            val vBuffer = vPlane.buffer
            
            val yRowStride = yPlane.rowStride
            val uvRowStride = uPlane.rowStride
            val uvPixelStride = uPlane.pixelStride
            
            // Create NV21 byte array (Y + interleaved VU)
            val nv21Size = width * height + width * height / 2
            val nv21 = ByteArray(nv21Size)
            
            // Copy Y plane
            var destPos = 0
            if (yRowStride == width) {
                // Fast path - no row padding
                yBuffer.position(0)
                yBuffer.get(nv21, 0, width * height)
                destPos = width * height
            } else {
                // Handle row stride padding
                for (row in 0 until height) {
                    yBuffer.position(row * yRowStride)
                    yBuffer.get(nv21, destPos, width)
                    destPos += width
                }
            }
            
            // Copy UV planes interleaved as VU (NV21 format)
            val uvHeight = height / 2
            val uvWidth = width / 2
            
            for (row in 0 until uvHeight) {
                for (col in 0 until uvWidth) {
                    val uvOffset = row * uvRowStride + col * uvPixelStride
                    
                    // NV21 format: V first, then U
                    nv21[destPos++] = vBuffer.get(uvOffset)
                    nv21[destPos++] = uBuffer.get(uvOffset)
                }
            }
            
            // Convert NV21 to JPEG then to Bitmap
            val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
            
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            var bitmap = BitmapFactory.decodeByteArray(out.toByteArray(), 0, out.size(), options)
            out.close()
            
            if (bitmap == null) {
                Log.e(TAG, "❌ Failed to decode bitmap from JPEG")
                return null
            }
            
            // Apply rotation to make image upright for MediaPipe
            val rotation = imageProxy.imageInfo.rotationDegrees
            Log.d(TAG, "📐 Image rotation: $rotation degrees, frontCamera: $useFrontCamera, size: ${bitmap.width}x${bitmap.height}")
            
            if (rotation != 0 || useFrontCamera) {
                val matrix = Matrix()
                matrix.postRotate(rotation.toFloat())
                
                // Mirror horizontally for front camera to match Python test behavior
                // The Python test does cv2.flip(frame, 1) which is a horizontal flip
                if (useFrontCamera) {
                    matrix.postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
                    Log.d(TAG, "📐 Applied horizontal flip for front camera")
                }
                
                val transformedBitmap = Bitmap.createBitmap(
                    bitmap, 0, 0,
                    bitmap.width, bitmap.height,
                    matrix, true
                )
                if (transformedBitmap != bitmap) {
                    bitmap.recycle()
                }
                bitmap = transformedBitmap
                Log.d(TAG, "📐 After transformation: ${bitmap.width}x${bitmap.height}")
            }
            
            bitmap
        } catch (e: Exception) {
            Log.e(TAG, "❌ Bitmap conversion error: ${e.message}")
            e.printStackTrace()
            null
        }
    }
    
    private fun detectHands(bitmap: Bitmap) {
        if (handLandmarker == null) {
            Log.e(TAG, "❌ HandLandmarker is null!")
            return
        }
        
        try {
            Log.d(TAG, "🔍 Processing frame: ${bitmap.width}x${bitmap.height}")
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = handLandmarker?.detect(mpImage)
            
            if (result != null) {
                val numHands = result.landmarks().size
                Log.d(TAG, "🖐️ MediaPipe result: $numHands hand(s) detected")
                
                if (numHands > 0) {
                    processDetectedHand(result)
                } else {
                    Log.d(TAG, "👋 No hands in frame")
                    sendNoHandDetected()
                }
            } else {
                Log.w(TAG, "⚠️ MediaPipe returned null result")
                sendNoHandDetected()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Hand detection error: ${e.message}")
            e.printStackTrace()
            sendNoHandDetected()
        }
    }
    
    private fun processDetectedHand(result: HandLandmarkerResult) {
        val numHands = result.landmarks().size
        Log.d(TAG, "🖐️ Processing $numHands hand(s)")
        
        // Model expects 126 floats = 2 hands × 21 landmarks × 3 coords
        // If only 1 hand detected, pad the second hand with zeros
        val landmarkArray = FloatArray(126) { 0f }
        
        // Fill NORMALIZED landmarks for each detected hand
        result.landmarks().forEachIndexed { handIndex, handLandmarks ->
            if (handIndex < 2) {  // Max 2 hands
                val handOffset = handIndex * 63  // Each hand = 21 landmarks × 3 coords
                
                // Get wrist position as reference point
                val wrist = handLandmarks[0]
                val wristX = wrist.x()
                val wristY = wrist.y()
                val wristZ = wrist.z()
                
                // Calculate hand size using distance from wrist to middle finger MCP (landmark 9)
                val middleMcp = handLandmarks.getOrNull(9)
                val handSize = if (middleMcp != null) {
                    val dx = middleMcp.x() - wristX
                    val dy = middleMcp.y() - wristY
                    val dz = middleMcp.z() - wristZ
                    sqrt(dx * dx + dy * dy + dz * dz).coerceAtLeast(0.001f)  // Match Python threshold
                } else {
                    0.1f  // Default scale if middle MCP not found
                }
                
                // Normalize all landmarks relative to wrist and scale by hand size
                handLandmarks.forEachIndexed { lmIndex, landmark ->
                    if (lmIndex < 21) {
                        val base = handOffset + lmIndex * 3
                        // Normalize: subtract wrist position and divide by hand size
                        landmarkArray[base] = (landmark.x() - wristX) / handSize
                        landmarkArray[base + 1] = (landmark.y() - wristY) / handSize
                        landmarkArray[base + 2] = (landmark.z() - wristZ) / handSize
                    }
                }
            }
        }
        
        // Log normalized landmark info (wrist should be at 0,0,0 after normalization)
        Log.d(TAG, "📐 Created NORMALIZED 126-float input for $numHands hand(s)")
        Log.d(TAG, "📍 Hand 1 wrist (normalized): x=${String.format("%.3f", landmarkArray[0])}, y=${String.format("%.3f", landmarkArray[1])}, z=${String.format("%.3f", landmarkArray[2])}")
        Log.d(TAG, "📍 Hand 1 index tip (normalized): x=${String.format("%.3f", landmarkArray[24])}, y=${String.format("%.3f", landmarkArray[25])}, z=${String.format("%.3f", landmarkArray[26])}")
        if (numHands > 1) {
            Log.d(TAG, "📍 Hand 2 wrist (normalized): x=${String.format("%.3f", landmarkArray[63])}, y=${String.format("%.3f", landmarkArray[64])}, z=${String.format("%.3f", landmarkArray[65])}")
        }
        
        // Classify the sign
        val (rawSign, rawConfidence) = classifySign(landmarkArray)
        
        // Apply confidence threshold and stabilization
        val (detectedSign, confidence) = stabilizePrediction(rawSign, rawConfidence)
        
        // Build landmarks log using first hand
        val primaryHandLandmarks = result.landmarks()[0]
        val landmarksLog = buildLandmarksLog(primaryHandLandmarks, detectedSign, confidence, rawSign, rawConfidence)
        
        // Send to Flutter
        val data = mapOf(
            "handDetected" to true,
            "landmarksLog" to landmarksLog,
            "detectedSign" to detectedSign,
            "confidence" to confidence.toDouble(),
            "timestamp" to System.currentTimeMillis(),
            "isFrontCamera" to useFrontCamera,
            "numHands" to numHands
        )
        
        mainHandler.post {
            eventSink?.success(data)
        }
        
        Log.d(TAG, "✅ Sign: $detectedSign (${String.format("%.1f", confidence * 100)}%) - $numHands hand(s)")
    }
    
    /**
     * Normalize landmarks relative to wrist position and hand size.
     * This makes the model invariant to hand position in frame and hand size/distance.
     */
    private fun normalizeLandmarks(landmarks: List<NormalizedLandmark>): List<FloatArray> {
        if (landmarks.isEmpty()) return emptyList()
        
        // Use wrist (landmark 0) as the reference point
        val wrist = landmarks[0]
        val wristX = wrist.x()
        val wristY = wrist.y()
        val wristZ = wrist.z()
        
        // Calculate hand size using distance from wrist to middle finger MCP (landmark 9)
        val middleMcp = landmarks.getOrNull(9)
        val handSize = if (middleMcp != null) {
            val dx = middleMcp.x() - wristX
            val dy = middleMcp.y() - wristY
            val dz = middleMcp.z() - wristZ
            sqrt(dx * dx + dy * dy + dz * dz).coerceAtLeast(0.001f)
        } else {
            0.1f  // Default scale if middle MCP not found
        }
        
        // Normalize all landmarks relative to wrist and scale by hand size
        return landmarks.map { landmark ->
            floatArrayOf(
                (landmark.x() - wristX) / handSize,
                (landmark.y() - wristY) / handSize,
                (landmark.z() - wristZ) / handSize
            )
        }
    }
    
    /**
     * Stabilize predictions to avoid flickering between signs.
     * Requires consistent predictions over multiple frames.
     */
    private fun stabilizePrediction(sign: String, confidence: Float): Pair<String, Float> {
        // If confidence is too low, don't count this prediction
        if (confidence < MIN_CONFIDENCE_THRESHOLD) {
            // Still track low-confidence predictions but don't update stable prediction
            return Pair(stablePrediction, stableConfidence)
        }
        
        // Add to prediction history
        lastPredictions.add(sign)
        
        // Keep only recent predictions
        if (lastPredictions.size > PREDICTION_STABILITY_COUNT * 2) {
            lastPredictions.removeAt(0)
        }
        
        // Count occurrences of each sign in recent predictions
        val recentPredictions = lastPredictions.takeLast(PREDICTION_STABILITY_COUNT)
        val signCounts = recentPredictions.groupingBy { it }.eachCount()
        val mostCommon = signCounts.maxByOrNull { it.value }
        
        // Only update stable prediction if we have enough consistent predictions
        if (mostCommon != null && mostCommon.value >= PREDICTION_STABILITY_COUNT - 1) {
            stablePrediction = mostCommon.key
            stableConfidence = confidence
        }
        
        return Pair(stablePrediction, stableConfidence)
    }
    
    private fun buildLandmarksLog(
        landmarks: List<NormalizedLandmark>,
        sign: String,
        confidence: Float,
        rawSign: String,
        rawConfidence: Float
    ): String {
        return buildString {
            appendLine("🖐️ HAND DETECTED!")
            appendLine("========================================")
            appendLine("📝 Stable Sign: ${if (sign.isEmpty()) "Analyzing..." else sign}")
            appendLine("📊 Confidence: ${String.format("%.1f", confidence * 100)}%")
            appendLine("----------------------------------------")
            appendLine("🔄 Raw Prediction: $rawSign (${String.format("%.1f", rawConfidence * 100)}%)")
            appendLine("📈 Min Threshold: ${String.format("%.0f", MIN_CONFIDENCE_THRESHOLD * 100)}%")
            appendLine("========================================")
            appendLine("📍 Landmarks (21 points):")
            val keyPoints = listOf(0 to "Wrist", 4 to "Thumb Tip", 8 to "Index Tip", 
                                   12 to "Middle Tip", 16 to "Ring Tip", 20 to "Pinky Tip")
            keyPoints.forEach { (index, name) ->
                if (index < landmarks.size) {
                    val lm = landmarks[index]
                    appendLine(String.format(
                        "  [%02d] %s: x=%.3f, y=%.3f, z=%.3f",
                        index, name, lm.x(), lm.y(), lm.z()
                    ))
                }
            }
            appendLine("========================================")
        }
    }
    
    private fun classifySign(landmarks: FloatArray): Pair<String, Float> {
        if (tfliteInterpreter == null) {
            Log.w(TAG, "⚠️ TFLite not ready, skipping classification")
            return Pair("?", 0.0f)
        }
        
        return try {
            // Get actual input size from the model
            val inputTensor = tfliteInterpreter!!.getInputTensor(0)
            val inputShape = inputTensor.shape()
            val inputSize = if (inputShape.size > 1) inputShape[1] else landmarks.size
            
            Log.d(TAG, "🔢 Model input shape: ${inputShape.contentToString()}, using size: $inputSize")
            
            // Prepare input buffer with the correct size
            val inputBuffer = ByteBuffer.allocateDirect(inputSize * 4).apply {
                order(ByteOrder.nativeOrder())
                for (i in 0 until inputSize) {
                    putFloat(landmarks.getOrElse(i) { 0f })
                }
                rewind()
            }
            
            // Get actual output size from the model
            val outputTensor = tfliteInterpreter!!.getOutputTensor(0)
            val outputShape = outputTensor.shape()
            val outputSize = if (outputShape.size > 1) outputShape[1] else outputShape[0]
            
            Log.d(TAG, "🔢 Model output shape: ${outputShape.contentToString()}, using size: $outputSize")
            
            // Prepare output buffer with actual model output size
            val outputBuffer = ByteBuffer.allocateDirect(outputSize * 4).apply {
                order(ByteOrder.nativeOrder())
            }
            
            // Run inference
            tfliteInterpreter?.run(inputBuffer, outputBuffer)
            
            // Find max probability and apply softmax for better probability distribution
            outputBuffer.rewind()
            val rawOutputs = FloatArray(outputSize)
            for (i in 0 until outputSize) {
                rawOutputs[i] = outputBuffer.float
            }
            
            // Apply softmax to get proper probabilities
            val probabilities = softmax(rawOutputs)
            
            // Create indexed list and sort by probability
            val indexedProbs = probabilities.mapIndexed { idx, prob -> Pair(idx, prob) }
                .sortedByDescending { it.second }
            
            // Log top 5 predictions for debugging
            val top5 = indexedProbs.take(5).map { (idx, prob) ->
                "${signLabels.getOrElse(idx) { "Class_$idx" }}(${String.format("%.1f", prob * 100)}%)"
            }.joinToString(", ")
            Log.d(TAG, "📊 Top 5 predictions: $top5")
            
            val maxIndex = indexedProbs[0].first
            val maxProb = indexedProbs[0].second
            
            // Check if there's ambiguity (second highest is too close)
            val secondProb = indexedProbs.getOrNull(1)?.second ?: 0f
            val confidenceGap = maxProb - secondProb
            
            // Reduce confidence if there's high ambiguity
            val adjustedConfidence = if (confidenceGap < 0.1f) {
                maxProb * 0.7f  // Reduce confidence if top 2 are close
            } else {
                maxProb
            }
            
            val sign = signLabels.getOrElse(maxIndex) { "Class_$maxIndex" }
            Pair(sign, adjustedConfidence)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Classification error: ${e.message}")
            e.printStackTrace()
            Pair("?", 0.0f)
        }
    }
    
    /**
     * Apply softmax to convert raw model outputs to probabilities
     */
    private fun softmax(input: FloatArray): FloatArray {
        val max = input.maxOrNull() ?: 0f
        val exps = input.map { kotlin.math.exp((it - max).toDouble()).toFloat() }
        val sum = exps.sum()
        return exps.map { it / sum }.toFloatArray()
    }
    
    private fun sendNoHandDetected() {
        // Clear prediction history when no hand is detected
        if (lastPredictions.isNotEmpty()) {
            lastPredictions.clear()
            // Don't clear stable prediction immediately - keep showing last detected sign briefly
        }
        
        val data = mapOf(
            "handDetected" to false,
            "landmarksLog" to "👋 No hand detected\n\nShow your hand clearly to the camera\n\nTips:\n• Ensure good lighting\n• Keep hand within frame\n• Show palm facing camera",
            "detectedSign" to "",
            "confidence" to 0.0,
            "timestamp" to System.currentTimeMillis(),
            "isFrontCamera" to useFrontCamera,
            "numHands" to 0
        )
        
        mainHandler.post {
            if (eventSink != null) {
                eventSink?.success(data)
            } else {
                Log.w(TAG, "⚠️ EventSink is null - Flutter not listening")
            }
        }
    }
    
    private fun sendDetectionStatus(message: String) {
        val data = mapOf(
            "handDetected" to false,
            "landmarksLog" to message,
            "detectedSign" to "",
            "confidence" to 0.0,
            "timestamp" to System.currentTimeMillis(),
            "isFrontCamera" to useFrontCamera,
            "numHands" to 0
        )
        
        mainHandler.post {
            eventSink?.success(data)
        }
    }
    
    private fun sendError(message: String) {
        mainHandler.post {
            eventSink?.error("DETECTION_ERROR", message, null)
        }
    }
    
    private fun switchCamera() {
        useFrontCamera = !useFrontCamera
        resetPredictionState()
        Log.d(TAG, "📷 Switching to ${if (useFrontCamera) "FRONT" else "BACK"} camera")
        
        if (isDetectionActive) {
            // Rebind camera with new selection
            mainHandler.post {
                bindCameraForAnalysis()
            }
        }
    }
    
    private fun stopDetection() {
        Log.d(TAG, "🛑 Stopping detection...")
        isDetectionActive = false
        isProcessingFrame = false
        resetPredictionState()
        
        try {
            cameraProvider?.unbindAll()
            imageAnalysis = null
            camera = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping detection: ${e.message}")
        }
    }
    
    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_CODE
        )
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && 
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            Log.d(TAG, if (granted) "✅ Camera permission granted" else "❌ Camera permission denied")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopDetection()
        cameraExecutor.shutdown()
        handLandmarker?.close()
        tfliteInterpreter?.close()
        Log.d(TAG, "🔴 MainActivity destroyed")
    }
}
