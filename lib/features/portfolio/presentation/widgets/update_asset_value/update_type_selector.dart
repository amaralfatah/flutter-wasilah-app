import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

enum AssetValueUpdateType {
  /// Penyesuaian total nilai aset (menimpa nilai lama).
  override,

  /// Penambahan ke nilai aset per tanggal catat.
  increment,
}

/// Pilihan timpa/tambah nilai (hanya untuk kas).
class UpdateTypeSelector extends StatelessWidget {
  const UpdateTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AssetValueUpdateType value;
  final ValueChanged<AssetValueUpdateType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AssetValueUpdateType>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<AssetValueUpdateType>(
            value: AssetValueUpdateType.override,
            label: Text(l10n.updateTypeOverride),
            icon: const Icon(Icons.edit_outlined),
          ),
          ButtonSegment<AssetValueUpdateType>(
            value: AssetValueUpdateType.increment,
            label: Text(l10n.updateTypeIncrement),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
