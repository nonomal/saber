
import 'dart:math' hide atan2;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/point_extensions.dart';
import 'package:saber/components/canvas/tools/pen.dart';
import 'package:saber/components/canvas/tools/stroke_properties.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/fast_math.dart';

class Stroke {
  final List<Point> _points = [];
  final int pageIndex;
  final String penType;

  late final StrokeProperties strokeProperties;

  bool _isComplete = false;
  bool get isComplete => isStraightLine || _isComplete;
  set isComplete(bool value) { _isComplete = value; _polygonNeedsUpdating = true; }

  /// Whether to draw a straight line from the first point to the last point.
  bool _isStraightLine = false;
  bool get isStraightLine => _isStraightLine;
  set isStraightLine(bool value) { _isStraightLine = value; _polygonNeedsUpdating = true; }

  bool _polygonNeedsUpdating = true;

  List<Offset>? _polygon;
  List<Offset> get polygon {
    if (_polygonNeedsUpdating) {
      _polygon = _getPolygon();
      _polygonNeedsUpdating = false;
    }
    return _polygon!;
  }

  Stroke({
    required this.strokeProperties,
    required this.pageIndex,
    required this.penType,
  });

  Stroke.fromJson(Map<String, dynamic> json) :
        _isComplete = json['f'],
        pageIndex = json['i'] ?? 0,
        penType = json['ty'] ?? (Pen).toString() {
    strokeProperties = StrokeProperties.fromJson(json);

    final List<dynamic> pointsJson = json['p'] as List<dynamic>;
    _points.insertAll(0, pointsJson.map(
      (point) => PointExtensions.fromJson(Map<String, dynamic>.from(point))
    ).toList());
  }
  // json keys should not be the same as the ones in the StrokeProperties class
  Map<String, dynamic> toJson() => {
    'f': isComplete,
    'p': (){
      if (isStraightLine && _points.length > 1) {
        return [
          _points.first.toJson(),
          _points.last.toJson(),
          _points.last.toJson(),
        ];
      }
      return _points.map((Point point) => point.toJson()).toList();
    }(),
    'i': pageIndex,
    'ty': penType.toString(),
  }..addAll(strokeProperties.toJson());

  addPoint(EditorCoreInfo context, Offset offset, [ double? pressure ]) {
    double x = max(min(offset.dx, context.width), 0);
    double y = max(min(offset.dy, context.height), 0);
    Point point = Point(x, y, pressure ?? 0.5);

    if (pressure != null) strokeProperties.simulatePressure = false;

    _points.add(point);
    _polygonNeedsUpdating = true;
  }

  List<Offset> _getPolygon() {
    final List<Point> points;
    if (isStraightLine) {
      Point last = snapLineToRightAngle(_points.first, _points.last);
      points = [ // todo: make this play nicer with the eraser
        _points.first,
        last,
        last,
      ];
    } else {
      points = _points;
    }

    return getStroke(
      points,
      isComplete: isComplete,

      size: strokeProperties.size,
      thinning: strokeProperties.thinning,
      smoothing: strokeProperties.smoothing,
      streamline: strokeProperties.streamline,
      taperStart: strokeProperties.taperStart,
      taperEnd: strokeProperties.taperEnd,
      capStart: strokeProperties.capStart,
      capEnd: strokeProperties.capEnd,
      simulatePressure: strokeProperties.simulatePressure,
    )
      .map((Point point) => Offset(point.x, point.y))
      .toList(growable: false);
  }

  String toSvgPath(EditorCoreInfo context) {
    String toSvgPoint(Offset offset) {
      return '${offset.dx} ${context.height - offset.dy}';
    }

    if (polygon.isEmpty) {
      return "";
    } else {
      return "M${polygon.map((offset) => toSvgPoint(offset)).join("L")}";
    }
  }

  double get maxY {
    return _points.isEmpty ? 0 : _points.map((Point point) => point.y).reduce(max);
  }

  static sqrDistBetweenPoints(Point p1, Point p2) {
    return pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2);
  }

  /// The maximum angle away from a right angle for a line to be snapped to a right angle.
  static const rightAngleThreshold = 0.1;
  /// The minimum length for a line to be snapped to a right angle.
  static const rightAngleMinLength = 10;
  /// Transforms the [last] point to be at a right angle to [first].
  static Point snapLineToRightAngle(Point first, Point last) {
    double dx = (last.x - first.x).abs(),
        dy = (last.y - first.y).abs();
    if (dx < rightAngleMinLength && dy < rightAngleMinLength) {
      return last;
    }

    double angle = atan2(dy, dx);
    if (angle > rightAngleThreshold) {
      return last;
    } else if (dx > dy) {
      return Point(last.x, first.y);
    } else {
      return Point(first.x, last.y);
    }
  }
}
