import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.isPassword = false,
    this.isVerified = false,
    this.maxLines = 1,
    this.prefixIcon,
  });
  final TextEditingController? controller;
  final String? label, hintText, helperText, errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled, isPassword, isVerified;
  final int maxLines;
  final IconData? prefixIcon;
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: widget.isPassword && !_visible,
    autocorrect: !widget.isPassword,
    enableSuggestions: !widget.isPassword,
    maxLines: widget.isPassword ? 1 : widget.maxLines,
    validator: widget.validator,
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onFieldSubmitted,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    autofillHints: widget.autofillHints,
    inputFormatters: widget.inputFormatters,
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
              onPressed: widget.enabled
                  ? () => setState(() => _visible = !_visible)
                  : null,
              icon: Icon(
                _visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            )
          : widget.isVerified
          ? Icon(Icons.verified_outlined, color: context.semanticColors.success)
          : null,
    ),
  );
}

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilter,
    this.hintText = 'Tìm quán ăn, món ăn...',
    this.filterCount = 0,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onFilter;
  final String hintText;
  final int filterCount;
  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_refresh);
      if (oldWidget.controller == null) _controller.dispose();
      _attach();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: widget.hintText,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Xoá nội dung',
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              icon: const Icon(Icons.cancel_outlined, size: 20),
            ),
          if (widget.onFilter != null) ...[
            SizedBox(
              height: 24,
              child: VerticalDivider(color: context.colors.outlineVariant),
            ),
            IconButton(
              tooltip: 'Bộ lọc',
              onPressed: widget.onFilter,
              icon: Badge(
                isLabelVisible: widget.filterCount > 0,
                label: Text('${widget.filterCount}'),
                backgroundColor: context.colors.secondaryContainer,
                textColor: context.colors.onSecondaryContainer,
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
