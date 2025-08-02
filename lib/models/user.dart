import 'package:saba2v2/models/restaurant_detail.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String userType;
  final RestaurantDetail? restaurantDetail; // مهم جداً: هنا نضع الـ model الآخر

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.restaurantDetail,
  });

  // هذه الـ factory هي التي ستحول الـ JSON إلى Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: json['user_type'],
      // تحقق إذا كانت بيانات المطعم موجودة قبل تحويلها
      restaurantDetail: json['restaurant_detail'] != null
          ? RestaurantDetail.fromJson(json['restaurant_detail'])
          : null,
    );
  }
}