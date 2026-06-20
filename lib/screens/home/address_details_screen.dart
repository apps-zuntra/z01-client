import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class AddressDetailsScreen extends StatefulWidget {
  final String mapAddress;
  final String locality;
  final double lat;
  final double lng;

  const AddressDetailsScreen({
    super.key,
    this.mapAddress = '',
    this.locality = '',
    this.lat = 0.0,
    this.lng = 0.0,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _doorNoController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final parts = [
      _doorNoController.text.trim(),
      _apartmentController.text.trim(),
      _streetController.text.trim(),
      widget.locality,
      widget.mapAddress,
    ].where((part) => part.isNotEmpty).toList();

    String fullAddress = parts.join(', ');
    
    if (_pincodeController.text.trim().isNotEmpty) {
      fullAddress += ' - ${_pincodeController.text.trim()}';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_address', fullAddress);
    
    // Ensure locality is not empty
    String finalLocality = widget.locality;
    if (finalLocality.isEmpty && _streetController.text.isNotEmpty) {
      finalLocality = _streetController.text.trim();
    } else if (finalLocality.isEmpty) {
      finalLocality = _doorNoController.text.trim();
    }
    
    await prefs.setString('location_locality', finalLocality);
    await prefs.setDouble('location_lat', widget.lat);
    await prefs.setDouble('location_lng', widget.lng);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Enter Address Details', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.mapAddress.isNotEmpty || widget.locality.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFCA9AFF), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.locality, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(widget.mapAddress, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildTextField('Door No. / Flat No. *', _doorNoController, true),
              const SizedBox(height: 16),
              _buildTextField('Apartment / Building Name', _apartmentController, false),
              const SizedBox(height: 16),
              _buildTextField('Street / Area *', _streetController, true),
              const SizedBox(height: 16),
              _buildTextField('Landmark (Optional)', _landmarkController, false),
              const SizedBox(height: 16),
              _buildTextField('Pincode *', _pincodeController, true, isNumber: true),
              
              const SizedBox(height: 40),
              FadeInUp(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCA9AFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Address & Proceed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isRequired, {bool isNumber = false}) {
    return FadeInUp(
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCA9AFF)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
