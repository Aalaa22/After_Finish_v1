// lib/screens/car_management_screen.dart

import 'package:flutter/material.dart';
import 'package:saba2v2/models/car_model.dart';
import 'package:saba2v2/screens/business/CarsScreens/add_car_dialog.dart';
import 'package:saba2v2/screens/business/CarsScreens/car_card_widget.dart';
import 'package:saba2v2/services/car_api_service.dart';
// ... باقي كود الشاشة الرئيسية كما هو من الإجابة السابقة
// (لا حاجة لتغيير أي شيء آخر هنا)
class AddCarRental extends StatefulWidget {
  const AddCarRental({super.key});

  @override
  State<AddCarRental> createState() => _AddCarRentalState();
}

class _AddCarRentalState extends State<AddCarRental> {
  // بيانات يفترض أن تأتي من Provider أو شاشة تسجيل الدخول
  final String _token = "your_auth_token_here"; // <-- ضع التوكن هنا
  final int _carRentalId = 3; 
  final String _ownerType = "office";

  late final CarApiService _apiService;
  late Future<List<Car>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = CarApiService(token: _token);
    _loadCars(); // تحميل السيارات عند فتح الشاشة لأول مرة
  }
  
  // دالة لجلب البيانات من الـ API
  void _loadCars() {
    setState(() {
      _carsFuture = _apiService.fetchMyCars(_carRentalId);
    });
  }

  // دالة تُستدعى بعد نجاح الإضافة
  void _onCarAddedSuccessfully() {
    // 1. أظهر رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("تمت إضافة السيارة بنجاح!"),
      backgroundColor: Colors.green,
    ));
    // 2. أعد تحميل قائمة السيارات لتظهر السيارة الجديدة
    _loadCars();
  }

  void _openAddCarDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCarDialog(
        carRentalId: _carRentalId,
        ownerType: _ownerType,
        apiService: _apiService,
        onCarAdded: _onCarAddedSuccessfully, // <-- استدعاء الدالة عند النجاح
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("سياراتي"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCars)],
      ),
      body: FutureBuilder<List<Car>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ في جلب البيانات: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لم تقم بإضافة أي سيارات بعد.", style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          
          final cars = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadCars(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                // استخدام واجهة CarCard الجميلة
                return CarCard(
                  car: cars[index],
                  onTap: () {
                    // TODO: يمكنك هنا فتح شاشة تفاصيل السيارة
                    print("Tapped on car ID: ${cars[index].id}");
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCarDialog,
        icon: const Icon(Icons.add),
        label: const Text("إضافة سيارة جديدة"),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }
}