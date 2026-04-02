import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for uploading images to Yandex Cloud Storage
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  
  // Yandex Cloud конфигурация
  final String _accessKey = 'YCAJEc75X1Jlr5yLrgszHSMOO';
  final String _secretKey = 'YCPEEWRWAFaVAY247EdNrrWh2uG_OW4OkZrqczzs';
  final String _bucket = 'daren';
  final String _endpoint = 'https://storage.yandexcloud.net';
  final String _region = 'ru-central1';
  
  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  /// Pick multiple images
  Future<List<File>> pickMultiple() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    return images.map((xFile) => File(xFile.path)).toList();
  }
  
  /// Upload image to Yandex Cloud Storage
  Future<String> uploadToYandex({
    required File file,
    required String userId,
    String folder = 'avatars',
  }) async {
    final fileName = '$folder/${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final uri = Uri.parse('$_endpoint/$_bucket/$fileName');
    
    final fileBytes = await file.readAsBytes();
    final date = DateTime.now().toUtc();
    final dateStamp = '${date.year}${_pad(date.month)}${_pad(date.day)}';
    final amzDate = '${dateStamp}T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
    
    final contentType = _getContentType(path.extension(file.path));
    final payloadHash = sha256.convert(fileBytes).toString();
    
    final headers = {
      'Host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Content-Type': contentType,
      'Content-Length': fileBytes.length.toString(),
    };
    
    final signature = _generateSignature(
      method: 'PUT',
      uri: uri,
      dateStamp: dateStamp,
      amzDate: amzDate,
      payloadHash: payloadHash,
      headers: headers,
    );
    
    headers['Authorization'] = 'AWS4-HMAC-SHA256 '
        'Credential=$_accessKey/$dateStamp/$_region/s3/aws4_request, '
        'SignedHeaders=host;x-amz-content-sha256;x-amz-date, '
        'Signature=$signature';
    
    final response = await http.put(uri, headers: headers, body: fileBytes);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return '$_endpoint/$_bucket/$fileName';
    } else {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Upload image (alias for uploadToYandex)
  Future<String> uploadToFirebase({
    required File file,
    required String userId,
    String folder = 'avatars',
  }) async {
    return uploadToYandex(file: file, userId: userId, folder: folder);
  }
  
  /// Delete image from Yandex Storage
  Future<void> deleteImage(String url) async {
    if (url.isEmpty || !url.contains(_bucket)) return;
    
    final objectName = url.split('/$_bucket/').last;
    final uri = Uri.parse('$_endpoint/$_bucket/$objectName');
    
    final date = DateTime.now().toUtc();
    final dateStamp = '${date.year}${_pad(date.month)}${_pad(date.day)}';
    final amzDate = '${dateStamp}T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
    
    const payloadHash = 'UNSIGNED-PAYLOAD';
    
    final headers = {
      'Host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
    };
    
    final signature = _generateSignature(
      method: 'DELETE',
      uri: uri,
      dateStamp: dateStamp,
      amzDate: amzDate,
      payloadHash: payloadHash,
      headers: headers,
    );
    
    headers['Authorization'] = 'AWS4-HMAC-SHA256 '
        'Credential=$_accessKey/$dateStamp/$_region/s3/aws4_request, '
        'SignedHeaders=host;x-amz-content-sha256;x-amz-date, '
        'Signature=$signature';
    
    await http.delete(uri, headers: headers);
  }
  
  /// Get default avatar URL
  String getDefaultAvatar({String gender = 'other'}) {
    return 'https://storage.yandexcloud.net/daren/default_avatar.png';
  }
  
  String _pad(int n) => n.toString().padLeft(2, '0');
  
  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
  
  String _generateSignature({
    required String method,
    required Uri uri,
    required String dateStamp,
    required String amzDate,
    required String payloadHash,
    required Map<String, String> headers,
  }) {
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value}')
        .join('\n');
    
    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).join(';');
    
    final canonicalRequest = [
      method,
      uri.path.isEmpty ? '/' : uri.path,
      uri.query,
      canonicalHeaders,
      '',
      signedHeaders,
      payloadHash,
    ].join('\n');
    
    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    
    final scope = '$dateStamp/$_region/s3/aws4_request';
    
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      canonicalRequestHash,
    ].join('\n');
    
    final kDate = _hmacSha256(utf8.encode('AWS4$_secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmacSha256(kDate, utf8.encode(_region));
    final kService = _hmacSha256(kRegion, utf8.encode('s3'));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));
    
    return signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }
}
