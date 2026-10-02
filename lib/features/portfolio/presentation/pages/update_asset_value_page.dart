import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/value_as_of.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/autofill_button.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/currency_picker.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/money_field.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/recorded_date_field.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/update_type_selector.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/value_preview_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';

export 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/update_type_selector.dart'
    show AssetValueUpdateType;

class UpdateAssetValuePage extends ConsumerStatefulWidget {
  const UpdateAssetValuePage({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<UpdateAssetValuePage> createState() =>
      _UpdateAssetValuePageState();
}

class _UpdateAssetValuePageState extends ConsumerState<UpdateAssetValuePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _avgBuyPriceController = TextEditingController();
  final _costController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  /// Kurs USD manual; kosong berarti memakai kurs pasar (Yahoo).
  final _rateController = TextEditingController();

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
  double? _marketUsdRate;

  /// Tombol autofill modal hanya muncul setelah jumlah unit atau harga beli
  /// diubah; tombol autofill nilai juga setelah modal diubah.
  bool _costAutofillOffered = false;
  bool _valueAutofillOffered = false;

  /// Pengguna sendiri mengosongkan jumlah unit / harga beli yang sebelumnya
  /// terisi; saat simpan, nilai tersimpan ikut dikosongkan (bukan
  /// dipertahankan).
  bool _quantityClearedByUser = false;
  bool _avgBuyPriceClearedByUser = false;

  /// Mata uang harga pasar aset terpilih (mis. `USD` untuk BTC-USD).
  String? _marketQuoteCurrency;

  /// Nilai pasar (IDR) dari jumlah unit × harga terkini; dipakai otomatis
  /// bila field nilai kosong.
  double? _marketValue;

  /// Nilai kas per tanggal catat, dasar mode tambah; `null` selama histori
  /// dimuat atau bukan mode tambah.
  double? _incrementBase;
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
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(assetOverviewProvider);
    final isLoading = ref.watch(updateAssetValueControllerProvider).isLoading;
    final usdRate = ref.watch(fxRateToIdrProvider('USD'));
    _marketUsdRate = usdRate.valueOrNull;
    final l10n = context.l10n;

    // Semua `ref.watch` (quote pasar, kurs, histori) dilakukan di sini, bukan
    // di builder AsyncValueView: watch di builder anak membuat langganan
    // provider autoDispose dibongkar-pasang setiap ketikan.
    final selectedAsset = switch (assetsValue.valueOrNull) {
      final assets? => _findSelectedAsset(assets),
      null => null,
    };
    _prefillHolding(selectedAsset);
    _prefillMoney(selectedAsset);
    _marketValue = _watchMarketValue(selectedAsset);
    _incrementBase = _watchIncrementBase(selectedAsset);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateAssetValueTitle)),
      body: SafeArea(
        child: AsyncValueView(
          value: assetsValue,
          onRetry: () => ref.invalidate(assetOverviewProvider),
          data: (assets) => _buildForm(
            context,
            assets: assets,
            selectedAsset: selectedAsset,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required List<PortfolioPosition> assets,
    required PortfolioPosition? selectedAsset,
    required bool isLoading,
  }) {
    final l10n = context.l10n;

    // Opsi tambah/timpa hanya untuk kas; aset lain selalu timpa.
    final allowIncrement = _allowsIncrement(selectedAsset);
    final isOverride =
        _resolveUpdateType(selectedAsset) == AssetValueUpdateType.override;
    // Kas cukup satu input (nilai); unit, harga beli, dan modal tak relevan.
    final showHoldingFields = !allowIncrement;

    // Mode tambah berpijak pada nilai per tanggal catat, bukan nilai
    // terkini, supaya catatan mundur tidak memakai saldo hari ini.
    final storedValue = selectedAsset?.currentValue ?? 0;
    final previousValue = isOverride
        ? storedValue
        : _incrementBase ?? storedValue;
    final inputValue = _moneyIdr(_valueController, _valueCurrency);
    final latestValue = _resolveTotalValue(selectedAsset) ?? previousValue;
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
            decoration: InputDecoration(labelText: l10n.assetDropdownLabel),
            items: assets
                .map(
                  (asset) => DropdownMenuItem<String>(
                    value: asset.id,
                    child: Text(asset.name),
                  ),
                )
                .toList(),
            validator: (value) => validateSelectedAsset(value, l10n),
            onChanged: (value) {
              setState(() {
                _selectedAssetId = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (allowIncrement) ...[
            UpdateTypeSelector(
              value: _updateType,
              onChanged: (type) {
                setState(() {
                  _updateType = type;
                  // Arti field nilai & modal ikut berganti (total vs.
                  // penambahan), jadi isinya disiapkan ulang: mode ubah
                  // diisi nilai existing, mode tambah dikosongkan.
                  _moneyPrefilledFor = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // Urutan mengikuti rantai hitung: unit × harga beli = modal;
          // unit × harga pasar = nilai. Cukup isi salah satu, sisanya
          // dihitung otomatis bila memungkinkan.
          if (showHoldingFields) ...[
            AppTextField(
              label: l10n.quantityLabel,
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [DecimalInputFormatter()],
              validator: (_) => _validateAtLeastOne(selectedAsset),
              onChanged: (text) => setState(() {
                _quantityClearedByUser = text.trim().isEmpty;
                _offerAutofill();
              }),
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
              onChanged: (text) => setState(() {
                _avgBuyPriceClearedByUser = text.trim().isEmpty;
                _offerAutofill();
              }),
              suffixIcon: CurrencyPicker(
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
              // Nilai tanpa harga pasar mengikuti modal.
              onEdited: () => _valueAutofillOffered = true,
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
            if (_costAutofillOffered)
              _autofillButton(
                controller: _costController,
                currency: _costCurrency,
                idr: _derivedCostIdr(selectedAsset),
                onFilled: () {
                  _costAutofillOffered = false;
                  _valueAutofillOffered = true;
                },
                enabled: !isLoading,
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _moneyField(
            label: !isOverride
                ? l10n.incrementValueFieldLabel
                : _tracksMarket(selectedAsset)
                ? l10n.totalValueOptionalFieldLabel
                : l10n.totalValueFieldLabel,
            controller: _valueController,
            currency: _valueCurrency,
            helperText:
                _marketValueHelper(selectedAsset) ??
                _moneyHelper(
                  _valueController,
                  _valueCurrency,
                  inputValue,
                  isOverride ? latestValue : null,
                ),
            validator: showHoldingFields
                ? (_) => _validateManualValue(selectedAsset)
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
          if (showHoldingFields && _valueAutofillOffered)
            _autofillButton(
              controller: _valueController,
              currency: _valueCurrency,
              // Nilai pasar (unit × harga terkini) bila ada; tanpa harga
              // pasar nilai mengikuti modal.
              idr: _marketValue ?? _resolveTotalCost(selectedAsset),
              onFilled: () => _valueAutofillOffered = false,
              enabled: !isLoading,
            ),
          const SizedBox(height: AppSpacing.lg),
          if (_usesUsd) ...[
            AppTextField(
              label: l10n.fxRateFieldLabel('USD'),
              helperText: _rateHelper(),
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [DecimalInputFormatter(maxDecimals: 2)],
              validator: _validateDecimal,
              // Nominal hasil prefill dihitung ulang dengan kurs baru, bukan
              // memakai nilai IDR lamanya.
              onChanged: (_) => setState(_exactIdr.clear),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          RecordedDateField(
            initialValue: _selectedDate,
            enabled: !isLoading,
            onChanged: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.noteFieldLabel,
            controller: _noteController,
            maxLines: 2,
            maxLength: noteMaxLength,
            validator: (value) => validateNote(value, l10n),
          ),
          const SizedBox(height: AppSpacing.lg),
          ValuePreviewCard(
            previousValue: previousValue,
            latestValue: latestValue,
            addedValue: isOverride ? null : inputValue ?? 0,
            previousCost: previousCost,
            latestCost: latestCost,
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
  }

  /// [MoneyField] dengan validasi nominal/kurs dan rebuild saat diketik.
  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required String currency,
    required String? helperText,
    required ValueChanged<String>? onCurrencyChanged,
    String? Function(String?)? validator,
    VoidCallback? onEdited,
  }) {
    return MoneyField(
      label: label,
      controller: controller,
      currency: currency,
      helperText: helperText,
      validator: (value) =>
          _validateMoney(value, currency) ?? validator?.call(value),
      onChanged: (_) => setState(() => onEdited?.call()),
      onCurrencyChanged: onCurrencyChanged,
    );
  }

  /// Tombol autofill di bawah field nominal untuk mengisinya dengan [idr].
  /// Disembunyikan bila field masih kosong (helper "Otomatis" sudah
  /// menampilkan nilai yang akan dipakai), [idr] belum bisa dihitung, atau
  /// sudah sama dengan isi field.
  Widget _autofillButton({
    required TextEditingController controller,
    required String currency,
    required double? idr,
    required VoidCallback onFilled,
    required bool enabled,
  }) {
    final rate = _rateOf(currency);
    final current = _moneyIdr(controller, currency);
    if (_isBlank(controller) ||
        idr == null ||
        rate == null ||
        (current != null && (current - idr).abs() < 0.5)) {
      return const SizedBox.shrink();
    }
    // Nominal ber-USD ditampilkan dolar sekaligus rupiahnya
    // (`$1,000.00 · Rp16.000.000`).
    final amount = currency == 'IDR'
        ? formatCurrency(idr)
        : '${formatPrice(idr / rate, currency)} · ${formatCurrency(idr)}';
    return AutofillButton(
      amount: amount,
      onPressed: enabled
          ? () => setState(() {
              _setMoney(controller, currency, idr, rate);
              onFilled();
            })
          : null,
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

  String? _rateHelper() {
    if (_rateController.text.trim().isNotEmpty) {
      return null;
    }
    final marketRate = _marketUsdRate;
    return marketRate == null
        ? context.l10n.fxRateManualHint
        : context.l10n.autoValueHelper(formatCurrency(marketRate));
  }

  /// Nilai pasar dari jumlah unit (field) × harga terkini, dikonversi ke
  /// IDR. Harga non-IDR (mis. SPY/BTC dalam USD) dikonversi via kurs Yahoo
  /// `{cur}IDR=X`; nilai portofolio selalu disimpan IDR.
  double? _watchMarketValue(PortfolioPosition? asset) {
    _marketQuoteCurrency = null;
    final symbol = asset?.marketSymbol;
    final quantity = _parseDecimalInput(_quantityController.text);
    // Harga Yahoo adalah harga hari ini: tidak berlaku untuk histori bulan
    // lain.
    if (symbol == null ||
        quantity == null ||
        quantity <= 0 ||
        !_isCurrentMonth) {
      return null;
    }
    final quote = ref.watch(marketQuoteProvider(symbol)).valueOrNull?.quote;
    if (quote == null) {
      return null;
    }
    _marketQuoteCurrency = quote.currency.toUpperCase();
    final rate = _marketQuoteCurrency == 'USD'
        ? _rateOf('USD')
        : ref.watch(fxRateToIdrProvider(quote.currency)).valueOrNull;
    if (rate == null) {
      return null;
    }
    return marketValueIdr(
      quantity: quantity,
      symbol: symbol,
      price: quote.price,
      rateToIdr: rate,
    );
  }

  /// Nilai kas per tanggal catat untuk mode tambah (lihat [valueAsOf]);
  /// `null` bila bukan mode tambah atau histori belum dimuat.
  double? _watchIncrementBase(PortfolioPosition? asset) {
    if (asset == null ||
        _resolveUpdateType(asset) != AssetValueUpdateType.increment) {
      return null;
    }
    final history = ref.watch(assetHistoryProvider(asset.id)).valueOrNull;
    if (history == null) {
      return null;
    }
    // Tanpa histori sama sekali (aset baru), nilai tersimpan yang dipakai.
    if (history.isEmpty) {
      return asset.currentValue;
    }
    return valueAsOf(history, _selectedDate ?? DateTime.now());
  }

  /// Aset yang nilainya mengikuti harga pasar (lihat `tracksMarketPrice`):
  /// field nilai opsional, kosong berarti memakai nilai pasar.
  bool _tracksMarket(PortfolioPosition? asset) =>
      asset != null &&
      asset.marketSymbol != null &&
      tracksMarketPrice(asset.category);

  /// Tanggal catat ada di bulan berjalan, satu-satunya bulan yang nilainya
  /// boleh diambil dari harga pasar.
  bool get _isCurrentMonth {
    final date = _selectedDate;
    final now = DateTime.now();
    return date == null || (date.year == now.year && date.month == now.month);
  }

  /// Aset pasar yang dicatat untuk bulan lain: nilai wajib diisi manual,
  /// karena harga pasar maupun nilai tercatat terkini bukan nilai bulan itu.
  bool _requiresManualValue(PortfolioPosition? asset) =>
      _tracksMarket(asset) && !_isCurrentMonth;

  /// Helper field nilai kosong untuk aset pasar; `null` berarti pakai helper
  /// umum ([_moneyHelper]).
  String? _marketValueHelper(PortfolioPosition? asset) {
    if (!_tracksMarket(asset) || !_isBlank(_valueController)) {
      return null;
    }
    if (_requiresManualValue(asset)) {
      return context.l10n.manualValueRequiredHelper;
    }
    final marketValue = _marketValue;
    return marketValue == null
        ? null
        : context.l10n.autoMarketValueHelper(formatCurrency(marketValue));
  }

  String? _validateManualValue(PortfolioPosition? asset) =>
      _requiresManualValue(asset) && _isBlank(_valueController)
      ? context.l10n.manualValueRequiredMessage
      : null;

  double? _rateOf(String currency) =>
      currency == 'IDR' ? 1 : _manualUsdRate ?? _marketUsdRate;

  double? get _manualUsdRate {
    final rate = _parseDecimalInput(_rateController.text);
    return rate == null || rate <= 0 ? null : rate;
  }

  /// Kurs USD ikut menentukan hasil bila salah satu field nominal dalam USD
  /// atau nilai pasar dihitung dari harga ber-USD.
  bool get _usesUsd =>
      _avgCurrency == 'USD' ||
      _costCurrency == 'USD' ||
      _valueCurrency == 'USD' ||
      _marketQuoteCurrency == 'USD';

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
    _costAutofillOffered = false;
    _valueAutofillOffered = false;
    _quantityClearedByUser = false;
    _avgBuyPriceClearedByUser = false;
    final currency =
        updateValueCurrencies.contains(asset.effectivePriceCurrency)
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
    // Aset pasar: field nilai dibiarkan kosong supaya nilai pasar terkini
    // yang tersimpan, bukan nilai tercatat lama.
    if (_tracksMarket(asset)) {
      _valueController.clear();
    } else {
      _setMoney(
        _valueController,
        _valueCurrency,
        asset.currentValue,
        valueRate,
      );
    }
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
        lotToShareFactor(asset?.marketSymbol) *
        avgBuyPrice *
        rate;
  }

  /// Jumlah unit atau harga beli diubah: modal & nilai yang dihitung darinya
  /// ditawarkan lewat tombol autofill.
  void _offerAutofill() {
    _costAutofillOffered = true;
    _valueAutofillOffered = true;
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

  /// Nilai total baru dalam IDR. Mode tambah: nilai per tanggal catat +
  /// penambahan. Bila field nilai kosong, dipakai (urut):
  /// nilai pasar, nilai tersimpan, lalu modal -- kecuali aset pasar yang
  /// dicatat untuk bulan lain, yang wajib diisi. `null` bila tak bisa
  /// dihitung.
  double? _resolveTotalValue(PortfolioPosition? asset) {
    final inputValue = _moneyIdr(_valueController, _valueCurrency);
    if (_resolveUpdateType(asset) == AssetValueUpdateType.increment) {
      final base = _incrementBase;
      return base == null ? null : base + (inputValue ?? 0);
    }
    if (inputValue != null || _requiresManualValue(asset)) {
      return inputValue;
    }
    return _marketValue ??
        (asset != null && _isHeld(asset) ? asset.currentValue : null) ??
        _resolveTotalCost(asset);
  }

  bool _isBlank(TextEditingController controller) =>
      controller.text.trim().isEmpty;

  /// Minimal satu dari jumlah unit, harga beli, modal, atau nilai terisi;
  /// untuk kas, nilai wajib diisi.
  String? _validateAtLeastOne(PortfolioPosition? asset) {
    if (_allowsIncrement(asset)) {
      return validateCurrencyValue(_valueController.text, context.l10n);
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
    // Hanya mengosongkan yang memang tersimpan dan dikosongkan pengguna;
    // field kosong sejak awal berarti "tidak diubah".
    final clearQuantity =
        !isCash &&
        _quantityClearedByUser &&
        selectedAsset?.quantity != null &&
        _isBlank(_quantityController);
    final clearAvgBuyPrice =
        !isCash &&
        _avgBuyPriceClearedByUser &&
        selectedAsset?.avgBuyPrice != null &&
        _isBlank(_avgBuyPriceController);

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
            clearQuantity: clearQuantity,
            clearAvgBuyPrice: clearAvgBuyPrice,
            // Kas tak punya harga beli; mata uang nilainya yang disimpan
            // supaya kas USD (mis. saldo Gotrade) tetap USD saat dibuka lagi.
            priceCurrency: isCash ? _valueCurrency : _avgCurrency,
            fxCurrency: _usesUsd ? 'USD' : null,
            fxRate: _usesUsd ? _rateOf('USD') : null,
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
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        InvalidCurrentValueException() => l10n.invalidCurrentValueMessage,
        InvalidTotalCostException() => l10n.invalidTotalCostMessage,
        ValidationException(:final failure) => validationMessage(
          l10n,
          failure,
        ),
        _ => l10n.updateAssetValueFailedMessage,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
