// Menyiapkan aset ikon dari logo sumber.
//
// Logo sumber datang dengan latar solid dan glyph yang tidak tepat di tengah.
// Skrip ini mengekstrak glyph jadi mask transparan, lalu menyusunnya ulang
// pada kanvas 1024x1024 dengan ukuran dan posisi yang terukur:
//
//   icon.png            latar biru, glyph putih  -> ikon iOS & legacy Android
//   icon_foreground.png transparan, glyph putih  -> adaptive icon Android
//   splash_light.png    transparan, glyph biru   -> splash tema terang
//   splash_dark.png     transparan, glyph putih  -> splash tema gelap
//
// Jalankan: dart run tool/prepare_icons.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const canvas = 1024;
final brandBlue = ColorRgb8(0x0B, 0x57, 0xD0);

/// Sisi terpanjang glyph pada ikon berlatar, relatif terhadap kanvas.
/// 62% mengisi bidang dengan mantap tanpa terasa sesak.
const filledGlyphRatio = 0.62;

/// Adaptive icon Android memotong dengan mask; zona amannya lingkaran
/// berdiameter 66/108 = 61,1% kanvas. Yang dibatasi harus lingkaran
/// pembatas glyph, bukan kotaknya — ujung kaki yang melebar ke bawah
/// justru titik terjauh dari pusat.
///
/// flutter_launcher_icons membungkus foreground dengan `inset="16%"`,
/// sehingga berkas ini hanya menempati 68% kanvas akhir. Karena itu
/// nilainya dibesarkan: 0,84 x 0,68 = 57% kanvas, masih di dalam zona aman.
const adaptiveSafeDiameter = 0.84;

/// Splash Android 12+ memotong logo dengan lingkaran berdiameter
/// 768/1152 = 66,7% kanvas. 58% aman untuk itu sekaligus enak dilihat
/// pada splash gaya lama.
const splashSafeDiameter = 0.58;

/// Bentuknya melebar di kaki dan meruncing di kepala, jadi titik berat
/// optiknya di bawah pusat geometris. Geser naik 2% agar terbaca seimbang.
const opticalLift = 0.02;

void main() {
  final source = decodePng(
    File('assets/icon/logo-wasilah-light.png').readAsBytesSync(),
  )!;
  stdout.writeln('Sumber: ${source.width}x${source.height}');

  final mask = _extractGlyph(source);
  stdout.writeln(
    'Kotak glyph: ${mask.width}x${mask.height} '
    '(${(mask.width / source.width * 100).toStringAsFixed(1)}% x '
    '${(mask.height / source.height * 100).toStringAsFixed(1)}% dari sumber)',
  );

  _write('assets/icon/icon.png', _compose(mask, filledGlyphRatio,
      glyph: ColorRgb8(255, 255, 255), background: brandBlue));
  _write(
    'assets/icon/icon_foreground.png',
    _composeWithinCircle(mask, adaptiveSafeDiameter,
        glyph: ColorRgb8(255, 255, 255)),
  );
  _write(
    'assets/icon/splash_light.png',
    _composeWithinCircle(mask, splashSafeDiameter, glyph: brandBlue),
  );
  _write(
    'assets/icon/splash_dark.png',
    _composeWithinCircle(mask, splashSafeDiameter,
        glyph: ColorRgb8(255, 255, 255)),
  );
}

/// Memotong glyph dari latar solid dan mengembalikannya sebagai mask
/// beralpha, sudah dipangkas tepat pada batas bentuknya.
Image _extractGlyph(Image source) {
  final background = source.getPixel(2, 2);
  var minX = source.width;
  var minY = source.height;
  var maxX = -1;
  var maxY = -1;

  final mask = Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      // Jarak ke warna latar dipakai langsung sebagai alpha, sehingga tepi
      // anti-alias ikut terbawa dan bentuknya tidak bergerigi.
      final distance = _distance(pixel, background);
      final alpha = (distance * 255).round().clamp(0, 255);
      mask.setPixelRgba(x, y, 255, 255, 255, alpha);

      if (alpha > 128) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < 0) {
    throw StateError('Glyph tidak ditemukan: seluruh gambar sewarna latar.');
  }

  return copyCrop(
    mask,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

double _distance(Pixel a, Color b) {
  final dr = (a.r - b.r) / 255.0;
  final dg = (a.g - b.g) / 255.0;
  final db = (a.b - b.b) / 255.0;
  final d = (dr.abs() + dg.abs() + db.abs()) / 3 * 2;
  return d > 1 ? 1 : d;
}

/// Seperti [_compose], tapi yang dijamin adalah lingkaran pembatas glyph
/// tidak melebihi [diameter] — ukurannya dicari lewat iterasi karena
/// jarak terjauh piksel dari pusat bergantung bentuk, bukan kotaknya.
Image _composeWithinCircle(
  Image mask,
  double diameter, {
  required Color glyph,
  Color? background,
}) {
  var ratio = diameter;
  late Image result;

  for (var attempt = 0; attempt < 8; attempt++) {
    result = _compose(mask, ratio, glyph: glyph, background: background);
    final actual = _maxRadius(result) * 2;
    if (actual <= diameter) {
      return result;
    }
    ratio *= diameter / actual;
  }

  return result;
}

/// Jarak terjauh piksel tampak dari pusat kanvas, relatif lebar kanvas.
double _maxRadius(Image image) {
  final centerX = image.width / 2;
  final centerY = image.height / 2;
  var maxSquared = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a <= 128) continue;
      final dx = x - centerX;
      final dy = y - centerY;
      final squared = dx * dx + dy * dy;
      if (squared > maxSquared) maxSquared = squared;
    }
  }

  return math.sqrt(maxSquared) / image.width;
}

/// Menempatkan [mask] di tengah kanvas 1024x1024 dengan sisi terpanjang
/// sebesar [ratio] dari kanvas, diwarnai [glyph] di atas [background].
Image _compose(
  Image mask,
  double ratio, {
  required Color glyph,
  Color? background,
}) {
  final target = (canvas * ratio).round();
  final scale = target / (mask.width > mask.height ? mask.width : mask.height);
  final scaled = copyResize(
    mask,
    width: (mask.width * scale).round(),
    height: (mask.height * scale).round(),
    interpolation: Interpolation.cubic,
  );

  final out = Image(width: canvas, height: canvas, numChannels: 4);
  if (background != null) {
    fill(out, color: background);
  }

  final left = ((canvas - scaled.width) / 2).round();
  final top = ((canvas - scaled.height) / 2 - canvas * opticalLift).round();

  for (var y = 0; y < scaled.height; y++) {
    for (var x = 0; x < scaled.width; x++) {
      final alpha = scaled.getPixel(x, y).a / 255.0;
      if (alpha <= 0) continue;

      final dx = left + x;
      final dy = top + y;
      if (dx < 0 || dy < 0 || dx >= canvas || dy >= canvas) continue;

      final under = out.getPixel(dx, dy);
      final underAlpha = under.a / 255.0;
      final outAlpha = alpha + underAlpha * (1 - alpha);
      out.setPixelRgba(
        dx,
        dy,
        _mix(glyph.r, under.r, alpha, underAlpha, outAlpha),
        _mix(glyph.g, under.g, alpha, underAlpha, outAlpha),
        _mix(glyph.b, under.b, alpha, underAlpha, outAlpha),
        (outAlpha * 255).round(),
      );
    }
  }

  return out;
}

int _mix(num top, num bottom, double topA, double bottomA, double outA) {
  if (outA <= 0) return 0;
  return ((top * topA + bottom * bottomA * (1 - topA)) / outA).round().clamp(
    0,
    255,
  );
}

void _write(String path, Image image) {
  File(path).writeAsBytesSync(encodePng(image));

  // Verifikasi: posisi dan ukuran glyph diukur ulang dari berkas hasil,
  // bukan diasumsikan dari parameter.
  final decoded = decodePng(File(path).readAsBytesSync())!;
  final background = decoded.getPixel(0, 0);
  final transparent = background.a < 8;

  var minX = decoded.width;
  var minY = decoded.height;
  var maxX = -1;
  var maxY = -1;
  var maxRadiusSquared = 0.0;
  final centerX = decoded.width / 2;
  final centerY = decoded.height / 2;

  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      final visible = transparent
          ? pixel.a > 128
          : _distance(pixel, background) > 0.5;
      if (!visible) continue;

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;

      final dx = x - centerX;
      final dy = y - centerY;
      final radiusSquared = dx * dx + dy * dy;
      if (radiusSquared > maxRadiusSquared) maxRadiusSquared = radiusSquared;
    }
  }

  final w = (maxX - minX + 1) / decoded.width;
  final h = (maxY - minY + 1) / decoded.height;
  final cx = (minX + maxX) / 2 / decoded.width;
  final cy = (minY + maxY) / 2 / decoded.height;
  // Lingkaran terkecil berpusat di tengah kanvas yang memuat seluruh glyph.
  // Inilah yang harus muat di zona aman, bukan kotak pembatasnya.
  final diameter = math.sqrt(maxRadiusSquared) * 2 / decoded.width;

  stdout.writeln(
    '  ditulis $path\n'
    '    ${decoded.width}x${decoded.height}, '
    'latar ${transparent ? 'transparan' : 'solid'}\n'
    '    glyph ${(w * 100).toStringAsFixed(1)}% x '
    '${(h * 100).toStringAsFixed(1)}%, '
    'lingkaran pembatas ${(diameter * 100).toStringAsFixed(1)}%\n'
    '    pusat ${(cx * 100).toStringAsFixed(1)}% / '
    '${(cy * 100).toStringAsFixed(1)}%',
  );
}
