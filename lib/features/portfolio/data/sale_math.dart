/// Posisi baru setelah satu penjualan dicatat. Harga rata-rata beli tidak
/// berubah: penjualan hanya mengurangi jumlah unit dan modal secara
/// proporsional.
typedef SaleResult = ({
  double quantity,
  double? totalCost,
  double? realizedProfit,
});

/// Selisih kecil akibat pembulatan desimal (mis. jual semua 0,00085 BTC)
/// tetap dianggap habis, bukan sisa debu.
const _dust = 1e-9;

/// Mengurangi posisi dengan satu penjualan.
///
/// [received] adalah uang yang benar-benar diterima (setelah fee) dalam
/// mata uang harga beli; [rateToIdr] mengubahnya ke IDR. [quantity] dan
/// [soldQuantity] dalam satuan holding (lot untuk saham IDX), [avgBuyPrice]
/// per lembar/unit -- [lotFactor] menjembatani keduanya.
///
/// Modal yang terjual = modal × porsi unit yang dijual; modal diambil dari
/// [totalCost] (IDR), atau unit × avg bila kosong. Tanpa keduanya, jumlah
/// unit tetap dikurangi tetapi modal dan untung/rugi terealisasi `null`.
///
/// `null` bila jumlah unit lama kosong, jumlah yang dijual melebihi yang
/// dimiliki, atau input tidak valid.
SaleResult? applySale({
  required double? quantity,
  required double? avgBuyPrice,
  required double? totalCost,
  required double soldQuantity,
  required double received,
  required double rateToIdr,
  double lotFactor = 1,
}) {
  if (soldQuantity <= 0 || received < 0 || rateToIdr <= 0 || lotFactor <= 0) {
    return null;
  }
  final oldQuantity = quantity ?? 0;
  if (oldQuantity <= 0 || soldQuantity > oldQuantity + _dust) {
    return null;
  }

  var newQuantity = oldQuantity - soldQuantity;
  if (newQuantity < _dust) {
    newQuantity = 0;
  }
  final soldShare = (oldQuantity - newQuantity) / oldQuantity;
  final costIdr =
      totalCost ??
      (avgBuyPrice == null
          ? null
          : oldQuantity * lotFactor * avgBuyPrice * rateToIdr);
  final soldCost = costIdr == null ? null : costIdr * soldShare;

  return (
    quantity: newQuantity,
    totalCost: costIdr == null
        ? null
        : newQuantity == 0
        ? 0
        : costIdr - soldCost!,
    realizedProfit: soldCost == null ? null : received * rateToIdr - soldCost,
  );
}
