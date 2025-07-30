class OrderModel {
  final String id;
  final String customerName;
  final String customerImage;
  final DateTime orderTime;
  final double totalAmount;
  final String status;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerImage,
    required this.orderTime,
    required this.totalAmount,
    required this.status,
    required this.items,
  });

  // دالة لتحويل الـ JSON إلى كائن OrderModel
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // ترجمة حالة الطلب من الإنجليزية إلى العربية
    String mapStatus(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return 'قيد الانتظار';
        case 'processing':
          return 'قيد التنفيذ';
        case 'completed':
        case 'delivered':
          return 'منتهية';
        default:
          return status; // للحالات غير المتوقعة
      }
    }

    return OrderModel(
      id: json['order_number'] ?? 'N/A',
      customerName: json['user']?['name'] ?? 'زبون',
      customerImage: json['user']?['profile_image'] ?? "assets/images/user_avatar.jpg",
      orderTime: DateTime.parse(json['created_at']),
      totalAmount: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: mapStatus(json['status']),
      items: (json['items'] as List<dynamic>?)
              ?.map((itemJson) => OrderItem.fromJson(itemJson))
              .toList() ?? [],
    );
  }
}

class OrderItem {
  final String name;
  final String image;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  // دالة لتحويل الـ JSON إلى كائن OrderItem
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['title'] ?? '',
      image: json['image'] ?? "assets/images/pizza.jpg", // صورة افتراضية
      price: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 0,
    );
  }
}