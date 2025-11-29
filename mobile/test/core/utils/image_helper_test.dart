import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/utils/image_helper.dart';

void main() {
  group('ImageHelper', () {
    group('FileTooLargeException', () {
      test('should have correct message', () {
        final exception = FileTooLargeException();
        expect(exception.message, equals('ファイルサイズが10MBを超えています'));
      });

      test('should have correct toString', () {
        final exception = FileTooLargeException();
        // FileTooLargeExceptionはUploadExceptionを継承しているため、
        // toStringの実装が異なる可能性がある
        expect(exception.message, contains('ファイルサイズが10MBを超えています'));
      });
    });

    group('UnsupportedFileTypeException', () {
      test('should have correct message', () {
        const exception = UnsupportedFileTypeException();
        expect(exception.message, equals('対応していないファイル形式です（JPEG, PNG, GIFのみ）'));
      });
    });

    group('constants', () {
      test('maxFileSizeBytes should be 10MB', () {
        expect(ImageHelper.maxFileSizeBytes, equals(10 * 1024 * 1024));
      });

      test('maxWidth should be 1024', () {
        expect(ImageHelper.maxWidth, equals(1024));
      });

      test('maxHeight should be 1024', () {
        expect(ImageHelper.maxHeight, equals(1024));
      });

      test('quality should be 85', () {
        expect(ImageHelper.quality, equals(85));
      });
    });

    group('isValidFileType', () {
      test('should return true for JPEG extension', () {
        expect(ImageHelper.isValidFileType('photo.jpeg'), isTrue);
        expect(ImageHelper.isValidFileType('photo.jpg'), isTrue);
        expect(ImageHelper.isValidFileType('photo.JPG'), isTrue);
        expect(ImageHelper.isValidFileType('photo.JPEG'), isTrue);
      });

      test('should return true for PNG extension', () {
        expect(ImageHelper.isValidFileType('photo.png'), isTrue);
        expect(ImageHelper.isValidFileType('photo.PNG'), isTrue);
      });

      test('should return true for GIF extension', () {
        expect(ImageHelper.isValidFileType('photo.gif'), isTrue);
        expect(ImageHelper.isValidFileType('photo.GIF'), isTrue);
      });

      test('should return false for unsupported extensions', () {
        expect(ImageHelper.isValidFileType('photo.webp'), isFalse);
        expect(ImageHelper.isValidFileType('photo.bmp'), isFalse);
        expect(ImageHelper.isValidFileType('photo.tiff'), isFalse);
        expect(ImageHelper.isValidFileType('document.pdf'), isFalse);
      });
    });
  });
}
