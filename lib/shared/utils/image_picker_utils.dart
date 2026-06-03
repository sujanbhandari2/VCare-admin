import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtils {
  /// Method to pick the image from camera
  ///
  static Future<XFile?> fromCamera() async {
    return await _pick(
      ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
  }

  /// Method to pick the image from gallery
  ///
  static Future<XFile?> fromGallery() async {
    return await _pick(
      ImageSource.gallery,
    );
  }

  /// Private method to pick the images
  ///
  static Future<XFile?> _pick(
      ImageSource source, {
        CameraDevice preferredCameraDevice = CameraDevice.rear,
      }) async {
    try {
      return await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImagePickerHelper._pick]====> $e');
      }
    }

    return null;
  }
}