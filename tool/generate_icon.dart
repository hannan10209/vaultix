import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Background gradient: #1A0533 to #3D1073 (top to bottom)
  const r1 = 0x1A, g1 = 0x05, b1 = 0x33;
  const r2 = 0x3D, g2 = 0x10, b2 = 0x73;
  for (int y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (r1 + (r2 - r1) * t).round();
    final g = (g1 + (g2 - g1) * t).round();
    final b = (b1 + (b2 - b1) * t).round();
    final color = img.ColorRgba8(r, g, b, 255);
    for (int x = 0; x < size; x++) {
      image.setPixel(x, y, color);
    }
  }

  // Lock body: rounded rectangle, centered
  const bodyW = 380, bodyH = 300, bodyR = 40;
  const bodyLeft = (size - bodyW) ~/ 2; // 322
  const bodyTop = size ~/ 2 - 20; // 492
  _drawRoundedRect(image, bodyLeft, bodyTop, bodyW, bodyH, bodyR,
      img.ColorRgba8(255, 255, 255, 255));

  // Shackle: thick arc at the top
  const shackleOx = size / 2; // 512
  final shackleOy = bodyTop.toDouble(); // top of body
  const shackleRx = 110.0;
  const shackleRy = 140.0;
  const strokeWidth = 55;

  // Draw shackle as filled difference of two ellipses (top half)
  for (int y = (shackleOy - shackleRy - strokeWidth).toInt();
      y <= shackleOy.toInt();
      y++) {
    for (int x = (shackleOx - shackleRx - strokeWidth).toInt();
        x <= (shackleOx + shackleRx + strokeWidth).toInt();
        x++) {
      if (x < 0 || x >= size || y < 0 || y >= size) continue;
      final dx = (x - shackleOx);
      final dy = (y - shackleOy);
      // outer ellipse
      final outerVal = (dx * dx) / ((shackleRx + strokeWidth / 2) * (shackleRx + strokeWidth / 2)) +
          (dy * dy) / ((shackleRy + strokeWidth / 2) * (shackleRy + strokeWidth / 2));
      // inner ellipse
      final innerVal = (dx * dx) / ((shackleRx - strokeWidth / 2) * (shackleRx - strokeWidth / 2)) +
          (dy * dy) / ((shackleRy - strokeWidth / 2) * (shackleRy - strokeWidth / 2));
      if (outerVal <= 1.0 && innerVal >= 1.0 && y <= shackleOy) {
        image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
      }
    }
  }

  // Keyhole: circle + slot, color matches gradient at that Y
  const keyholeR = 40;
  final keyholeCx = size ~/ 2;
  final keyholeCy = bodyTop + bodyH ~/ 2 - 20;

  // Get background color at keyhole center for the cutout
  final khR = (0x1A + ((0x3D - 0x1A) * 0.55)).toInt();
  final khG = (0x05 + ((0x10 - 0x05) * 0.55)).toInt();
  final khB = (0x33 + ((0x73 - 0x33) * 0.55)).toInt();
  final keyholeColor = img.ColorRgba8(khR, khG, khB, 255);

  // Keyhole circle
  for (int y = keyholeCy - keyholeR; y <= keyholeCy + keyholeR; y++) {
    for (int x = keyholeCx - keyholeR; x <= keyholeCx + keyholeR; x++) {
      if (x < 0 || x >= size || y < 0 || y >= size) continue;
      final dx = x - keyholeCx;
      final dy = y - keyholeCy;
      if (dx * dx + dy * dy <= keyholeR * keyholeR) {
        image.setPixel(x, y, keyholeColor);
      }
    }
  }

  // Keyhole slot
  const slotW = 24, slotH = 70;
  for (int y = keyholeCy + keyholeR - 10;
      y <= keyholeCy + keyholeR - 10 + slotH;
      y++) {
    for (int x = keyholeCx - slotW ~/ 2; x <= keyholeCx + slotW ~/ 2; x++) {
      if (x < 0 || x >= size || y < 0 || y >= size) continue;
      image.setPixel(x, y, keyholeColor);
    }
  }

  final pngBytes = img.encodePng(image);
  final outputFile = File('assets/icon/vaultix_icon.png');
  outputFile.writeAsBytesSync(pngBytes);
  print('Icon generated: ${outputFile.path} (${pngBytes.length} bytes)');
}

void _drawRoundedRect(img.Image image, int left, int top, int width,
    int height, int radius, img.Color color) {
  final right = left + width;
  final bottom = top + height;

  for (int y = top; y < bottom; y++) {
    for (int x = left; x < right; x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;

      // Check corners
      bool inside = true;
      // Top-left corner
      if (x < left + radius && y < top + radius) {
        final dx = x - (left + radius);
        final dy = y - (top + radius);
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Top-right corner
      if (x >= right - radius && y < top + radius) {
        final dx = x - (right - radius - 1);
        final dy = y - (top + radius);
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Bottom-left corner
      if (x < left + radius && y >= bottom - radius) {
        final dx = x - (left + radius);
        final dy = y - (bottom - radius - 1);
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }
      // Bottom-right corner
      if (x >= right - radius && y >= bottom - radius) {
        final dx = x - (right - radius - 1);
        final dy = y - (bottom - radius - 1);
        if (dx * dx + dy * dy > radius * radius) inside = false;
      }

      if (inside) {
        image.setPixel(x, y, color);
      }
    }
  }
}
