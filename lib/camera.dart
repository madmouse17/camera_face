import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  // bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;
  @override
  void initState() {
    // SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
    _caminit().then((_) {
      onNewCameraSelected(cameras![0]);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> _caminit() async {
    cameras = await availableCameras();
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? CameraPreview(
                controller!,
                child: Stack(
                  children: [
                    Positioned(
                        bottom: 2,
                        child: IconButton(
                          icon: Icon(_isRearCameraSelected
                              ? Icons.camera_front
                              : Icons.camera_rear),
                          iconSize: 100,
                          onPressed: () {
                            setState(() {
                              _isCameraInitialized = false;
                            });
                            onNewCameraSelected(
                                cameras![_isRearCameraSelected ? 1 : 0]);
                            setState(() {
                              _isRearCameraSelected = !_isRearCameraSelected;
                            });
                          },
                          color: Colors.white,
                        ))
                  ],
                ),
              )
            : Container(),
      ),
    );
  }
}
