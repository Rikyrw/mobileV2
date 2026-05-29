import 'dart:async';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'greenpoint_api_service.dart';

class WastePhotoValidationService {
  const WastePhotoValidationService();

  Future<WastePhotoValidationResult> validateWastePhoto({
    required XFile image,
    required int selectedWasteId,
    required String selectedWasteName,
  }) async {
    final bytes = await image.readAsBytes();
    final photoDataUrl =
        'data:${_resolveMimeType(image)};base64,${base64Encode(bytes)}';

    try {
      final response = await GreenPointApiService.validateWastePhoto(
        jenisId: selectedWasteId,
        photoDataUrl: photoDataUrl,
      );

      return WastePhotoValidationResult.fromBackend(
        response,
        selectedWasteName,
      );
    } on TimeoutException {
      throw const WastePhotoValidationException(
        'Validasi foto terlalu lama. Cek koneksi, lalu coba lagi.',
      );
    } on GreenPointApiException catch (error) {
      throw WastePhotoValidationException(error.message);
    } catch (e) {
      throw WastePhotoValidationException(
        'Validasi foto gagal di server GreenPoint. Detail: $e',
      );
    }
  }

  static String _resolveMimeType(XFile image) {
    final mimeType = image.mimeType?.trim();
    if (mimeType == 'image/png' || mimeType == 'image/jpeg') {
      return mimeType!;
    }

    final cleanPath = image.path.split('?').first.toLowerCase();
    final dot = cleanPath.lastIndexOf('.');
    final extension = dot == -1 ? '' : cleanPath.substring(dot + 1);

    return extension == 'png' ? 'image/png' : 'image/jpeg';
  }
}

class WastePhotoValidationResult {
  const WastePhotoValidationResult({
    required this.isWaste,
    required this.matchesSelectedWaste,
    required this.detectedWasteName,
    required this.confidence,
    required this.reason,
  });

  factory WastePhotoValidationResult.fromBackend(
    Map<String, dynamic> json,
    String selectedWasteName,
  ) {
    final valid = json['valid'] == true;
    final rawConfidence = json['confidence'];
    final confidenceValue = rawConfidence is num
        ? rawConfidence.toDouble()
        : double.tryParse(rawConfidence?.toString() ?? '') ?? 0;
    final detectedWasteName = _text(json['detected_type']);
    final reason = _text(json['message']);

    return WastePhotoValidationResult(
      isWaste: valid,
      matchesSelectedWaste: valid,
      detectedWasteName: detectedWasteName.isEmpty
          ? selectedWasteName
          : detectedWasteName,
      confidence: _confidenceLabel(confidenceValue),
      reason: reason,
    );
  }

  factory WastePhotoValidationResult.rejected(String reason) {
    return WastePhotoValidationResult(
      isWaste: false,
      matchesSelectedWaste: false,
      detectedWasteName: '',
      confidence: 'low',
      reason: reason,
    );
  }

  final bool isWaste;
  final bool matchesSelectedWaste;
  final String detectedWasteName;
  final String confidence;
  final String reason;

  bool get isAccepted {
    return isWaste && matchesSelectedWaste && confidence != 'low';
  }

  String warningMessage(String expectedWasteName) {
    final cleanReason = reason.trim();

    if (!isWaste) {
      return cleanReason.isEmpty
          ? 'Foto harus berisi sampah atau barang bekas yang terlihat jelas.'
          : cleanReason;
    }

    if (!matchesSelectedWaste) {
      final detected = detectedWasteName.trim();
      final detectedText = detected.isEmpty ? '' : ' Terdeteksi: $detected.';
      return 'Foto harus sesuai dengan jenis "$expectedWasteName" dari daftar admin.$detectedText';
    }

    if (confidence == 'low') {
      return 'Foto belum cukup jelas untuk memastikan jenis "$expectedWasteName". Ambil ulang dengan pencahayaan yang lebih baik.';
    }

    return cleanReason.isEmpty
        ? 'Foto belum memenuhi validasi sampah.'
        : cleanReason;
  }

  static String _confidenceLabel(double value) {
    if (value >= 0.75) return 'high';
    if (value >= 0.45) return 'medium';
    return 'low';
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

class WastePhotoValidationException implements Exception {
  const WastePhotoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
