import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:saba2v2/models/order_model.dart';
import 'package:saba2v2/services/auth_service.dart';

class OrderService {
  final String _baseUrl = 'http://192.168.1.7:8000';
  final AuthService _authService = AuthService();

  Future<List<OrderModel>> getOrders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/api/orders');
    debugPrint("OrderService: Fetching orders from $uri");

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> ordersJson = responseData['orders'] ?? [];
      
      debugPrint("OrderService: Successfully fetched ${ordersJson.length} orders.");
      return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      debugPrint("API ERROR (getOrders): Status ${response.statusCode}, Body: ${response.body}");
      throw Exception('Failed to fetch orders. Status: ${response.statusCode}');
    }
  }
}