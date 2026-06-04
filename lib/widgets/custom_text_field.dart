import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? suffixText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final FocusNode? focusNode;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.suffixText,
    this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            suffixText: suffixText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textSecondary, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
