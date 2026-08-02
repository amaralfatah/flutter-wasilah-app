import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Satu kartu berisi banyak baris, dipisah divider tipis full-bleed.
///
/// Dipakai untuk semua daftar di app supaya tiap tab memakai bahasa visual
/// yang sama. Baris bertanggung jawab atas padding horizontalnya sendiri agar
/// divider tetap menyentuh tepi kartu.
class AppListCard extends StatelessWidget {
  const AppListCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
