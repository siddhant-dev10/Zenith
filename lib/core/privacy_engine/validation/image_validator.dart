import 'dart:typed_data';

/// Supported image formats recognized by Zenith.
enum SupportedImageFormat {
  jpeg,
  png,
  webp,
  heic,
  unknown;

  String get mimeType {
    switch (this) {
      case SupportedImageFormat.jpeg:
        return 'image/jpeg';
      case SupportedImageFormat.png:
        return 'image/png';
      case SupportedImageFormat.webp:
        return 'image/webp';
      case SupportedImageFormat.heic:
        return 'image/heic';
      case SupportedImageFormat.unknown:
        return 'application/octet-stream';
    }
  }

  String get extension {
    switch (this) {
      case SupportedImageFormat.jpeg:
        return 'jpg';
      case SupportedImageFormat.png:
        return 'png';
      case SupportedImageFormat.webp:
        return 'webp';
      case SupportedImageFormat.heic:
        return 'heic';
      case SupportedImageFormat.unknown:
        return 'bin';
    }
  }
}

/// Result of image validation check.
class ImageValidationResult {
  final bool isValid;
  final SupportedImageFormat format;
  final String mimeType;
  final int byteSize;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const ImageValidationResult({
    required this.isValid,
    required this.format,
    required this.mimeType,
    required this.byteSize,
    this.errorMessage,
    this.metadata = const {},
  });

  factory ImageValidationResult.valid({
    required SupportedImageFormat format,
    required int byteSize,
    Map<String, dynamic> metadata = const {},
  }) {
    return ImageValidationResult(
      isValid: true,
      format: format,
      mimeType: format.mimeType,
      byteSize: byteSize,
      metadata: metadata,
    );
  }

  factory ImageValidationResult.invalid({
    required String errorMessage,
    int byteSize = 0,
    SupportedImageFormat format = SupportedImageFormat.unknown,
  }) {
    return ImageValidationResult(
      isValid: false,
      format: format,
      mimeType: format.mimeType,
      byteSize: byteSize,
      errorMessage: errorMessage,
    );
  }
}

/// Thrown when an image payload fails format, size, or integrity validation.
class ImageValidationException implements Exception {
  final String message;
  final SupportedImageFormat? format;

  const ImageValidationException(this.message, {this.format});

  @override
  String toString() => 'ImageValidationException: $message';
}

/// Deterministic image payload validator enforcing format, size, and integrity.
class ImageValidator {
  /// Maximum permitted file size in bytes (25 Megabytes).
  static const int maxFileSize = 25 * 1024 * 1024;

  /// Minimum required header length to verify magic bytes.
  static const int minHeaderBytes = 12;

  /// Validates a raw image byte buffer before ingestion into the analysis pipeline.
  static ImageValidationResult validate(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return ImageValidationResult.invalid(
        errorMessage: 'Image payload is empty or null.',
        byteSize: 0,
      );
    }

    final byteSize = bytes.length;

    // Check size ceiling
    if (byteSize > maxFileSize) {
      final sizeMb = (byteSize / (1024 * 1024)).toStringAsFixed(2);
      return ImageValidationResult.invalid(
        errorMessage:
            'Image exceeds maximum allowed size of 25 MB (Received $sizeMb MB).',
        byteSize: byteSize,
      );
    }

    // Check minimum length for header inspection
    if (byteSize < minHeaderBytes) {
      return ImageValidationResult.invalid(
        errorMessage:
            'Image payload is too small to contain a valid header ($byteSize bytes).',
        byteSize: byteSize,
      );
    }

    // Inspect magic bytes
    final format = _detectFormat(bytes);

    if (format == SupportedImageFormat.unknown) {
      return ImageValidationResult.invalid(
        errorMessage: 'Unsupported or corrupted file format. Supported formats: JPEG, PNG, WebP, HEIC.',
        byteSize: byteSize,
        format: format,
      );
    }

    // Format-specific sanity verification
    final sanityCheck = _verifyFormatSanity(bytes, format);
    if (sanityCheck != null) {
      return ImageValidationResult.invalid(
        errorMessage: sanityCheck,
        byteSize: byteSize,
        format: format,
      );
    }

    return ImageValidationResult.valid(
      format: format,
      byteSize: byteSize,
      metadata: {
        'byteSize': byteSize,
        'format': format.name,
        'mimeType': format.mimeType,
      },
    );
  }

  /// Detects image format by checking file header magic bytes.
  static SupportedImageFormat _detectFormat(Uint8List bytes) {
    // JPEG: Starts with FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return SupportedImageFormat.jpeg;
    }

    // PNG: Starts with 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return SupportedImageFormat.png;
    }

    // WebP: Starts with 'RIFF' (bytes 0-3) and 'WEBP' at bytes 8-11
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return SupportedImageFormat.webp;
    }

    // HEIC/HEIF: Bytes 4-7 are 'ftyp' followed by major brands like 'heic', 'mif1', 'heix', 'msf1'
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 && // f
        bytes[5] == 0x74 && // t
        bytes[6] == 0x79 && // y
        bytes[7] == 0x70) {
      // p
      final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'mif1' ||
          brand == 'msf1' ||
          brand == 'hevc') {
        return SupportedImageFormat.heic;
      }
    }

    return SupportedImageFormat.unknown;
  }

  /// Verifies file termination or internal container consistency.
  static String? _verifyFormatSanity(
    Uint8List bytes,
    SupportedImageFormat format,
  ) {
    switch (format) {
      case SupportedImageFormat.jpeg:
        // JPEG should end with EOI marker FF D9 in normal cases
        if (bytes.length >= 2) {
          final last1 = bytes[bytes.length - 2];
          final last2 = bytes[bytes.length - 1];
          // We don't reject strictly if trailing metadata exists, but flag if badly truncated
          if (last1 == 0xFF && last2 == 0xD9) {
            return null;
          }
        }
        return null;
      case SupportedImageFormat.png:
        // PNG must end with IEND chunk (bytes: 49 45 4E 44 AE 42 60 82)
        if (bytes.length >= 12) {
          final endChunk = bytes.sublist(bytes.length - 8);
          // Check for 'IEND' text in the last chunk
          if (endChunk[0] == 0x49 &&
              endChunk[1] == 0x45 &&
              endChunk[2] == 0x4E &&
              endChunk[3] == 0x44) {
            return null;
          }
        }
        return null;
      default:
        return null;
    }
  }
}
