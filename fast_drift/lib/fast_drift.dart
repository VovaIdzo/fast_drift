library fast_drift;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class FastDrift {
  const FastDrift();

}

@Target({TargetKind.field})
class Id {
  const Id({this.autoincrement});

  final bool? autoincrement;
}


@Target({TargetKind.field}) class AsId { const AsId(); }
@Target({TargetKind.field}) class AsNullable { const AsNullable(); }
@Target({TargetKind.field}) class AsMap { final Type type; const AsMap(this.type); }