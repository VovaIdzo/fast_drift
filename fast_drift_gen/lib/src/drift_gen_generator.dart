import 'package:analyzer/dart/element/element.dart' show ClassElement, Element;
import 'package:build/build.dart' show BuildStep;
import 'package:fast_drift/fast_drift.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart'
    show ConstantReader, GeneratorForAnnotation, InvalidGenerationSourceError;

import 'field_info.dart';
import 'helpers.dart';
import 'package:collection/collection.dart';

/// A `Generator` for `package:build_runner`
class FastDriftGenerator extends GeneratorForAnnotation<FastDrift> {
  FastDriftGenerator() : super();

  @override
  String generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      BuildStep buildStep,
      ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Only classes can be annotated with "CopyWith". "$element" is not a ClassElement.',
        element: element,
      );
    }

    final ClassElement classElement = element;
    final privacyPrefix = element.isPrivate ? "_" : "";
    final classAnnotation = readClassAnnotation(annotation);
    final sortedFields = sortedConstructorFields(classElement, null);
    final typeParametersAnnotation = typeParametersString(classElement, false);
    final typeParametersNames = typeParametersString(classElement, true);
    final typeAnnotation = classElement.name + typeParametersNames;

    for (final field in sortedFields) {
      if (field.classFieldInfo != null &&
          field.nullable == false &&
          field.classFieldInfo?.nullable == true) {
        throw InvalidGenerationSourceError(
          'The constructor parameter "${field.name}" is not nullable, whereas the corresponding class field is nullable. This use case is not supported.',
          element: element,
        );
      }
    }

    return _buildTemplate(classElement.name, sortedFields);
  }


  String _buildTemplate(String className, List<ConstructorParameterInfo> sortedFields){

    final companion = sortedFields.map((e){
      return "${e.name}: Value(item.${e.name})";
    }).join(",\n");

    final jsonConverters = sortedFields.map((e){
      if (e.jsonConverterFieldAnnotation == null){
        return null;
      }

      final pureType = e.type
          .replaceAll("?", "")
          .replaceAll("List", "")
          .replaceAll("<", "")
          .replaceAll(">", "");

      final isListConverter = e.type.startsWith("List<");

      if (isListConverter){
        return '''
    static TypeConverter<${e.type}, String> ${e.name}ListConverter = TypeConverter.json(
      fromJson: (json) => (json as List).map((e) => e.fromJson(json as Map<String, Object?>) as $pureType).toList(), 
      toJson: (item) => item?.map((e) => e.toJson()).toList(),
    );
        ''';
      }

      return '''
  static TypeConverter<$pureType, String> ${e.name}Converter = TypeConverter.json(
    fromJson: (json) => $pureType.fromJson(json as Map<String, Object?>),
    toJson: (item) => item?.toJson(),
  );
      ''';
    }).whereNotNull().join("\n");

    final columns = sortedFields.map((e){
      final body = "${e.name};";

      var type = "";
      if (e.type == "int" || e.type == "int?"){
        type = "IntColumn";
      } else if (e.type == "bool" || e.type == "bool?"){
        type = "BoolColumn";
      } else {
        type = "TextColumn";
      }

      var annotations = "";
      if (e.idFieldAnnotation != null){
        annotations += "@AsId()\n";
      }
      if (e.nullable){
        annotations += "@AsNullable()\n";
      }

      if (e.jsonConverterFieldAnnotation != null){
        annotations += "@AsJsonConverter()\n";
      } else if (e.type != "int" && e.type != "int?"
          && e.type != "String" && e.type != "String?"
          && e.type != "bool" && e.type != "bool?"
      ){
        annotations += "@AsMap(${e.type.replaceAll(RegExp("[?<>]"), "")}Converter)\n";
      }

      return "$annotations abstract final $type $body";
    }).join("\n");

    return '''
    
abstract mixin class ${className}FastDrift implements Insertable<${className}> {
  @override
  Map<String, Expression<Object>> toColumns(bool nullToAbsent) {
    final item = this as ${className};
    
    return ${className}TableCompanion(
      $companion
    ).toColumns(nullToAbsent);
  }
  
}


abstract mixin class ${className}FastDriftTableColumns {
  $columns
  $jsonConverters
}    
   
    ''';
  }
}