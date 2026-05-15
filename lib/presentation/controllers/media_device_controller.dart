import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

enum MediaDeviceErrorType {
  noCameraDetected,
  cameraInitFailed,
  microphoneInitFailed,
  videoStreamFailed,
}

class MediaDeviceController extends ChangeNotifier with WidgetsBindingObserver {
  MediaDeviceController() {
    WidgetsBinding.instance.addObserver(this);
  }

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _selectedCamera;
  MediaStream? _microphoneStream;

  var _cameraPermission = PermissionStatus.denied;
  var _microphonePermission = PermissionStatus.denied;

  bool _isInitializingCamera = false;
  bool _isStartingMicrophone = false;
  MediaDeviceErrorType? _lastErrorType;
  bool _wasCameraInitializedBeforePause = false;
  bool _isVideoFrameStreamActive = false;

  CameraController? get cameraController => _cameraController;
  CameraDescription? get selectedCamera => _selectedCamera;

  PermissionStatus get cameraPermission => _cameraPermission;
  PermissionStatus get microphonePermission => _microphonePermission;

  bool get isCameraPermissionGranted => _cameraPermission.isGranted;
  bool get isMicrophonePermissionGranted => _microphonePermission.isGranted;

  bool get isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  bool get isMicrophoneReady => _microphoneStream != null;

  bool get isInitializingCamera => _isInitializingCamera;
  bool get isStartingMicrophone => _isStartingMicrophone;
  bool get isVideoFrameStreamActive => _isVideoFrameStreamActive;

  MediaDeviceErrorType? get lastErrorType => _lastErrorType;

  String? lastErrorMessage(AppLocalizations l10n) {
    final error = _lastErrorType;
    if (error == null) return null;
    return switch (error) {
      MediaDeviceErrorType.noCameraDetected => l10n.deviceErrorNoCameraDetected,
      MediaDeviceErrorType.cameraInitFailed => l10n.deviceErrorCameraInitFailed,
      MediaDeviceErrorType.microphoneInitFailed =>
        l10n.deviceErrorMicrophoneInitFailed,
      MediaDeviceErrorType.videoStreamFailed => l10n.deviceErrorVideoStreamFailed,
    };
  }

  bool get canOpenSettings =>
      _cameraPermission.isPermanentlyDenied ||
      _microphonePermission.isPermanentlyDenied ||
      _cameraPermission.isRestricted ||
      _microphonePermission.isRestricted;

  Future<void> refreshPermissions() async {
    _cameraPermission = await Permission.camera.status;
    _microphonePermission = await Permission.microphone.status;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    _cameraPermission = results[Permission.camera] ?? PermissionStatus.denied;
    _microphonePermission =
        results[Permission.microphone] ?? PermissionStatus.denied;
    notifyListeners();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> start() async {
    _lastErrorType = null;
    await refreshPermissions();
    if (!isCameraPermissionGranted || !isMicrophonePermissionGranted) {
      await requestPermissions();
    }
    await Future.wait<void>([
      initCamera(),
      startMicrophone(),
    ]);
  }

  Future<void> initCamera() async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;
    _lastErrorType = null;
    notifyListeners();

    try {
      await refreshPermissions();
      if (!isCameraPermissionGranted) {
        _disposeCamera();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _disposeCamera();
        _lastErrorType = MediaDeviceErrorType.noCameraDetected;
        return;
      }

      final preferred = _cameras.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCamera = preferred.isNotEmpty ? preferred.first : _cameras.first;

      final controller = CameraController(
        _selectedCamera!,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController?.dispose();
      _cameraController = controller;
      await controller.initialize();
      try {
        await controller.setFocusMode(FocusMode.auto);
      } on UnimplementedError {
        // Algunos backends no implementan control de foco. La camara puede
        // seguir funcionando aunque esta optimizacion no este disponible.
      } on CameraException {
        // Si el dispositivo no soporta cambiar el foco, evitamos bloquear
        // toda la inicializacion de la camara.
      }
      notifyListeners();
    } on CameraException catch (_) {
      _disposeCamera();
      _lastErrorType = MediaDeviceErrorType.cameraInitFailed;
    } catch (e) {
      _disposeCamera();
      _lastErrorType = MediaDeviceErrorType.cameraInitFailed;
    } finally {
      _isInitializingCamera = false;
      notifyListeners();
    }
  }

  Future<void> startMicrophone() async {
    if (_isStartingMicrophone) return;
    if (isMicrophoneReady) return;

    _isStartingMicrophone = true;
    _lastErrorType = null;
    notifyListeners();

    try {
      await refreshPermissions();
      if (!isMicrophonePermissionGranted) {
        await stopMicrophone();
        return;
      }

      _microphoneStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
    } catch (e) {
      await stopMicrophone();
      _lastErrorType = MediaDeviceErrorType.microphoneInitFailed;
    } finally {
      _isStartingMicrophone = false;
      notifyListeners();
    }
  }

  MediaStream? get microphoneStream => _microphoneStream;

  Future<void> startVideoFrameStream(ValueChanged<CameraImage> onFrame) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isVideoFrameStreamActive) return;

    try {
      await controller.startImageStream(onFrame);
      _isVideoFrameStreamActive = true;
      notifyListeners();
    } on CameraException catch (_) {
      _lastErrorType = MediaDeviceErrorType.videoStreamFailed;
      notifyListeners();
    } catch (e) {
      _lastErrorType = MediaDeviceErrorType.videoStreamFailed;
      notifyListeners();
    }
  }

  Future<void> stopVideoFrameStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_isVideoFrameStreamActive) return;

    try {
      await controller.stopImageStream();
    } catch (_) {}
    _isVideoFrameStreamActive = false;
    notifyListeners();
  }

  Future<void> stopMicrophone() async {
    final stream = _microphoneStream;
    _microphoneStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _lastErrorType = null;
    await stopVideoFrameStream();
    _disposeCamera();
    await stopMicrophone();
    notifyListeners();
  }

  void _disposeCamera() {
    final controller = _cameraController;
    _cameraController = null;
    _selectedCamera = null;
    if (controller != null) {
      controller.dispose();
    }
  }

  void _disposeMicrophone() {
    final stream = _microphoneStream;
    _microphoneStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      stream.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasCameraInitializedBeforePause = controller.value.isInitialized;
      stopVideoFrameStream();
      controller.dispose();
      _cameraController = null;
      notifyListeners();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_wasCameraInitializedBeforePause) {
        _wasCameraInitializedBeforePause = false;
        initCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _disposeMicrophone();
    super.dispose();
  }
}
