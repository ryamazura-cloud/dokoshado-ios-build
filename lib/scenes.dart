import 'package:flutter/material.dart';

enum _Setting {
  station,
  reception,
  street,
  museum,
  pier,
  square,
  room,
  airport,
  cafe,
  trail,
  market,
  coast,
  apartment,
  study,
}

const _practice = [
  _Setting.station,
  _Setting.reception,
  _Setting.street,
  _Setting.museum,
  _Setting.station,
  _Setting.reception,
  _Setting.street,
  _Setting.cafe,
  _Setting.pier,
  _Setting.square,
  _Setting.room,
  _Setting.airport,
  _Setting.cafe,
  _Setting.trail,
  _Setting.market,
  _Setting.airport,
  _Setting.reception,
  _Setting.street,
  _Setting.coast,
  _Setting.museum,
  _Setting.airport,
  _Setting.pier,
  _Setting.apartment,
  _Setting.street,
  _Setting.trail,
];
const _challenges = [
  _Setting.station,
  _Setting.street,
  _Setting.pier,
  _Setting.trail,
  _Setting.coast,
];

class TravelScene extends StatelessWidget {
  const TravelScene(this.file, {super.key, this.category = 'travel'});
  final String file;
  final String category;

  @override
  Widget build(BuildContext context) {
    final settings = file.startsWith('challenge-') ? _challenges : _practice;
    final number = int.tryParse(file.split('-').last) ?? 1;
    final setting = switch (category) {
      'beauty' || 'health' || 'money' => _Setting.reception,
      'food' || 'fashion' => _Setting.market,
      'entertainment' => _Setting.museum,
      'lifestyle' => _Setting.room,
      'parenting' || 'pets' || 'sports' => _Setting.trail,
      'learning' || 'games' || 'business' || 'gadgets' => _Setting.study,
      'relationships' => _Setting.square,
      'cars' => _Setting.street,
      _ => settings[(number - 1).clamp(0, settings.length - 1)],
    };
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 400 / 143,
          child: CustomPaint(painter: _Scene(setting, number)),
        ),
      ),
    );
  }
}

const _sky = Color(0xffbfe4ef);
const _cream = Color(0xffffedd5);
const _paper = Color(0xfffbf7e9);
const _ink = Color(0xff27486b);
const _blue = Color(0xff3c779e);
const _sea = Color(0xff5fa2ba);
const _green = Color(0xff649b87);
const _deepGreen = Color(0xff377568);
const _terra = Color(0xffc66d55);
const _gold = Color(0xfff3ba63);
const _ground = Color(0xffe4d6bc);
const _glass = Color(0xffa2d1df);

class _Scene extends CustomPainter {
  const _Scene(this.setting, this.variant);
  final _Setting setting;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 143);
    final art = _Art(canvas);
    art.rect(0, 0, 400, 143, _sky);
    art.circle(345, 24, 12, _paper);
    art.cloud(82, 23);
    art.cloud(257, 34);
    switch (setting) {
      case _Setting.station:
        art.rect(0, 105, 400, 38, _ground);
        art.rect(0, 118, 400, 25, _ink);
        art.rect(0, 117, 400, 4, _gold);
        art.line(0, 132, 400, 132, _glass, 2);
        art.vehicle(80, 47, 255, _terra);
        art.rect(0, 10, 400, 8, _ink);
        art.rect(27, 18, 5, 95, _ink);
        art.rect(361, 18, 5, 95, _ink);
        art.person(55, 120, _blue);
        art.bag(66, 105, _gold);
      case _Setting.reception:
        art.rect(0, 0, 400, 108, _cream);
        art.rect(0, 108, 400, 35, _ground);
        art.rect(26, 15, 96, 80, _ink, radius: 3);
        art.rect(31, 20, 86, 70, _glass);
        art.line(73, 20, 73, 90, _paper, 3);
        art.line(31, 55, 117, 55, _paper, 3);
        art.rect(290, 18, 68, 46, _ink, radius: 3);
        art.rect(295, 23, 58, 36, _sky);
        art.polygon([
          const Offset(296, 55),
          const Offset(321, 32),
          const Offset(352, 55),
        ], _green);
        art.circle(226, 23, 13, _paper);
        art.line(226, 23, 226, 15, _ink, 2);
        art.line(226, 23, 232, 25, _ink, 2);
        art.person(248, 105, _blue);
        art.rect(185, 78, 174, 51, _blue, radius: 3);
        art.rect(179, 74, 184, 9, _ink, radius: 3);
        art.rect(199, 91, 146, 30, _glass, radius: 3);
        art.rect(289, 54, 28, 17, _ink, radius: 2);
        art.line(303, 71, 303, 75, _ink, 3);
        art.person(152, 134, _terra);
        art.bag(116, 113, _gold);
      case _Setting.street:
        art.city();
        art.rect(0, 109, 400, 34, _ink);
        for (var x = 6.0; x < 400; x += 45) {
          art.line(x, 130, x + 21, 130, _cream, 2);
        }
        art.vehicle(
          variant == 18 ? 143 : 90,
          67,
          variant == 18 ? 129 : 208,
          variant == 7 ? _terra : _blue,
        );
        art.rect(327, 42, 4, 71, _ink);
        art.rect(318, 39, 22, 18, _paper, radius: 2);
        art.line(323, 47, 335, 47, _blue, 3);
        art.person(357, 126, _terra);
        art.bag(370, 109, _gold);
      case _Setting.museum:
        art.rect(0, 108, 400, 35, _ground);
        art.polygon([
          const Offset(103, 49),
          const Offset(200, 12),
          const Offset(297, 49),
        ], _ink);
        art.rect(113, 49, 174, 61, _cream);
        art.rect(187, 63, 27, 47, _blue);
        for (var x = 124.0; x < 280; x += 33) {
          art.rect(x, 55, 10, 54, _paper);
        }
        art.rect(102, 109, 196, 5, _blue);
        art.rect(94, 115, 212, 5, _glass);
        art.tree(57, 116);
        art.tree(340, 112);
        art.person(156, 133, _terra);
        art.person(239, 131, _deepGreen);
      case _Setting.pier:
        art.rect(0, 67, 400, 76, _sea);
        art.waves();
        art.polygon([
          const Offset(210, 92),
          const Offset(347, 92),
          const Offset(327, 112),
          const Offset(231, 112),
        ], _ink);
        art.rect(234, 60, 84, 33, _paper, radius: 4);
        art.rect(251, 48, 43, 13, _terra, radius: 3);
        for (var x = 240.0; x < 316; x += 18) {
          art.rect(x, 68, 13, 13, _glass, radius: 2);
        }
        art.rect(0, 108, 164, 14, _ground);
        art.rect(38, 56, 59, 52, _cream);
        art.rect(33, 51, 70, 9, _terra);
        art.rect(52, 68, 28, 20, _blue);
        art.person(130, 111, _terra);
      case _Setting.square:
        art.city();
        art.rect(0, 104, 400, 39, _ground);
        art.oval(136, 107, 126, 24, _sea);
        art.rect(193, 82, 11, 35, _blue);
        art.line(198, 84, 174, 105, _paper, 2);
        art.line(198, 84, 221, 105, _paper, 2);
        art.person(284, 126, _terra);
        art.line(292, 67, 292, 106, _ink, 2);
        art.polygon([
          const Offset(263, 77),
          const Offset(292, 58),
          const Offset(320, 77),
        ], _gold);
        art.person(111, 132, _blue);
      case _Setting.room:
        art.rect(0, 0, 400, 107, _cream);
        art.rect(0, 107, 400, 36, _ground);
        art.rect(237, 13, 116, 75, _ink, radius: 3);
        art.rect(243, 19, 104, 63, _glass);
        art.line(295, 19, 295, 82, _paper, 4);
        art.rect(52, 57, 146, 63, _blue, radius: 5);
        art.rect(58, 74, 130, 30, _paper, radius: 4);
        art.rect(91, 82, 110, 30, _sea, radius: 4);
        art.rect(64, 78, 33, 12, _cream, radius: 5);
        art.rect(210, 92, 31, 25, _ink);
        art.line(225, 66, 225, 92, _terra, 3);
        art.polygon([
          const Offset(211, 73),
          const Offset(217, 57),
          const Offset(233, 57),
          const Offset(239, 73),
        ], _gold);
        art.bag(302, 105, _terra);
        art.person(333, 132, _blue);
      case _Setting.airport:
        art.rect(0, 69, 400, 43, _ground);
        art.rect(0, 85, 400, 15, _blue);
        art.line(0, 92, 400, 92, _paper, 1);
        art.polygon([
          const Offset(107, 68),
          const Offset(183, 61),
          const Offset(205, 39),
          const Offset(214, 39),
          const Offset(209, 60),
          const Offset(273, 56),
          const Offset(291, 43),
          const Offset(299, 43),
          const Offset(297, 57),
          const Offset(313, 61),
          const Offset(306, 68),
          const Offset(212, 72),
          const Offset(194, 83),
          const Offset(181, 83),
          const Offset(192, 72),
          const Offset(122, 76),
        ], _paper);
        for (var x = 18.0; x < 400; x += 89) {
          art.rect(x, 0, 5, 113, _ink);
        }
        art.rect(0, 109, 400, 34, _cream);
        art.rect(307, 100, 61, 23, _blue, radius: 3);
        art.person(67, 132, _terra);
        art.bag(81, 112, _gold);
      case _Setting.cafe:
      case _Setting.market:
        art.city();
        art.rect(0, 113, 400, 30, _ground);
        art.store(38, setting == _Setting.market ? _deepGreen : _terra);
        art.store(211, setting == _Setting.market ? _terra : _blue);
        if (setting == _Setting.market) {
          for (var x = 62.0; x < 150; x += 12) {
            art.circle(x, 103, 5, x % 3 == 2 ? _terra : _gold);
          }
        } else {
          art.oval(253, 112, 67, 9, _ink);
          art.line(284, 119, 284, 138, _ink, 3);
          art.rect(272, 105, 8, 8, _paper, radius: 2);
          art.rect(292, 105, 8, 8, _paper, radius: 2);
        }
        art.person(191, 130, _deepGreen);
      case _Setting.trail:
        art.polygon([
          const Offset(0, 90),
          const Offset(87, 19),
          const Offset(163, 82),
          const Offset(262, 12),
          const Offset(400, 89),
          const Offset(400, 143),
          const Offset(0, 143),
        ], _blue);
        art.polygon([
          const Offset(236, 32),
          const Offset(262, 12),
          const Offset(292, 30),
          const Offset(269, 27),
          const Offset(259, 38),
        ], _paper);
        art.polygon([
          const Offset(0, 100),
          const Offset(96, 74),
          const Offset(213, 102),
          const Offset(313, 75),
          const Offset(400, 98),
          const Offset(400, 143),
          const Offset(0, 143),
        ], _green);
        art.polygon([
          const Offset(111, 143),
          const Offset(213, 96),
          const Offset(261, 88),
          const Offset(231, 102),
          const Offset(169, 143),
        ], _cream);
        art.tree(60, 121);
        art.tree(335, 127);
        art.person(181, 136, _terra);
      case _Setting.coast:
        art.rect(0, 60, 400, 83, _sea);
        art.waves();
        art.polygon([
          const Offset(0, 92),
          const Offset(99, 71),
          const Offset(168, 94),
          const Offset(239, 112),
          const Offset(288, 143),
          const Offset(0, 143),
        ], _ground);
        art.rect(84, 32, 23, 57, _paper);
        art.rect(84, 53, 23, 10, _terra);
        art.polygon([
          const Offset(78, 34),
          const Offset(95, 21),
          const Offset(113, 34),
        ], _terra);
        art.rect(93, 40, 6, 10, _ink);
        art.line(0, 115, 161, 107, _ink, 10);
        art.rect(142, 94, 30, 12, _gold, radius: 2);
        art.person(213, 133, _blue);
      case _Setting.study:
        art.rect(0, 0, 400, 108, _cream);
        art.rect(0, 108, 400, 35, _ground);
        art.rect(25, 16, 88, 70, _ink, radius: 4);
        art.rect(31, 22, 76, 58, _glass);
        art.line(70, 22, 70, 80, _paper, 3);
        art.rect(171, 74, 195, 9, _ink, radius: 3);
        art.rect(182, 83, 8, 47, _blue);
        art.rect(342, 83, 8, 47, _blue);
        art.rect(209, 30, 90, 47, _blue, radius: 5);
        art.rect(215, 36, 78, 34, _glass, radius: 2);
        art.line(224, 46, 270, 46, _paper, 2);
        art.line(224, 55, 263, 55, _paper, 2);
        art.rect(305, 60, 31, 13, _terra, radius: 2);
        art.rect(306, 62, 29, 7, _paper);
        art.person(149, 131, _terra);
      case _Setting.apartment:
        art.rect(0, 110, 400, 33, _ground);
        art.rect(98, 24, 200, 94, _cream, radius: 4);
        art.polygon([
          const Offset(87, 26),
          const Offset(196, 4),
          const Offset(310, 26),
        ], _terra);
        for (var x = 115.0; x < 278; x += 55) {
          art.rect(x, 36, 38, 25, _ink, radius: 2);
          art.rect(x + 3, 39, 32, 19, _glass);
        }
        art.rect(179, 72, 43, 46, _blue);
        art.rect(116, 76, 38, 23, _glass);
        art.rect(244, 76, 38, 23, _glass);
        art.tree(53, 123);
        art.tree(339, 123);
        art.person(150, 136, _terra);
        art.bag(164, 115, _gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Scene oldDelegate) =>
      oldDelegate.setting != setting || oldDelegate.variant != variant;
}

class _Art {
  _Art(this.canvas);
  final Canvas canvas;
  final _paint = Paint();

  Paint fill(Color color) => _paint
    ..color = color
    ..style = PaintingStyle.fill;

  void rect(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    double radius = 0,
  }) => canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
    fill(color),
  );
  void circle(double x, double y, double r, Color color) =>
      canvas.drawCircle(Offset(x, y), r, fill(color));
  void oval(double x, double y, double w, double h, Color color) =>
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), fill(color));
  void line(
    double x,
    double y,
    double x2,
    double y2,
    Color color,
    double width,
  ) => canvas.drawLine(
    Offset(x, y),
    Offset(x2, y2),
    fill(color)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void polygon(List<Offset> points, Color color) =>
      canvas.drawPath(Path()..addPolygon(points, true), fill(color));

  void cloud(double x, double y) {
    oval(x, y, 48, 11, _paper);
    circle(x + 17, y + 1, 9, _paper);
    circle(x + 31, y + 2, 7, _paper);
  }

  void tree(double x, double y) {
    rect(x - 2, y - 26, 4, 26, _ink);
    circle(x, y - 30, 14, _deepGreen);
    circle(x - 7, y - 37, 9, _green);
  }

  void bag(double x, double y, Color color) {
    rect(x + 4, y - 5, 9, 7, _ink, radius: 2);
    rect(x, y, 17, 18, color, radius: 3);
    line(x + 5, y + 3, x + 5, y + 14, _cream, 1);
  }

  void person(double x, double ground, Color coat) {
    oval(x - 12, ground - 2, 24, 5, _ink.withValues(alpha: .16));
    line(x - 4, ground - 15, x - 6, ground - 1, _ink, 4);
    line(x + 4, ground - 15, x + 6, ground - 1, _ink, 4);
    rect(x - 8, ground - 33, 16, 21, coat, radius: 6);
    circle(x, ground - 39, 6, _gold);
    oval(x - 6, ground - 47, 12, 7, _ink);
  }

  void vehicle(double x, double y, double w, Color color) {
    circle(x + 27, y + 44, 8, _ink);
    circle(x + w - 30, y + 44, 8, _ink);
    rect(x, y, w, 45, color, radius: 10);
    rect(x + 12, y + 7, w - 24, 18, _glass, radius: 4);
    for (var k = x + 35; k < x + w - 19; k += 26) {
      line(k, y + 7, k, y + 25, color, 3);
    }
    line(x + 7, y + 34, x + w - 8, y + 34, _paper, 3);
  }

  void city() {
    for (var i = 0; i < 9; i++) {
      final x = i * 46.0;
      final top = 31.0 + (i * 17 % 32);
      rect(x, top, 43, 109 - top, i.isEven ? _cream : _glass);
      for (var y = top + 11; y < 88; y += 14) {
        rect(x + 7, y, 8, 9, _blue);
        rect(x + 25, y, 8, 9, _blue);
      }
    }
  }

  void waves() {
    for (var i = 0; i < 13; i++) {
      final x = (i * 61 % 390).toDouble();
      final y = (i * 13 % 61 + 75).toDouble();
      line(x, y, x + 21, y, _glass, 2);
    }
  }

  void store(double x, Color color) {
    rect(x, 64, 143, 53, _paper);
    rect(x + 9, 79, 124, 30, _glass);
    for (var k = 0; k < 9; k++) {
      rect(x - 4 + 17 * k, 65, 17, 14, k.isEven ? color : _cream);
    }
  }
}
