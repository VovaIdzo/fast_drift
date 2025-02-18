import 'package:analyzer/dart/element/element.dart' show ClassElement, Element;
import 'package:build/build.dart' show BuildStep;
import 'package:fast_drift/fast_drift.dart';
import 'package:collection/collection.dart';
import 'package:fast_drift_gen/src/fast_drift_table_annotation.dart';
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
        'Only classes can be annotated with "FastDrift". "$element" is not a ClassElement.',
        element: element,
      );
    }

    ClassElement classElement = element;
    final privacyPrefix = element.isPrivate ? "_" : "";
    final classAnnotation = readClassAnnotation(annotation);
    if (classAnnotation is FastDriftTableAnnotation) {
      classElement = classAnnotation.type.element! as ClassElement;
    }
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

  String _buildTemplate(
      String className, List<ConstructorParameterInfo> sortedFields) {
    final companion = sortedFields
        .map((e) {
          if (e.ignoreAnnotation != null) {
            return null;
          }

          return "${e.name}: Value(item.${e.name})";
        })
        .whereNotNull()
        .join(",\n");

    final jsonConverters = sortedFields
        .map((e) {
          if (e.jsonConverterFieldAnnotation == null) {
            return null;
          }

          var pureType = e.type;
          final isListConverter = e.type.startsWith("List<");
          final className = e.type.replaceAll(RegExp("[?<> ]"), "");
          final driftType = e.nullable ? "String?" : "String";

          if (isListConverter) {
            pureType =
                e.type.replaceAll(RegExp("[?<> ]"), "").replaceAll("List", "");

            return '''
class ${className}Converter extends TypeConverter<${e.type}, $driftType> {
  const ${className}Converter();

  @override
  ${e.type} fromSql($driftType fromDb) {
    ${e.nullable ? "if (fromDb == null) return null;" : ""}
   
    return (jsonDecode(fromDb) as List).map((obj) => $pureType.fromJson(obj)).toList();
  }

  @override
  $driftType toSql(${e.type} value) {
    ${e.nullable ? "if (value == null) return null;" : ""}

    return jsonEncode(value.map((e) => e.toJson()).toList());
  }
}
        ''';
          }

          return '''
class ${className}Converter extends TypeConverter<${e.type}, $driftType> {
  const ${className}Converter();

  @override
  ${e.type} fromSql($driftType fromDb) {
    ${e.nullable ? "if (fromDb == null) return null;" : ""}
   
    return $className.fromJson(jsonDecode(fromDb));
  }

  @override
  $driftType toSql(${e.type} value) {
    ${e.nullable ? "if (value == null) return null;" : ""}

    return jsonEncode(e.toJson());
  }
}      
      ''';
        })
        .whereNotNull()
        .join("\n");

    final columns = sortedFields
        .map((e) {
          if (e.ignoreAnnotation != null) {
            return null;
          }

          final body = "${e.name};";

          var type = "";
          if (e.type == "int" || e.type == "int?") {
            type = "IntColumn";
          } else if (e.type == "DateTime" || e.type == "DateTime?") {
            type = "DateTimeColumn";
          } else if (e.type == "bool" || e.type == "bool?") {
            type = "BoolColumn";
          } else {
            type = "TextColumn";
          }

          return "abstract final $type $body";
        })
        .whereNotNull()
        .join("\n");

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
}  

extension ${className}X on ${className} {
  Insertable<${className}> toInsertable([bool nullToAbsent = false]) {
    final item = this as ${className};
    
    return RawValuesInsertable(${className}TableCompanion(
      $companion
    ).toColumns(nullToAbsent));
  }
}

extension ${className}ListX on List<${className}> {
  Iterable<Insertable<${className}>> toInsertable([bool nullToAbsent = false]) {
    return map((e) => e.toInsertable(nullToAbsent));
  }
}  
   
$jsonConverters
    ''';
  }
}
