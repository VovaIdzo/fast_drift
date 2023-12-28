library fast_drift_gen.builder;

import 'package:build/build.dart' show Builder, BuilderOptions;
import 'package:fast_drift_gen/src/drift_gen_generator.dart';
import 'package:source_gen/source_gen.dart' show SharedPartBuilder;

/// Supports `package:build_runner` creation and configuration of
/// `copy_with_extension_gen`.
///
/// Not meant to be invoked by hand-authored code.
Builder fastDrift(BuilderOptions config) {
  return SharedPartBuilder(
    [FastDriftGenerator()],
    'fastDrift',
  );
}