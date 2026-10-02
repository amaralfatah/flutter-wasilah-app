import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

/// Panjang maksimum catatan update nilai.
const noteMaxLength = 200;

/// Jenis kegagalan validasi. Lapisan non-UI (controller) melempar
/// [ValidationException] berisi kode ini; UI menerjemahkannya lewat
/// [validationMessage] supaya pesan mengikuti bahasa aplikasi.
enum ValidationFailure {
  valueRequired,
  valueInvalid,
  valueNegative,
  assetRequired,
  dateRequired,
  noteTooLong,
  assetNameRequired,
  assetCodeRequired,
}

class ValidationException implements Exception {
  const ValidationException(this.failure);

  final ValidationFailure failure;

  @override
  String toString() => 'ValidationException(${failure.name})';
}

String validationMessage(
  AppLocalizations l10n,
  ValidationFailure failure, {
  int maxLength = noteMaxLength,
}) => switch (failure) {
  ValidationFailure.valueRequired => l10n.valueRequiredMessage,
  ValidationFailure.valueInvalid => l10n.valueInvalidMessage,
  ValidationFailure.valueNegative => l10n.valueNegativeMessage,
  ValidationFailure.assetRequired => l10n.assetRequiredMessage,
  ValidationFailure.dateRequired => l10n.dateRequiredMessage,
  ValidationFailure.noteTooLong => l10n.noteTooLongMessage(maxLength),
  ValidationFailure.assetNameRequired => l10n.assetNameRequired,
  ValidationFailure.assetCodeRequired => l10n.assetCodeRequired,
};

// ------------------------- Pemeriksaan (tanpa l10n) -------------------------

bool isBlank(String? value) => value == null || value.trim().isEmpty;

ValidationFailure? checkCurrencyValue(String? value) {
  if (isBlank(value)) {
    return ValidationFailure.valueRequired;
  }

  final parsed = parseCurrencyInput(value!);
  if (parsed == null) {
    return ValidationFailure.valueInvalid;
  }

  if (parsed < 0) {
    return ValidationFailure.valueNegative;
  }

  return null;
}

ValidationFailure? checkSelectedAsset(String? assetId) =>
    assetId == null || assetId.isEmpty ? ValidationFailure.assetRequired : null;

ValidationFailure? checkSelectedDate(DateTime? date) =>
    date == null ? ValidationFailure.dateRequired : null;

ValidationFailure? checkNote(String? value, {int maxLength = noteMaxLength}) =>
    value != null && value.length > maxLength
    ? ValidationFailure.noteTooLong
    : null;

// --------------------------- Validator form (l10n) ---------------------------

String? validateRequiredText(
  String? value, {
  required String message,
}) {
  if (isBlank(value)) {
    return message;
  }

  return null;
}

String? validateCurrencyValue(String? value, AppLocalizations l10n) =>
    _localize(l10n, checkCurrencyValue(value));

/// Seperti [validateCurrencyValue], tetapi boleh dikosongkan.
String? validateOptionalCurrencyValue(String? value, AppLocalizations l10n) {
  if (isBlank(value)) {
    return null;
  }

  return validateCurrencyValue(value, l10n);
}

String? validateSelectedAsset(String? assetId, AppLocalizations l10n) =>
    _localize(l10n, checkSelectedAsset(assetId));

String? validateSelectedDate(DateTime? date, AppLocalizations l10n) =>
    _localize(l10n, checkSelectedDate(date));

String? validateNote(
  String? value,
  AppLocalizations l10n, {
  int maxLength = noteMaxLength,
}) => switch (checkNote(value, maxLength: maxLength)) {
  final failure? => validationMessage(l10n, failure, maxLength: maxLength),
  null => null,
};

String? _localize(AppLocalizations l10n, ValidationFailure? failure) =>
    failure == null ? null : validationMessage(l10n, failure);

// ------------------------------ Parsing rupiah ------------------------------

/// Digit bagian bulat dari input rupiah. Rupiah tidak berdesimal, jadi semua
/// mulai koma desimal (format Indonesia, `1.500.000,50`) dibuang; titik
/// pemisah ribuan, prefiks `Rp`, dan karakter non-digit lain diabaikan.
String rupiahDigits(String input) {
  final commaIndex = input.indexOf(',');
  final integerPart = commaIndex < 0 ? input : input.substring(0, commaIndex);
  return integerPart.replaceAll(RegExp('[^0-9]'), '');
}

double? parseCurrencyInput(String input) {
  final digits = rupiahDigits(input);
  if (digits.isEmpty) {
    return null;
  }

  return double.tryParse(digits);
}
