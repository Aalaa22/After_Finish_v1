// lib/services/car_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';

class CarApiService {
  final String _baseUrl = "http://192.168.1.8:8000";
  final String _token;

  CarApiService({required String token}) : _token = token;

  /// ترفع ملف صورة إلى السيرفر وتعيد رابط الصورة كنص.
  Future<String> uploadImage(File imageFile) async {
    try {
      if (_token.isEmpty) {
        throw Exception('User is not authenticated. Token is missing.');
      }

      final uri = Uri.parse('$_baseUrl/api/upload');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('files[]', imageFile.path));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);

      // --- *** التعديل الأهم هنا *** ---
      // الآن نقبل رمز 200 (OK) ورمز 201 (Created) كحالات نجاح
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Image Upload Error Body: ${response.body}');
        // لا يزال من الجيد طباعة الجسم حتى لو كان هناك خطأ حقيقي
        throw Exception('فشل رفع الصورة. رمز الحالة: ${response.statusCode}');
      }
      // --- نهاية التعديل ---

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == true) {
        if (jsonResponse['files'] != null && jsonResponse['files'] is List && jsonResponse['files'].isNotEmpty) {
          return jsonResponse['files'][0] as String;
        } else {
          throw Exception('الرد من السيرفر لا يحتوي على قائمة الملفات المطلوبة.');
        }
      } else {
        throw Exception('السيرفر أعاد حالة فشل: ${jsonResponse['message'] ?? 'خطأ غير معروف'}');
      }

    } on SocketException {
      throw Exception('خطأ في الشبكة: يرجى التحقق من اتصالك بالإنترنت.');
    } on Exception catch (e) {
      debugPrint('An exception occurred in CarApiService.uploadImage: $e');
      rethrow;
    }
  }

  // --- دوال إضافة وجلب السيارات تبقى كما هي تمامًا ---
  
  Future<void> addCar(Map<String, dynamic> carData) async {
    final url = Uri.parse('$_baseUrl/api/cars');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(carData),
    );

    // من الأفضل قبول 201 هنا أيضًا لعملية الإنشاء
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('فشل إضافة السيارة: ${response.body}');
    }
  }

  
  
   Future<List<Car>> fetchMyCars(int carRentalId) async {
    final url = Uri.parse('$_baseUrl/api/cars?car_rental_id=$carRentalId');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    // --- طباعة رد السيرفر للمساعدة في اكتشاف الأخطاء ---
    debugPrint('Get My Cars - Status Code: ${response.statusCode}');
    debugPrint('Get My Cars - Response Body: ${response.body}');
    // --- نهاية الإضافة ---

    if (response.statusCode == 200) {
      try {
        // تأكد من أن الرد يحتوي على بيانات قبل محاولة تحليله
        if (response.body.isEmpty) {
          throw Exception('الرد من السيرفر فارغ.');
        }
        final Map<String, dynamic> responseData = json.decode(response.body);

        // **نقطة مهمة جداً:** تأكد من المفتاح الصحيح الذي يحتوي على القائمة
        // قد يكون 'data', 'cars', 'items' أو أي شيء آخر
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final List<dynamic> carsList = responseData['data'];
          return carsList.map((jsonData) => Car.fromJson(jsonData)).toList();
        } else {
          // إذا لم يجد مفتاح 'data'، يرمي خطأً واضحًا
          throw Exception("الرد من السيرفر لا يحتوي على مفتاح 'data' المتوقع أو أنه ليس قائمة.");
        }
      } catch (e) {
        debugPrint("Error parsing fetchMyCars response: $e");
        throw Exception("خطأ في تحليل البيانات القادمة من السيرفر.");
      }
    } else {
      // إذا فشل الطلب، ارمي خطأً يحتوي على رسالة السيرفر إن وجدت
      String errorMessage = 'فشل جلب قائمة السيارات. رمز الحالة: ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          errorMessage += ' - ${json.decode(response.body)['message']}';
        } catch (_) {
          // تجاهل الخطأ إذا لم يكن الجسم JSON
        }
      }
      throw Exception(errorMessage);
    }
  }
}