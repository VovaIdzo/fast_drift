// ignore_for_file: unused_element

import 'package:fast_drift/fast_drift.dart';

/// Make sure the `part` is specified before running the builder.
part 'example.g.dart'; /// It should not be commented.

/// Lets you use it like this: `SimpleObject(id: "test").copyWith(id: "new values", intValue: 10).copyWithNull(intValue: true)`.
/// Or like this: `SimpleObject(id: "test").copyWith.id("new value")`.
@FastDrift()
class SimpleObject {
  const SimpleObject({
    required this.id,
    this.intValue,
    this.stringValue,
    this.customObjValue,
  });

  @Id(autoincrement: false)
  final int id;
  final int? intValue;
  final String? stringValue;
  @JsonConverter()
  final CustomObj? customObjValue;

  String get text => "";
}

class CustomObj {

}