import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

class RefreshablePageBody extends StatelessWidget {
  const RefreshablePageBody({
    required this.onRefresh,
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding.resolve(Directionality.of(context));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = (constraints.maxHeight - resolvedPadding.vertical)
              .clamp(0.0, double.infinity);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: SizedBox(width: double.infinity, child: child),
            ),
          );
        },
      ),
    );
  }
}
