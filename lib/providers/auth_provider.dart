// مسار الملف: lib/providers/auth_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:saba2v2/models/property_model.dart';
import 'package:saba2v2/services/auth_service.dart';
import 'package:saba2v2/services/image_upload_service.dart';
import 'package:saba2v2/services/property_service.dart';

/// enum لتمثيل حالة المصادقة بشكل واضح
enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

/// Provider شامل لإدارة حالة المصادقة والعقارات في التطبيق
class AuthProvider with ChangeNotifier {
  //============================================================================
  // 1. الخدمات والاعتماديات (Dependencies)
  //============================================================================
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  int? _realEstateId;

  

  // أضف Getter جديد
  int? get realEstateId => _realEstateId;

  //============================================================================
  // 2. متغيرات الحالة (State Variables)
  //============================================================================

  // -- حالة المصادقة --
  AuthStatus _authStatus = AuthStatus.uninitialized;
  Map<String, dynamic>? _userData;
  String? _token;

  // -- حالة العقارات --
  List<Property> _properties = [];
  bool _isLoading = false; // متغير تحميل واحد لكل العمليات الطويلة

  //============================================================================
  // 3. الـ Getters (لقراءة الحالة من الواجهة)
  //============================================================================

   AuthStatus get authStatus => _authStatus;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _authStatus == AuthStatus.authenticated;
  String? get token => _token;
  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  
  // Getter لنوع المستخدم لتسهيل الوصول إليه من أي مكان
  String? get userType => _userData?['user_type'];

  

  //============================================================================
  // 4. دوال إدارة الحالة (Actions)
  //============================================================================

  /// يتم استدعاؤها عند بدء تشغيل التطبيق لتهيئة الحالة
  Future<void> initialize() async {
    await _loadUserSession();
  }

  /// تحميل جلسة المستخدم من التخزين المحلي وجلب بياناته
 Future<void> _loadUserSession() async {
    _token = await _authService.getToken();
    _userData = await _authService.getUserData();

    if (_token != null && _userData != null) {
      _authStatus = AuthStatus.authenticated;
      debugPrint("AuthProvider SESSION: Session loaded. User type is: '$userType'.");

      // التحقق من نوع المستخدم قبل جلب العقارات
      if (userType == 'real_estate_office' || userType == 'real_estate_individual') {
        debugPrint("AuthProvider SESSION: User is Real Estate. Fetching properties...");
        await fetchMyProperties();
      } else {
        debugPrint("AuthProvider SESSION: User is not a real estate type. Skipping property fetch.");
      }

    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  //-----------------------------------------------------
  // دوال خاصة بالمصادقة والعقارات
  //-----------------------------------------------------

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      if (result['status'] == true && result['user'] != null) {
        debugPrint("AuthProvider LOGIN: Login API call successful.");

        // قراءة البيانات المحفوظة حديثًا بواسطة الخدمة
        await _loadUserSession(); // هذه الدالة أصبحت ذكية وستقوم باللازم

        return result;
      } else {
        // في حالة فشل تسجيل الدخول من الـ API
        _authStatus = AuthStatus.unauthenticated;
        return result;
      }
    } catch (e) {
      debugPrint("AuthProvider LOGIN: An error occurred: $e");
      _authStatus = AuthStatus.unauthenticated;
      return {'status': false, 'message': 'حدث خطأ غير متوقع: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint("Failed to logout from server: $e");
    } finally {
      _authStatus = AuthStatus.unauthenticated;
      _userData = null;
      _token = null;
      _properties.clear(); // مسح قائمة العقارات عند الخروج
      notifyListeners();
    }
  }
  
  
  
 
 
  /// جلب عقارات المستخدم الحالي من الـ API
  // في ملف: lib/providers/auth_provider.dart

  Future<void> fetchMyProperties() async {
    if (!isLoggedIn) {
      debugPrint("AuthProvider FETCH: User is not logged in. Aborting fetch.");
      return;
    }

    debugPrint("AuthProvider FETCH: Starting to fetch properties...");
    _isLoading = true;
    notifyListeners(); // <-- إعلام الواجهة ببدء التحميل

    try {
      // استدعاء الخدمة لجلب البيانات
      final fetchedProperties = await _propertyService.getMyProperties();

      // تحديث قائمة العقارات في الـ Provider
      _properties = fetchedProperties;

      // ==========================================================
      // --- طباعة تشخيصية للتحقق من البيانات المستلمة ---
      debugPrint(
          "AuthProvider FETCH: Successfully fetched ${_properties.length} properties.");
      if (_properties.isNotEmpty) {
        debugPrint(
            "AuthProvider FETCH: First property address: ${_properties.first.address}");
      }
      // ==========================================================
    } catch (error) {
      debugPrint(
          "AuthProvider FETCH: An error occurred while fetching properties.");
      debugPrint("Error details: $error");
      // في حالة الخطأ، تأكد من إفراغ القائمة
      _properties = [];
    }

    // إيقاف التحميل وإعلام الواجهة بالتغيير النهائي
    _isLoading = false;
    debugPrint("AuthProvider FETCH: Fetch finished. Notifying listeners.");
    notifyListeners(); // <-- التأكد من إعلام الواجهة بالبيانات الجديدة أو القائمة الفارغة
  }

  /// إضافة عقار جديد (رفع الصورة ثم إضافة البيانات)
  Future<bool> addProperty({
    required String address,
    required String type,
    required int price,
    required String description,
    required File imageFile,
    required int bedrooms,
    required int bathrooms,
    required String view,
    required String paymentMethod,
    required String area,
    required bool isReady,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String imageUrl = await _imageUploadService.uploadImage(imageFile);
      final newProperty = await _propertyService.addProperty(
        address: address,
        type: type,
        price: price,
        description: description,
        imageUrl: imageUrl,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        view: view,
        paymentMethod: paymentMethod,
        area: area,
        isReady: isReady,
      );
      _properties.insert(0, newProperty);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint("AuthProvider: Error during add property process: $error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تحديث بيانات عقار
  // في ملف: lib/providers/auth_provider.dart

// استبدل هذه الدالة بالكامل
  Future<bool> updateProperty({
    required Property updatedProperty, // <-- الاسم الصحيح هو updatedProperty
    File? newImageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var propertyDataToSend = updatedProperty.toJson();

      if (newImageFile != null) {
        debugPrint("AuthProvider: Uploading new image for update...");
        final newImageUrl = await _imageUploadService.uploadImage(newImageFile);
        propertyDataToSend['image_url'] = newImageUrl;
      }

      final savedProperty = await _propertyService.updateProperty(
          updatedProperty.id, // <-- تمرير الـ ID
          propertyDataToSend // <-- تمرير الـ Map
          );

      final index = _properties.indexWhere((p) => p.id == savedProperty.id);
      if (index != -1) {
        _properties[index] = savedProperty;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint("AuthProvider: Error updating property: $error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProperty(int propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _propertyService.deleteProperty(propertyId);

      // احذف العقار من القائمة المحلية
      _properties.removeWhere((p) => p.id == propertyId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint("AuthProvider: Error deleting property: $error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  //-----------------------------------------------------
  // دوال التسجيل الكاملة
  //-----------------------------------------------------

  Future<Map<String, dynamic>> registerNormalUser(
      {required String name,
      required String email,
      required String password,
      required String phone,
      required String governorate}) async {
    final result = await _authService.registerNormalUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        governorate: governorate);
    if (result['status'] == true) await _loadUserSession();
    return result;
  }

  Future<Map<String, dynamic>> registerRealstateOffice(
      {required String username,
      required String email,
      required String password,
      required String phone,
      required String city,
      required String address,
      required bool vat,
      required String officeLogoPath,
      required String ownerIdFrontPath,
      required String ownerIdBackPath,
      required String officeImagePath,
      required String commercialCardFrontPath,
      required String commercialCardBackPath}) async {
    final result = await _authService.registerRealstateOffice(
        username: username,
        email: email,
        password: password,
        phone: phone,
        city: city,
        address: address,
        vat: vat,
        officeLogoPath: officeLogoPath,
        ownerIdFrontPath: ownerIdFrontPath,
        ownerIdBackPath: ownerIdBackPath,
        officeImagePath: officeImagePath,
        commercialCardFrontPath: commercialCardFrontPath,
        commercialCardBackPath: commercialCardBackPath);
    if (result['status'] == true) await _loadUserSession();
    return result;
  }

  Future<Map<String, dynamic>> registerIndividualAgent(
      {required String name,
      required String email,
      required String password,
      required String phone,
      required String governorate,
      required String profileImage,
      required String agentIdFrontImage,
      required String agentIdBackImage,
      String? taxCardFrontImage,
      String? taxCardBackImage}) async {
    return await _authService.registerIndividualAgent(
        name: name,
        email: email,
        password: password,
        phone: phone,
        governorate: governorate,
        profileImage: profileImage,
        agentIdFrontImage: agentIdFrontImage,
        agentIdBackImage: agentIdBackImage,
        taxCardFrontImage: taxCardFrontImage,
        taxCardBackImage: taxCardBackImage);
  }

  Future<Map<String, dynamic>> registerDeliveryOffice(
      {required String fullName,
      required String email,
      required String password,
      required String phone,
      required String officeName,
      required String governorate,
      required String logoImageUrl,
      required String commercialFrontImageUrl,
      required String commercialBackImageUrl,
      required List<String> paymentMethods,
      required List<String> rentalTypes,
      required double costPerKm,
      required double driverCost,
      required int maxKmPerDay}) async {
    return await _authService.registerDeliveryOffice(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        officeName: officeName,
        governorate: governorate,
        logoImageUrl: logoImageUrl,
        commercialFrontImageUrl: commercialFrontImageUrl,
        commercialBackImageUrl: commercialBackImageUrl,
        paymentMethods: paymentMethods,
        rentalTypes: rentalTypes,
        costPerKm: costPerKm,
        driverCost: driverCost,
        maxKmPerDay: maxKmPerDay);
  }

  Future<Map<String, dynamic>> registerDeliveryPerson(
      {required String fullName,
      required String email,
      required String password,
      required String phone,
      required String governorate,
      required String profileImageUrl,
      required List<String> paymentMethods,
      required List<String> rentalTypes,
      required double costPerKm,
      required double driverCost,
      required int maxKmPerDay}) async {
    return await _authService.registerDeliveryPerson(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        governorate: governorate,
        profileImageUrl: profileImageUrl,
        paymentMethods: paymentMethods,
        rentalTypes: rentalTypes,
        costPerKm: costPerKm,
        driverCost: driverCost,
        maxKmPerDay: maxKmPerDay);
  }

  Future<Map<String, dynamic>> registerRestaurant(
      {required Map<String, dynamic> legalData,
      required Map<String, dynamic> accountInfo,
      required Map<String, dynamic> workHours}) async {
    return await _authService.registerRestaurant(
        legalData: legalData, accountInfo: accountInfo, workHours: workHours);
  }
}
