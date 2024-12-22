import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class SearchInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final Function(String)? onChanged;
  final FocusNode? focusNode;

  const SearchInputField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onClear,
    this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField> {
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateHasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasText);
    super.dispose();
  }

  void _updateHasText() {
    setState(() {
      _hasText = widget.controller.text.isNotEmpty;
    });
  }

  Widget _buildIcon() {
    final color = (_isFocused || _hasText) ? logoColorSecondary : Colors.grey;
    return Icon(
      Icons.search_outlined,
      size: 20,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = (_isFocused || _hasText)
        ? logoColorSecondary
        : Colors.grey.withOpacity(0.2);
    return Container(
      height: 40, // Thinner height
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: TextFormField(
                style: primaryTextStyle.copyWith(fontSize: 14),
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: subtitleTextStyle.copyWith(fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: widget.onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: (_isFocused || _hasText)
                      ? logoColorSecondary
                      : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
