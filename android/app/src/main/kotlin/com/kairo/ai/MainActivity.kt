package com.kairo.ai

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.graphics.Bitmap
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
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    
    // Channel names (must match Flutter side)
    private val METHOD_CHANNEL = "com.kairo.ai/detection"
    private val EVENT_CHANNEL = "com.kairo.ai/detection_stream"
    
    // Camera permission request code
    private val CAMERA_PERMISSION_CODE = 100
    
    // Event sink for streaming data to Flutter
    private var eventSink: EventChannel.EventSink? = null
    
    // Camera related
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private lateinit var cameraExecutor: ExecutorService
    private var isDetectionActive = false
    
    // MediaPipe HandLandmarker
    private var handLandmarker: HandLandmarker? = null
    
    // Handler for UI thread operations
    private val mainHandler = Handler(Looper.getMainLooper())
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize camera executor
        cameraExecutor = Executors.newSingleThreadExecutor()
        
        // Initialize MediaPipe
        initializeHandLandmarker()
        
        // Setup MethodChannel for commands
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDetection" -> {
                    startDetection()
                    result.success(null)
                }
                
                "stopDetection" -> {
                    stopDetection()
                    result.success(null)
                }
                
                "checkCameraPermission" -> {
                    val hasPermission = checkCameraPermission()
                    result.success(hasPermission)
                }
                
                "requestCameraPermission" -> {
                    requestCameraPermission()
                    result.success(null)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup EventChannel for streaming data
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "✅ Flutter is now listening to detection stream")
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                stopDetection()
                Log.d(TAG, "❌ Flutter stopped listening to detection stream")
            }
        })
    }
    
    private fun initializeHandLandmarker() {
        try {
            // Copy the model from assets to cache if not already done
            val modelFile = File(cacheDir, "hand_landmarker.task")
            if (!modelFile.exists()) {
                assets.open("hand_landmarker.task").use { input ->
                    FileOutputStream(modelFile).use { output ->
                        input.copyTo(output)
                    }
                }
            }
            
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()
            
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .build()
            
            handLandmarker = HandLandmarker.createFromOptions(this, options)
            Log.d(TAG, "✅ MediaPipe HandLandmarker initialized")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing HandLandmarker: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun startDetection() {
        if (!checkCameraPermission()) {
            Log.e(TAG, "❌ Camera permission not granted")
            return
        }
        
        isDetectionActive = true
        Log.d(TAG, "🎥 Starting camera and detection...")
        
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error starting camera: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(this))
    }
    
    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        
        // Unbind all use cases before rebinding
        cameraProvider.unbindAll()
        
        // Camera selector (back camera)
        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        
        // Image analysis use case
        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also {
                it.setAnalyzer(cameraExecutor) { imageProxy ->
                    processImageProxy(imageProxy)
                }
            }
        
        try {
            // Bind use cases to camera
            cameraProvider.bindToLifecycle(
                this,
                cameraSelector,
                imageAnalysis
            )
            Log.d(TAG, "✅ Camera use cases bound")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Use case binding failed: ${e.message}")
        }
    }
    
    private fun processImageProxy(imageProxy: ImageProxy) {
        if (!isDetectionActive) {
            imageProxy.close()
            return
        }
        
        try {
            // Convert ImageProxy to Bitmap
            val bitmap = imageProxy.toBitmap()
            
            // Detect hand landmarks
            detectHandLandmarks(bitmap)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing frame: ${e.message}")
        } finally {
            imageProxy.close()
        }
    }
    
    private fun detectHandLandmarks(bitmap: Bitmap) {
        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = handLandmarker?.detect(mpImage)
            
            if (result != null && result.landmarks().isNotEmpty()) {
                // Hand detected! Extract landmarks
                val handLandmarks = result.landmarks()[0]
                
                // Format landmarks as readable log
                val landmarksLog = buildString {
                    appendLine("Hand Detected! 21 Landmarks:")
                    appendLine("=".repeat(40))
                    handLandmarks.forEachIndexed { index, landmark ->
                        appendLine(
                            String.format(
                                "Point %2d: x=%.3f, y=%.3f, z=%.3f",
                                index,
                                landmark.x(),
                                landmark.y(),
                                landmark.z()
                            )
                        )
                    }
                    appendLine("=".repeat(40))
                }
                
                // Send to Flutter
                val data = mapOf(
                    "handDetected" to true,
                    "landmarksLog" to landmarksLog,
                    "timestamp" to System.currentTimeMillis()
                )
                
                mainHandler.post {
                    eventSink?.success(data)
                }
                
                Log.d(TAG, "✅ Hand detected with ${handLandmarks.size} landmarks")
            } else {
                // No hand detected
                val data = mapOf(
                    "handDetected" to false,
                    "landmarksLog" to "No hand detected",
                    "timestamp" to System.currentTimeMillis()
                )
                
                mainHandler.post {
                    eventSink?.success(data)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error detecting landmarks: ${e.message}")
        }
    }
    
    private fun stopDetection() {
        isDetectionActive = false
        Log.d(TAG, "🛑 Stopping camera and detection...")
        
        cameraProvider?.unbindAll()
        imageAnalysis = null
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
        
        when (requestCode) {
            CAMERA_PERMISSION_CODE -> {
                val granted = grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED
                
                if (granted) {
                    Log.d(TAG, "✅ Camera permission granted")
                } else {
                    Log.d(TAG, "❌ Camera permission denied")
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopDetection()
        cameraExecutor.shutdown()
        handLandmarker?.close()
    }
    
    companion object {
        private const val TAG = "KairoAI"
    }
}

// Extension function to convert ImageProxy to Bitmap
private fun ImageProxy.toBitmap(): Bitmap {
    val buffer = planes[0].buffer
    val bytes = ByteArray(buffer.remaining())
    buffer.get(bytes)
    
    return android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
}
