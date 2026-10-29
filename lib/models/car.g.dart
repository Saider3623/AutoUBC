// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCarCollection on Isar {
  IsarCollection<Car> get cars => this.collection();
}

const CarSchema = CollectionSchema(
  name: r'Car',
  id: -8398112620925430914,
  properties: {
    r'driverName': PropertySchema(
      id: 0,
      name: r'driverName',
      type: IsarType.string,
    ),
    r'fuelTypes': PropertySchema(
      id: 1,
      name: r'fuelTypes',
      type: IsarType.stringList,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'plateNumber': PropertySchema(
      id: 3,
      name: r'plateNumber',
      type: IsarType.string,
    ),
    r'selectedFuelTypesForConsumption': PropertySchema(
      id: 4,
      name: r'selectedFuelTypesForConsumption',
      type: IsarType.stringList,
    )
  },
  estimateSize: _carEstimateSize,
  serialize: _carSerialize,
  deserialize: _carDeserialize,
  deserializeProp: _carDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _carGetId,
  getLinks: _carGetLinks,
  attach: _carAttach,
  version: '3.1.0+1',
);

int _carEstimateSize(
  Car object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.driverName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.fuelTypes;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.plateNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.selectedFuelTypesForConsumption;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _carSerialize(
  Car object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.driverName);
  writer.writeStringList(offsets[1], object.fuelTypes);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.plateNumber);
  writer.writeStringList(offsets[4], object.selectedFuelTypesForConsumption);
}

Car _carDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Car();
  object.driverName = reader.readStringOrNull(offsets[0]);
  object.fuelTypes = reader.readStringList(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.plateNumber = reader.readStringOrNull(offsets[3]);
  object.selectedFuelTypesForConsumption = reader.readStringList(offsets[4]);
  return object;
}

P _carDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _carGetId(Car object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _carGetLinks(Car object) {
  return [];
}

void _carAttach(IsarCollection<dynamic> col, Id id, Car object) {
  object.id = id;
}

extension CarQueryWhereSort on QueryBuilder<Car, Car, QWhere> {
  QueryBuilder<Car, Car, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CarQueryWhere on QueryBuilder<Car, Car, QWhereClause> {
  QueryBuilder<Car, Car, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Car, Car, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Car, Car, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Car, Car, QAfterWhereClause> idBetween(
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
}

extension CarQueryFilter on QueryBuilder<Car, Car, QFilterCondition> {
  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'driverName',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'driverName',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'driverName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'driverName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'driverName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'driverName',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> driverNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'driverName',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fuelTypes',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fuelTypes',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fuelTypes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fuelTypes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fuelTypes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelTypes',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fuelTypes',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> fuelTypesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fuelTypes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Car, Car, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Car, Car, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Car, Car, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plateNumber',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plateNumber',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plateNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plateNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plateNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plateNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition> plateNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plateNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedFuelTypesForConsumption',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedFuelTypesForConsumption',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedFuelTypesForConsumption',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedFuelTypesForConsumption',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedFuelTypesForConsumption',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedFuelTypesForConsumption',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedFuelTypesForConsumption',
        value: '',
      ));
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Car, Car, QAfterFilterCondition>
      selectedFuelTypesForConsumptionLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'selectedFuelTypesForConsumption',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension CarQueryObject on QueryBuilder<Car, Car, QFilterCondition> {}

extension CarQueryLinks on QueryBuilder<Car, Car, QFilterCondition> {}

extension CarQuerySortBy on QueryBuilder<Car, Car, QSortBy> {
  QueryBuilder<Car, Car, QAfterSortBy> sortByDriverName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'driverName', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> sortByDriverNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'driverName', Sort.desc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> sortByPlateNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plateNumber', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> sortByPlateNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plateNumber', Sort.desc);
    });
  }
}

extension CarQuerySortThenBy on QueryBuilder<Car, Car, QSortThenBy> {
  QueryBuilder<Car, Car, QAfterSortBy> thenByDriverName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'driverName', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByDriverNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'driverName', Sort.desc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByPlateNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plateNumber', Sort.asc);
    });
  }

  QueryBuilder<Car, Car, QAfterSortBy> thenByPlateNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plateNumber', Sort.desc);
    });
  }
}

extension CarQueryWhereDistinct on QueryBuilder<Car, Car, QDistinct> {
  QueryBuilder<Car, Car, QDistinct> distinctByDriverName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'driverName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Car, Car, QDistinct> distinctByFuelTypes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fuelTypes');
    });
  }

  QueryBuilder<Car, Car, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Car, Car, QDistinct> distinctByPlateNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plateNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Car, Car, QDistinct>
      distinctBySelectedFuelTypesForConsumption() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedFuelTypesForConsumption');
    });
  }
}

extension CarQueryProperty on QueryBuilder<Car, Car, QQueryProperty> {
  QueryBuilder<Car, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Car, String?, QQueryOperations> driverNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'driverName');
    });
  }

  QueryBuilder<Car, List<String>?, QQueryOperations> fuelTypesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fuelTypes');
    });
  }

  QueryBuilder<Car, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Car, String?, QQueryOperations> plateNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plateNumber');
    });
  }

  QueryBuilder<Car, List<String>?, QQueryOperations>
      selectedFuelTypesForConsumptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedFuelTypesForConsumption');
    });
  }
}
