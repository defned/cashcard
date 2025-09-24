import 'package:image/image.dart' as img;

/// Draw the image [src] onto the image [dst].
///
/// In other words, drawImage will take an rectangular area from src of
/// width [src_w] and height [src_h] at position ([src_x],[src_y]) and place it
/// in a rectangular area of [dst] of width [dst_w] and height [dst_h] at
/// position ([dst_x],[dst_y]).
///
/// If the source and destination coordinates and width and heights differ,
/// appropriate stretching or shrinking of the image fragment will be performed.
/// The coordinates refer to the upper left corner. This function can be used to
/// copy regions within the same image (if [dst] is the same as [src])
/// but if the regions overlap the results will be unpredictable.

img.Image drawImage(img.Image dst, img.Image src,
    {int dstX = 0,
    int dstY = 0,
    int dstW,
    int dstH,
    int srcX = 0,
    int srcY = 0,
    int srcW,
    int srcH,
    bool blend = true}) {
  srcW ??= src.width;
  srcH ??= src.height;
  dstW ??= dst.width;
  dstH ??= dst.height;

  // Scaling factor to fit src dimensions to dst dimensions
  final scaleX = srcW / dstW;
  final scaleY = srcH / dstH;

  for (var y = 0; y < dstH && dstY + y < dst.height; ++y) {
    for (var x = 0; x < dstW && dstX + x < dst.width; ++x) {
      // Calculate the corresponding source coordinates with scaling
      final srcPosX = srcX + (x * scaleX).toInt();
      final srcPosY = srcY + (y * scaleY).toInt();

      // Ensure the source coordinates are within bounds
      if (srcPosX < src.width && srcPosY < src.height) {
        final srcPixel = src.getPixel(srcPosX, srcPosY);

        if (blend) {
          img.drawPixel(dst, dstX + x, dstY + y, srcPixel);
        } else {
          dst.setPixel(dstX + x, dstY + y, srcPixel);
        }
      }
    }
  }

  return dst;
}
