import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'customer_report_issue_screen.dart';

/// CUSTOMER APP: Confirm Delivery Screen
/// Route to this screen when the customer wants to confirm they received the item.
class CustomerConfirmDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CustomerConfirmDeliveryScreen({
    super.key, 
    required this.booking,
  });

  @override
  State<CustomerConfirmDeliveryScreen> createState() => _CustomerConfirmDeliveryScreenState();
}

class _CustomerConfirmDeliveryScreenState extends State<CustomerConfirmDeliveryScreen> {
  final List<File> _pickedImages = [];
  bool _isLoading = false;

  // Colors based on your screenshot
  static const Color _bgColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _purple = Color(0xFFCA9AFF); // The purple button color
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Colors.white70;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _pickedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _confirmReceipt() async {
    setState(() => _isLoading = true);
    
    try {
      final bookingId = widget.booking['id'].toString();
      
      // Call the backend API
      // This MUST hit POST /bookings/:id/complete
      final success = await ApiService.completeBooking(bookingId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery Confirmed! Your rental has started.')),
          );
          Navigator.pop(context, true); // Go back to booking details
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to confirm delivery.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract info from booking object
    final title = widget.booking['listing_name'] ?? widget.booking['item_name'] ?? 'Booking Item';
    final location = widget.booking['location_address'] ?? widget.booking['location'] ?? 'Unknown Location';
    final priceStr = widget.booking['total_amount']?.toString() ?? widget.booking['total_price']?.toString() ?? '0';
    final rawImage = widget.booking['image_1'] ?? widget.booking['listing_image'];
    final imageUrl = ApiService.getSafeImageUrl(rawImage);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: const BackButton(color: _textPrimary),
        title: const Text('Confirm Your Delivery', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify everything before confirming receipt.',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Item Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                        : Container(width: 70, height: 70, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(title, style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B2A4A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('₹$priceStr', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: _textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(child: Text(location, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Upload Photos Section
            const Text('UPLOAD PHOTOS (OPTIONAL)', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: _buildUploadButton(Icons.camera_alt_outlined, 'Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: _buildUploadButton(Icons.upload_file_outlined, 'Upload Image'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Image Preview
            if (_pickedImages.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _pickedImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(entry.value),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1C3D), // Deep purple tint
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFCA9AFF), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By confirming delivery, your rental period officially starts and return policies become active.',
                      style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("I've Received", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Report Issue Button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerReportIssueScreen(booking: widget.booking),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, color: _textSecondary, size: 18),
                label: const Text('Report an Issue', style: TextStyle(color: _textSecondary, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
