import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/privacy_engine/validation/image_validator.dart';

void main() {
  group('ImageValidator Tests', () {
    test('Rejects null or empty byte payloads', () {
      final nullResult = ImageValidator.validate(null);
      expect(nullResult.isValid, false);
      expect(nullResult.errorMessage, contains('empty or null'));

      final emptyResult = ImageValidator.validate(Uint8List(0));
      expect(emptyResult.isValid, false);
      expect(emptyResult.errorMessage, contains('empty or null'));
    });

    test('Rejects payloads smaller than minimum header size', () {
      final tinyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      final result = ImageValidator.validate(tinyBytes);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('too small'));
    });

    test('Rejects files exceeding 25 MB limit', () {
      // 25 MB + 1 byte
      final oversizedBytes = Uint8List(ImageValidator.maxFileSize + 1);
      // Prepend valid PNG header
      oversizedBytes.setRange(0, 8, [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);

      final result = ImageValidator.validate(oversizedBytes);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('exceeds maximum allowed size'));
    });

    test('Validates authentic JPEG magic bytes', () {
      final jpegBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0xFF,
        0xD9,
      ]);

      final result = ImageValidator.validate(jpegBytes);
      expect(result.isValid, true);
      expect(result.format, SupportedImageFormat.jpeg);
      expect(result.mimeType, 'image/jpeg');
    });

    test('Validates authentic PNG magic bytes', () {
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG magic
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, // IEND
      ]);

      final result = ImageValidator.validate(pngBytes);
      expect(result.isValid, true);
      expect(result.format, SupportedImageFormat.png);
      expect(result.mimeType, 'image/png');
    });

    test('Validates authentic WebP magic bytes', () {
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // 'RIFF'
        0x20, 0x00, 0x00, 0x00, // file length
        0x57, 0x45, 0x42, 0x50, // 'WEBP'
        0x56, 0x50, 0x38, 0x20, // 'VP8 '
      ]);

      final result = ImageValidator.validate(webpBytes);
      expect(result.isValid, true);
      expect(result.format, SupportedImageFormat.webp);
      expect(result.mimeType, 'image/webp');
    });

    test('Validates authentic HEIC magic bytes', () {
      final heicBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18, // size
        0x66, 0x74, 0x79, 0x70, // 'ftyp'
        0x68, 0x65, 0x69, 0x63, // 'heic'
        0x00, 0x00, 0x00, 0x00,
      ]);

      final result = ImageValidator.validate(heicBytes);
      expect(result.isValid, true);
      expect(result.format, SupportedImageFormat.heic);
      expect(result.mimeType, 'image/heic');
    });

    test('Rejects unsupported binary payload (e.g. PDF or MP3)', () {
      final pdfBytes = Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
        0x31,
        0x2E,
        0x35,
        0x0A,
        0x25,
        0xE2,
        0xE3,
      ]); // '%PDF-1.5'

      final result = ImageValidator.validate(pdfBytes);
      expect(result.isValid, false);
      expect(
        result.errorMessage,
        contains('Unsupported or corrupted file format'),
      );
    });
  });
}
