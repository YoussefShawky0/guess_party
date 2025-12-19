import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoomCodeInput extends StatelessWidget {
  final TextEditingController controller;

  const RoomCodeInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Room Code',
        prefixIcon: const Icon(Icons.vpn_key_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isTablet ? 32 : 28,
        fontWeight: FontWeight.bold,
        letterSpacing: isTablet ? 16 : 12,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter room code';
        }
        if (value.length != 6) {
          return 'Room code must be 6 digits';
        }
        return null;
      },
    );
  }
}
