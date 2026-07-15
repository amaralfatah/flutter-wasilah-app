String? validateRequiredText(
  String? value, {
  required String message,
}) {
  if (value == null || value.trim().isEmpty) {
    return message;
  }

  return null;
}

String? validateCurrencyValue(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nilai aset wajib diisi.';
  }

  final parsed = parseCurrencyInput(value);
  if (parsed == null) {
    return 'Nilai aset tidak valid.';
  }

  if (parsed < 0) {
    return 'Nilai aset tidak boleh kurang dari nol.';
  }

  return null;
}

String? validateSelectedAsset(String? assetId) {
  if (assetId == null || assetId.isEmpty) {
    return 'Aset wajib dipilih.';
  }

  return null;
}

String? validateSelectedDate(DateTime? date) {
  if (date == null) {
    return 'Tanggal wajib dipilih.';
  }

  return null;
}

String? validateNote(String? value, {int maxLength = 200}) {
  if (value != null && value.length > maxLength) {
    return 'Catatan maksimal $maxLength karakter.';
  }

  return null;
}

double? parseCurrencyInput(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return null;
  }

  return double.tryParse(digits);
}
