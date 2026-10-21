/// Posisi baru setelah satu pembelian dicatat.
typedef PurchaseResult = ({
  double quantity,
  double avgBuyPrice,
  double totalCost,
});

/// Menggabungkan satu pembelian ke posisi yang ada dengan rata-rata
/// tertimbang: avg = (modal lama + [paid]) / jumlah unit baru.
///
/// [paid] adalah total yang benar-benar dibayar (fee sudah termasuk) dalam
/// mata uang harga beli; [rateToIdr] mengubahnya ke IDR untuk modal.
/// [quantity]/[boughtQuantity] dalam satuan holding (lot untuk saham IDX),
/// [avgBuyPrice] per lembar/unit -- [lotFactor] menjembatani keduanya.
///
/// Modal lama diambil dari unit × avg; bila avg kosong, dari [totalCost]
/// (IDR). `null` bila posisi lama tidak cukup lengkap untuk dirata-rata
/// (mis. ada modal tanpa jumlah unit), atau input pembelian tidak positif.
PurchaseResult? applyPurchase({
  required double? quantity,
  required double? avgBuyPrice,
  required double? totalCost,
  required double boughtQuantity,
  required double paid,
  required double rateToIdr,
  double lotFactor = 1,
}) {
  if (boughtQuantity <= 0 || paid <= 0 || rateToIdr <= 0 || lotFactor <= 0) {
    return null;
  }
  final oldQuantity = quantity ?? 0;
  final double oldCost;
  if (oldQuantity <= 0) {
    // Tanpa unit, modal lama tak bisa dibagi ke unit mana pun.
    if ((totalCost ?? 0) > 0) {
      return null;
    }
    oldCost = 0;
  } else if (avgBuyPrice != null) {
    oldCost = oldQuantity * lotFactor * avgBuyPrice;
  } else if (totalCost != null) {
    oldCost = totalCost / rateToIdr;
  } else {
    return null;
  }

  final newQuantity = oldQuantity + boughtQuantity;
  return (
    quantity: newQuantity,
    avgBuyPrice: (oldCost + paid) / (newQuantity * lotFactor),
    totalCost: (totalCost ?? oldCost * rateToIdr) + paid * rateToIdr,
  );
}
