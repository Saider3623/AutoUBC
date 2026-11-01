// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odometer_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOdometerLogCollection on Isar {
  IsarCollection<OdometerLog> get odometerLogs => this.collection();
}

const OdometerLogSchema = CollectionSchema(
  name: r'OdometerLog',
  id: 7128341148888209882,
  properties: {
    r'carId': PropertySchema(id: 0, name: r'carId', type: IsarType.long),
    r'dateString': PropertySchema(
      id: 1,
      name: r'dateString',
      type: IsarType.string,
    ),
    r'odometer': PropertySchema(id: 2, name: r'odometer', type: IsarType.long),
    r'uniqueKey': PropertySchema(
      id: 3,
      name: r'uniqueKey',
      type: IsarType.string,
    ),
  },
  estimateSize: _odometerLogEstimateSize,
  serialize: _odometerLogSerialize,
  deserialize: _odometerLogDeserialize,
  deserializeProp: _odometerLogDeserializeProp,
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
        ),
      ],
    ),
    r'uniqueKey_carId': IndexSchema(
      id: -7106498506534069626,
      name: r'uniqueKey_carId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'carId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {
    r'car': LinkSchema(
      id: 4946060533501122115,
      name: r'car',
      target: r'Car',
      single: true,
    ),
  },
  embeddedSchemas: {},
  getId: _odometerLogGetId,
  getLinks: _odometerLogGetLinks,
  attach: _odometerLogAttach,
  version: '3.1.0+1',
);

int _odometerLogEstimateSize(
  OdometerLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateString.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _odometerLogSerialize(
  OdometerLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.carId);
  writer.writeString(offsets[1], object.dateString);
  writer.writeLong(offsets[2], object.odometer);
  writer.writeString(offsets[3], object.uniqueKey);
}

OdometerLog _odometerLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OdometerLog();
  object.carId = reader.readLongOrNull(offsets[0]);
  object.dateString = reader.readString(offsets[1]);
  object.id = id;
  object.odometer = reader.readLong(offsets[2]);
  return object;
}

P _odometerLogDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _odometerLogGetId(OdometerLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _odometerLogGetLinks(OdometerLog object) {
  return [object.car];
}

void _odometerLogAttach(
  IsarCollection<dynamic> col,
  Id id,
  OdometerLog object,
) {
  object.id = id;
  object.car.attach(col, col.isar.collection<Car>(), r'car', id);
}

extension OdometerLogByIndex on IsarCollection<OdometerLog> {
  Future<OdometerLog?> getByUniqueKeyCarId(String uniqueKey, int? carId) {
    return getByIndex(r'uniqueKey_carId', [uniqueKey, carId]);
  }

  OdometerLog? getByUniqueKeyCarIdSync(String uniqueKey, int? carId) {
    return getByIndexSync(r'uniqueKey_carId', [uniqueKey, carId]);
  }

  Future<bool> deleteByUniqueKeyCarId(String uniqueKey, int? carId) {
    return deleteByIndex(r'uniqueKey_carId', [uniqueKey, carId]);
  }

  bool deleteByUniqueKeyCarIdSync(String uniqueKey, int? carId) {
    return deleteByIndexSync(r'uniqueKey_carId', [uniqueKey, carId]);
  }

  Future<List<OdometerLog?>> getAllByUniqueKeyCarId(
    List<String> uniqueKeyValues,
    List<int?> carIdValues,
  ) {
    final len = uniqueKeyValues.length;
    assert(
      carIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], carIdValues[i]]);
    }

    return getAllByIndex(r'uniqueKey_carId', values);
  }

  List<OdometerLog?> getAllByUniqueKeyCarIdSync(
    List<String> uniqueKeyValues,
    List<int?> carIdValues,
  ) {
    final len = uniqueKeyValues.length;
    assert(
      carIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], carIdValues[i]]);
    }

    return getAllByIndexSync(r'uniqueKey_carId', values);
  }

  Future<int> deleteAllByUniqueKeyCarId(
    List<String> uniqueKeyValues,
    List<int?> carIdValues,
  ) {
    final len = uniqueKeyValues.length;
    assert(
      carIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], carIdValues[i]]);
    }

    return deleteAllByIndex(r'uniqueKey_carId', values);
  }

  int deleteAllByUniqueKeyCarIdSync(
    List<String> uniqueKeyValues,
    List<int?> carIdValues,
  ) {
    final len = uniqueKeyValues.length;
    assert(
      carIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uniqueKeyValues[i], carIdValues[i]]);
    }

    return deleteAllByIndexSync(r'uniqueKey_carId', values);
  }

  Future<Id> putByUniqueKeyCarId(OdometerLog object) {
    return putByIndex(r'uniqueKey_carId', object);
  }

  Id putByUniqueKeyCarIdSync(OdometerLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey_carId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKeyCarId(List<OdometerLog> objects) {
    return putAllByIndex(r'uniqueKey_carId', objects);
  }

  List<Id> putAllByUniqueKeyCarIdSync(
    List<OdometerLog> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uniqueKey_carId', objects, saveLinks: saveLinks);
  }
}

extension OdometerLogQueryWhereSort
    on QueryBuilder<OdometerLog, OdometerLog, QWhere> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhere> anyCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'carId'),
      );
    });
  }
}

extension OdometerLogQueryWhere
    on QueryBuilder<OdometerLog, OdometerLog, QWhereClause> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'carId', value: [null]),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'carId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdEqualTo(
    int? carId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'carId', value: [carId]),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdNotEqualTo(
    int? carId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'carId',
                lower: [],
                upper: [carId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'carId',
                lower: [carId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'carId',
                lower: [carId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'carId',
                lower: [],
                upper: [carId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdGreaterThan(
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'carId',
          lower: [carId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdLessThan(
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'carId',
          lower: [],
          upper: [carId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause> carIdBetween(
    int? lowerCarId,
    int? upperCarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'carId',
          lower: [lowerCarId],
          includeLower: includeLower,
          upper: [upperCarId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToAnyCarId(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'uniqueKey_carId',
          value: [uniqueKey],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyNotEqualToAnyCarId(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdIsNull(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'uniqueKey_carId',
          value: [uniqueKey, null],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdIsNotNull(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'uniqueKey_carId',
          lower: [uniqueKey, null],
          includeLower: false,
          upper: [uniqueKey],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyCarIdEqualTo(String uniqueKey, int? carId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'uniqueKey_carId',
          value: [uniqueKey, carId],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdNotEqualTo(String uniqueKey, int? carId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey],
                upper: [uniqueKey, carId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey, carId],
                includeLower: false,
                upper: [uniqueKey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey, carId],
                includeLower: false,
                upper: [uniqueKey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey_carId',
                lower: [uniqueKey],
                upper: [uniqueKey, carId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdGreaterThan(
    String uniqueKey,
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'uniqueKey_carId',
          lower: [uniqueKey, carId],
          includeLower: include,
          upper: [uniqueKey],
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdLessThan(
    String uniqueKey,
    int? carId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'uniqueKey_carId',
          lower: [uniqueKey],
          upper: [uniqueKey, carId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterWhereClause>
  uniqueKeyEqualToCarIdBetween(
    String uniqueKey,
    int? lowerCarId,
    int? upperCarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'uniqueKey_carId',
          lower: [uniqueKey, lowerCarId],
          includeLower: includeLower,
          upper: [uniqueKey, upperCarId],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OdometerLogQueryFilter
    on QueryBuilder<OdometerLog, OdometerLog, QFilterCondition> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'carId'),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  carIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'carId'),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> carIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'carId', value: value),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  carIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'carId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> carIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'carId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> carIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'carId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateString',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateString',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateString', value: ''),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  dateStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateString', value: ''),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> odometerEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'odometer', value: value),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  odometerGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'odometer',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  odometerLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'odometer',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> odometerBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'odometer',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uniqueKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uniqueKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition>
  uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uniqueKey', value: ''),
      );
    });
  }
}

extension OdometerLogQueryObject
    on QueryBuilder<OdometerLog, OdometerLog, QFilterCondition> {}

extension OdometerLogQueryLinks
    on QueryBuilder<OdometerLog, OdometerLog, QFilterCondition> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> car(
    FilterQuery<Car> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'car');
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterFilterCondition> carIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'car', 0, true, 0, true);
    });
  }
}

extension OdometerLogQuerySortBy
    on QueryBuilder<OdometerLog, OdometerLog, QSortBy> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByOdometerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension OdometerLogQuerySortThenBy
    on QueryBuilder<OdometerLog, OdometerLog, QSortThenBy> {
  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByOdometerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.desc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QAfterSortBy> thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension OdometerLogQueryWhereDistinct
    on QueryBuilder<OdometerLog, OdometerLog, QDistinct> {
  QueryBuilder<OdometerLog, OdometerLog, QDistinct> distinctByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carId');
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QDistinct> distinctByDateString({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QDistinct> distinctByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'odometer');
    });
  }

  QueryBuilder<OdometerLog, OdometerLog, QDistinct> distinctByUniqueKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }
}

extension OdometerLogQueryProperty
    on QueryBuilder<OdometerLog, OdometerLog, QQueryProperty> {
  QueryBuilder<OdometerLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OdometerLog, int?, QQueryOperations> carIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carId');
    });
  }

  QueryBuilder<OdometerLog, String, QQueryOperations> dateStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateString');
    });
  }

  QueryBuilder<OdometerLog, int, QQueryOperations> odometerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'odometer');
    });
  }

  QueryBuilder<OdometerLog, String, QQueryOperations> uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }
}
