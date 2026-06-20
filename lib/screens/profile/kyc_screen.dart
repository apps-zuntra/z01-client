import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../core/constants.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  static const Color _purple = Color(0xFFCA9AFF);
  static const Color _darkBg = Color(0xFF161616);
  static const Color _cardBg = Color(0xFF222222);

  void _nextStep() {
    setState(() {
      if (_currentStep < 4) _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitKyc() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.submitKyc({
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
      });
      _nextStep(); // Go to success screen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: _currentStep == 4 ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: _prevStep,
        ),
        title: Text(
          _currentStep == 0 ? 'KYC Verification' : 
          _currentStep == 1 ? 'Personal Details' : 
          _currentStep == 2 ? 'Upload ID Proof' : 
          'Face Verification',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStepContent(),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildIntroStep();
      case 1: return _buildPersonalDetailsStep();
      case 2: return _buildIdProofStep();
      case 3: return _buildFaceVerificationStep();
      case 4: return _buildSuccessStep();
      default: return const SizedBox.shrink();
    }
  }

  // ====== STEP 0: INTRO ======
  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        children: [
          const Text('Take less than 2 Minutes', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: Color(0xFFDDDDDD), shape: BoxShape.circle),
          ),
          const SizedBox(height: 24),
          const Text(
            'Complete KYC to Rent Equipment',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify your identity to book cameras,lenses,studios\n& Manpower',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C4DCC), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Why Verify?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('You must be 18+ to rent equipment'),
                _buildBulletPoint('You must be 18+ to rent equipment'),
                _buildBulletPoint('You must be 18+ to rent equipment'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Show 'How it works' dialog or bottom sheet
              _showHowItWorksSheet();
            },
            child: const Text('How does this work?', style: TextStyle(color: _purple, fontSize: 14)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Start Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How verifying your identity works', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBulletPoint('To start the process, you\'ll be prompted to log in to your DigiLocker account.', iconColor: Colors.white),
              const SizedBox(height: 8),
              _buildBulletPoint('DigiLocker will ask for your permission to share the following details with Z01: your full name, date of birth, gender, phone number, and photo, along with a unique identifier and confirmation of whether your DigiLocker account is linked to Aadhaar.', iconColor: Colors.white),
              const SizedBox(height: 8),
              _buildBulletPoint('Once you provide consent, Z01 will ask you to take a selfie.', iconColor: Colors.white),
              const SizedBox(height: 16),
              const Text('If your DigiLocker photo matches your selfie, and your name and birth year match your Z01 profile details, your account will be successfully verified and marked as Verified on Z01.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _purple),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go Back', style: TextStyle(color: _purple, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildBulletPoint(String text, {Color iconColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: CircleAvatar(radius: 3, backgroundColor: iconColor),
          ),
          Expanded(child: Text(text, style: TextStyle(color: iconColor, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  // ====== STEP 1: PERSONAL DETAILS ======
  Widget _buildPersonalDetailsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(1),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name'),
                  _buildInputField(controller: _nameController),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Phone Number'),
                  _buildInputField(
                    controller: _phoneController,
                    suffix: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Email Id'),
                  _buildInputField(
                    controller: _emailController,
                    suffix: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Get Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('DOB'),
                  _buildInputField(controller: _dobController, hint: 'DD/MM/YYYY'),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('You must be 18+ to rent equipment', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Address Details'),
                  _buildInputField(controller: _addressController, maxLines: 3),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ====== STEP 2: ID PROOF ======
  Widget _buildIdProofStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProgressBar(2),
          const SizedBox(height: 48),
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: Color(0xFFDDDDDD), shape: BoxShape.circle),
          ),
          const SizedBox(height: 24),
          const Text('Add a verification badge', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Verified members get seamless booking the\ncameras,lenses,studios & Manpower',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Verify with DigiLocker', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBulletPoint('Sigin into DigiLocker'),
                _buildBulletPoint('Authorize DigiLocker to share your data with Z01'),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock, color: Colors.white38, size: 20),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Verify with DigiLocker', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ====== STEP 3: FACE VERIFICATION ======
  Widget _buildFaceVerificationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProgressBar(3),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _purple.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Instructions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBulletPoint('Deposit will be refunded after equipment return'),
                _buildBulletPoint('Equipment must be returned in original condition'),
                _buildBulletPoint('Late returns will be charged at hourly rate'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: Color(0xFFDDDDDD), shape: BoxShape.circle),
          ),
          const SizedBox(height: 24),
          const Text('Complete Face Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Verify your identity to book cameras,lenses,studios\n& Manpower',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Start Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ====== STEP 4: SUCCESS ======
  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 4)),
            child: const Icon(Icons.check, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('KYC Completed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Verify your identity to book cameras,lenses,studios\n& Manpower',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C4DCC), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("What's unlock", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSuccessBullet('Govt Id'),
                const SizedBox(height: 12),
                _buildSuccessBullet('Clear photos of ID'),
                const SizedBox(height: 12),
                _buildSuccessBullet('A quick selfie for face verification'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go To Home', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBullet(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  // ====== UTILS ======
  Widget _buildProgressBar(int stepIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $stepIndex of 3', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: stepIndex >= 1 ? _purple : Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: stepIndex >= 2 ? _purple : Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: stepIndex >= 3 ? _purple : Colors.white24, borderRadius: BorderRadius.circular(2)))),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hint,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 12),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}
