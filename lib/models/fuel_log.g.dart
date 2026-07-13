// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFuelLogCollection on Isar {
  IsarCollection<FuelLog> get fuelLogs => this.collection();
}

const FuelLogSchema = CollectionSchema(
  name: r'FuelLog',
  id: -4687562640734145961,
  properties: {
    r'carId': PropertySchema(
      id: 0,
      name: r'carId',
      type: IsarType.long,
    ),
    r'dateString': PropertySchema(
      id: 1,
      name: r'dateString',
      type: IsarType.string,
    ),
    r'fuelType': PropertySchema(
      id: 2,
      name: r'fuelType',
      type: IsarType.string,
    ),
    r'liters': PropertySchema(
      id: 3,
      name: r'liters',
      type: IsarType.double,
    ),
    r'timeString': PropertySchema(
      id: 4,
      name: r'timeString',
      type: IsarType.string,
    )
  },
  estimateSize: _fuelLogEstimateSize,
  serialize: _fuelLogSerialize,
  deserialize: _fuelLogDeserialize,
  deserializeProp: _fuelLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'carId': IndexSchema(
      id: -7879293051651118710,
      name: r'carId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'carId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'car': LinkSchema(
      id: -3289399544419227225,
      name: r'car',
      target: r'Car',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _fuelLogGetId,
  getLinks: _fuelLogGetLinks,
  attach: _fuelLogAttach,
  version: '3.1.0+1',
);

int _fuelLogEstimateSize(
  FuelLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateString.length * 3;
  bytesCount += 3 + object.fuelType.length * 3;
  bytesCount += 3 + object.timeString.length * 3;
  return bytesCount;
}

void _fuelLogSerialize(
  FuelLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.carId);
  writer.writeString(offsets[1], object.dateString);
  writer.writeString(offsets[2], object.fuelType);
  writer.writeDouble(offsets[3], object.liters);
  writer.writeString(offsets[4], object.timeString);
}

FuelLog _fuelLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FuelLog();
  object.carId = reader.readLongOrNull(offsets[0]);
  object.dateString = reader.readString(offsets[1]);
  object.fuelType = reader.readString(offsets[2]);
  object.id = id;
  object.liters = reader.readDouble(offsets[3]);
  object.timeString = reader.readString(offsets[4]);
  return object;
}

P _fuelLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fuelLogGetId(FuelLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fuelLogGetLinks(FuelLog object) {
  return [object.car];
}

void _fuelLogAttach(IsarCollection<dynamic> col, Id id, FuelLog object) {
  object.id = id;
  object.car.attach(col, col.isar.collection<Car>(), r'car', id);
}

extension FuelLogQueryWhereSort on QueryBuilder<FuelLog, FuelLog, QWhere> {
  QueryBuilder<FuelLog, FuelLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhere> anyCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'carId'),
      );
    });
  }
}

extension FuelLogQueryWhere on QueryBuilder<FuelLog, FuelLog, QWhereClause> {
  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'carId',
        value: [null],
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'carId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdEqualTo(int? carId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'carId',
        value: [carId],
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdNotEqualTo(
      int? carId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'carId',
              lower: [],
              upper: [carId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'carId',
              lower: [carId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'carId',
              lower: [carId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'carId',
              lower: [],
              upper: [carId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdGreaterThan(
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'carId',
        lower: [carId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdLessThan(
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'carId',
        lower: [],
        upper: [carId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterWhereClause> carIdBetween(
    int? lowerCarId,
    int? upperCarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'carId',
        lower: [lowerCarId],
        includeLower: includeLower,
        upper: [upperCarId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FuelLogQueryFilter
    on QueryBuilder<FuelLog, FuelLog, QFilterCondition> {
  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carId',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carId',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carId',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carId',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carId',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> dateStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fuelType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fuelType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelType',
        value: '',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> fuelTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fuelType',
        value: '',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> litersEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'liters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> litersGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'liters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> litersLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'liters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> litersBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'liters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeString',
        value: '',
      ));
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> timeStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeString',
        value: '',
      ));
    });
  }
}

extension FuelLogQueryObject
    on QueryBuilder<FuelLog, FuelLog, QFilterCondition> {}

extension FuelLogQueryLinks
    on QueryBuilder<FuelLog, FuelLog, QFilterCondition> {
  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> car(
      FilterQuery<Car> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'car');
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterFilterCondition> carIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'car', 0, true, 0, true);
    });
  }
}

extension FuelLogQuerySortBy on QueryBuilder<FuelLog, FuelLog, QSortBy> {
  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByFuelType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByFuelTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByLiters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liters', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByLitersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liters', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByTimeString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> sortByTimeStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.desc);
    });
  }
}

extension FuelLogQuerySortThenBy
    on QueryBuilder<FuelLog, FuelLog, QSortThenBy> {
  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByFuelType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByFuelTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByLiters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liters', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByLitersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'liters', Sort.desc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByTimeString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.asc);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QAfterSortBy> thenByTimeStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.desc);
    });
  }
}

extension FuelLogQueryWhereDistinct
    on QueryBuilder<FuelLog, FuelLog, QDistinct> {
  QueryBuilder<FuelLog, FuelLog, QDistinct> distinctByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carId');
    });
  }

  QueryBuilder<FuelLog, FuelLog, QDistinct> distinctByDateString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QDistinct> distinctByFuelType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fuelType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FuelLog, FuelLog, QDistinct> distinctByLiters() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'liters');
    });
  }

  QueryBuilder<FuelLog, FuelLog, QDistinct> distinctByTimeString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeString', caseSensitive: caseSensitive);
    });
  }
}

extension FuelLogQueryProperty
    on QueryBuilder<FuelLog, FuelLog, QQueryProperty> {
  QueryBuilder<FuelLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FuelLog, int?, QQueryOperations> carIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carId');
    });
  }

  QueryBuilder<FuelLog, String, QQueryOperations> dateStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateString');
    });
  }

  QueryBuilder<FuelLog, String, QQueryOperations> fuelTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fuelType');
    });
  }

  QueryBuilder<FuelLog, double, QQueryOperations> litersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'liters');
    });
  }

  QueryBuilder<FuelLog, String, QQueryOperations> timeStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeString');
    });
  }
}
