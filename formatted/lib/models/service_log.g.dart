// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetServiceLogCollection on Isar {
  IsarCollection<ServiceLog> get serviceLogs => this.collection();
}

const ServiceLogSchema = CollectionSchema(
  name: r'ServiceLog',
  id: 965719939908863728,
  properties: {
    r'carId': PropertySchema(id: 0, name: r'carId', type: IsarType.long),
    r'date': PropertySchema(id: 1, name: r'date', type: IsarType.dateTime),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'odometer': PropertySchema(id: 3, name: r'odometer', type: IsarType.long),
  },
  estimateSize: _serviceLogEstimateSize,
  serialize: _serviceLogSerialize,
  deserialize: _serviceLogDeserialize,
  deserializeProp: _serviceLogDeserializeProp,
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
  },
  links: {
    r'car': LinkSchema(
      id: 2018999977178689559,
      name: r'car',
      target: r'Car',
      single: true,
    ),
  },
  embeddedSchemas: {},
  getId: _serviceLogGetId,
  getLinks: _serviceLogGetLinks,
  attach: _serviceLogAttach,
  version: '3.1.0+1',
);

int _serviceLogEstimateSize(
  ServiceLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  return bytesCount;
}

void _serviceLogSerialize(
  ServiceLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.carId);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.odometer);
}

ServiceLog _serviceLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ServiceLog();
  object.carId = reader.readLongOrNull(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.description = reader.readString(offsets[2]);
  object.id = id;
  object.odometer = reader.readLong(offsets[3]);
  return object;
}

P _serviceLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _serviceLogGetId(ServiceLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _serviceLogGetLinks(ServiceLog object) {
  return [object.car];
}

void _serviceLogAttach(IsarCollection<dynamic> col, Id id, ServiceLog object) {
  object.id = id;
  object.car.attach(col, col.isar.collection<Car>(), r'car', id);
}

extension ServiceLogQueryWhereSort
    on QueryBuilder<ServiceLog, ServiceLog, QWhere> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhere> anyCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'carId'),
      );
    });
  }
}

extension ServiceLogQueryWhere
    on QueryBuilder<ServiceLog, ServiceLog, QWhereClause> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'carId', value: [null]),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdIsNotNull() {
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdEqualTo(
    int? carId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'carId', value: [carId]),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdNotEqualTo(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdGreaterThan(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdLessThan(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterWhereClause> carIdBetween(
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
}

extension ServiceLogQueryFilter
    on QueryBuilder<ServiceLog, ServiceLog, QFilterCondition> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'carId'),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'carId'),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'carId', value: value),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdLessThan(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIdBetween(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> dateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> odometerEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'odometer', value: value),
      );
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition>
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> odometerLessThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> odometerBetween(
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
}

extension ServiceLogQueryObject
    on QueryBuilder<ServiceLog, ServiceLog, QFilterCondition> {}

extension ServiceLogQueryLinks
    on QueryBuilder<ServiceLog, ServiceLog, QFilterCondition> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> car(
    FilterQuery<Car> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'car');
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterFilterCondition> carIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'car', 0, true, 0, true);
    });
  }
}

extension ServiceLogQuerySortBy
    on QueryBuilder<ServiceLog, ServiceLog, QSortBy> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> sortByOdometerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.desc);
    });
  }
}

extension ServiceLogQuerySortThenBy
    on QueryBuilder<ServiceLog, ServiceLog, QSortThenBy> {
  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByCarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carId', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.asc);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QAfterSortBy> thenByOdometerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'odometer', Sort.desc);
    });
  }
}

extension ServiceLogQueryWhereDistinct
    on QueryBuilder<ServiceLog, ServiceLog, QDistinct> {
  QueryBuilder<ServiceLog, ServiceLog, QDistinct> distinctByCarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carId');
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QDistinct> distinctByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ServiceLog, ServiceLog, QDistinct> distinctByOdometer() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'odometer');
    });
  }
}

extension ServiceLogQueryProperty
    on QueryBuilder<ServiceLog, ServiceLog, QQueryProperty> {
  QueryBuilder<ServiceLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ServiceLog, int?, QQueryOperations> carIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carId');
    });
  }

  QueryBuilder<ServiceLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ServiceLog, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ServiceLog, int, QQueryOperations> odometerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'odometer');
    });
  }
}
