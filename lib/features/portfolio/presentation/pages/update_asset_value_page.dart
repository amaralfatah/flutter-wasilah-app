import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';

enum AssetValueUpdateType {
  /// Penyesuaian total nilai aset (menimpa nilai lama).
  override,

  /// Penambahan ke nilai aset saat ini.
  increment,
}

class UpdateAssetValuePage extends ConsumerStatefulWidget {
  const UpdateAssetValuePage({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<UpdateAssetValuePage> createState() =>
      _UpdateAssetValuePageState();
}

class _UpdateAssetValuePageState extends ConsumerState<UpdateAssetValuePage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();
  DateTime? _selectedDate;
  String? _costPrefilledFor;
  String? _selectedAssetId;
  AssetValueUpdateType _updateType = AssetValueUpdateType.override;

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.assetId;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(assetListProvider);
    final submitState = ref.watch(updateAssetValueControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update nilai aset')),
      body: AsyncValueView(
        value: assetsValue,
        onRetry: () => ref.invalidate(assetListProvider),
        data: (assets) {
          final selectedAsset = _findSelectedAsset(assets);
          final previousValue = selectedAsset?.currentValue ?? 0;
          final inputValue = parseCurrencyInput(_valueController.text) ?? 0;
          final latestValue = _updateType == AssetValueUpdateType.override
              ? (parseCurrencyInput(_valueController.text) ?? previousValue)
              : previousValue + inputValue;
          _prefillCost(selectedAsset);
          final previousCost = selectedAsset?.totalCost;
          final inputCost = parseCurrencyInput(_costController.text) ?? 0;
          final latestCost = _resolveTotalCost(selectedAsset) ?? previousCost;
          final isOverride = _updateType == AssetValueUpdateType.override;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedAssetId),
                  initialValue: _selectedAssetId,
                  decoration: const InputDecoration(labelText: 'Aset'),
                  items: assets
                      .map(
                        (asset) => DropdownMenuItem<String>(
                          value: asset.id,
                          child: Text(asset.name),
                        ),
                      )
                      .toList(),
                  validator: validateSelectedAsset,
                  onChanged: (value) {
                    setState(() {
                      _selectedAssetId = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tipe pembaruan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AssetValueUpdateType>(
                    segments: const [
                      ButtonSegment<AssetValueUpdateType>(
                        value: AssetValueUpdateType.override,
                        label: Text('Ubah'),
                        icon: Icon(Icons.edit_outlined),
                      ),
                      ButtonSegment<AssetValueUpdateType>(
                        value: AssetValueUpdateType.increment,
                        label: Text('Tambah'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_updateType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _updateType = newSelection.first;
                        // Arti field modal ikut berganti (total vs.
                        // penambahan), jadi isinya disiapkan ulang.
                        _costPrefilledFor = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: isOverride ? 'Total nilai aset' : 'Penambahan nilai',
                  helperText: isOverride
                      ? 'Nilai aset akan disesuaikan menjadi nominal ini.'
                      : 'Nominal ini akan ditambahkan ke nilai aset saat ini.',
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  prefixText: 'Rp',
                  validator: validateCurrencyValue,
                  inputFormatters: const [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: isOverride
                      ? 'Total modal (opsional)'
                      : 'Penambahan modal (opsional)',
                  helperText: isOverride
                      ? 'Total dana yang sudah disetor. Kosongkan bila '
                            'modal tidak berubah.'
                      : 'Dana yang baru disetor. Kosongkan bila penambahan '
                            'berasal dari hasil investasi.',
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  prefixText: 'Rp',
                  validator: validateOptionalCurrencyValue,
                  inputFormatters: const [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                FormField<DateTime>(
                  initialValue: _selectedDate,
                  validator: validateSelectedDate,
                  builder: (field) {
                    final selectedDate = field.value;
                    final hasValue = selectedDate != null;

                    return InkWell(
                      onTap: submitState.isLoading
                          ? null
                          : () => _selectDate(context, field),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal pencatatan',
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          hasValue
                              ? formatFullDate(selectedDate)
                              : 'Pilih tanggal',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: hasValue
                                    ? null
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Catatan (opsional)',
                  controller: _noteController,
                  maxLines: 2,
                  maxLength: 200,
                  validator: validateNote,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PreviewRow(
                        label: 'Nilai saat ini',
                        value: formatCurrency(previousValue),
                      ),
                      if (!isOverride) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _PreviewRow(
                          label: 'Tambahan nilai',
                          value: '+ ${formatCurrency(inputValue)}',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _PreviewRow(
                        label: 'Nilai terbaru',
                        value: formatCurrency(latestValue),
                      ),
                      if (latestCost != null) ...[
                        const Divider(height: AppSpacing.xl),
                        _PreviewRow(
                          label: 'Modal saat ini',
                          value: previousCost == null
                              ? '-'
                              : formatCurrency(previousCost),
                        ),
                        if (!isOverride) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _PreviewRow(
                            label: 'Tambahan modal',
                            value: '+ ${formatCurrency(inputCost)}',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _PreviewRow(
                          label: 'Modal terbaru',
                          value: formatCurrency(latestCost),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PreviewRow(
                          label: profitLossLabel(latestValue - latestCost),
                          value: formatProfitLoss(
                            latestValue - latestCost,
                            cost: latestCost,
                          ),
                          valueColor: profitLossColorOf(
                            context,
                            latestValue - latestCost,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Simpan',
                  onPressed: submitState.isLoading
                      ? null
                      : () => _submit(selectedAsset),
                  isLoading: submitState.isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Siapkan field modal sekali per pergantian aset atau mode: mode ubah
  /// diisi modal saat ini, mode tambah dikosongkan.
  void _prefillCost(Asset? asset) {
    if (asset == null || asset.id == _costPrefilledFor) {
      return;
    }
    _costPrefilledFor = asset.id;
    final cost = asset.totalCost;
    _costController.text =
        cost == null || _updateType == AssetValueUpdateType.increment
        ? ''
        : formatCurrency(cost).replaceFirst('Rp', '');
  }

  /// Modal baru yang dikirim ke repository; `null` berarti modal tidak
  /// berubah (repository membawa modal terakhir).
  double? _resolveTotalCost(Asset? asset) {
    final inputCost = parseCurrencyInput(_costController.text);
    if (_updateType == AssetValueUpdateType.override) {
      return inputCost;
    }
    if (asset == null || inputCost == null || inputCost == 0) {
      return null;
    }
    // Aset tanpa modal dianggap modalnya sama dengan nilainya sekarang,
    // supaya setoran baru tidak terbaca sebagai seluruh modal.
    return (asset.totalCost ?? asset.currentValue) + inputCost;
  }

  Asset? _findSelectedAsset(List<Asset> assets) {
    for (final asset in assets) {
      if (asset.id == _selectedAssetId) {
        return asset;
      }
    }

    return null;
  }

  Future<void> _submit(Asset? selectedAsset) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedAssetId = _selectedAssetId;
    final parsedValue = parseCurrencyInput(_valueController.text);
    final selectedDate = _selectedDate;

    if (selectedAssetId == null ||
        parsedValue == null ||
        selectedDate == null) {
      return;
    }

    final effectiveTotal = _updateType == AssetValueUpdateType.override
        ? parsedValue
        : (selectedAsset?.currentValue ?? 0) + parsedValue;
    final totalCost = _resolveTotalCost(selectedAsset);

    try {
      await ref
          .read(updateAssetValueControllerProvider.notifier)
          .submit(
            assetId: selectedAssetId,
            totalValue: effectiveTotal,
            recordedAt: selectedDate,
            note: _noteController.text,
            totalCost: totalCost,
          );

      if (!mounted) {
        return;
      }

      final assetName = selectedAsset?.name ?? 'Aset';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nilai $assetName berhasil diperbarui.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ArgumentError
          ? error.message.toString()
          : 'Pembaruan nilai aset belum berhasil. Coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
    field.didChange(pickedDate);
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
