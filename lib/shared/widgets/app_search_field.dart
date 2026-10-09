import 'package:flutter/material.dart';

enum AppSearchFieldShape {
  standard, // Radius 12
  pill,     // Radius 28
}

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool isLoading;
  
  // Design tokens
  final AppSearchFieldShape shape;
  final bool dynamicBorderRadius; // Toggles between 28 (focused & empty) and 12 (unfocused or typing)
  final Color? fillColor;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final bool unfocusOnTapOutside;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.textInputAction = TextInputAction.search,
    this.autofocus = false,
    this.isLoading = false,
    this.shape = AppSearchFieldShape.standard,
    this.dynamicBorderRadius = false,
    this.fillColor,
    this.isDense = false,
    this.contentPadding,
    this.unfocusOnTapOutside = true,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  TextEditingController get _controller => widget.controller ?? (_internalController ??= TextEditingController());
  FocusNode get _focusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    // Rebuild for dynamic border radius changes when typing/clearing
    if (widget.dynamicBorderRadius && mounted) {
      setState(() {});
    }
  }

  double _getBorderRadius() {
    if (widget.dynamicBorderRadius) {
      return (_isFocused && _controller.text.isEmpty) ? 28.0 : 12.0;
    }
    return widget.shape == AppSearchFieldShape.pill ? 28.0 : 12.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = _getBorderRadius();

    final outlineColor = colorScheme.outline.withValues(alpha: 0.3);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: const TextStyle(
        letterSpacing: 0, // Prevents letter splitting for Arabic script
      ),
      onTapOutside: widget.unfocusOnTapOutside
          ? (_) {
              _focusNode.unfocus();
            }
          : null,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: theme.hintColor,
          letterSpacing: 0,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _isFocused
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        suffixIcon: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (_controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      if (widget.onChanged != null) {
                        widget.onChanged!('');
                      }
                      if (widget.onClear != null) {
                        widget.onClear!();
                      }
                      _focusNode.requestFocus();
                    },
                  )
                : null),
        filled: true,
        fillColor: widget.fillColor ?? colorScheme.surface,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: outlineColor,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: outlineColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
