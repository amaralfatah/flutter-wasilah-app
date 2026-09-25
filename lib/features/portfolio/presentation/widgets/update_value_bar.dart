import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';

/// Tombol "Update nilai" yang menempel di bawah layar, untuk slot
/// `Scaffold.bottomNavigationBar`.
class UpdateValueBar extends StatelessWidget {
  const UpdateValueBar({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    // Padding di dalam SafeArea supaya jaraknya ditambahkan ke inset nav bar;
    // `SafeArea.minimum` hanya mengambil nilai terbesar.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
          ),
          onPressed: () =>
              context.push('${RouteNames.portfolio}/$assetId/update'),
          child: Text(context.l10n.updateValueButton),
        ),
      ),
    );
  }
}
