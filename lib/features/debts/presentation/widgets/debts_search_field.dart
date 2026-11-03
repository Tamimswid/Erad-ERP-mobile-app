import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class DebtsSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const DebtsSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<DebtsSearchField> createState() => _DebtsSearchFieldState();
}

class _DebtsSearchFieldState extends State<DebtsSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onChanged(query),
    );
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 14, color: scheme.foreground),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(fontSize: 13, color: scheme.mutedForeground),
        prefixIcon: Icon(
          sc.LucideIcons.search,
          size: 18,
          color: scheme.mutedForeground,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: Icon(
                  sc.LucideIcons.x,
                  size: 16,
                  color: scheme.mutedForeground,
                ),
              ),
        filled: true,
        fillColor: scheme.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
