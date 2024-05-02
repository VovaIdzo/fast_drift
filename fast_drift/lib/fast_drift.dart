library fast_drift;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class FastDrift {
  const FastDrift();

}

@Target({TargetKind.field})
class IdToDrift {
  const IdToDrift({this.autoincrement});

  final bool? autoincrement;
}

@Target({TargetKind.field})
class JsonToDrift { const JsonToDrift(); }

@Target({TargetKind.field})
class IgnoreToDrift { const IgnoreToDrift(); }


@Target({TargetKind.field}) class AsId { const AsId(); }
@Target({TargetKind.field}) class AsNullable { const AsNullable(); }
@Target({TargetKind.field}) class AsMap { final Type type; const AsMap(this.type); }
@Target({TargetKind.field}) class AsJsonConverter { const AsJsonConverter(); }