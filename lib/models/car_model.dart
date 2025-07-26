// lib/models/car_model.dart

// هذا هو المصدر الوحيد والحقيقي لتعريف السيارة
class Car {
  final int id;
  final String carType;
  final String carModel;
  final String carImageFront;
  final String carPlateNumber;
  final String governorate;
  final double price;

  Car({
    required this.id,
    required this.carType,
    required this.carModel,
    required this.carImageFront,
    required this.carPlateNumber,
    required this.governorate,
    required this.price,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? 0,
      carType: json['car_type'] ?? 'N/A',
      carModel: json['car_model'] ?? 'N/A',
      carImageFront: json['car_image_front'] ?? '',
      carPlateNumber: json['car_plate_number'] ?? 'N/A',
      governorate: json['governorate'] ?? 'غير محدد',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}