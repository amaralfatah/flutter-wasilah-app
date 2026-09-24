import 'package:flutter/material.dart';

/// Daftar baris dipisah divider tipis.
///
/// Tidak membawa padding horizontal sendiri: halaman pemanggil bertanggung
/// jawab membuat area di sekitarnya tanpa jarak horizontal (lihat
/// `RefreshablePageBody` dengan padding horizontal 0) supaya daftar
/// menyentuh tepi layar. Baris (mis. AssetListItem) menyediakan padding
/// horizontalnya sendiri agar teks tidak menempel tepi; divider tanpa
/// indent supaya garisnya sepanjang lebar page, bukan lebar konten.
class AppListCard extends StatelessWidget {
  const AppListCard({
    required this.children,
    super.key,
    this.hasHeader = false,
  });

  final List<Widget> children;

  /// `true` kalau `children.first` adalah baris header/toggle (mis.
  /// AssetTableHeader) — divider tepat di bawahnya dihilangkan supaya
  /// header menyatu langsung dengan baris pertama.
  final bool hasHeader;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    const divider = Divider(
      height: 1,
      thickness: 0.2,
    );

    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1 && !(hasHeader && index == 0))
            divider,
        ],
      ],
    );
  }
}
