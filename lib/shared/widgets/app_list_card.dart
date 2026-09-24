import 'package:flutter/material.dart';

/// Daftar baris dipisah divider tipis, termasuk di bawah baris header
/// tabel (mis. AssetTableHeader) seperti tabel Stockbit.
///
/// Tidak membawa padding horizontal sendiri: halaman pemanggil bertanggung
/// jawab membuat area di sekitarnya tanpa jarak horizontal (lihat
/// `RefreshablePageBody` dengan padding horizontal 0) supaya daftar
/// menyentuh tepi layar. Baris (mis. AssetListItem) menyediakan padding
/// horizontalnya sendiri agar teks tidak menempel tepi; divider tanpa
/// indent supaya garisnya sepanjang lebar page, bukan lebar konten.
class AppListCard extends StatelessWidget {
  const AppListCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    const divider = Divider();

    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) divider,
        ],
      ],
    );
  }
}
