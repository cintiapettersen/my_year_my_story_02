import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect,
    this.enableSuggestions,
    this.textCapitalization,
    this.textInputAction,
    this.validator,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.keyboardType == TextInputType.emailAddress;
    final effectiveAutocorrect =
        widget.autocorrect ?? (!widget.obscureText && !isEmail);
    final effectiveSuggestions =
        widget.enableSuggestions ?? (!widget.obscureText && !isEmail);
    final effectiveCapitalization = widget.textCapitalization ??
        (isEmail ? TextCapitalization.none : TextCapitalization.sentences);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isFocused
    ? const Color(0xFFC03B66).withOpacity(0.5)
    : Colors.grey.withOpacity(0.2),

          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText && _isObscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: effectiveCapitalization,
          autocorrect: effectiveAutocorrect,
          enableSuggestions: effectiveSuggestions,
          smartQuotesType: effectiveSuggestions
              ? SmartQuotesType.enabled
              : SmartQuotesType.disabled,
          smartDashesType: effectiveSuggestions
              ? SmartDashesType.enabled
              : SmartDashesType.disabled,
          validator: widget.validator,
          enabled: widget.enabled,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
  color: Colors.black,
),
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
  color: _isFocused
      ? const Color(0xFFC03B66)
      : Colors.grey.withOpacity(0.6),
),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _isFocused
    ? const Color(0xFFC03B66)
    : const Color(0xFFE2377D),
              size: 22,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFE2377D),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
      ),
    );
  }
}
