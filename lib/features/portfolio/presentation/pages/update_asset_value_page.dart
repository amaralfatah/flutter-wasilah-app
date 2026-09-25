import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
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
  static const _currencies = ['IDR', 'USD'];

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _avgBuyPriceController = TextEditingController();
  final _costController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  /// Nilai IDR persis untuk teks yang diisi program (prefill/konversi mata
  /// uang). Selama teksnya tidak disentuh, nilai asli dipakai supaya tidak
  /// bergeser akibat pembulatan kurs bolak-balik.
  final _exactIdr = <TextEditingController, (String, double)>{};

  DateTime? _selectedDate;
  String? _holdingPrefilledFor;
  String? _moneyPrefilledFor;
  String? _selectedAssetId;
  String _avgCurrency = 'IDR';
  String _costCurrency = 'IDR';
  String _valueCurrency = 'IDR';
  double? _usdRate;

  /// Nilai pasar (IDR) dari jumlah unit × harga terkini; dipakai otomatis
  /// bila field nilai kosong.
  double? _marketValue;
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
    _quantityController.dispose();
    _avgBuyPriceController.dispose();
    _costController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(assetOverviewProvider);
    final submitState = ref.watch(updateAssetValueControllerProvider);
    final usdRate = ref.watch(fxRateToIdrProvider('USD'));
    _usdRate = usdRate.valueOrNull;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateAssetValueTitle)),
      body: SafeArea(
        child: AsyncValueView(
          value: assetsValue,
          onRetry: () => ref.invalidate(assetOverviewProvider),
          data: (assets) {
            final selectedAsset = _findSelectedAsset(assets);
            _prefillHolding(selectedAsset);
            _prefillMoney(selectedAsset);
            _marketValue = _watchMarketValue(selectedAsset);

            // Opsi tambah/timpa hanya untuk kas; aset lain selalu timpa.
            final allowIncrement = _allowsIncrement(selectedAsset);
            final isOverride =
                _resolveUpdateType(selectedAsset) ==
                AssetValueUpdateType.override;
            // Kas cukup satu input (nilai); unit, harga beli, dan modal
            // tak relevan.
            final showHoldingFields = !allowIncrement;
            final isLoading = submitState.isLoading;

            final previousValue = selectedAsset?.currentValue ?? 0;
            final inputValue = _moneyIdr(_valueController, _valueCurrency);
            final latestValue =
                _resolveTotalValue(selectedAsset) ?? previousValue;
            final previousCost = selectedAsset?.totalCost;
            final latestCost = showHoldingFields
                ? _resolveTotalCost(selectedAsset) ?? previousCost
                : null;

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
                            _moneyPrefilledFor = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  // Urutan mengikuti rantai hitung: unit × harga beli =
                  // modal; unit × harga pasar = nilai. Cukup isi salah satu,
                  // sisanya dihitung otomatis bila memungkinkan.
                  if (showHoldingFields) ...[
                    AppTextField(
                      label: l10n.quantityLabel,
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [DecimalInputFormatter()],
                      validator: (_) => _validateAtLeastOne(selectedAsset),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.avgBuyPriceLabel,
                      controller: _avgBuyPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [DecimalInputFormatter()],
                      validator: _validateDecimal,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: _CurrencyPicker(
                        value: _avgCurrency,
                        onChanged: isLoading ? null : _switchAvgCurrency,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _moneyField(
                      label: l10n.totalCostLabel,
                      controller: _costController,
                      currency: _costCurrency,
                      helperText: _moneyHelper(
                        _costController,
                        _costCurrency,
                        _moneyIdr(_costController, _costCurrency),
                        _derivedCostIdr(selectedAsset),
                      ),
                      onCurrencyChanged: isLoading
                          ? null
                          : (currency) => setState(() {
                              _switchMoneyCurrency(
                                _costController,
                                _costCurrency,
                                currency,
                              );
                              _costCurrency = currency;
                            }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _moneyField(
                    label: isOverride
                        ? l10n.totalValueFieldLabel
                        : l10n.incrementValueFieldLabel,
                    controller: _valueController,
                    currency: _valueCurrency,
                    helperText: _moneyHelper(
                      _valueController,
                      _valueCurrency,
                      inputValue,
                      isOverride ? latestValue : null,
                    ),
                    validator: showHoldingFields
                        ? null
                        : (_) => _validateAtLeastOne(selectedAsset),
                    onCurrencyChanged: isLoading
                        ? null
                        : (currency) => setState(() {
                            _switchMoneyCurrency(
                              _valueController,
                              _valueCurrency,
                              currency,
                            );
                            _valueCurrency = currency;
                          }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FormField<DateTime>(
                    initialValue: _selectedDate,
                    validator: validateSelectedDate,
                    builder: (field) {
                      final selectedDate = field.value;
                      final hasValue = selectedDate != null;

                      return InkWell(
                        onTap: isLoading
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
                            value: '+ ${formatCurrency(inputValue ?? 0)}',
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
                    onPressed: isLoading ? null : () => _submit(selectedAsset),
                    isLoading: isLoading,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Field nominal (modal/nilai) dengan pilihan mata uang inline. IDR diisi
  /// bilangan bulat berpemisah ribuan; mata uang lain boleh 2 desimal.
  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required String currency,
    required String? helperText,
    required ValueChanged<String>? onCurrencyChanged,
    String? Function(String?)? validator,
  }) {
    final isIdr = currency == 'IDR';
    return AppTextField(
      label: label,
      helperText: helperText,
      controller: controller,
      keyboardType: isIdr
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isIdr
          ? const [RupiahInputFormatter()]
          : const [DecimalInputFormatter(maxDecimals: 2)],
      validator: (value) =>
          _validateMoney(value, currency) ?? validator?.call(value),
      onChanged: (_) => setState(() {}),
      suffixIcon: _CurrencyPicker(
        value: currency,
        onChanged: onCurrencyChanged,
      ),
    );
  }

  /// Helper field nominal: bila diisi dalam mata uang asing tampilkan hasil
  /// konversinya; bila kosong tampilkan nilai yang akan dipakai otomatis.
  String? _moneyHelper(
    TextEditingController controller,
    String currency,
    double? inputIdr,
    double? autoIdr,
  ) {
    final l10n = context.l10n;
    if (controller.text.trim().isEmpty) {
      return autoIdr == null
          ? null
          : l10n.autoValueHelper(
              formatCurrency(autoIdr),
            );
    }
    if (currency == 'IDR') {
      return null;
    }
    final rate = _rateOf(currency);
    if (rate == null) {
      return l10n.fxRateUnavailableMessage;
    }
    return l10n.foreignValueHelper(
      inputIdr == null ? '-' : formatCurrency(inputIdr),
      currency,
      formatCurrency(rate),
    );
  }

  /// Nilai pasar dari jumlah unit (field) × harga terkini, dikonversi ke
  /// IDR. Harga non-IDR (mis. SPY/BTC dalam USD) dikonversi via kurs Yahoo
  /// `{cur}IDR=X`; nilai portofolio selalu disimpan IDR.
  double? _watchMarketValue(PortfolioPosition? asset) {
    final symbol = asset?.marketSymbol;
    final quantity = _parseDecimalInput(_quantityController.text);
    if (symbol == null || quantity == null || quantity <= 0) {
      return null;
    }
    final quote = ref.watch(marketQuoteProvider(symbol)).valueOrNull?.quote;
    if (quote == null) {
      return null;
    }
    final rate = ref.watch(fxRateToIdrProvider(quote.currency)).valueOrNull;
    if (rate == null) {
      return null;
    }
    return quantity * _lotToShareFactor(symbol) * quote.price * rate;
  }

  /// Saham IDX (simbol `.JK`) dicatat dalam lot, sedangkan harga per
  /// lembar; 1 lot = 100 lembar. Aset lain 1:1.
  double _lotToShareFactor(String? symbol) =>
      symbol != null && symbol.toUpperCase().endsWith('.JK') ? 100 : 1;

  double? _rateOf(String currency) => currency == 'IDR' ? 1 : _usdRate;

  String _formatMoney(double amount, String currency) => currency == 'IDR'
      ? formatNumber(amount)
      : _formatDecimalInput(amount, decimals: 2);

  double? _parseMoney(String text, String currency) =>
      currency == 'IDR' ? parseCurrencyInput(text) : _parseDecimalInput(text);

  /// Isi field nominal dari nilai IDR dan ingat nilai persisnya.
  void _setMoney(
    TextEditingController controller,
    String currency,
    double idr,
    double rate,
  ) {
    final formatted = _formatMoney(idr / rate, currency);
    controller.text = formatted;
    _exactIdr[controller] = (formatted, idr);
  }

  /// Isi field nominal dalam IDR; `null` bila kosong/tidak valid atau kurs
  /// belum tersedia.
  double? _moneyIdr(TextEditingController controller, String currency) {
    final exact = _exactIdr[controller];
    if (exact != null && exact.$1 == controller.text) {
      return exact.$2;
    }
    final amount = _parseMoney(controller.text, currency);
    final rate = _rateOf(currency);
    if (amount == null || rate == null) {
      return null;
    }
    return amount * rate;
  }

  /// Ganti mata uang field nominal sambil mengonversi isinya.
  void _switchMoneyCurrency(
    TextEditingController controller,
    String from,
    String to,
  ) {
    final idr = _moneyIdr(controller, from);
    final rate = _rateOf(to);
    if (idr == null || rate == null) {
      controller.clear();
      _exactIdr.remove(controller);
      return;
    }
    _setMoney(controller, to, idr, rate);
  }

  void _switchAvgCurrency(String to) {
    setState(() {
      final amount = _parseDecimalInput(_avgBuyPriceController.text);
      final fromRate = _rateOf(_avgCurrency);
      final toRate = _rateOf(to);
      _avgCurrency = to;
      if (amount == null || fromRate == null || toRate == null) {
        _avgBuyPriceController.clear();
        return;
      }
      final converted = amount * fromRate / toRate;
      _avgBuyPriceController.text = _formatDecimalInput(
        converted,
        decimals: 2,
      );
    });
  }

  /// Aset yang sudah ada di portofolio (bukan posisi kosong).
  bool _isHeld(PortfolioPosition asset) =>
      asset.lastUpdatedAt.millisecondsSinceEpoch > 0;

  /// Isi jumlah unit, harga avg, dan mata uang sekali per pergantian aset.
  /// Semua field nominal mengikuti mata uang harga aset (mis. SPY → USD).
  void _prefillHolding(PortfolioPosition? asset) {
    if (asset == null || asset.id == _holdingPrefilledFor) {
      return;
    }
    _holdingPrefilledFor = asset.id;
    _moneyPrefilledFor = null;
    final currency = _currencies.contains(asset.effectivePriceCurrency)
        ? asset.effectivePriceCurrency
        : 'IDR';
    _avgCurrency = currency;
    _costCurrency = currency;
    _valueCurrency = currency;
    final quantity = asset.quantity;
    _quantityController.text = quantity == null
        ? ''
        : _formatDecimalInput(quantity);
    final avgBuyPrice = asset.avgBuyPrice;
    _avgBuyPriceController.text = avgBuyPrice == null
        ? ''
        : _formatDecimalInput(avgBuyPrice);
  }

  /// Isi field nilai & modal sekali per pergantian aset atau mode: mode ubah
  /// diisi nilai tersimpan, mode tambah dan aset baru dikosongkan. Field
  /// non-IDR menunggu kurs dulu karena nilai tersimpan (IDR) perlu
  /// dikonversi.
  void _prefillMoney(PortfolioPosition? asset) {
    if (asset == null) {
      return;
    }
    final key = '${asset.id}/${_resolveUpdateType(asset).name}';
    if (key == _moneyPrefilledFor) {
      return;
    }
    final isIncrement =
        _resolveUpdateType(asset) == AssetValueUpdateType.increment;
    if (isIncrement || !_isHeld(asset)) {
      _moneyPrefilledFor = key;
      _valueController.clear();
      _costController.clear();
      return;
    }
    final valueRate = _rateOf(_valueCurrency);
    final costRate = _rateOf(_costCurrency);
    if (valueRate == null || costRate == null) {
      return;
    }
    _moneyPrefilledFor = key;
    _setMoney(_valueController, _valueCurrency, asset.currentValue, valueRate);
    final cost = asset.totalCost;
    if (cost == null) {
      _costController.clear();
    } else {
      _setMoney(_costController, _costCurrency, cost, costRate);
    }
  }

  double? _parseDecimalInput(String text) => parseDecimalInput(text);

  /// Format angka untuk field desimal, sama dengan hasil
  /// [DecimalInputFormatter] (`1.234,56`).
  String _formatDecimalInput(double value, {int? decimals}) => formatQuantity(
    decimals == null ? value : double.parse(value.toStringAsFixed(decimals)),
  );

  /// Modal dari jumlah unit × harga beli rata-rata, dalam IDR.
  double? _derivedCostIdr(PortfolioPosition? asset) {
    final quantity = _parseDecimalInput(_quantityController.text);
    final avgBuyPrice = _parseDecimalInput(_avgBuyPriceController.text);
    final rate = _rateOf(_avgCurrency);
    if (quantity == null || avgBuyPrice == null || rate == null) {
      return null;
    }
    return quantity *
        _lotToShareFactor(asset?.marketSymbol) *
        avgBuyPrice *
        rate;
  }

  /// Modal baru dari field modal atau unit × harga beli; `null` berarti
  /// modal tidak berubah (repository membawa modal terakhir). Kas tak
  /// punya input modal.
  double? _resolveTotalCost(PortfolioPosition? asset) {
    if (_allowsIncrement(asset)) {
      return null;
    }
    return _moneyIdr(_costController, _costCurrency) ?? _derivedCostIdr(asset);
  }

  /// Nilai total baru dalam IDR. Bila field nilai kosong, dipakai (urut):
  /// nilai pasar, nilai tersimpan, lalu modal. `null` bila tak bisa
  /// dihitung.
  double? _resolveTotalValue(PortfolioPosition? asset) {
    final inputValue = _moneyIdr(_valueController, _valueCurrency);
    if (_resolveUpdateType(asset) == AssetValueUpdateType.increment) {
      return (asset?.currentValue ?? 0) + (inputValue ?? 0);
    }
    return inputValue ??
        _marketValue ??
        (asset != null && _isHeld(asset) ? asset.currentValue : null) ??
        _resolveTotalCost(asset);
  }

  bool _isBlank(TextEditingController controller) =>
      controller.text.trim().isEmpty;

  /// Minimal satu dari jumlah unit, harga beli, modal, atau nilai terisi;
  /// untuk kas, nilai wajib diisi.
  String? _validateAtLeastOne(PortfolioPosition? asset) {
    if (_allowsIncrement(asset)) {
      return validateCurrencyValue(_valueController.text);
    }
    if (_isBlank(_quantityController) &&
        _isBlank(_avgBuyPriceController) &&
        _isBlank(_costController) &&
        _isBlank(_valueController)) {
      return context.l10n.atLeastOneValueMessage;
    }
    return null;
  }

  String? _validateDecimal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return _parseDecimalInput(value) == null
        ? context.l10n.invalidNumberMessage
        : null;
  }

  String? _validateMoney(String? value, String currency) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (_parseMoney(value, currency) == null) {
      return context.l10n.invalidNumberMessage;
    }
    return _rateOf(currency) == null
        ? context.l10n.fxRateUnavailableMessage
        : null;
  }

  /// Hanya kas yang boleh mode tambah; aset lain selalu timpa.
  bool _allowsIncrement(PortfolioPosition? asset) =>
      asset?.category == AssetCategory.cash;

  /// Mode efektif: pilihan pengguna dihormati hanya untuk kas, selain itu
  /// dipaksa timpa (override).
  AssetValueUpdateType _resolveUpdateType(PortfolioPosition? asset) =>
      _allowsIncrement(asset) ? _updateType : AssetValueUpdateType.override;

  PortfolioPosition? _findSelectedAsset(List<PortfolioPosition> assets) {
    for (final asset in assets) {
      if (asset.id == _selectedAssetId) {
        return asset;
      }
    }

    return null;
  }

  Future<void> _submit(PortfolioPosition? selectedAsset) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = context.l10n;
    final selectedAssetId = _selectedAssetId;
    final totalValue = _resolveTotalValue(selectedAsset);
    final selectedDate = _selectedDate;

    if (selectedAssetId == null || selectedDate == null) {
      return;
    }
    if (totalValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.valueUnresolvedMessage)),
      );
      return;
    }

    final isCash = _allowsIncrement(selectedAsset);

    try {
      await ref
          .read(updateAssetValueControllerProvider.notifier)
          .submit(
            assetId: selectedAssetId,
            totalValue: totalValue,
            recordedAt: selectedDate,
            note: _noteController.text,
            // Kas tak untung/rugi: modal selalu mengikuti nilainya supaya
            // kolom modal & untung/rugi di daftar holding tidak kosong.
            totalCost: isCash ? totalValue : _resolveTotalCost(selectedAsset),
            quantity: isCash
                ? null
                : _parseDecimalInput(_quantityController.text),
            avgBuyPrice: isCash
                ? null
                : _parseDecimalInput(_avgBuyPriceController.text),
            // Kas tak punya harga beli; mata uang nilainya yang disimpan
            // supaya kas USD (mis. saldo Gotrade) tetap USD saat dibuka lagi.
            priceCurrency: isCash ? _valueCurrency : _avgCurrency,
          );

      if (!mounted) {
        return;
      }

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

/// Pilihan mata uang inline di ujung field nominal.
class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: _UpdateAssetValuePageState._currencies
              .map(
                (currency) => DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                ),
              )
              .toList(),
          onChanged: onChanged == null
              ? null
              : (currency) {
                  if (currency != null && currency != value) {
                    onChanged!(currency);
                  }
                },
        ),
      ),
    );
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
