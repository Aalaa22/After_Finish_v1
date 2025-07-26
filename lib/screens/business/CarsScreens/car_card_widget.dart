// lib/widgets/car_card_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saba2v2/models/car_model.dart';


class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const CarCard({Key? key, required this.car, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Image.network(
                car.carImageFront,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 60, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${car.carType} ${car.carModel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(car.governorate, style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(intl.NumberFormat('#,###').format(car.price), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      const SizedBox(width: 4),
                      const Text('ج.م / يوم', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const Spacer(),
                      Icon(Icons.pin_drop_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(car.carPlateNumber, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}