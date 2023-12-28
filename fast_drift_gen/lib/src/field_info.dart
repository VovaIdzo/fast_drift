import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, FieldElement, ParameterElement;
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:fast_drift/fast_drift.dart';
import 'package:fast_drift_gen/src/fast_drift_id_field_annotation.dart';
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
      ParameterElement element,
      ClassElement classElement, {
        required this.isPositioned,
      })  : idFieldAnnotation = _readIdFieldAnnotation(element, classElement),
        classFieldInfo = _classFieldInfo(element.name, classElement),
        jsonConverterFieldAnnotation = _readJsonConverterFieldAnnotation(element, classElement),
        super(
        name: element.name,
        nullable: element.type.nullabilitySuffix != NullabilitySuffix.none,
        type: element.type.getDisplayString(withNullability: true),
      );

  final FastDriftIdFieldAnnotation? idFieldAnnotation;
  final FastDriftJsonConverterFieldAnnotation? jsonConverterFieldAnnotation;

  final bool isPositioned;

  final FieldInfo? classFieldInfo;

  @override
  String toString() {
    return 'type:$type name:$name fieldAnnotation:$idFieldAnnotation nullable:$nullable';
  }

  /// Returns the field info for the constructor parameter in the relevant class.
  static FieldInfo? _classFieldInfo(
      String fieldName,
      ClassElement classElement,
      ) {
    final field = classElement.fields
        .where((e) => e.name == fieldName)
        .fold<FieldElement?>(null, (previousValue, element) => element);
    if (field == null) return null;

    return FieldInfo(
      name: field.name,
      nullable: field.type.nullabilitySuffix != NullabilitySuffix.none,
      type: field.type.getDisplayString(withNullability: true),
    );
  }

  static FastDriftIdFieldAnnotation? _readIdFieldAnnotation(
      ParameterElement element,
      ClassElement classElement,
      ) {
    final fieldElement = classElement.getField(element.name);
    if (fieldElement is! FieldElement) {
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

  static FastDriftJsonConverterFieldAnnotation? _readJsonConverterFieldAnnotation(
      ParameterElement element,
      ClassElement classElement,
      ) {
    final fieldElement = classElement.getField(element.name);
    if (fieldElement is! FieldElement) {
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