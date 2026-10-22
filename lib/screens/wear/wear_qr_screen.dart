import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class WearQRScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WearQRScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final qrBase64 = data['qrBase64'] as String? ?? '';
    Uint8List? imageBytes;
    if (qrBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(qrBase64);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: imageBytes != null
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 48,
                        color: Colors.white30,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check-in',
            style: TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
