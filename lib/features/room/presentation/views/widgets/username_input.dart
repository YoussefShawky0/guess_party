import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsernameInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;

  const UsernameInput({super.key, required this.controller, this.hintText});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Your Username',
        hintText: hintText ?? 'Enter username',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: FaIcon(FontAwesomeIcons.user, size: 20),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      style: TextStyle(fontSize: isTablet ? 20 : 18),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
        }
        if (value.length < 2) {
          return 'Username must be at least 2 characters';
        }
        return null;
      },
    );
  }
}
