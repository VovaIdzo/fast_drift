
import 'package:fast_drift/fast_drift.dart';

/// The internal representation of parameters entered by the library's user.
class FastDriftIdFieldAnnotation implements IdToDrift {
  const FastDriftIdFieldAnnotation({required this.autoincrement});

  const FastDriftIdFieldAnnotation.defaults() : this(autoincrement: false);

  @override
  final bool autoincrement;
}