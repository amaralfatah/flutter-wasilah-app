class InvalidCurrentValueException implements Exception {
  const InvalidCurrentValueException();
}

class InvalidTotalCostException implements Exception {
  const InvalidTotalCostException();
}

class InvalidTargetPercentageException implements Exception {
  const InvalidTargetPercentageException();
}

class TargetPercentageExceededException implements Exception {
  const TargetPercentageExceededException();
}

class GoogleNotConnectedException implements Exception {
  const GoogleNotConnectedException();
}

class GoogleAuthorizationRequiredException implements Exception {
  const GoogleAuthorizationRequiredException();
}

class InvalidBackupFileException implements Exception {
  const InvalidBackupFileException();
}

class GoogleConnectFailedException implements Exception {
  const GoogleConnectFailedException();
}

class BackupFailedException implements Exception {
  const BackupFailedException();
}

class MarketSymbolNotFoundException implements Exception {
  const MarketSymbolNotFoundException();
}

class MarketDataUnavailableException implements Exception {
  const MarketDataUnavailableException();
}

/// Dilempar saat menghapus master aset yang masih punya holding portofolio
/// dan/atau histori snapshot (`asset_snapshots`). Aset harus dikeluarkan
/// dari portofolio dulu sebelum bisa dihapus (RESTRICT).
class AssetHasHoldingException implements Exception {
  const AssetHasHoldingException();
}
