import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, FieldElement, ParameterElement;
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:fast_drift/fast_drift.dart';
import 'package:fast_drift_gen/src/fast_drift_id_field_annotation.dart';
import 'package:fast_drift_gen/src/fast_drift_ignore_field_annotation.dart';
import 'package:fast_drift_gen/src/fast_drift_json_field_annotation.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;

/// Class field info relevant for code generation.
class FieldInfo {
  FieldInfo({required this.name, required this.nullable, required this.type});

  /// Parameter / field type.
  final String name;

  /// If the type is nullable. `dynamic` is considered non-nullable as it doesn't have nullability flag.
  final bool nullable;

  /// Type name with nullability flag.
  final String type;

  /// True if the type is `dynamic`.
  bool get isDynamic => type == "dynamic";
}

class ConstructorParameterInfo extends FieldInfo {
  ConstructorParameterInfo(
    FormalParameterElement element,
    ClassElement2 classElement, {
    required this.isPositioned,
  })  : idFieldAnnotation = _readIdFieldAnnotation(element, classElement),
        classFieldInfo = _classFieldInfo(element.name3 ?? '', classElement),
        ignoreAnnotation = _readIgnoreFieldAnnotation(element, classElement),
        jsonConverterFieldAnnotation =
            _readJsonConverterFieldAnnotation(element, classElement),
        super(
          name: element.name3 ?? '',
          nullable: element.type.nullabilitySuffix != NullabilitySuffix.none,
          type: element.type.getDisplayString(withNullability: true),
        );

  final FastDriftIdFieldAnnotation? idFieldAnnotation;
  final FastDriftJsonConverterFieldAnnotation? jsonConverterFieldAnnotation;
  final FastDriftIgnoreFieldAnnotation? ignoreAnnotation;

  final bool isPositioned;

  final FieldInfo? classFieldInfo;

  @override
  String toString() {
    return 'type:$type name:$name fieldAnnotation:$idFieldAnnotation nullable:$nullable';
  }

  /// Returns the field info for the constructor parameter in the relevant class.
  static FieldInfo? _classFieldInfo(
    String fieldName,
    ClassElement2 classElement,
  ) {
    final field = classElement.fields2
        .where((e) => e.name3 == fieldName)
        .fold<FieldElement2?>(null, (previousValue, element) => element);
    if (field == null) return null;

    return FieldInfo(
      name: field.name3 ?? '',
      nullable: field.type.nullabilitySuffix != NullabilitySuffix.none,
      type: field.type.getDisplayString(withNullability: true),
    );
  }

  static FastDriftIdFieldAnnotation? _readIdFieldAnnotation(
    FormalParameterElement element,
    ClassElement2 classElement,
  ) {
    final fieldElement = classElement.getField2(element.name3 ?? '');
    if (fieldElement is! FieldElement2) {
      return null;
    }

    const checker = TypeChecker.fromRuntime(IdToDrift);
    final annotation = checker.firstAnnotationOf(fieldElement);
    if (annotation is! DartObject) {
      return null;
    }

    final reader = ConstantReader(annotation);
    final immutable = reader.peek('autoincrement')?.boolValue;

    return FastDriftIdFieldAnnotation(
      autoincrement: immutable ?? false,
    );
  }

  static FastDriftIgnoreFieldAnnotation? _readIgnoreFieldAnnotation(
    FormalParameterElement element,
    ClassElement2 classElement,
  ) {
    final fieldElement = classElement.getField2(element.name3 ?? '');
    if (fieldElement is! FieldElement2) {
      return null;
    }

    const checker = TypeChecker.fromRuntime(IgnoreToDrift);
    final annotation = checker.firstAnnotationOf(fieldElement);
    if (annotation is! DartObject) {
      return null;
    }

    return const FastDriftIgnoreFieldAnnotation();
  }

  static FastDriftJsonConverterFieldAnnotation?
      _readJsonConverterFieldAnnotation(
    FormalParameterElement element,
    ClassElement2 classElement,
  ) {
    final fieldElement = classElement.getField2(element.name3 ?? '');
    if (fieldElement is! FieldElement2) {
      return null;
    }

    const checker = TypeChecker.fromRuntime(JsonToDrift);
    final annotation = checker.firstAnnotationOf(fieldElement);
    if (annotation is! DartObject) {
      return null;
    }

    return FastDriftJsonConverterFieldAnnotation();
  }
}
