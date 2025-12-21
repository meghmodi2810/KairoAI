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

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "KairoAI"
        private const val METHOD_CHANNEL = "com.kairo.ai/detection"
        private const val EVENT_CHANNEL = "com.kairo.ai/detection_stream"
        private const val CAMERA_PERMISSION_CODE = 100
    }
    
    // Event sink for streaming data to Flutter
    private var eventSink: EventChannel.EventSink? = null
    
    // Camera related
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private lateinit var cameraExecutor: ExecutorService
    private var isDetectionActive = false
    private var useFrontCamera = true
    
    // MediaPipe HandLandmarker
    private var handLandmarker: HandLandmarker? = null
    private var isHandLandmarkerReady = false
    
    // TensorFlow Lite Interpreter
    private var tfliteInterpreter: Interpreter? = null
    private var isTfliteReady = false
    
    // Sign language labels (35 classes to match ISL model output)
    // ISL includes A-Z (26) + numbers 0-9 (10) - 1 = 35, or specific ISL gestures
    private val signLabels = listOf(
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3",
        "4", "5", "6", "7", "8"
    )
    
    // Handler for UI thread operations
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Frame processing control
    private var frameCounter = 0
    private val PROCESS_EVERY_N_FRAMES = 3
    private var lastProcessTime = 0L
    private val MIN_PROCESS_INTERVAL_MS = 100L
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🚀 KairoAI MainActivity initializing...")
        Log.d(TAG, "========================================")
        
        // Initialize camera executor
        cameraExecutor = Executors.newSingleThreadExecutor()
        
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
    
    private fun initializeHandLandmarker() {
        try {
            Log.d(TAG, "🔄 Initializing MediaPipe HandLandmarker...")
            
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()
            
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumHands(2)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(com.google.mediapipe.tasks.vision.core.RunningMode.IMAGE)
                .build()
            
            handLandmarker = HandLandmarker.createFromOptions(this, options)
            isHandLandmarkerReady = true
            
            Log.d(TAG, "✅ MediaPipe HandLandmarker initialized successfully!")
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
        
        Log.d(TAG, "🎥 Starting native camera for detection...")
        
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraForAnalysis()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting camera provider: ${e.message}")
                sendError("Failed to access camera")
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
        
        val cameraSelector = if (useFrontCamera) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        
        // Use smaller resolution for faster processing
        imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(android.util.Size(320, 240))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()
            .also { analysis ->
                analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                    processFrame(imageProxy)
                }
            }
        
        try {
            provider.bindToLifecycle(
                this,
                cameraSelector,
                imageAnalysis
            )
            
            Log.d(TAG, "✅ Camera bound for analysis: ${if (useFrontCamera) "FRONT" else "BACK"}")
            
            // Send initial status
            sendDetectionStatus("Detection started - Show your hand to the camera")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to bind camera: ${e.message}")
            sendError("Failed to start camera: ${e.message}")
        }
    }
    
    private fun processFrame(imageProxy: ImageProxy) {
        if (!isDetectionActive) {
            imageProxy.close()
            return
        }
        
        // Frame rate control
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastProcessTime < MIN_PROCESS_INTERVAL_MS) {
            imageProxy.close()
            return
        }
        
        frameCounter++
        if (frameCounter % PROCESS_EVERY_N_FRAMES != 0) {
            imageProxy.close()
            return
        }
        
        lastProcessTime = currentTime
        
        try {
            val bitmap = convertToBitmap(imageProxy)
            if (bitmap != null) {
                detectHands(bitmap)
            } else {
                Log.w(TAG, "⚠️ Failed to convert frame to bitmap")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Frame processing error: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }
    
    private fun convertToBitmap(imageProxy: ImageProxy): Bitmap? {
        return try {
            val planes = imageProxy.planes
            val yBuffer = planes[0].buffer
            val uBuffer = planes[1].buffer
            val vBuffer = planes[2].buffer
            
            val ySize = yBuffer.remaining()
            val uSize = uBuffer.remaining()
            val vSize = vBuffer.remaining()
            
            val nv21 = ByteArray(ySize + uSize + vSize)
            yBuffer.get(nv21, 0, ySize)
            vBuffer.get(nv21, ySize, vSize)
            uBuffer.get(nv21, ySize + vSize, uSize)
            
            val yuvImage = YuvImage(
                nv21,
                ImageFormat.NV21,
                imageProxy.width,
                imageProxy.height,
                null
            )
            
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(
                Rect(0, 0, imageProxy.width, imageProxy.height),
                85,
                out
            )
            
            var bitmap = BitmapFactory.decodeByteArray(out.toByteArray(), 0, out.size())
            
            // Apply rotation and mirroring
            val matrix = Matrix()
            val rotation = imageProxy.imageInfo.rotationDegrees
            
            if (rotation != 0) {
                matrix.postRotate(rotation.toFloat())
            }
            
            // Mirror front camera for natural selfie view
            if (useFrontCamera) {
                matrix.postScale(-1f, 1f)
            }
            
            if (rotation != 0 || useFrontCamera) {
                bitmap = Bitmap.createBitmap(
                    bitmap, 0, 0,
                    bitmap.width, bitmap.height,
                    matrix, true
                )
            }
            
            bitmap
        } catch (e: Exception) {
            Log.e(TAG, "❌ Bitmap conversion error: ${e.message}")
            null
        }
    }
    
    private fun detectHands(bitmap: Bitmap) {
        if (handLandmarker == null) {
            Log.e(TAG, "❌ HandLandmarker is null!")
            return
        }
        
        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = handLandmarker?.detect(mpImage)
            
            if (result != null && result.landmarks().isNotEmpty()) {
                processDetectedHand(result)
            } else {
                sendNoHandDetected()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Hand detection error: ${e.message}")
            sendNoHandDetected()
        }
    }
    
    private fun processDetectedHand(result: HandLandmarkerResult) {
        // Always provide 2 hands (126 floats) to TFLite, pad with zeros if only 1 hand detected
        val numHands = result.landmarks().size
        val landmarkArray = FloatArray(126) { 0f } // 2 hands x 21 x 3
        for (h in 0 until minOf(numHands, 2)) {
            val handLandmarks = result.landmarks()[h]
            handLandmarks.forEachIndexed { index, landmark ->
                if (index < 21) {
                    val base = h * 63 + index * 3
                    landmarkArray[base] = landmark.x()
                    landmarkArray[base + 1] = landmark.y()
                    landmarkArray[base + 2] = landmark.z()
                }
            }
        }
        // Use the first detected hand's landmarks for logging (or empty list)
        val primaryHandLandmarks = if (result.landmarks().isNotEmpty()) result.landmarks()[0] else listOf<NormalizedLandmark>()
        // Classify the sign
        val (detectedSign, confidence) = classifySign(landmarkArray)
        
        // Build landmarks log
        val landmarksLog = buildLandmarksLog(primaryHandLandmarks, detectedSign, confidence)
        
        // Send to Flutter
        val data = mapOf(
            "handDetected" to true,
            "landmarksLog" to landmarksLog,
            "detectedSign" to detectedSign,
            "confidence" to confidence.toDouble(),
            "timestamp" to System.currentTimeMillis(),
            "isFrontCamera" to useFrontCamera,
            "numHands" to result.landmarks().size
        )
        
        mainHandler.post {
            eventSink?.success(data)
        }
        
        Log.d(TAG, "🖐️ Hand detected! Sign: $detectedSign (${String.format("%.1f", confidence * 100)}%)")
    }
    
    private fun buildLandmarksLog(
        landmarks: List<NormalizedLandmark>,
        sign: String,
        confidence: Float
    ): String {
        return buildString {
            appendLine("🖐️ HAND DETECTED!")
            appendLine("========================================")
            appendLine("📝 Detected Sign: $sign")
            appendLine("📊 Confidence: ${String.format("%.1f", confidence * 100)}%")
            appendLine("========================================")
            appendLine("📍 Landmarks (21 points):")
            landmarks.forEachIndexed { index, lm ->
                appendLine(String.format(
                    "  [%02d] x=%.3f, y=%.3f, z=%.3f",
                    index, lm.x(), lm.y(), lm.z()
                ))
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
            // Prepare input (always 126 floats)
            val inputBuffer = ByteBuffer.allocateDirect(126 * 4).apply {
                order(ByteOrder.nativeOrder())
                landmarks.forEach { putFloat(it) }
                rewind()
            }
            // Get actual output size from the model
            val outputTensor = tfliteInterpreter!!.getOutputTensor(0)
            val outputSize = outputTensor.shape()[1] // Get the number of classes from model
            
            // Prepare output buffer with actual model output size
            val outputBuffer = ByteBuffer.allocateDirect(outputSize * 4).apply {
                order(ByteOrder.nativeOrder())
            }
            // Run inference
            tfliteInterpreter?.run(inputBuffer, outputBuffer)
            
            // Find max probability and log top predictions for debugging
            outputBuffer.rewind()
            val probabilities = mutableListOf<Pair<Int, Float>>()
            
            for (i in 0 until outputSize) {
                val prob = outputBuffer.float
                probabilities.add(Pair(i, prob))
            }
            
            // Sort by probability descending
            probabilities.sortByDescending { it.second }
            
            // Log top 5 predictions for debugging
            val top5 = probabilities.take(5).map { (idx, prob) ->
                "${signLabels.getOrElse(idx) { "Class_$idx" }}(${String.format("%.1f", prob * 100)}%)"
            }.joinToString(", ")
            Log.d(TAG, "📊 Top 5 predictions: $top5")
            
            val maxIndex = probabilities[0].first
            val maxProb = probabilities[0].second
            
            val sign = signLabels.getOrElse(maxIndex) { "Class_$maxIndex" }
            Pair(sign, maxProb)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Classification error: ${e.message}")
            Pair("?", 0.0f)
        }
    }
    
    private fun sendNoHandDetected() {
        val data = mapOf(
            "handDetected" to false,
            "landmarksLog" to "👋 No hand detected\n\nShow your hand clearly to the camera",
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
        Log.d(TAG, "📷 Switching to ${if (useFrontCamera) "FRONT" else "BACK"} camera")
        
        if (isDetectionActive) {
            bindCameraForAnalysis()
        }
    }
    
    private fun stopDetection() {
        Log.d(TAG, "🛑 Stopping detection...")
        isDetectionActive = false
        
        try {
            cameraProvider?.unbindAll()
            imageAnalysis = null
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
