import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
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
  final _quantityController = TextEditingController();
  final _avgBuyPriceController = TextEditingController();
  DateTime? _selectedDate;
  String? _valuePrefilledFor;
  String? _costPrefilledFor;
  String? _holdingPrefilledFor;
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
    _quantityController.dispose();
    _avgBuyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(assetListProvider);
    final submitState = ref.watch(updateAssetValueControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateAssetValueTitle)),
      body: SafeArea(
        child: AsyncValueView(
          value: assetsValue,
          onRetry: () => ref.invalidate(assetListProvider),
          data: (assets) {
            final selectedAsset = _findSelectedAsset(assets);
            // Opsi tambah/timpa hanya untuk kas; aset lain selalu timpa.
            final allowIncrement = _allowsIncrement(selectedAsset);
            final isOverride =
                _resolveUpdateType(selectedAsset) ==
                AssetValueUpdateType.override;
            final previousValue = selectedAsset?.currentValue ?? 0;
            final inputValue = parseCurrencyInput(_valueController.text) ?? 0;
            final latestValue = isOverride
                ? (parseCurrencyInput(_valueController.text) ?? previousValue)
                : previousValue + inputValue;
            _prefillValue(selectedAsset);
            _prefillCost(selectedAsset);
            _prefillHolding(selectedAsset);
            final previousCost = selectedAsset?.totalCost;
            final inputCost = parseCurrencyInput(_costController.text) ?? 0;
            final latestCost = _resolveTotalCost(selectedAsset) ?? previousCost;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedAssetId),
                    initialValue: _selectedAssetId,
                    decoration: InputDecoration(
                      labelText: l10n.assetDropdownLabel,
                    ),
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
                  if (allowIncrement) ...[
                    Text(
                      l10n.updateTypeLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
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
                        selected: {_updateType},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _updateType = newSelection.first;
                            // Arti field nilai & modal ikut berganti (total
                            // vs. penambahan), jadi isinya disiapkan ulang:
                            // mode ubah diisi nilai existing, mode tambah
                            // dikosongkan.
                            _valuePrefilledFor = null;
                            _costPrefilledFor = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppTextField(
                    label: isOverride
                        ? l10n.totalValueFieldLabel
                        : l10n.incrementValueFieldLabel,
                    helperText: isOverride
                        ? l10n.totalValueFieldHelper
                        : l10n.incrementValueFieldHelper,
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    prefixText: 'Rp',
                    validator: validateCurrencyValue,
                    inputFormatters: const [RupiahInputFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),
                  _buildValueSuggestion(selectedAsset),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: isOverride
                        ? l10n.commonTotalCostOptionalLabel
                        : l10n.incrementCostFieldLabel,
                    helperText: isOverride
                        ? l10n.totalCostFieldHelper
                        : l10n.incrementCostFieldHelper,
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    prefixText: 'Rp',
                    validator: validateOptionalCurrencyValue,
                    inputFormatters: const [RupiahInputFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.quantityOptionalLabel,
                    helperText: l10n.quantityHelper,
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.avgBuyPriceOptionalLabel,
                    helperText: l10n.avgBuyPriceHelper,
                    controller: _avgBuyPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText:
                        '${selectedAsset?.effectivePriceCurrency ?? 'IDR'} ',
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
                            labelText: l10n.commonRecordedAtLabel,
                            errorText: field.errorText,
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          child: Text(
                            hasValue
                                ? formatFullDate(
                                    selectedDate,
                                    Localizations.localeOf(context),
                                  )
                                : l10n.commonSelectDatePlaceholder,
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
                    label: l10n.noteFieldLabel,
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
                          l10n.previewLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PreviewRow(
                          label: l10n.commonCurrentValueLabel,
                          value: formatCurrency(previousValue),
                        ),
                        if (!isOverride) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _PreviewRow(
                            label: l10n.addedValueLabel,
                            value: '+ ${formatCurrency(inputValue)}',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _PreviewRow(
                          label: l10n.latestValueLabel,
                          value: formatCurrency(latestValue),
                        ),
                        if (latestCost != null) ...[
                          const Divider(height: AppSpacing.xl),
                          _PreviewRow(
                            label: l10n.currentCostLabel,
                            value: previousCost == null
                                ? '-'
                                : formatCurrency(previousCost),
                          ),
                          if (!isOverride) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _PreviewRow(
                              label: l10n.addedCostLabel,
                              value: '+ ${formatCurrency(inputCost)}',
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          _PreviewRow(
                            label: l10n.latestCostLabel,
                            value: formatCurrency(latestCost),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _PreviewRow(
                            label: profitLossLabel(
                              context,
                              latestValue - latestCost,
                            ),
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
                    label: l10n.commonSave,
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
      ),
    );
  }

  /// Saran nilai total = jumlah lembar × harga terkini, dikonversi ke IDR.
  /// Muncul bila aset punya jumlah unit dan simbol pasar. Harga non-IDR
  /// (mis. SPY/BTC dalam USD) dikonversi via kurs Yahoo `{cur}IDR=X`; nilai
  /// portofolio selalu disimpan IDR.
  ///
  /// Saham IDX (simbol `.JK`) dicatat dalam lot, sedangkan harga Yahoo per
  /// lembar; 1 lot = 100 lembar, jadi jumlah lot dikali 100 dulu.
  Widget _buildValueSuggestion(Asset? asset) {
    final symbol = asset?.marketSymbol;
    final quantity = asset?.quantity;
    if (asset == null || symbol == null || quantity == null || quantity <= 0) {
      return const SizedBox.shrink();
    }

    // Jumlah unit efektif dalam satuan harga (lembar untuk saham IDX).
    final shares = quantity * _lotToShareFactor(symbol);

    return ref
        .watch(marketQuoteProvider(symbol))
        .maybeWhen(
          data: (result) {
            final quote = result.quote;
            final nativeTotal = shares * quote.price;
            if (quote.currency == 'IDR') {
              return _valueSuggestionCard(
                quote: quote,
                units: shares,
                suggestedIdr: nativeTotal,
                rate: null,
              );
            }
            return ref
                .watch(fxRateToIdrProvider(quote.currency))
                .maybeWhen(
                  data: (rate) => _valueSuggestionCard(
                    quote: quote,
                    units: shares,
                    suggestedIdr: nativeTotal * rate,
                    rate: rate,
                  ),
                  orElse: () => const SizedBox.shrink(),
                );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }

  /// 1 lot = 100 lembar untuk saham IDX (`.JK`); aset lain 1:1.
  double _lotToShareFactor(String symbol) =>
      symbol.toUpperCase().endsWith('.JK') ? 100 : 1;

  Widget _valueSuggestionCard({
    required MarketQuote quote,
    required double units,
    required double suggestedIdr,
    required double? rate,
  }) {
    final l10n = context.l10n;
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(
                l10n.valueSuggestionChip(formatCurrency(suggestedIdr)),
              ),
              onPressed: () => _applyValueSuggestion(suggestedIdr),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.valueSuggestionDetail(
              formatQuantity(units),
              formatPrice(quote.price, quote.currency),
            ),
            style: captionStyle,
          ),
          if (rate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.valueSuggestionFxDetail(
                quote.currency,
                formatCurrency(rate),
              ),
              style: captionStyle,
            ),
          ],
        ],
      ),
    );
  }

  void _applyValueSuggestion(double value) {
    setState(() {
      _updateType = AssetValueUpdateType.override;
      _valueController.text = formatNumber(value);
    });
  }

  /// Siapkan field nilai sekali per pergantian aset atau mode: mode ubah
  /// diisi nilai saat ini (semua field berisi existing), mode tambah
  /// dikosongkan (nominal yang ditambahkan).
  void _prefillValue(Asset? asset) {
    if (asset == null || asset.id == _valuePrefilledFor) {
      return;
    }
    _valuePrefilledFor = asset.id;
    _valueController.text =
        _resolveUpdateType(asset) == AssetValueUpdateType.increment
        ? ''
        : formatNumber(asset.currentValue);
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
        cost == null ||
            _resolveUpdateType(asset) == AssetValueUpdateType.increment
        ? ''
        : formatCurrency(cost).replaceFirst('Rp', '');
  }

  /// Isi field jumlah unit, harga avg, dan mata uang sekali per pergantian
  /// aset, dari nilai tersimpan aset itu.
  void _prefillHolding(Asset? asset) {
    if (asset == null || asset.id == _holdingPrefilledFor) {
      return;
    }
    _holdingPrefilledFor = asset.id;
    final quantity = asset.quantity;
    _quantityController.text = quantity == null
        ? ''
        : _formatDecimalInput(quantity);
    final avgBuyPrice = asset.avgBuyPrice;
    _avgBuyPriceController.text = avgBuyPrice == null
        ? ''
        : _formatDecimalInput(avgBuyPrice);
  }

  /// Parse input desimal bebas (unit / harga per unit); `null` bila kosong.
  double? _parseDecimalInput(String text) {
    final cleaned = text.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  String _formatDecimalInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  /// Modal baru yang dikirim ke repository; `null` berarti modal tidak
  /// berubah (repository membawa modal terakhir).
  double? _resolveTotalCost(Asset? asset) {
    final inputCost = parseCurrencyInput(_costController.text);
    if (_resolveUpdateType(asset) == AssetValueUpdateType.override) {
      return inputCost;
    }
    if (asset == null || inputCost == null || inputCost == 0) {
      return null;
    }
    // Aset tanpa modal dianggap modalnya sama dengan nilainya sekarang,
    // supaya setoran baru tidak terbaca sebagai seluruh modal.
    return (asset.totalCost ?? asset.currentValue) + inputCost;
  }

  /// Hanya kas yang boleh mode tambah; aset lain selalu timpa.
  bool _allowsIncrement(Asset? asset) => asset?.category == AssetCategory.cash;

  /// Mode efektif: pilihan pengguna dihormati hanya untuk kas, selain itu
  /// dipaksa timpa (override).
  AssetValueUpdateType _resolveUpdateType(Asset? asset) =>
      _allowsIncrement(asset) ? _updateType : AssetValueUpdateType.override;

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

    final effectiveTotal =
        _resolveUpdateType(selectedAsset) == AssetValueUpdateType.override
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
            quantity: _parseDecimalInput(_quantityController.text),
            avgBuyPrice: _parseDecimalInput(_avgBuyPriceController.text),
          );

      if (!mounted) {
        return;
      }

      final l10n = context.l10n;
      final assetName = selectedAsset?.name ?? l10n.commonAsset;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.assetValueUpdatedMessage(assetName)),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final l10n = context.l10n;
      final message = switch (error) {
        InvalidCurrentValueException() => l10n.invalidCurrentValueMessage,
        InvalidTotalCostException() => l10n.invalidTotalCostMessage,
        ArgumentError() => error.message.toString(),
        _ => l10n.updateAssetValueFailedMessage,
      };
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
