import 'package:analyzer/dart/element/element.dart'
    show ClassElement, ConstructorElement;
import 'package:fast_drift/fast_drift.dart';
import 'package:fast_drift_gen/src/fast_drift_annotation.dart';
import 'package:fast_drift_gen/src/fast_drift_table_annotation.dart';
import 'package:fast_drift_gen/src/field_info.dart';
import 'package:source_gen/source_gen.dart'
    show ConstantReader, InvalidGenerationSourceError, TypeChecker;

/// Generates a list of `FieldInfo` for each class field that will be a part of the code generation process.
/// The resulting array is sorted by the field name. `Throws` on error.
List<ConstructorParameterInfo> sortedConstructorFields(
  ClassElement element,
  String? constructor,
) {
  final targetConstructor = constructor != null
      ? element.getNamedConstructor(constructor)
      : element.unnamedConstructor;

  if (targetConstructor is! ConstructorElement) {
    if (constructor != null) {
      throw InvalidGenerationSourceError(
        'Named Constructor "$constructor" constructor is missing.',
        element: element,
      );
    } else {
      throw InvalidGenerationSourceError(
        'Default constructor for "${element.name}" is missing.',
        element: element,
      );
    }
  }

  final parameters = targetConstructor.parameters;
  if (parameters.isEmpty) {
    throw InvalidGenerationSourceError(
      'Unnamed constructor for ${element.name} has no parameters or missing.',
      element: element,
    );
  }

  final fields = <ConstructorParameterInfo>[];

  for (final parameter in parameters) {
    final field = ConstructorParameterInfo(
      parameter,
      element,
      isPositioned: parameter.isPositional,
    );

    fields.add(field);
  }

  return fields;
}

/// Restores the `CopyWith` annotation provided by the user.
FastDriftAnnotation readClassAnnotation(
  ConstantReader reader,
) {
  const tableChecker = TypeChecker.fromRuntime(FastDriftTable);
  if (reader.instanceOf(tableChecker)) {
    final type = reader.peek('type')?.typeValue;
    if (type == null) {
      return FastDriftAnnotation();
    }
    return FastDriftTableAnnotation(type);
  }

  return FastDriftAnnotation();
}

/// Returns parameter names or full parameters declaration declared by this class or an empty string.
///
/// If `nameOnly` is `true`: `class MyClass<T extends String, Y>` returns `<T, Y>`.
///
/// If `nameOnly` is `false`: `class MyClass<T extends String, Y>` returns `<T extends String, Y>`.
String typeParametersString(ClassElement classElement, bool nameOnly) {
  final names = classElement.typeParameters
      .map(
        (e) => nameOnly ? e.name : e.getDisplayString(withNullability: true),
      )
      .join(',');
  if (names.isNotEmpty) {
    return '<$names>';
  } else {
    return '';
  }
}

/// Returns constructor for the given type and optional named constructor name. E.g. "TestConstructor" or "TestConstructor._private" when "_private" constructor name is provided.
String constructorFor(String typeAnnotation, String? namedConstructor) =>
    "$typeAnnotation${namedConstructor == null ? "" : ".$namedConstructor"}";
