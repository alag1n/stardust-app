import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// GitHub конфигурация для загрузки изображений
const String _githubOwner = 'alag1n';
const String _githubRepo = 'stardust-images';
const String _githubToken = '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';

/// Wrapper class for XFile to handle both mobile and web
class _XFileWrapper {
  final XFile _xFile;
  
  _XFileWrapper(this._xFile);
  
  Future<List<int>> readAsBytes() async {
    return await _xFile.readAsBytes();
  }
  
  String get path => _xFile.path;
  
  String get name => _xFile.name;
}

/// Service for uploading images to Yandex Cloud Storage
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  
  // Yandex Cloud конфигурация
  final String _accessKey = 'YCAJEc75X1Jlr5yLrgszHSMOO';
  final String _secretKey = 'YCPEEWRWAFaVAY247EdNrrWh2uG_OW4OkZrqczzs';
  final String _bucket = 'daren';
  final String _endpoint = 'https://storage.yandexcloud.net';
  final String _region = 'ru-central1';
  
  // Proxy function URL for web
  final String _proxyUrl = 'https://functions.yandexcloud.net/d4e3g69asu4ph8871vct';
  
  /// Pick image from gallery
  Future<dynamic> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      return _XFileWrapper(image);
    }
    return null;
  }
  
  /// Pick image from camera
  Future<dynamic> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      return _XFileWrapper(image);
    }
    return null;
  }
  
  /// Pick multiple images
  Future<List<dynamic>> pickMultiple() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    return images.map((xFile) => _XFileWrapper(xFile)).toList();
  }
  
  /// Upload image to GitHub
  Future<String> uploadToGitHub({
    required dynamic file,
    required String userId,
    String folder = 'photos',
  }) async {
    final ext = path.extension(file.path).isNotEmpty 
        ? path.extension(file.path) 
        : '.jpg';
    final fileName = '${folder}/${userId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    
    final fileBytes = await file.readAsBytes();
    final base64Content = base64Encode(fileBytes);
    
    final uri = Uri.parse(
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/contents/$fileName'
    );
    
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'token $_githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': 'Upload image $fileName',
        'content': base64Content,
      }),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['content']['download_url'];
    } else {
      throw Exception('GitHub upload failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Upload image to Yandex Cloud Storage
  Future<String> uploadToYandex({
    required dynamic file,
    required String userId,
    String folder = 'avatars',
  }) async {
    // Используем GitHub для загрузки (работает везде)
    return uploadToGitHub(file: file, userId: userId, folder: folder);
  }
  
  /// Upload image (alias for uploadToYandex)
  Future<String> uploadToFirebase({
    required dynamic file,
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
