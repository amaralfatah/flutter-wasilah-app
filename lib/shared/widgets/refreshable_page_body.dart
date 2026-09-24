import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

/// Lebar baca maksimum konten. Material 3 meminta konten dibatasi di window
/// lebar; tanpa ini satu baris teks membentang penuh layar tablet.
const _maxContentWidth = 840.0;

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
          // Sisa lebar dibagi rata jadi padding kiri-kanan, bukan diregangkan
          // ke konten. Cara ini menjaga perilaku tinggi minimum di bawah tetap
          // apa adanya.
          final sideGutter =
              ((constraints.maxWidth -
                          resolvedPadding.horizontal -
                          _maxContentWidth) /
                      2)
                  .clamp(0.0, double.infinity);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                resolvedPadding + EdgeInsets.symmetric(horizontal: sideGutter),
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
