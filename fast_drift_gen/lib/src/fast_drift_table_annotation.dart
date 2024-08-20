import 'package:analyzer/dart/element/type.dart';
import 'package:fast_drift/fast_drift.dart';
import 'package:fast_drift_gen/src/fast_drift_annotation.dart';

/// The internal representation of parameters entered by the library's user.
class FastDriftTableAnnotation extends FastDriftAnnotation {
  final DartType type;
  const FastDriftTableAnnotation(this.type);
}
