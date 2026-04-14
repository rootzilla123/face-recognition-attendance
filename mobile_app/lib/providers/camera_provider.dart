import 'package:flutter/material.dart';
import '../core/models/camera.dart';
import '../core/services/camera_service.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _service = CameraService();

  List<Camera> cameras = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchCameras() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      cameras = await _service.getCameras();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addCamera(Map<String, dynamic> fields) async {
    try {
      await _service.addCamera(
        name: fields['name'],
        location: fields['location'],
        streamUrl: fields['stream_url'],
        protocol: fields['protocol'],
        username: fields['username'],
        password: fields['password'],
        frameRate: fields['frame_rate'] ?? 5,
      );
      await fetchCameras();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCamera(int id, Map<String, dynamic> fields) async {
    try {
      await _service.updateCamera(id, fields);
      await fetchCameras();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCamera(int id, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _service.stopCamera(id);
      } else {
        await _service.startCamera(id);
      }
      await fetchCameras();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCamera(int id) async {
    try {
      await _service.deleteCamera(id);
      await fetchCameras();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
