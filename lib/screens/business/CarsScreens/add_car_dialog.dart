// lib/widgets/add_car_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saba2v2/services/car_api_service.dart';

class AddCarDialog extends StatefulWidget {
  final int carRentalId;
  final String ownerType;
  final CarApiService apiService;
  final VoidCallback onCarAdded; // لإعادة تحميل القائمة بعد الإضافة

  const AddCarDialog({
    Key? key,
    required this.carRentalId,
    required this.ownerType,
    required this.apiService,
    required this.onCarAdded,
  }) : super(key: key);

  @override
  _AddCarDialogState createState() => _AddCarDialogState();
}

class _AddCarDialogState extends State<AddCarDialog> {
  final _formKey = GlobalKey<FormState>();
  final carTypeController = TextEditingController();
  final modelController = TextEditingController();
  final colorController = TextEditingController();
  final plateNumberController = TextEditingController();
  
  File? licenseFrontImage, licenseBackImage, carLicenseFront, carLicenseBack, carImageFront, carImageBack;
  
  bool _isSaving = false;

  @override
  void dispose() {
    carTypeController.dispose();
    modelController.dispose();
    colorController.dispose();
    plateNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveCar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final allImages = {
      "صورة الرخصة (وجه)": licenseFrontImage, "صورة الرخصة (خلف)": licenseBackImage,
      "استمارة السيارة (وجه)": carLicenseFront, "استمارة السيارة (خلف)": carLicenseBack,
      "صورة السيارة (أمام)": carImageFront, "صورة السيارة (خلف)": carImageBack,
    };

    if (allImages.containsValue(null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى رفع جميع الصور المطلوبة (6 صور)"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, String> imageUrls = {};
      for (var entry in allImages.entries) {
        imageUrls[entry.key] = await widget.apiService.uploadImage(entry.value!);
      }
      
      final Map<String, dynamic> carData = {
        "car_rental_id": widget.carRentalId,
        "owner_type": widget.ownerType,
        "car_type": carTypeController.text,
        "car_model": modelController.text,
        "car_color": colorController.text,
        "car_plate_number": plateNumberController.text,
        // تأكد من أن هذه المفاتيح تطابق ما يتوقعه الـ API
        "license_front_image": imageUrls["صورة الرخصة (وجه)"],
        "license_back_image": imageUrls["صورة الرخصة (خلف)"],
        "car_license_front": imageUrls["استمارة السيارة (وجه)"],
        "car_license_back": imageUrls["استمارة السيارة (خلف)"],
        "car_image_front": imageUrls["صورة السيارة (أمام)"],
        "car_image_back": imageUrls["صورة السيارة (خلف)"],
      };

      await widget.apiService.addCar(carData);
      
      if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إضافة السيارة بنجاح"), backgroundColor: Colors.green));
          widget.onCarAdded();
      }

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحفظ: $e"), backgroundColor: Colors.red));
    } finally {
       if (mounted) {
         setState(() => _isSaving = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isSaving,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("إضافة سيارة جديدة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      
                      _buildTextField(controller: carTypeController, label: "نوع السيارة", icon: Icons.rv_hookup),
                      _buildTextField(controller: modelController, label: "موديل السيارة", icon: Icons.directions_car),
                      _buildTextField(controller: colorController, label: "لون السيارة", icon: Icons.color_lens),
                      _buildTextField(controller: plateNumberController, label: "رقم لوحة السيارة", icon: Icons.pin),
                      
                      const Divider(height: 24),
                      const Text("الأوراق والصور المطلوبة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildImagePicker("صورة الرخصة (وجه)", licenseFrontImage, (file) => setState(() => licenseFrontImage = file)),
                          _buildImagePicker("صورة الرخصة (خلف)", licenseBackImage, (file) => setState(() => licenseBackImage = file)),
                          _buildImagePicker("استمارة السيارة (وجه)", carLicenseFront, (file) => setState(() => carLicenseFront = file)),
                          _buildImagePicker("استمارة السيارة (خلف)", carLicenseBack, (file) => setState(() => carLicenseBack = file)),
                          _buildImagePicker("صورة السيارة (أمام)", carImageFront, (file) => setState(() => carImageFront = file)),
                          _buildImagePicker("صورة السيارة (خلف)", carImageBack, (file) => setState(() => carImageBack = file)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("إلغاء")),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _handleSaveCar,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text("إضافة السيارة"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (_isSaving)
               Container(
                 decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                 child: const Center(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       CircularProgressIndicator(),
                       SizedBox(height: 16),
                       Text("جاري الحفظ...", style: TextStyle(color: Colors.white, fontSize: 16)),
                     ],
                   ),
                 ),
               )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget _buildImagePicker(String title, File? imageFile, Function(File) onImageSelected) {
    final picker = ImagePicker();

    Future<void> pickImage() async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        onImageSelected(File(pickedFile.path));
      }
    }

    return InkWell(
      onTap: pickImage,
      child: Container(
        width: 150,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: imageFile == null ? Colors.grey.shade400 : Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(imageFile, fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
      ),
    );
  }
}