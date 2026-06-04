import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'app_colors.dart';

Future<XFile?> cropImage(XFile image, BuildContext context) async {
  try {
    String sourcePath = image.path;

    if (!kIsWeb && !sourcePath.startsWith('/')) {
      final dir = await getTemporaryDirectory();
      final bytes = await image.readAsBytes();
      final ext = image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final tempFile = File('${dir.path}/cropper_${DateTime.now().millisecondsSinceEpoch}$ext');
      await tempFile.writeAsBytes(bytes);
      sourcePath = tempFile.path;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        if (!kIsWeb)
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.deepEmerald,
            statusBarColor: AppColors.deepEmerald,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            cropFrameStrokeWidth: 8,
            cropGridStrokeWidth: 5,
            cropGridColor: Colors.white,
            cropFrameColor: Colors.white,
            showCropGrid: true,
            activeControlsWidgetColor: AppColors.deepEmerald,
            dimmedLayerColor: Colors.black54,
          ),
        if (!kIsWeb)
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        WebUiSettings(
          context: context, // ignore: use_build_context_synchronously
          presentStyle: WebPresentStyle.dialog,
          size: CropperSize(
            width: (MediaQuery.of(context).size.width * 0.85).toInt(),
            height: (MediaQuery.of(context).size.height * 0.55).toInt(),
          ),
        ),
      ],
    );

    if (croppedFile != null) {
      if (kIsWeb) {
        return XFile(croppedFile.path);
      }
      final croppedBytes = await croppedFile.readAsBytes();
      final newName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempDir = await getTemporaryDirectory();
      final savedFile = File('${tempDir.path}/$newName');
      await savedFile.writeAsBytes(croppedBytes);
      return XFile(savedFile.path, name: newName);
    }
  } catch (e) {
    debugPrint('Image crop error: $e');
  }

  return null;
}
