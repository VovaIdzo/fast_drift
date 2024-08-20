// ignore_for_file: unused_element

import 'package:fast_drift/fast_drift.dart';

/// Lets you use it like this: `SimpleObject(id: "test").copyWith(id: "new values", intValue: 10).copyWithNull(intValue: true)`.
/// Or like this: `SimpleObject(id: "test").copyWith.id("new value")`.
class SimpleObject {
  const SimpleObject({
    required this.id,
    this.intValue,
    this.stringValue,
    this.list,
    this.obj,
  });

  @IdToDrift()
  final int id;
  final int? intValue;
  final String? stringValue;
  @JsonToDrift()
  final List<CustomObj>? list;
  @JsonToDrift()
  final CustomObj? obj;

  String get text => "";
}

class CustomObj {}
