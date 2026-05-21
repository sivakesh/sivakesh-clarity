import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInput extends StatefulWidget {
  final ValueChanged<String> onSendOtp;
  final bool isLoading;

  const PhoneInput({
    super.key,
    required this.onSendOtp,
    this.isLoading = false,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  static const int _minPhoneLength = 10;
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  String? _inlineError;
  bool _isPressed = false;
  bool _isFocused = false;

  final List<String> _countryCodes = const ['+91', '+1', '+44', '+61'];

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  String _trimLeadingZeros(String input) => input.replaceFirst(RegExp(r'^0+'), '');

  bool _isValidPhone(String value) {
    final digits = _trimLeadingZeros(_digitsOnly(value.trim()));
    return digits.length >= _minPhoneLength;
  }

  void _onSubmit() {
    final cleaned = _trimLeadingZeros(_digitsOnly(_phoneController.text.trim()));
    if (!_isValidPhone(cleaned)) {
      setState(() {
        _inlineError = 'Enter a valid phone number';
      });
      return;
    }
    setState(() {
      _inlineError = null;
    });
    final fullPhone = '$_selectedCountryCode$cleaned';
    widget.onSendOtp(fullPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF202226),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? const Color(0x66C9D7FF)
                  : const Color(0x26FFFFFF),
              width: 1,
            ),
            boxShadow: _isFocused
                ? const [
                    BoxShadow(
                      color: Color(0x1F87A8FF),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2C31),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x29FFFFFF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    dropdownColor: const Color(0xFF232323),
                    style: const TextStyle(
                      color: Color(0xFFE9E9EA),
                      fontWeight: FontWeight.w500,
                    ),
                    iconEnabledColor: const Color(0xFFBFC3CC),
                    items: _countryCodes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ),
                        )
                        .toList(),
                    onChanged: widget.isLoading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCountryCode = value;
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 24, color: const Color(0x30FFFFFF)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  enabled: !widget.isLoading,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: const TextStyle(
                    color: Color(0xFFF0F0F0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () => setState(() => _isFocused = true),
                  onChanged: (_) {
                    if (!_isFocused) {
                      setState(() => _isFocused = true);
                    }
                    if (_inlineError != null) {
                      setState(() {
                        _inlineError = null;
                      });
                    } else {
                      setState(() {});
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    hintText: '9876543210',
                    hintStyle: TextStyle(color: Color(0xFF8B8E95)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter a valid phone number',
              style: TextStyle(color: Color(0xFFE58B92), fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: FilledButton(
            onPressed: widget.isLoading || !_isValidPhone(_phoneController.text)
                ? null
                : _onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE9EAEC),
              foregroundColor: const Color(0xFF1A1B1D),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send OTP'),
          ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus && _isFocused) {
              setState(() => _isFocused = false);
            }
          },
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
