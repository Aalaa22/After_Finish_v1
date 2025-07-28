// مسار الملف: services/ar_rental_office_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/service_request_model.dart'; // تأكد من صحة المسار

class CarRentalOfficeService {
  final String _apiBaseUrl = "http://192.168.1.7:8000/api/provider/service-requests";
  final String token;

  CarRentalOfficeService({required this.token});

  //==============================================================
  // دوال جلب البيانات (GET)
  //==============================================================

  /// 1. جلب الطلبات قيد الانتظار
  Future<List<ServiceRequest>> getPendingRequests() async {
    // هذا هو الرابط الأساسي للطلبات الجديدة
    final url = Uri.parse(_apiBaseUrl); 
    return _getRequests(url);
  }

  /// 2. جلب الطلبات قيد التنفيذ
  Future<List<ServiceRequest>> getInProgressRequests() async {
    // استخدام الرابط الصحيح الذي قدمته
    final url = Uri.parse('$_apiBaseUrl/accept'); 
    return _getRequests(url);
  }

  /// 3. جلب الطلبات المنتهية
  Future<List<ServiceRequest>> getCompletedRequests() async {
    // استخدام الرابط الصحيح الذي قدمته
    final url = Uri.parse('$_apiBaseUrl/complete');
    return _getRequests(url);
  }

  /// دالة مساعدة عامة لجلب قوائم الطلبات
  Future<List<ServiceRequest>> _getRequests(Uri url) async {
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        
        // بناءً على آخر رد API صحيح، الطلبات موجودة داخل مفتاح 'requests'
        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('requests')) {
          final List<dynamic> requestsList = decodedBody['requests'];
          return requestsList.map((json) => ServiceRequest.fromJson(json)).toList();
        } else {
          // في حالة أن الرد لا يحتوي على 'requests'، ربما يكون قائمة فارغة مباشرة
          // كإجراء احتياطي، يمكننا إرجاع قائمة فارغة بدلاً من إطلاق خطأ
          return [];
        }
      } else {
        throw Exception('فشل جلب الطلبات من ($url) - خطأ ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error in _getRequests ($url): $e");
      throw Exception('حدث خطأ في الشبكة أو في تنسيق البيانات.');
    }
  }

  //==============================================================
  // دوال الإجراءات (POST)
  //==============================================================

  /// 4. قبول طلب خدمة
  Future<Map<String, dynamic>> acceptServiceRequest({required int requestId}) async {
    final url = Uri.parse('$_apiBaseUrl/$requestId/accept');
    return _postAction(url, successMessage: 'تم قبول الطلب بنجاح');
  }
  
  /// 5. إنهاء طلب خدمة
  Future<Map<String, dynamic>> completeServiceRequest({required int requestId}) async {
    final url = Uri.parse('$_apiBaseUrl/$requestId/complete');
    return _postAction(url, successMessage: 'تم إنهاء الطلب بنجاح');
  }

  /// دالة مساعدة عامة لإجراءات POST
  Future<Map<String, dynamic>> _postAction(Uri url, {required String successMessage}) async {
    try {
      final response = await http.post(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'status': true, 'message': responseData['message'] ?? successMessage};
      } else {
        throw Exception(responseData['message'] ?? 'فشل تنفيذ الإجراء');
      }
    } catch (e) {
      debugPrint("Error in _postAction ($url): $e");
      throw Exception('حدث خطأ في الشبكة: $e');
    }
  }

  //==============================================================
  // دالة تحديث التوفر (لا تغيير فيها)
  //==============================================================
  Future<bool> updateAvailability({
    required int officeDetailId,
    bool? isAvailableForDelivery,
    bool? isAvailableForRent,
  }) async {
    // ملاحظة: الرابط هنا مختلف، لذلك لا يمكن دمجه مع الـ base url أعلاه
    final availabilityUrl = Uri.parse('http://192.168.1.7:8000/api/car-rental-office-detail/$officeDetailId/availability');

    final body = {
      if (isAvailableForDelivery != null) "is_available_for_delivery": isAvailableForDelivery,
      if (isAvailableForRent != null) "is_available_for_rent": isAvailableForRent,
    };

    final response = await http.patch(
      availabilityUrl,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == true;
    } else {
      throw Exception("Failed to update availability: ${response.body}");
    }
  }
}