import AVFoundation
import Flutter
import Foundation
import ImageIO
import TensorFlowLite
import UIKit
import Vision
import simd

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var signDetectionController: SignDetectionController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      signDetectionController = SignDetectionController(
        messenger: controller.binaryMessenger,
        textureRegistry: controller
      )
      signDetectionController?.registerChannels()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    signDetectionController?.teardown()
    super.applicationWillTerminate(application)
  }
}

private final class CameraTextureSource: NSObject, FlutterTexture {
  private let lock = NSLock()
  private var pixelBuffer: CVPixelBuffer?

  func update(pixelBuffer: CVPixelBuffer) {
    lock.lock()
    self.pixelBuffer = pixelBuffer
    lock.unlock()
  }

  func clear() {
    lock.lock()
    pixelBuffer = nil
    lock.unlock()
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    lock.lock()
    defer { lock.unlock() }
    guard let buffer = pixelBuffer else {
      return nil
    }
    return Unmanaged.passRetained(buffer)
  }
}

private final class SignDetectionController: NSObject, FlutterStreamHandler, AVCaptureVideoDataOutputSampleBufferDelegate {
  private struct HandObservation {
    let landmarks: [SIMD3<Float>]
  }

  private static let methodChannelName = "com.kairo.ai/detection"
  private static let eventChannelName = "com.kairo.ai/detection_stream"

  private static let jointOrder: [VNHumanHandPoseObservation.JointName] = [
    .wrist,
    .thumbCMC,
    .thumbMP,
    .thumbIP,
    .thumbTip,
    .indexMCP,
    .indexPIP,
    .indexDIP,
    .indexTip,
    .middleMCP,
    .middlePIP,
    .middleDIP,
    .middleTip,
    .ringMCP,
    .ringPIP,
    .ringDIP,
    .ringTip,
    .littleMCP,
    .littlePIP,
    .littleDIP,
    .littleTip,
  ]

  private let signLabels: [String] = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "1", "2", "3", "4", "5", "6", "7", "8", "9",
  ]

  private let minConfidenceThreshold: Float = 0.15
  private let predictionStabilityCount = 1
  private let minProcessIntervalMs: Double = 33.0

  private let messenger: FlutterBinaryMessenger
  private weak var textureRegistry: FlutterTextureRegistry?

  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?

  private let textureSource = CameraTextureSource()
  private var textureId: Int64?

  private let captureSession = AVCaptureSession()
  private let captureQueue = DispatchQueue(label: "com.kairo.ai.detection.capture")
  private var videoOutput: AVCaptureVideoDataOutput?

  private var currentCameraPosition: AVCaptureDevice.Position = .front
  private var isDetectionActive = false
  private var isProcessingFrame = false
  private var lastProcessTimeMs: Double = 0

  private var handPoseRequest: VNDetectHumanHandPoseRequest?
  private var isHandDetectorReady = false

  private var interpreter: Interpreter?
  private var isTfliteReady = false

  private var lastPredictions: [String] = []
  private var stablePrediction = ""
  private var stableConfidence: Float = 0

  init(messenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry) {
    self.messenger = messenger
    self.textureRegistry = textureRegistry
    super.init()
    initializeHandPoseDetector()
    initializeTFLiteInterpreter()
  }

  deinit {
    teardown()
  }

  func registerChannels() {
    let method = FlutterMethodChannel(name: Self.methodChannelName, binaryMessenger: messenger)
    method.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
    methodChannel = method

    let event = FlutterEventChannel(name: Self.eventChannelName, binaryMessenger: messenger)
    event.setStreamHandler(self)
    eventChannel = event
  }

  func teardown() {
    stopDetection()
    eventSink = nil
    methodChannel?.setMethodCallHandler(nil)
    eventChannel?.setStreamHandler(nil)
    if let textureId {
      textureRegistry?.unregisterTexture(textureId)
    }
    textureId = nil
    textureSource.clear()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    textureSource.update(pixelBuffer: pixelBuffer)
    if let textureId {
      DispatchQueue.main.async { [weak self] in
        self?.textureRegistry?.textureFrameAvailable(textureId)
      }
    }

    guard isDetectionActive, isHandDetectorReady, isTfliteReady else {
      return
    }

    let nowMs = currentTimestampMs()
    if (nowMs - lastProcessTimeMs) < minProcessIntervalMs {
      return
    }
    if isProcessingFrame {
      return
    }

    isProcessingFrame = true
    lastProcessTimeMs = nowMs
    processFrame(pixelBuffer: pixelBuffer)
    isProcessingFrame = false
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startDetection":
      ensureTextureRegistered()
      startDetection()
      result([
        "success": true,
        "handLandmarkerReady": isHandDetectorReady,
        "tfliteReady": isTfliteReady,
        "textureId": textureId ?? -1,
      ])
    case "stopDetection":
      stopDetection()
      result(true)
    case "switchCamera":
      switchCamera()
      result(isFrontCamera())
    case "checkCameraPermission":
      result(checkCameraPermission())
    case "requestCameraPermission":
      requestCameraPermission(result: result)
    case "isFrontCamera":
      result(isFrontCamera())
    case "getStatus":
      result([
        "isDetectionActive": isDetectionActive,
        "handLandmarkerReady": isHandDetectorReady,
        "tfliteReady": isTfliteReady,
        "useFrontCamera": isFrontCamera(),
      ])
    case "resetPrediction":
      resetPredictionState()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func ensureTextureRegistered() {
    guard textureId == nil else {
      return
    }
    textureId = textureRegistry?.register(textureSource)
  }

  private func initializeHandPoseDetector() {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    handPoseRequest = request
    isHandDetectorReady = true
  }

  private func initializeTFLiteInterpreter() {
    do {
      guard let modelPath = flutterAssetPath(for: "isl_model_advanced.tflite")
        ?? Bundle.main.path(forResource: "isl_model_advanced", ofType: "tflite")
      else {
        isTfliteReady = false
        return
      }

      var options = Interpreter.Options()
      options.threadCount = 4

      let loadedInterpreter = try Interpreter(modelPath: modelPath, options: options)
      try loadedInterpreter.allocateTensors()

      interpreter = loadedInterpreter
      isTfliteReady = true
    } catch {
      isTfliteReady = false
    }
  }

  private func flutterAssetPath(for asset: String) -> String? {
    return Bundle.main.path(forResource: "flutter_assets/\(asset)", ofType: nil)
  }

  private func resetPredictionState() {
    lastPredictions.removeAll(keepingCapacity: true)
    stablePrediction = ""
    stableConfidence = 0
  }

  private func startDetection() {
    guard checkCameraPermission() else {
      sendError("Camera permission not granted")
      return
    }
    guard isHandDetectorReady else {
      sendError("Hand detection model not ready")
      return
    }
    guard isTfliteReady else {
      sendError("TFLite model not ready")
      return
    }
    guard !isDetectionActive else {
      return
    }

    isDetectionActive = true
    isProcessingFrame = false
    lastProcessTimeMs = 0
    resetPredictionState()

    captureQueue.async { [weak self] in
      self?.configureAndStartCaptureSession()
    }

    sendDetectionStatus("Detection started - show your hand to the camera")
  }

  private func stopDetection() {
    isDetectionActive = false
    isProcessingFrame = false
    resetPredictionState()

    captureQueue.async { [weak self] in
      guard let self else {
        return
      }
      if self.captureSession.isRunning {
        self.captureSession.stopRunning()
      }
      self.captureSession.beginConfiguration()
      self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
      self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
      self.captureSession.commitConfiguration()
      self.videoOutput = nil
      self.textureSource.clear()
      if let textureId = self.textureId {
        DispatchQueue.main.async { [weak self] in
          self?.textureRegistry?.textureFrameAvailable(textureId)
        }
      }
    }
  }

  private func switchCamera() {
    currentCameraPosition = isFrontCamera() ? .back : .front
    resetPredictionState()

    guard isDetectionActive else {
      return
    }

    captureQueue.async { [weak self] in
      self?.configureAndStartCaptureSession()
    }
  }

  private func isFrontCamera() -> Bool {
    currentCameraPosition == .front
  }

  private func checkCameraPermission() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      result(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    default:
      result(false)
    }
  }

  private func configureAndStartCaptureSession() {
    do {
      try configureCaptureSession()
      if !captureSession.isRunning {
        captureSession.startRunning()
      }
    } catch {
      sendError("Failed to configure camera: \(error.localizedDescription)")
      isDetectionActive = false
    }
  }

  private func configureCaptureSession() throws {
    captureSession.beginConfiguration()
    defer { captureSession.commitConfiguration() }

    captureSession.sessionPreset = .vga640x480
    captureSession.inputs.forEach { captureSession.removeInput($0) }
    captureSession.outputs.forEach { captureSession.removeOutput($0) }

    guard let cameraDevice = findCameraDevice(position: currentCameraPosition) else {
      throw NSError(domain: "KairoAI", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No camera available for requested position"])
    }

    let input = try AVCaptureDeviceInput(device: cameraDevice)
    guard captureSession.canAddInput(input) else {
      throw NSError(domain: "KairoAI", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Unable to add camera input"])
    }
    captureSession.addInput(input)

    let output = AVCaptureVideoDataOutput()
    output.alwaysDiscardsLateVideoFrames = true
    output.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
    ]
    output.setSampleBufferDelegate(self, queue: captureQueue)

    guard captureSession.canAddOutput(output) else {
      throw NSError(domain: "KairoAI", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Unable to add camera output"])
    }
    captureSession.addOutput(output)

    if let connection = output.connection(with: .video) {
      if connection.isVideoOrientationSupported {
        connection.videoOrientation = .portrait
      }
      if connection.isVideoMirroringSupported {
        connection.isVideoMirrored = isFrontCamera()
      }
    }

    videoOutput = output
  }

  private func findCameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: position
    )
    if let device = discovery.devices.first {
      return device
    }

    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
  }

  private func processFrame(pixelBuffer: CVPixelBuffer) {
    guard let request = handPoseRequest else {
      sendNoHandDetected()
      return
    }

    do {
      let handler = VNImageRequestHandler(
        cvPixelBuffer: pixelBuffer,
        orientation: visionOrientation(),
        options: [:]
      )
      try handler.perform([request])

      guard let observations = request.results, !observations.isEmpty else {
        sendNoHandDetected()
        return
      }

      let hands = observations.compactMap { makeHandObservation(from: $0) }
      guard !hands.isEmpty else {
        sendNoHandDetected()
        return
      }

      processDetectedHands(hands)
    } catch {
      sendNoHandDetected()
    }
  }

  private func visionOrientation() -> CGImagePropertyOrientation {
    return isFrontCamera() ? .leftMirrored : .right
  }

  private func makeHandObservation(from observation: VNHumanHandPoseObservation) -> HandObservation? {
    guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
      return nil
    }

    var points: [SIMD3<Float>] = []
    points.reserveCapacity(Self.jointOrder.count)

    for joint in Self.jointOrder {
      guard let point = recognizedPoints[joint], point.confidence > 0.1 else {
        return nil
      }
      points.append(SIMD3<Float>(
        Float(point.location.x),
        Float(1.0 - point.location.y),
        0
      ))
    }

    return HandObservation(landmarks: points)
  }

  private func processDetectedHands(_ hands: [HandObservation]) {
    let sortedHands = hands.sorted { lhs, rhs in
      lhs.landmarks[0].x < rhs.landmarks[0].x
    }

    var landmarkArray = [Float](repeating: 0, count: 126)
    var orientationArray = [Float](repeating: -1, count: 4)

    for (sortedIndex, hand) in sortedHands.prefix(2).enumerated() {
      let handOffset = sortedIndex * 63

      let wrist = hand.landmarks[0]
      let middleMcp = hand.landmarks[9]
      let handSize = max(simd_length(middleMcp - wrist), 0.001)

      for lmIndex in 0..<min(hand.landmarks.count, 21) {
        let landmark = hand.landmarks[lmIndex]
        let base = handOffset + (lmIndex * 3)
        landmarkArray[base] = (landmark.x - wrist.x) / handSize
        landmarkArray[base + 1] = (landmark.y - wrist.y) / handSize
        landmarkArray[base + 2] = (landmark.z - wrist.z) / handSize
      }

      let thumbTip = hand.landmarks[4]
      let indexMcp = hand.landmarks[5]
      let ringMcp = hand.landmarks[13]
      let pinkyMcp = hand.landmarks[17]

      let palmCenterX = (indexMcp.x + middleMcp.x + ringMcp.x + pinkyMcp.x) / 4
      let thumbIsLeftOfCenter = thumbTip.x < palmCenterX
      let isLeftHand = inferIsLeftHand(hand: hand, sortedIndex: sortedIndex, totalHands: sortedHands.count)
      let isLeft: Float = isLeftHand ? 1 : 0
      let isPalmFacing: Float = isLeftHand
        ? (thumbIsLeftOfCenter ? 0 : 1)
        : (thumbIsLeftOfCenter ? 1 : 0)

      orientationArray[sortedIndex * 2] = isPalmFacing
      orientationArray[(sortedIndex * 2) + 1] = isLeft
    }

    var fullFeatures = [Float](repeating: 0, count: 130)
    for i in 0..<126 {
      fullFeatures[i] = landmarkArray[i]
    }
    for i in 0..<4 {
      fullFeatures[126 + i] = orientationArray[i]
    }

    let (rawSign, rawConfidence) = classifySign(features: fullFeatures)
    let (detectedSign, confidence) = stabilizePrediction(sign: rawSign, confidence: rawConfidence)

    let landmarksLog = buildLandmarksLog(
      landmarks: sortedHands[0].landmarks,
      sign: detectedSign,
      confidence: confidence,
      rawSign: rawSign,
      rawConfidence: rawConfidence
    )

    emitEvent([
      "handDetected": true,
      "landmarksLog": landmarksLog,
      "detectedSign": detectedSign,
      "confidence": Double(confidence),
      "timestamp": Int(currentTimestampMs()),
      "isFrontCamera": isFrontCamera(),
      "numHands": sortedHands.count,
    ])
  }

  private func inferIsLeftHand(hand: HandObservation, sortedIndex: Int, totalHands: Int) -> Bool {
    if totalHands > 1 {
      return sortedIndex == 0
    }

    let thumbTipX = hand.landmarks[4].x
    let indexMcpX = hand.landmarks[5].x
    return thumbTipX > indexMcpX
  }

  private func classifySign(features: [Float]) -> (String, Float) {
    guard let interpreter else {
      return ("?", 0)
    }

    do {
      let inputTensor = try interpreter.input(at: 0)
      let inputShape = inputTensor.shape.dimensions
      let inputSize = inputShape.count > 1 ? inputShape[1] : features.count

      var inputValues = [Float](repeating: 0, count: inputSize)
      for idx in 0..<min(inputSize, features.count) {
        inputValues[idx] = features[idx]
      }

      try interpreter.copy(Data(fromArray: inputValues), toInputAt: 0)
      try interpreter.invoke()

      let outputTensor = try interpreter.output(at: 0)
      let probabilities = outputTensor.data.toArray(of: Float.self)

      guard !probabilities.isEmpty else {
        return ("?", 0)
      }

      let sorted = probabilities.enumerated().sorted { lhs, rhs in
        lhs.element > rhs.element
      }
      guard let top = sorted.first else {
        return ("?", 0)
      }

      let second = sorted.dropFirst().first?.element ?? 0
      let confidenceGap = top.element - second
      let adjustedConfidence = confidenceGap < 0.1 ? top.element * 0.7 : top.element

      let label = signLabels.indices.contains(top.offset) ? signLabels[top.offset] : "Class_\(top.offset)"
      return (label, adjustedConfidence)
    } catch {
      return ("?", 0)
    }
  }

  private func stabilizePrediction(sign: String, confidence: Float) -> (String, Float) {
    if confidence < minConfidenceThreshold {
      return (stablePrediction, stableConfidence)
    }

    lastPredictions.append(sign)
    let maxHistory = predictionStabilityCount * 2
    if lastPredictions.count > maxHistory {
      lastPredictions.removeFirst(lastPredictions.count - maxHistory)
    }

    let recent = Array(lastPredictions.suffix(predictionStabilityCount))
    var counts: [String: Int] = [:]
    for candidate in recent {
      counts[candidate, default: 0] += 1
    }

    if let winner = counts.max(by: { lhs, rhs in lhs.value < rhs.value }),
       winner.value >= max(predictionStabilityCount - 1, 1)
    {
      stablePrediction = winner.key
      stableConfidence = confidence
    }

    return (stablePrediction, stableConfidence)
  }

  private func buildLandmarksLog(
    landmarks: [SIMD3<Float>],
    sign: String,
    confidence: Float,
    rawSign: String,
    rawConfidence: Float
  ) -> String {
    let keyPoints = [
      (0, "Wrist"),
      (4, "Thumb Tip"),
      (8, "Index Tip"),
      (12, "Middle Tip"),
      (16, "Ring Tip"),
      (20, "Pinky Tip"),
    ]

    var lines: [String] = []
    lines.append("HAND DETECTED")
    lines.append("========================================")
    lines.append("Stable Sign: \(sign.isEmpty ? "Analyzing..." : sign)")
    lines.append(String(format: "Confidence: %.1f%%", confidence * 100))
    lines.append("----------------------------------------")
    lines.append(String(format: "Raw Prediction: %@ (%.1f%%)", rawSign, rawConfidence * 100))
    lines.append(String(format: "Min Threshold: %.0f%%", minConfidenceThreshold * 100))
    lines.append("========================================")
    lines.append("Landmarks (21 points):")

    for (index, label) in keyPoints {
      if index < landmarks.count {
        let point = landmarks[index]
        lines.append(String(
          format: "  [%02d] %@: x=%.3f, y=%.3f, z=%.3f",
          index,
          label,
          point.x,
          point.y,
          point.z
        ))
      }
    }
    lines.append("========================================")

    return lines.joined(separator: "\n")
  }

  private func sendNoHandDetected() {
    if !lastPredictions.isEmpty {
      lastPredictions.removeAll(keepingCapacity: true)
    }

    emitEvent([
      "handDetected": false,
      "landmarksLog": "No hand detected\n\nShow your hand clearly to the camera\n\nTips:\n- Ensure good lighting\n- Keep hand within frame\n- Show palm facing camera",
      "detectedSign": "",
      "confidence": 0.0,
      "timestamp": Int(currentTimestampMs()),
      "isFrontCamera": isFrontCamera(),
      "numHands": 0,
    ])
  }

  private func sendDetectionStatus(_ message: String) {
    emitEvent([
      "handDetected": false,
      "landmarksLog": message,
      "detectedSign": "",
      "confidence": 0.0,
      "timestamp": Int(currentTimestampMs()),
      "isFrontCamera": isFrontCamera(),
      "numHands": 0,
    ])
  }

  private func sendError(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(FlutterError(code: "DETECTION_ERROR", message: message, details: nil))
    }
  }

  private func emitEvent(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }

  private func currentTimestampMs() -> Double {
    return Date().timeIntervalSince1970 * 1000
  }
}

private extension Data {
  init<T>(fromArray values: [T]) {
    self = values.withUnsafeBufferPointer { buffer in
      Data(buffer: buffer)
    }
  }

  func toArray<T>(of type: T.Type) -> [T] {
    guard !isEmpty else {
      return []
    }
    let elementCount = count / MemoryLayout<T>.stride
    return withUnsafeBytes { rawBuffer in
      let typedBuffer = rawBuffer.bindMemory(to: T.self)
      return Array(typedBuffer.prefix(elementCount))
    }
  }
}
