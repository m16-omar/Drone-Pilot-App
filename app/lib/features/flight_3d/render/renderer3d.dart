import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Vertices, VertexMode;
import 'package:flutter/material.dart';

/// Flat-shaded 3D renderer on top of [Canvas.drawVertices] inspired by Lagos Life.
/// World space: right-handed, y up, x right (east), z forward (north), meters.
/// Supports 3D rotation (yaw, pitch, roll), perspective camera, directional lighting,
/// soft fog, glow emission, ground polygons, and painter's sorting.

class Face {
  Face(
    this.indices,
    this.color,
    this.nx,
    this.ny,
    this.nz, {
    this.glow = false,
  });

  final List<int> indices;
  final Color color;
  final double nx, ny, nz;
  final bool glow;
}

class Mesh {
  Mesh(this.vertices, this.faces) {
    var x0 = double.infinity, y0 = double.infinity, z0 = double.infinity;
    var x1 = -double.infinity, y1 = -double.infinity, z1 = -double.infinity;
    for (var i = 0; i < vertices.length; i += 3) {
      x0 = math.min(x0, vertices[i]);
      x1 = math.max(x1, vertices[i]);
      y0 = math.min(y0, vertices[i + 1]);
      y1 = math.max(y1, vertices[i + 1]);
      z0 = math.min(z0, vertices[i + 2]);
      z1 = math.max(z1, vertices[i + 2]);
    }
    cx = (x0 + x1) / 2;
    cy = (y0 + y1) / 2;
    cz = (z0 + z1) / 2;
    var r = 0.0;
    for (var i = 0; i < vertices.length; i += 3) {
      final dx = vertices[i] - cx;
      final dy = vertices[i + 1] - cy;
      final dz = vertices[i + 2] - cz;
      r = math.max(r, math.sqrt(dx * dx + dy * dy + dz * dz));
    }
    radius = r;
  }

  final Float64List vertices;
  final List<Face> faces;
  late final double cx, cy, cz;
  late final double radius;

  factory Mesh.box(
    double w,
    double h,
    double d,
    Color color, {
    double cx = 0,
    double cy = 0,
    double cz = 0,
    Color? top,
    Color? front,
    Color? bottomColor,
    bool glow = false,
  }) {
    final x0 = cx - w / 2, x1 = cx + w / 2;
    final y0 = cy - h / 2, y1 = cy + h / 2;
    final z0 = cz - d / 2, z1 = cz + d / 2;
    final v = Float64List.fromList([
      x0, y0, z0, x1, y0, z0, x1, y1, z0, x0, y1, z0, // back (z0)
      x0, y0, z1, x1, y0, z1, x1, y1, z1, x0, y1, z1, // front (z1)
    ]);
    return Mesh(v, [
      Face([4, 5, 6, 7], front ?? color, 0, 0, 1, glow: glow), // +z
      Face([1, 0, 3, 2], color, 0, 0, -1, glow: glow), // -z
      Face([5, 1, 2, 6], color, 1, 0, 0, glow: glow), // +x
      Face([0, 4, 7, 3], color, -1, 0, 0, glow: glow), // -x
      Face([7, 6, 2, 3], top ?? color, 0, 1, 0, glow: glow), // +y
      Face([0, 1, 5, 4], bottomColor ?? color, 0, -1, 0, glow: glow), // -y
    ]);
  }

  factory Mesh.cylinder(
    double radius,
    double height,
    Color color, {
    int segments = 8,
    double cx = 0,
    double cy = 0,
    double cz = 0,
    Color? capColor,
  }) {
    final v = <double>[];
    final faces = <Face>[];

    // Vertices: bottom ring, then top ring
    final y0 = cy - height / 2;
    final y1 = cy + height / 2;

    for (var i = 0; i < segments; i++) {
      final a = i / segments * math.pi * 2;
      final x = cx + math.cos(a) * radius;
      final z = cz + math.sin(a) * radius;
      v.addAll([x, y0, z]);
    }
    for (var i = 0; i < segments; i++) {
      final a = i / segments * math.pi * 2;
      final x = cx + math.cos(a) * radius;
      final z = cz + math.sin(a) * radius;
      v.addAll([x, y1, z]);
    }

    // Side faces
    for (var i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      final b0 = i;
      final b1 = next;
      final t1 = next + segments;
      final t0 = i + segments;
      final midA = (i + 0.5) / segments * math.pi * 2;
      faces.add(Face(
        [b0, b1, t1, t0],
        color,
        math.cos(midA),
        0,
        math.sin(midA),
      ));
    }

    // Top cap
    final topIndices = [for (var i = 0; i < segments; i++) i + segments];
    faces.add(Face(topIndices, capColor ?? color, 0, 1, 0));

    // Bottom cap
    final bottomIndices = [for (var i = segments - 1; i >= 0; i--) i];
    faces.add(Face(bottomIndices, capColor ?? color, 0, -1, 0));

    return Mesh(Float64List.fromList(v), faces);
  }
}

/// A 3D Part placed in world coordinates with full 3-axis rotation (yaw, pitch, roll).
class Part {
  Part(
    this.mesh, {
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.bright = 1.0,
  });

  final Mesh mesh;
  double x, y, z;
  double yaw, pitch, roll; // in radians
  double bright;

  // Precomputed rotation matrix elements
  double m00 = 1, m01 = 0, m02 = 0;
  double m10 = 0, m11 = 1, m12 = 0;
  double m20 = 0, m21 = 0, m22 = 1;

  void computeMatrix() {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final cr = math.cos(roll), sr = math.sin(roll);

    m00 = cy * cr + sy * sp * sr;
    m01 = -cy * sr + sy * sp * cr;
    m02 = sy * cp;

    m10 = cp * sr;
    m11 = cp * cr;
    m12 = -sp;

    m20 = -sy * cr + cy * sp * sr;
    m21 = sy * sr + cy * sp * cr;
    m22 = cy * cp;
  }
}

class GroundPoly {
  GroundPoly(this.points, this.color, {this.y = 0});

  final Float64List points; // x, z pairs
  final Color color;
  final double y;

  late final double cx = _calcCenter(0);
  late final double cz = _calcCenter(1);
  late final double radius = _calcRadius();

  double _calcCenter(int offset) {
    var sum = 0.0;
    final count = points.length ~/ 2;
    for (var i = 0; i < count; i++) {
      sum += points[i * 2 + offset];
    }
    return sum / count;
  }

  double _calcRadius() {
    var maxR = 0.0;
    final count = points.length ~/ 2;
    for (var i = 0; i < count; i++) {
      final dx = points[i * 2] - cx;
      final dz = points[i * 2 + 1] - cz;
      maxR = math.max(maxR, math.sqrt(dx * dx + dz * dz));
    }
    return maxR;
  }

  factory GroundPoly.rect(double x0, double z0, double x1, double z1, Color color, {double y = 0}) =>
      GroundPoly(Float64List.fromList([x0, z0, x0, z1, x1, z1, x1, z0]), color, y: y);

  factory GroundPoly.circle(double cx, double cz, double r, Color color, {double y = 0, int sides = 16}) {
    final pts = Float64List(sides * 2);
    for (var i = 0; i < sides; i++) {
      final a = -i / sides * math.pi * 2;
      pts[i * 2] = cx + math.cos(a) * r;
      pts[i * 2 + 1] = cz + math.sin(a) * r;
    }
    return GroundPoly(pts, color, y: y);
  }

  /// Builds a ring as a list of convex quads.
  static List<GroundPoly> ring(double cx, double cz, double rInner, double rOuter, Color color, {double y = 0, int sides = 16}) {
    final quads = <GroundPoly>[];
    for (var i = 0; i < sides; i++) {
      final a0 = -i / sides * math.pi * 2;
      final a1 = -(i + 1) / sides * math.pi * 2;
      final x0In = cx + math.cos(a0) * rInner;
      final z0In = cz + math.sin(a0) * rInner;
      final x1In = cx + math.cos(a1) * rInner;
      final z1In = cz + math.sin(a1) * rInner;
      final x1Out = cx + math.cos(a1) * rOuter;
      final z1Out = cz + math.sin(a1) * rOuter;
      final x0Out = cx + math.cos(a0) * rOuter;
      final z0Out = cz + math.sin(a0) * rOuter;

      quads.add(GroundPoly(Float64List.fromList([
        x0In, z0In,
        x1In, z1In,
        x1Out, z1Out,
        x0Out, z0Out,
      ]), color, y: y));
    }
    return quads;
  }
}

class Lighting {
  const Lighting({
    required this.skyTop,
    required this.skyBottom,
    required this.fog,
    this.ambient = 0.55,
    this.diffuse = 0.6,
    this.lx = 0.4,
    this.ly = 0.8,
    this.lz = 0.4,
    this.tint = const Color(0xFFFFFFFF),
    this.fogStart = 60,
    this.fogEnd = 160,
    this.glow = 1.0,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color fog;
  final double ambient, diffuse;
  final double lx, ly, lz;
  final Color tint;
  final double fogStart, fogEnd;
  final double glow;

  static const day = Lighting(
    skyTop: Color(0xFF0F172A),
    skyBottom: Color(0xFF1E293B),
    fog: Color(0xFF0F172A),
    ambient: 0.5,
    diffuse: 0.6,
    lx: 0.5,
    ly: 0.85,
    lz: -0.2,
    tint: Color(0xFFFFFFFF),
    glow: 1.0,
  );

  static const sunset = Lighting(
    skyTop: Color(0xFF1E1B4B),
    skyBottom: Color(0xFF7C2D12),
    fog: Color(0xFF431407),
    ambient: 0.45,
    diffuse: 0.65,
    lx: -0.7,
    ly: 0.4,
    lz: 0.3,
    tint: Color(0xFFFFEDD5),
    glow: 1.2,
  );

  static const night = Lighting(
    skyTop: Color(0xFF020617),
    skyBottom: Color(0xFF0B132B),
    fog: Color(0xFF020617),
    ambient: 0.28,
    diffuse: 0.35,
    lx: 0.2,
    ly: 0.9,
    lz: 0.3,
    tint: Color(0xFF93C5FD),
    glow: 1.5,
  );
}

class Camera {
  double x = 0, y = 3, z = 6;
  double yaw = 0; // 0 looks north (-z)
  double pitch = -0.25; // negative looks down
  double fovY = 60 * math.pi / 180;
  double near = 0.2;
}

class Renderer3D {
  Renderer3D();

  Float32List _pos = Float32List(1 << 16);
  Int32List _col = Int32List(1 << 15);
  int _nVerts = 0;

  late double _cx, _cy, _cz, _sinY, _cosY, _sinP, _cosP, _f, _hx, _hy, _near, _tanX, _tanY;
  late Lighting _light;
  late double _lx, _ly, _lz;

  final _clipIn = Float64List(3 * 64);
  final _clipOut = Float64List(3 * 72);
  final _sorted = <Part>[];
  final _depth = <Part, double>{};

  void _setup(Camera cam, Size size, Lighting light) {
    _cx = cam.x;
    _cy = cam.y;
    _cz = cam.z;
    _sinY = math.sin(cam.yaw);
    _cosY = math.cos(cam.yaw);
    _sinP = math.sin(cam.pitch);
    _cosP = math.cos(cam.pitch);
    _f = (size.height / 2) / math.tan(cam.fovY / 2);
    _hx = size.width / 2;
    _hy = size.height / 2;
    _near = cam.near;
    _tanY = math.tan(cam.fovY / 2);
    _tanX = _tanY * size.width / size.height;
    _light = light;
    final l = math.sqrt(light.lx * light.lx + light.ly * light.ly + light.lz * light.lz);
    _lx = light.lx / l;
    _ly = light.ly / l;
    _lz = light.lz / l;
  }

  double _vx = 0, _vy = 0, _vz = 0;
  void _toView(double x, double y, double z) {
    final dx = x - _cx, dy = y - _cy, dz = z - _cz;
    final rx = dx * _cosY + dz * _sinY;
    final rz = -dx * _sinY + dz * _cosY;
    _vx = rx;
    _vy = dy * _cosP + rz * _sinP;
    _vz = -dy * _sinP + rz * _cosP;
  }

  Offset? project(double x, double y, double z) {
    _toView(x, y, z);
    if (-_vz < _near) return null;
    return Offset(_hx + _f * _vx / -_vz, _hy - _f * _vy / -_vz);
  }

  bool _visible(double x, double y, double z, double r) {
    _toView(x, y, z);
    final d = -_vz;
    if (d < -r || d - r > _light.fogEnd) return false;
    if (_vx.abs() > d * _tanX + r * 1.5) return false;
    if (_vy.abs() > d * _tanY + r * 1.5) return false;
    return true;
  }

  void render(
    Canvas canvas,
    Size size,
    Camera cam,
    Lighting light,
    List<GroundPoly> ground,
    List<Part> parts, {
    bool drawSky = true,
  }) {
    _setup(cam, size, light);
    _nVerts = 0;

    if (drawSky) {
      final rect = Offset.zero & size;
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light.skyTop, light.skyBottom],
      );
      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    }

    // 1. Ground polygons
    for (final g in ground) {
      if (!_visible(g.cx, g.y, g.cz, g.radius)) continue;
      final dist = math.sqrt(math.pow(g.cx - _cx, 2) + math.pow(g.cz - _cz, 2));
      final color = _shade(g.color, 0, 1, 0, math.max(0, dist - g.radius * 0.5));
      final n = g.points.length ~/ 2;
      for (var i = 0; i < n; i++) {
        _toView(g.points[i * 2], g.y, g.points[i * 2 + 1]);
        _clipIn[i * 3] = _vx;
        _clipIn[i * 3 + 1] = _vy;
        _clipIn[i * 3 + 2] = _vz;
      }
      _emitPolygon(n, color);
    }

    // 2. 3D Parts sorted far-to-near
    _sorted.clear();
    _depth.clear();
    for (final p in parts) {
      p.computeMatrix();
      final m = p.mesh;
      final wx = p.x + p.m00 * m.cx + p.m01 * m.cy + p.m02 * m.cz;
      final wy = p.y + p.m10 * m.cx + p.m11 * m.cy + p.m12 * m.cz;
      final wz = p.z + p.m20 * m.cx + p.m21 * m.cy + p.m22 * m.cz;
      if (!_visible(wx, wy, wz, m.radius)) continue;
      _sorted.add(p);
      _depth[p] = (wx - _cx) * (wx - _cx) + (wy - _cy) * (wy - _cy) + (wz - _cz) * (wz - _cz);
    }
    _sorted.sort((a, b) => _depth[b]!.compareTo(_depth[a]!));

    for (final p in _sorted) {
      _drawPart(p);
    }

    if (_nVerts == 0) return;
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(_pos, 0, _nVerts * 2),
      colors: Int32List.sublistView(_col, 0, _nVerts),
    );
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    vertices.dispose();
  }

  void _drawPart(Part p) {
    final m = p.mesh;
    final v = m.vertices;
    final dist = math.sqrt(_depth[p]!);

    for (final f in m.faces) {
      // Transform face normal with part's 3D rotation matrix
      final nx = p.m00 * f.nx + p.m01 * f.ny + p.m02 * f.nz;
      final ny = p.m10 * f.nx + p.m11 * f.ny + p.m12 * f.nz;
      final nz = p.m20 * f.nx + p.m21 * f.ny + p.m22 * f.nz;

      // Back-face culling using camera ray to first vertex
      final i0 = f.indices[0] * 3;
      final lx0 = v[i0], ly0 = v[i0 + 1], lz0 = v[i0 + 2];
      final wx0 = p.x + p.m00 * lx0 + p.m01 * ly0 + p.m02 * lz0;
      final wy0 = p.y + p.m10 * lx0 + p.m11 * ly0 + p.m12 * lz0;
      final wz0 = p.z + p.m20 * lx0 + p.m21 * ly0 + p.m22 * lz0;

      if (nx * (_cx - wx0) + ny * (_cy - wy0) + nz * (_cz - wz0) <= 0) continue;

      final color = f.glow
          ? _glow(f.color, dist)
          : _shade(f.color, nx, ny, nz, dist, bright: p.bright);

      final n = f.indices.length;
      for (var k = 0; k < n; k++) {
        final i = f.indices[k] * 3;
        final lx = v[i], ly = v[i + 1], lz = v[i + 2];
        final wx = p.x + p.m00 * lx + p.m01 * ly + p.m02 * lz;
        final wy = p.y + p.m10 * lx + p.m11 * ly + p.m12 * lz;
        final wz = p.z + p.m20 * lx + p.m21 * ly + p.m22 * lz;
        _toView(wx, wy, wz);
        _clipIn[k * 3] = _vx;
        _clipIn[k * 3 + 1] = _vy;
        _clipIn[k * 3 + 2] = _vz;
      }
      _emitPolygon(n, color);
    }
  }

  void _emitPolygon(int n, int color) {
    var allIn = true;
    var anyIn = false;
    for (var i = 0; i < n; i++) {
      final inside = -_clipIn[i * 3 + 2] >= _near;
      allIn &= inside;
      anyIn |= inside;
    }
    if (!anyIn) return;

    Float64List src = _clipIn;
    var count = n;
    if (!allIn) {
      count = 0;
      for (var i = 0; i < n; i++) {
        final j = (i + 1) % n;
        final ax = _clipIn[i * 3], ay = _clipIn[i * 3 + 1], az = _clipIn[i * 3 + 2];
        final bx = _clipIn[j * 3], by = _clipIn[j * 3 + 1], bz = _clipIn[j * 3 + 2];
        final aIn = -az >= _near, bIn = -bz >= _near;
        if (aIn) {
          _clipOut[count * 3] = ax;
          _clipOut[count * 3 + 1] = ay;
          _clipOut[count * 3 + 2] = az;
          count++;
        }
        if (aIn != bIn) {
          final t = (-_near - az) / (bz - az);
          _clipOut[count * 3] = ax + (bx - ax) * t;
          _clipOut[count * 3 + 1] = ay + (by - ay) * t;
          _clipOut[count * 3 + 2] = -_near;
          count++;
        }
      }
      if (count < 3) return;
      src = _clipOut;
    }

    final tris = count - 2;
    _ensure(tris * 3);
    double px(int i) => _hx + _f * src[i * 3] / -src[i * 3 + 2];
    double py(int i) => _hy - _f * src[i * 3 + 1] / -src[i * 3 + 2];
    final x0 = px(0), y0 = py(0);
    for (var k = 1; k <= tris; k++) {
      final o = _nVerts * 2;
      _pos[o] = x0;
      _pos[o + 1] = y0;
      _pos[o + 2] = px(k);
      _pos[o + 3] = py(k);
      _pos[o + 4] = px(k + 1);
      _pos[o + 5] = py(k + 1);
      _col[_nVerts] = color;
      _col[_nVerts + 1] = color;
      _col[_nVerts + 2] = color;
      _nVerts += 3;
    }
  }

  void _ensure(int moreVerts) {
    final need = _nVerts + moreVerts;
    if (need <= _col.length) return;
    final cap = math.max(need, _col.length * 2);
    _pos = Float32List(cap * 2)..setRange(0, _nVerts * 2, _pos);
    _col = Int32List(cap)..setRange(0, _nVerts, _col);
  }

  int _glow(Color c, double dist) {
    final g = _light.glow;
    final base = Color.lerp(c, const Color(0xFFFFFFFF), (g - 1.0).clamp(0.0, 0.5))!;
    final fog = ((dist - _light.fogStart) / (_light.fogEnd - _light.fogStart)).clamp(0.0, 1.0) * 0.5;
    final out = Color.lerp(base, _light.fog, fog)!;
    return out.toARGB32();
  }

  int _shade(Color c, double nx, double ny, double nz, double dist, {double bright = 1.0}) {
    final l = _light;
    final lambert = math.max(0.0, nx * _lx + ny * _ly + nz * _lz);
    final k = math.min(1.3, (l.ambient + l.diffuse * lambert) * bright);
    var r = c.r * k * l.tint.r;
    var g = c.g * k * l.tint.g;
    var b = c.b * k * l.tint.b;
    final fog = ((dist - l.fogStart) / (l.fogEnd - l.fogStart)).clamp(0.0, 1.0);
    if (fog > 0) {
      r += (l.fog.r - r) * fog;
      g += (l.fog.g - g) * fog;
      b += (l.fog.b - b) * fog;
    }
    int ch(double v) => (v.clamp(0.0, 1.0) * 255).round();
    return 0xFF000000 | ch(r) << 16 | ch(g) << 8 | ch(b);
  }
}
