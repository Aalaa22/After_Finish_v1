// مسار الملف: lib/services/image_upload_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:saba2v2/services/auth_service.dart';
class ImageUploadService {
  final String _baseUrl = 'http://192.168.1.7:8000';
  final AuthService _authService = AuthService();

  /// ترفع ملف صورة إلى السيرفر وتعيد رابط الصورة كنص
  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/upload');
    
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('User is not authenticated.');

      // --- [تتبع 1: بداية العملية] ---
      debugPrint("--- UPLOAD START ---");
      debugPrint("Uploading to: $uri");
      debugPrint("File path: ${imageFile.path}");
      
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.files.add(await http.MultipartFile.fromPath('files[]', imageFile.path));
      
      // --- [تتبع 2: إرسال الطلب] ---
      debugPrint("Sending multipart request...");
      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);
      
      // --- [تتبع 3: استلام الرد] ---
      debugPrint("Response received. Status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload image. Server returned status: ${response.statusCode}');
      }

      var jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['status'] == true) {
        if (jsonResponse['files'] != null && jsonResponse['files'] is List && jsonResponse['files'].isNotEmpty) {
          
          final imageUrl = jsonResponse['files'][0] as String;
          // --- [تتبع 4: النجاح واستخلاص الرابط] ---
          debugPrint("!!! UPLOAD SUCCESS !!!. Returned URL: $imageUrl");
          debugPrint("--- UPLOAD END ---");

          return imageUrl;
        } else {
          throw Exception('Image upload failed: API response is missing the "files" array.');
        }
      } else {
        throw Exception('Image upload failed: API returned status false. Message: ${jsonResponse['message'] ?? 'Unknown error'}');
      }
    } on SocketException {
      debugPrint("!!! UPLOAD FAILED: SocketException !!!");
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      debugPrint("!!! UPLOAD FAILED: An exception occurred !!!: $e");
      rethrow;
    }
  }
}