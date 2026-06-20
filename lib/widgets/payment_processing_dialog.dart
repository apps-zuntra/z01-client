import 'dart:async';
import 'package:flutter/material.dart';

class PaymentProcessingDialog extends StatefulWidget {
  final Future<bool> Function() onProcess;
  final VoidCallback onSuccess;
  final Function(String) onFailure;

  const PaymentProcessingDialog({
    super.key,
    required this.onProcess,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  bool _apiCompleted = false;
  bool _apiSuccess = false;
  String _errorMessage = 'Payment failed. Please try again.';

  final List<String> _loadingSteps = [
    'Connecting to secure gateway...',
    'Encrypting payment details...',
    'Authorizing transaction with bank...',
    'Securing your booking seats...',
    'Generating receipt & finalising...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Premium "loading long" transition
    );

    _controller.addListener(() {
      final step = (_controller.value * _loadingSteps.length).floor();
      if (step != _currentStep && step < _loadingSteps.length) {
        setState(() {
          _currentStep = step;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishProcessing();
      }
    });

    _startProcess();
  }

  Future<void> _startProcess() async {
    // Start progress bar animation
    _controller.forward();

    try {
      final result = await widget.onProcess();
      _apiSuccess = result;
      _apiCompleted = true;
    } catch (e) {
      _apiSuccess = false;
      _apiCompleted = true;
      _errorMessage = e.toString();
    } finally {
      if (mounted && _controller.status != AnimationStatus.completed) {
        // API is done, quickly speed up the remaining animation
        _controller.duration = const Duration(milliseconds: 400);
        _controller.forward(from: _controller.value);
      }
    }
  }

  void _finishProcessing() {
    if (_apiCompleted) {
      if (mounted) {
        Navigator.pop(context); // Dismiss the dialog
        if (_apiSuccess) {
          widget.onSuccess();
        } else {
          widget.onFailure(_errorMessage);
        }
      }
    } else {
      // If API call hasn't finished, wait a bit and check again
      Future.delayed(const Duration(milliseconds: 500), _finishProcessing);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // High-fidelity progress circle with percent text
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCA9AFF)),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Micro-animated status updates
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingSteps[_currentStep],
                  key: ValueKey<int>(_currentStep),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close or exit the app',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
