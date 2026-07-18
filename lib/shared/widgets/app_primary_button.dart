import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              const SizedBox(width: 12),
              Text(label),
            ],
          )
        : Text(label);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: buttonChild,
    );

    if (!isFullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
