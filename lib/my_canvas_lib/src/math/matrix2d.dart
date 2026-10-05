import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// 2D affine matrix stored as:
/// | a  c  tx |
/// | b  d  ty |
/// | 0  0   1 |
class Matrix2D {
  Matrix2D(this.a, this.b, this.c, this.d, this.tx, this.ty);

  Matrix2D.identity() : this(1, 0, 0, 1, 0, 0);

  Matrix2D.copy(Matrix2D other)
    : this(other.a, other.b, other.c, other.d, other.tx, other.ty);

  double a;
  double b;
  double c;
  double d;
  double tx;
  double ty;

  void setIdentity() {
    a = 1;
    b = 0;
    c = 0;
    d = 1;
    tx = 0;
    ty = 0;
  }

  void copyFrom(Matrix2D other) {
    a = other.a;
    b = other.b;
    c = other.c;
    d = other.d;
    tx = other.tx;
    ty = other.ty;
  }

  /// this = this * other  (column vector: p' = this * other * p)
  void multiply(Matrix2D other) {
    final na = a * other.a + c * other.b;
    final nb = b * other.a + d * other.b;
    final nc = a * other.c + c * other.d;
    final nd = b * other.c + d * other.d;
    final ntx = a * other.tx + c * other.ty + tx;
    final nty = b * other.tx + d * other.ty + ty;
    a = na;
    b = nb;
    c = nc;
    d = nd;
    tx = ntx;
    ty = nty;
  }

  void translate(double x, double y) {
    multiply(Matrix2D(1, 0, 0, 1, x, y));
  }

  void scale(double sx, double sy) {
    multiply(Matrix2D(sx, 0, 0, sy, 0, 0));
  }

  void rotate(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    multiply(Matrix2D(cos, sin, -sin, cos, 0, 0));
  }

  Offset transformPoint(Offset p) {
    return Offset(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);
  }

  Matrix2D inverted() {
    final det = a * d - b * c;
    if (det.abs() < 1e-12) {
      return Matrix2D.identity();
    }
    final id = 1.0 / det;
    final na = d * id;
    final nb = -b * id;
    final nc = -c * id;
    final nd = a * id;
    return Matrix2D(na, nb, nc, nd, -(na * tx + nc * ty), -(nb * tx + nd * ty));
  }

  Offset inverseTransformPoint(Offset p) => inverted().transformPoint(p);

  void applyToCanvas(Canvas canvas) {
    canvas.transform(
      Float64List.fromList(<double>[
        a,
        b,
        0,
        0,
        c,
        d,
        0,
        0,
        0,
        0,
        1,
        0,
        tx,
        ty,
        0,
        1,
      ]),
    );
  }

  @override
  String toString() => 'Matrix2D(a: $a, b: $b, c: $c, d: $d, tx: $tx, ty: $ty)';
}
