// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoresTable extends Stores with TableInfo<$StoresTable, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationalHoursMeta = const VerificationMeta(
    'operationalHours',
  );
  @override
  late final GeneratedColumn<String> operationalHours = GeneratedColumn<String>(
    'operational_hours',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftDurationHoursMeta =
      const VerificationMeta('shiftDurationHours');
  @override
  late final GeneratedColumn<int> shiftDurationHours = GeneratedColumn<int>(
    'shift_duration_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9),
  );
  static const VerificationMeta _shiftStartTimeMeta = const VerificationMeta(
    'shiftStartTime',
  );
  @override
  late final GeneratedColumn<String> shiftStartTime = GeneratedColumn<String>(
    'shift_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('09:00:00'),
  );
  static const VerificationMeta _isAttendanceEnabledMeta =
      const VerificationMeta('isAttendanceEnabled');
  @override
  late final GeneratedColumn<bool> isAttendanceEnabled = GeneratedColumn<bool>(
    'is_attendance_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_attendance_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _adminNameMeta = const VerificationMeta(
    'adminName',
  );
  @override
  late final GeneratedColumn<String> adminName = GeneratedColumn<String>(
    'admin_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adminAvatarMeta = const VerificationMeta(
    'adminAvatar',
  );
  @override
  late final GeneratedColumn<String> adminAvatar = GeneratedColumn<String>(
    'admin_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    email,
    phoneNumber,
    logoUrl,
    description,
    operationalHours,
    shiftDurationHours,
    shiftStartTime,
    isAttendanceEnabled,
    adminName,
    adminAvatar,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Store> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('operational_hours')) {
      context.handle(
        _operationalHoursMeta,
        operationalHours.isAcceptableOrUnknown(
          data['operational_hours']!,
          _operationalHoursMeta,
        ),
      );
    }
    if (data.containsKey('shift_duration_hours')) {
      context.handle(
        _shiftDurationHoursMeta,
        shiftDurationHours.isAcceptableOrUnknown(
          data['shift_duration_hours']!,
          _shiftDurationHoursMeta,
        ),
      );
    }
    if (data.containsKey('shift_start_time')) {
      context.handle(
        _shiftStartTimeMeta,
        shiftStartTime.isAcceptableOrUnknown(
          data['shift_start_time']!,
          _shiftStartTimeMeta,
        ),
      );
    }
    if (data.containsKey('is_attendance_enabled')) {
      context.handle(
        _isAttendanceEnabledMeta,
        isAttendanceEnabled.isAcceptableOrUnknown(
          data['is_attendance_enabled']!,
          _isAttendanceEnabledMeta,
        ),
      );
    }
    if (data.containsKey('admin_name')) {
      context.handle(
        _adminNameMeta,
        adminName.isAcceptableOrUnknown(data['admin_name']!, _adminNameMeta),
      );
    }
    if (data.containsKey('admin_avatar')) {
      context.handle(
        _adminAvatarMeta,
        adminAvatar.isAcceptableOrUnknown(
          data['admin_avatar']!,
          _adminAvatarMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Store map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Store(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      operationalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operational_hours'],
      ),
      shiftDurationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shift_duration_hours'],
      )!,
      shiftStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_start_time'],
      )!,
      isAttendanceEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_attendance_enabled'],
      )!,
      adminName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_name'],
      ),
      adminAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_avatar'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $StoresTable createAlias(String alias) {
    return $StoresTable(attachedDatabase, alias);
  }
}

class Store extends DataClass implements Insertable<Store> {
  final String id;
  final String? name;
  final String? address;
  final String? email;
  final String? phoneNumber;
  final String? logoUrl;
  final String? description;
  final String? operationalHours;
  final int shiftDurationHours;
  final String shiftStartTime;
  final bool isAttendanceEnabled;
  final String? adminName;
  final String? adminAvatar;
  final DateTime? createdAt;
  const Store({
    required this.id,
    this.name,
    this.address,
    this.email,
    this.phoneNumber,
    this.logoUrl,
    this.description,
    this.operationalHours,
    required this.shiftDurationHours,
    required this.shiftStartTime,
    required this.isAttendanceEnabled,
    this.adminName,
    this.adminAvatar,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || operationalHours != null) {
      map['operational_hours'] = Variable<String>(operationalHours);
    }
    map['shift_duration_hours'] = Variable<int>(shiftDurationHours);
    map['shift_start_time'] = Variable<String>(shiftStartTime);
    map['is_attendance_enabled'] = Variable<bool>(isAttendanceEnabled);
    if (!nullToAbsent || adminName != null) {
      map['admin_name'] = Variable<String>(adminName);
    }
    if (!nullToAbsent || adminAvatar != null) {
      map['admin_avatar'] = Variable<String>(adminAvatar);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      operationalHours: operationalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(operationalHours),
      shiftDurationHours: Value(shiftDurationHours),
      shiftStartTime: Value(shiftStartTime),
      isAttendanceEnabled: Value(isAttendanceEnabled),
      adminName: adminName == null && nullToAbsent
          ? const Value.absent()
          : Value(adminName),
      adminAvatar: adminAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(adminAvatar),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Store.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Store(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      email: serializer.fromJson<String?>(json['email']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      description: serializer.fromJson<String?>(json['description']),
      operationalHours: serializer.fromJson<String?>(json['operationalHours']),
      shiftDurationHours: serializer.fromJson<int>(json['shiftDurationHours']),
      shiftStartTime: serializer.fromJson<String>(json['shiftStartTime']),
      isAttendanceEnabled: serializer.fromJson<bool>(
        json['isAttendanceEnabled'],
      ),
      adminName: serializer.fromJson<String?>(json['adminName']),
      adminAvatar: serializer.fromJson<String?>(json['adminAvatar']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'address': serializer.toJson<String?>(address),
      'email': serializer.toJson<String?>(email),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'description': serializer.toJson<String?>(description),
      'operationalHours': serializer.toJson<String?>(operationalHours),
      'shiftDurationHours': serializer.toJson<int>(shiftDurationHours),
      'shiftStartTime': serializer.toJson<String>(shiftStartTime),
      'isAttendanceEnabled': serializer.toJson<bool>(isAttendanceEnabled),
      'adminName': serializer.toJson<String?>(adminName),
      'adminAvatar': serializer.toJson<String?>(adminAvatar),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Store copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> operationalHours = const Value.absent(),
    int? shiftDurationHours,
    String? shiftStartTime,
    bool? isAttendanceEnabled,
    Value<String?> adminName = const Value.absent(),
    Value<String?> adminAvatar = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Store(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    address: address.present ? address.value : this.address,
    email: email.present ? email.value : this.email,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    description: description.present ? description.value : this.description,
    operationalHours: operationalHours.present
        ? operationalHours.value
        : this.operationalHours,
    shiftDurationHours: shiftDurationHours ?? this.shiftDurationHours,
    shiftStartTime: shiftStartTime ?? this.shiftStartTime,
    isAttendanceEnabled: isAttendanceEnabled ?? this.isAttendanceEnabled,
    adminName: adminName.present ? adminName.value : this.adminName,
    adminAvatar: adminAvatar.present ? adminAvatar.value : this.adminAvatar,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      operationalHours: data.operationalHours.present
          ? data.operationalHours.value
          : this.operationalHours,
      shiftDurationHours: data.shiftDurationHours.present
          ? data.shiftDurationHours.value
          : this.shiftDurationHours,
      shiftStartTime: data.shiftStartTime.present
          ? data.shiftStartTime.value
          : this.shiftStartTime,
      isAttendanceEnabled: data.isAttendanceEnabled.present
          ? data.isAttendanceEnabled.value
          : this.isAttendanceEnabled,
      adminName: data.adminName.present ? data.adminName.value : this.adminName,
      adminAvatar: data.adminAvatar.present
          ? data.adminAvatar.value
          : this.adminAvatar,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('description: $description, ')
          ..write('operationalHours: $operationalHours, ')
          ..write('shiftDurationHours: $shiftDurationHours, ')
          ..write('shiftStartTime: $shiftStartTime, ')
          ..write('isAttendanceEnabled: $isAttendanceEnabled, ')
          ..write('adminName: $adminName, ')
          ..write('adminAvatar: $adminAvatar, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    email,
    phoneNumber,
    logoUrl,
    description,
    operationalHours,
    shiftDurationHours,
    shiftStartTime,
    isAttendanceEnabled,
    adminName,
    adminAvatar,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber &&
          other.logoUrl == this.logoUrl &&
          other.description == this.description &&
          other.operationalHours == this.operationalHours &&
          other.shiftDurationHours == this.shiftDurationHours &&
          other.shiftStartTime == this.shiftStartTime &&
          other.isAttendanceEnabled == this.isAttendanceEnabled &&
          other.adminName == this.adminName &&
          other.adminAvatar == this.adminAvatar &&
          other.createdAt == this.createdAt);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> address;
  final Value<String?> email;
  final Value<String?> phoneNumber;
  final Value<String?> logoUrl;
  final Value<String?> description;
  final Value<String?> operationalHours;
  final Value<int> shiftDurationHours;
  final Value<String> shiftStartTime;
  final Value<bool> isAttendanceEnabled;
  final Value<String?> adminName;
  final Value<String?> adminAvatar;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.operationalHours = const Value.absent(),
    this.shiftDurationHours = const Value.absent(),
    this.shiftStartTime = const Value.absent(),
    this.isAttendanceEnabled = const Value.absent(),
    this.adminName = const Value.absent(),
    this.adminAvatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.operationalHours = const Value.absent(),
    this.shiftDurationHours = const Value.absent(),
    this.shiftStartTime = const Value.absent(),
    this.isAttendanceEnabled = const Value.absent(),
    this.adminName = const Value.absent(),
    this.adminAvatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Store> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<String>? logoUrl,
    Expression<String>? description,
    Expression<String>? operationalHours,
    Expression<int>? shiftDurationHours,
    Expression<String>? shiftStartTime,
    Expression<bool>? isAttendanceEnabled,
    Expression<String>? adminName,
    Expression<String>? adminAvatar,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (description != null) 'description': description,
      if (operationalHours != null) 'operational_hours': operationalHours,
      if (shiftDurationHours != null)
        'shift_duration_hours': shiftDurationHours,
      if (shiftStartTime != null) 'shift_start_time': shiftStartTime,
      if (isAttendanceEnabled != null)
        'is_attendance_enabled': isAttendanceEnabled,
      if (adminName != null) 'admin_name': adminName,
      if (adminAvatar != null) 'admin_avatar': adminAvatar,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? address,
    Value<String?>? email,
    Value<String?>? phoneNumber,
    Value<String?>? logoUrl,
    Value<String?>? description,
    Value<String?>? operationalHours,
    Value<int>? shiftDurationHours,
    Value<String>? shiftStartTime,
    Value<bool>? isAttendanceEnabled,
    Value<String?>? adminName,
    Value<String?>? adminAvatar,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      operationalHours: operationalHours ?? this.operationalHours,
      shiftDurationHours: shiftDurationHours ?? this.shiftDurationHours,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      isAttendanceEnabled: isAttendanceEnabled ?? this.isAttendanceEnabled,
      adminName: adminName ?? this.adminName,
      adminAvatar: adminAvatar ?? this.adminAvatar,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (operationalHours.present) {
      map['operational_hours'] = Variable<String>(operationalHours.value);
    }
    if (shiftDurationHours.present) {
      map['shift_duration_hours'] = Variable<int>(shiftDurationHours.value);
    }
    if (shiftStartTime.present) {
      map['shift_start_time'] = Variable<String>(shiftStartTime.value);
    }
    if (isAttendanceEnabled.present) {
      map['is_attendance_enabled'] = Variable<bool>(isAttendanceEnabled.value);
    }
    if (adminName.present) {
      map['admin_name'] = Variable<String>(adminName.value);
    }
    if (adminAvatar.present) {
      map['admin_avatar'] = Variable<String>(adminAvatar.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('description: $description, ')
          ..write('operationalHours: $operationalHours, ')
          ..write('shiftDurationHours: $shiftDurationHours, ')
          ..write('shiftStartTime: $shiftStartTime, ')
          ..write('isAttendanceEnabled: $isAttendanceEnabled, ')
          ..write('adminName: $adminName, ')
          ..write('adminAvatar: $adminAvatar, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('staff'),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _permissionsMeta = const VerificationMeta(
    'permissions',
  );
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    password,
    fullName,
    role,
    storeId,
    createdAt,
    lastUpdated,
    avatarUrl,
    permissions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('permissions')) {
      context.handle(
        _permissionsMeta,
        permissions.isAcceptableOrUnknown(
          data['permissions']!,
          _permissionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      permissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String? email;
  final String? password;
  final String? fullName;
  final String role;
  final String? storeId;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final String? avatarUrl;
  final String? permissions;
  const Profile({
    required this.id,
    this.email,
    this.password,
    this.fullName,
    required this.role,
    this.storeId,
    this.createdAt,
    this.lastUpdated,
    this.avatarUrl,
    this.permissions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || permissions != null) {
      map['permissions'] = Variable<String>(permissions);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      role: Value(role),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      permissions: permissions == null && nullToAbsent
          ? const Value.absent()
          : Value(permissions),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String?>(json['email']),
      password: serializer.fromJson<String?>(json['password']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      permissions: serializer.fromJson<String?>(json['permissions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String?>(email),
      'password': serializer.toJson<String?>(password),
      'fullName': serializer.toJson<String?>(fullName),
      'role': serializer.toJson<String>(role),
      'storeId': serializer.toJson<String?>(storeId),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'permissions': serializer.toJson<String?>(permissions),
    };
  }

  Profile copyWith({
    String? id,
    Value<String?> email = const Value.absent(),
    Value<String?> password = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    String? role,
    Value<String?> storeId = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> lastUpdated = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> permissions = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    email: email.present ? email.value : this.email,
    password: password.present ? password.value : this.password,
    fullName: fullName.present ? fullName.value : this.fullName,
    role: role ?? this.role,
    storeId: storeId.present ? storeId.value : this.storeId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    permissions: permissions.present ? permissions.value : this.permissions,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      password: data.password.present ? data.password.value : this.password,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    password,
    fullName,
    role,
    storeId,
    createdAt,
    lastUpdated,
    avatarUrl,
    permissions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.email == this.email &&
          other.password == this.password &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.storeId == this.storeId &&
          other.createdAt == this.createdAt &&
          other.lastUpdated == this.lastUpdated &&
          other.avatarUrl == this.avatarUrl &&
          other.permissions == this.permissions);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String?> email;
  final Value<String?> password;
  final Value<String?> fullName;
  final Value<String> role;
  final Value<String?> storeId;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> lastUpdated;
  final Value<String?> avatarUrl;
  final Value<String?> permissions;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.password = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.storeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    this.email = const Value.absent(),
    this.password = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.storeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? password,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<String>? storeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUpdated,
    Expression<String>? avatarUrl,
    Expression<String>? permissions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (storeId != null) 'store_id': storeId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (permissions != null) 'permissions': permissions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? email,
    Value<String?>? password,
    Value<String?>? fullName,
    Value<String>? role,
    Value<String?>? storeId,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? lastUpdated,
    Value<String?>? avatarUrl,
    Value<String?>? permissions,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      permissions: permissions ?? this.permissions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('permissions: $permissions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconUrl,
    storeId,
    createdAt,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String? name;
  final String? iconUrl;
  final String? storeId;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  const Category({
    required this.id,
    this.name,
    this.iconUrl,
    this.storeId,
    this.createdAt,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'storeId': serializer.toJson<String?>(storeId),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Category copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    storeId: storeId.present ? storeId.value : this.storeId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconUrl, storeId, createdAt, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconUrl == this.iconUrl &&
          other.storeId == this.storeId &&
          other.createdAt == this.createdAt &&
          other.lastUpdated == this.lastUpdated);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> iconUrl;
  final Value<String?> storeId;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.storeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.storeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<String>? storeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (storeId != null) 'store_id': storeId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? iconUrl,
    Value<String?>? storeId,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? lastUpdated,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta(
    'buyPrice',
  );
  @override
  late final GeneratedColumn<double> buyPrice = GeneratedColumn<double>(
    'buy_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basePriceMeta = const VerificationMeta(
    'basePrice',
  );
  @override
  late final GeneratedColumn<double> basePrice = GeneratedColumn<double>(
    'base_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salePriceMeta = const VerificationMeta(
    'salePrice',
  );
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
    'sale_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wholesalePricesJsonMeta =
      const VerificationMeta('wholesalePricesJson');
  @override
  late final GeneratedColumn<String> wholesalePricesJson =
      GeneratedColumn<String>(
        'wholesale_prices_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stockQuantityMeta = const VerificationMeta(
    'stockQuantity',
  );
  @override
  late final GeneratedColumn<double> stockQuantity = GeneratedColumn<double>(
    'stock_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isStockManagedMeta = const VerificationMeta(
    'isStockManaged',
  );
  @override
  late final GeneratedColumn<bool> isStockManaged = GeneratedColumn<bool>(
    'is_stock_managed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stock_managed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    buyPrice,
    basePrice,
    salePrice,
    wholesalePricesJson,
    stockQuantity,
    isStockManaged,
    isAvailable,
    sku,
    unitId,
    description,
    imageUrl,
    categoryId,
    storeId,
    isDeleted,
    createdAt,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('buy_price')) {
      context.handle(
        _buyPriceMeta,
        buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta),
      );
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
      );
    }
    if (data.containsKey('sale_price')) {
      context.handle(
        _salePriceMeta,
        salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta),
      );
    }
    if (data.containsKey('wholesale_prices_json')) {
      context.handle(
        _wholesalePricesJsonMeta,
        wholesalePricesJson.isAcceptableOrUnknown(
          data['wholesale_prices_json']!,
          _wholesalePricesJsonMeta,
        ),
      );
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
        _stockQuantityMeta,
        stockQuantity.isAcceptableOrUnknown(
          data['stock_quantity']!,
          _stockQuantityMeta,
        ),
      );
    }
    if (data.containsKey('is_stock_managed')) {
      context.handle(
        _isStockManagedMeta,
        isStockManaged.isAcceptableOrUnknown(
          data['is_stock_managed']!,
          _isStockManagedMeta,
        ),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      buyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_price'],
      ),
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_price'],
      ),
      salePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_price'],
      ),
      wholesalePricesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wholesale_prices_json'],
      ),
      stockQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_quantity'],
      ),
      isStockManaged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stock_managed'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String? name;
  final double? buyPrice;
  final double? basePrice;
  final double? salePrice;
  final String? wholesalePricesJson;
  final double? stockQuantity;
  final bool isStockManaged;
  final bool isAvailable;
  final String? sku;
  final String? unitId;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final String? storeId;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  const Product({
    required this.id,
    this.name,
    this.buyPrice,
    this.basePrice,
    this.salePrice,
    this.wholesalePricesJson,
    this.stockQuantity,
    required this.isStockManaged,
    required this.isAvailable,
    this.sku,
    this.unitId,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.storeId,
    required this.isDeleted,
    this.createdAt,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || buyPrice != null) {
      map['buy_price'] = Variable<double>(buyPrice);
    }
    if (!nullToAbsent || basePrice != null) {
      map['base_price'] = Variable<double>(basePrice);
    }
    if (!nullToAbsent || salePrice != null) {
      map['sale_price'] = Variable<double>(salePrice);
    }
    if (!nullToAbsent || wholesalePricesJson != null) {
      map['wholesale_prices_json'] = Variable<String>(wholesalePricesJson);
    }
    if (!nullToAbsent || stockQuantity != null) {
      map['stock_quantity'] = Variable<double>(stockQuantity);
    }
    map['is_stock_managed'] = Variable<bool>(isStockManaged);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      buyPrice: buyPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(buyPrice),
      basePrice: basePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(basePrice),
      salePrice: salePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(salePrice),
      wholesalePricesJson: wholesalePricesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(wholesalePricesJson),
      stockQuantity: stockQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(stockQuantity),
      isStockManaged: Value(isStockManaged),
      isAvailable: Value(isAvailable),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      unitId: unitId == null && nullToAbsent
          ? const Value.absent()
          : Value(unitId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      isDeleted: Value(isDeleted),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      buyPrice: serializer.fromJson<double?>(json['buyPrice']),
      basePrice: serializer.fromJson<double?>(json['basePrice']),
      salePrice: serializer.fromJson<double?>(json['salePrice']),
      wholesalePricesJson: serializer.fromJson<String?>(
        json['wholesalePricesJson'],
      ),
      stockQuantity: serializer.fromJson<double?>(json['stockQuantity']),
      isStockManaged: serializer.fromJson<bool>(json['isStockManaged']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      sku: serializer.fromJson<String?>(json['sku']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'buyPrice': serializer.toJson<double?>(buyPrice),
      'basePrice': serializer.toJson<double?>(basePrice),
      'salePrice': serializer.toJson<double?>(salePrice),
      'wholesalePricesJson': serializer.toJson<String?>(wholesalePricesJson),
      'stockQuantity': serializer.toJson<double?>(stockQuantity),
      'isStockManaged': serializer.toJson<bool>(isStockManaged),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'sku': serializer.toJson<String?>(sku),
      'unitId': serializer.toJson<String?>(unitId),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'categoryId': serializer.toJson<String?>(categoryId),
      'storeId': serializer.toJson<String?>(storeId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Product copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<double?> buyPrice = const Value.absent(),
    Value<double?> basePrice = const Value.absent(),
    Value<double?> salePrice = const Value.absent(),
    Value<String?> wholesalePricesJson = const Value.absent(),
    Value<double?> stockQuantity = const Value.absent(),
    bool? isStockManaged,
    bool? isAvailable,
    Value<String?> sku = const Value.absent(),
    Value<String?> unitId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    buyPrice: buyPrice.present ? buyPrice.value : this.buyPrice,
    basePrice: basePrice.present ? basePrice.value : this.basePrice,
    salePrice: salePrice.present ? salePrice.value : this.salePrice,
    wholesalePricesJson: wholesalePricesJson.present
        ? wholesalePricesJson.value
        : this.wholesalePricesJson,
    stockQuantity: stockQuantity.present
        ? stockQuantity.value
        : this.stockQuantity,
    isStockManaged: isStockManaged ?? this.isStockManaged,
    isAvailable: isAvailable ?? this.isAvailable,
    sku: sku.present ? sku.value : this.sku,
    unitId: unitId.present ? unitId.value : this.unitId,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    storeId: storeId.present ? storeId.value : this.storeId,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      wholesalePricesJson: data.wholesalePricesJson.present
          ? data.wholesalePricesJson.value
          : this.wholesalePricesJson,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      isStockManaged: data.isStockManaged.present
          ? data.isStockManaged.value
          : this.isStockManaged,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      sku: data.sku.present ? data.sku.value : this.sku,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('basePrice: $basePrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('wholesalePricesJson: $wholesalePricesJson, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('isStockManaged: $isStockManaged, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('sku: $sku, ')
          ..write('unitId: $unitId, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('categoryId: $categoryId, ')
          ..write('storeId: $storeId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    buyPrice,
    basePrice,
    salePrice,
    wholesalePricesJson,
    stockQuantity,
    isStockManaged,
    isAvailable,
    sku,
    unitId,
    description,
    imageUrl,
    categoryId,
    storeId,
    isDeleted,
    createdAt,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.buyPrice == this.buyPrice &&
          other.basePrice == this.basePrice &&
          other.salePrice == this.salePrice &&
          other.wholesalePricesJson == this.wholesalePricesJson &&
          other.stockQuantity == this.stockQuantity &&
          other.isStockManaged == this.isStockManaged &&
          other.isAvailable == this.isAvailable &&
          other.sku == this.sku &&
          other.unitId == this.unitId &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.categoryId == this.categoryId &&
          other.storeId == this.storeId &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.lastUpdated == this.lastUpdated);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String?> name;
  final Value<double?> buyPrice;
  final Value<double?> basePrice;
  final Value<double?> salePrice;
  final Value<String?> wholesalePricesJson;
  final Value<double?> stockQuantity;
  final Value<bool> isStockManaged;
  final Value<bool> isAvailable;
  final Value<String?> sku;
  final Value<String?> unitId;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<String?> categoryId;
  final Value<String?> storeId;
  final Value<bool> isDeleted;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.wholesalePricesJson = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.isStockManaged = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.sku = const Value.absent(),
    this.unitId = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.wholesalePricesJson = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.isStockManaged = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.sku = const Value.absent(),
    this.unitId = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? buyPrice,
    Expression<double>? basePrice,
    Expression<double>? salePrice,
    Expression<String>? wholesalePricesJson,
    Expression<double>? stockQuantity,
    Expression<bool>? isStockManaged,
    Expression<bool>? isAvailable,
    Expression<String>? sku,
    Expression<String>? unitId,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? categoryId,
    Expression<String>? storeId,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (basePrice != null) 'base_price': basePrice,
      if (salePrice != null) 'sale_price': salePrice,
      if (wholesalePricesJson != null)
        'wholesale_prices_json': wholesalePricesJson,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (isStockManaged != null) 'is_stock_managed': isStockManaged,
      if (isAvailable != null) 'is_available': isAvailable,
      if (sku != null) 'sku': sku,
      if (unitId != null) 'unit_id': unitId,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (categoryId != null) 'category_id': categoryId,
      if (storeId != null) 'store_id': storeId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<double?>? buyPrice,
    Value<double?>? basePrice,
    Value<double?>? salePrice,
    Value<String?>? wholesalePricesJson,
    Value<double?>? stockQuantity,
    Value<bool>? isStockManaged,
    Value<bool>? isAvailable,
    Value<String?>? sku,
    Value<String?>? unitId,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<String?>? categoryId,
    Value<String?>? storeId,
    Value<bool>? isDeleted,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? lastUpdated,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      basePrice: basePrice ?? this.basePrice,
      salePrice: salePrice ?? this.salePrice,
      wholesalePricesJson: wholesalePricesJson ?? this.wholesalePricesJson,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isStockManaged: isStockManaged ?? this.isStockManaged,
      isAvailable: isAvailable ?? this.isAvailable,
      sku: sku ?? this.sku,
      unitId: unitId ?? this.unitId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      storeId: storeId ?? this.storeId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<double>(buyPrice.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<double>(basePrice.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (wholesalePricesJson.present) {
      map['wholesale_prices_json'] = Variable<String>(
        wholesalePricesJson.value,
      );
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<double>(stockQuantity.value);
    }
    if (isStockManaged.present) {
      map['is_stock_managed'] = Variable<bool>(isStockManaged.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('basePrice: $basePrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('wholesalePricesJson: $wholesalePricesJson, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('isStockManaged: $isStockManaged, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('sku: $sku, ')
          ..write('unitId: $unitId, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('categoryId: $categoryId, ')
          ..write('storeId: $storeId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductOptionsTable extends ProductOptions
    with TableInfo<$ProductOptionsTable, ProductOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionNameMeta = const VerificationMeta(
    'optionName',
  );
  @override
  late final GeneratedColumn<String> optionName = GeneratedColumn<String>(
    'option_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'is_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    storeId,
    optionName,
    isRequired,
    createdAt,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('option_name')) {
      context.handle(
        _optionNameMeta,
        optionName.isAcceptableOrUnknown(data['option_name']!, _optionNameMeta),
      );
    }
    if (data.containsKey('is_required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['is_required']!, _isRequiredMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductOption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      optionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_name'],
      ),
      isRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $ProductOptionsTable createAlias(String alias) {
    return $ProductOptionsTable(attachedDatabase, alias);
  }
}

class ProductOption extends DataClass implements Insertable<ProductOption> {
  final String id;
  final String? productId;
  final String? storeId;
  final String? optionName;
  final bool isRequired;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  const ProductOption({
    required this.id,
    this.productId,
    this.storeId,
    this.optionName,
    required this.isRequired,
    this.createdAt,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || optionName != null) {
      map['option_name'] = Variable<String>(optionName);
    }
    map['is_required'] = Variable<bool>(isRequired);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  ProductOptionsCompanion toCompanion(bool nullToAbsent) {
    return ProductOptionsCompanion(
      id: Value(id),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      optionName: optionName == null && nullToAbsent
          ? const Value.absent()
          : Value(optionName),
      isRequired: Value(isRequired),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory ProductOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductOption(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String?>(json['productId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      optionName: serializer.fromJson<String?>(json['optionName']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String?>(productId),
      'storeId': serializer.toJson<String?>(storeId),
      'optionName': serializer.toJson<String?>(optionName),
      'isRequired': serializer.toJson<bool>(isRequired),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  ProductOption copyWith({
    String? id,
    Value<String?> productId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<String?> optionName = const Value.absent(),
    bool? isRequired,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => ProductOption(
    id: id ?? this.id,
    productId: productId.present ? productId.value : this.productId,
    storeId: storeId.present ? storeId.value : this.storeId,
    optionName: optionName.present ? optionName.value : this.optionName,
    isRequired: isRequired ?? this.isRequired,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  ProductOption copyWithCompanion(ProductOptionsCompanion data) {
    return ProductOption(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      optionName: data.optionName.present
          ? data.optionName.value
          : this.optionName,
      isRequired: data.isRequired.present
          ? data.isRequired.value
          : this.isRequired,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductOption(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('optionName: $optionName, ')
          ..write('isRequired: $isRequired, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    storeId,
    optionName,
    isRequired,
    createdAt,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductOption &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.storeId == this.storeId &&
          other.optionName == this.optionName &&
          other.isRequired == this.isRequired &&
          other.createdAt == this.createdAt &&
          other.lastUpdated == this.lastUpdated);
}

class ProductOptionsCompanion extends UpdateCompanion<ProductOption> {
  final Value<String> id;
  final Value<String?> productId;
  final Value<String?> storeId;
  final Value<String?> optionName;
  final Value<bool> isRequired;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const ProductOptionsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.optionName = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductOptionsCompanion.insert({
    required String id,
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.optionName = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ProductOption> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? storeId,
    Expression<String>? optionName,
    Expression<bool>? isRequired,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (storeId != null) 'store_id': storeId,
      if (optionName != null) 'option_name': optionName,
      if (isRequired != null) 'is_required': isRequired,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductOptionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? productId,
    Value<String?>? storeId,
    Value<String?>? optionName,
    Value<bool>? isRequired,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? lastUpdated,
    Value<int>? rowid,
  }) {
    return ProductOptionsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      optionName: optionName ?? this.optionName,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (optionName.present) {
      map['option_name'] = Variable<String>(optionName.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('optionName: $optionName, ')
          ..write('isRequired: $isRequired, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductOptionValuesTable extends ProductOptionValues
    with TableInfo<$ProductOptionValuesTable, ProductOptionValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductOptionValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionIdMeta = const VerificationMeta(
    'optionId',
  );
  @override
  late final GeneratedColumn<String> optionId = GeneratedColumn<String>(
    'option_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueNameMeta = const VerificationMeta(
    'valueName',
  );
  @override
  late final GeneratedColumn<String> valueName = GeneratedColumn<String>(
    'value_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceAdjustmentMeta = const VerificationMeta(
    'priceAdjustment',
  );
  @override
  late final GeneratedColumn<double> priceAdjustment = GeneratedColumn<double>(
    'price_adjustment',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockMultiplierMeta = const VerificationMeta(
    'stockMultiplier',
  );
  @override
  late final GeneratedColumn<double> stockMultiplier = GeneratedColumn<double>(
    'stock_multiplier',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    optionId,
    valueName,
    priceAdjustment,
    stockMultiplier,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_option_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductOptionValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('option_id')) {
      context.handle(
        _optionIdMeta,
        optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta),
      );
    }
    if (data.containsKey('value_name')) {
      context.handle(
        _valueNameMeta,
        valueName.isAcceptableOrUnknown(data['value_name']!, _valueNameMeta),
      );
    }
    if (data.containsKey('price_adjustment')) {
      context.handle(
        _priceAdjustmentMeta,
        priceAdjustment.isAcceptableOrUnknown(
          data['price_adjustment']!,
          _priceAdjustmentMeta,
        ),
      );
    }
    if (data.containsKey('stock_multiplier')) {
      context.handle(
        _stockMultiplierMeta,
        stockMultiplier.isAcceptableOrUnknown(
          data['stock_multiplier']!,
          _stockMultiplierMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductOptionValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductOptionValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      optionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_id'],
      ),
      valueName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_name'],
      ),
      priceAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_adjustment'],
      ),
      stockMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_multiplier'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ProductOptionValuesTable createAlias(String alias) {
    return $ProductOptionValuesTable(attachedDatabase, alias);
  }
}

class ProductOptionValue extends DataClass
    implements Insertable<ProductOptionValue> {
  final String id;
  final String? optionId;
  final String? valueName;
  final double? priceAdjustment;
  final double stockMultiplier;
  final DateTime? createdAt;
  const ProductOptionValue({
    required this.id,
    this.optionId,
    this.valueName,
    this.priceAdjustment,
    required this.stockMultiplier,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || optionId != null) {
      map['option_id'] = Variable<String>(optionId);
    }
    if (!nullToAbsent || valueName != null) {
      map['value_name'] = Variable<String>(valueName);
    }
    if (!nullToAbsent || priceAdjustment != null) {
      map['price_adjustment'] = Variable<double>(priceAdjustment);
    }
    map['stock_multiplier'] = Variable<double>(stockMultiplier);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  ProductOptionValuesCompanion toCompanion(bool nullToAbsent) {
    return ProductOptionValuesCompanion(
      id: Value(id),
      optionId: optionId == null && nullToAbsent
          ? const Value.absent()
          : Value(optionId),
      valueName: valueName == null && nullToAbsent
          ? const Value.absent()
          : Value(valueName),
      priceAdjustment: priceAdjustment == null && nullToAbsent
          ? const Value.absent()
          : Value(priceAdjustment),
      stockMultiplier: Value(stockMultiplier),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ProductOptionValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductOptionValue(
      id: serializer.fromJson<String>(json['id']),
      optionId: serializer.fromJson<String?>(json['optionId']),
      valueName: serializer.fromJson<String?>(json['valueName']),
      priceAdjustment: serializer.fromJson<double?>(json['priceAdjustment']),
      stockMultiplier: serializer.fromJson<double>(json['stockMultiplier']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'optionId': serializer.toJson<String?>(optionId),
      'valueName': serializer.toJson<String?>(valueName),
      'priceAdjustment': serializer.toJson<double?>(priceAdjustment),
      'stockMultiplier': serializer.toJson<double>(stockMultiplier),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  ProductOptionValue copyWith({
    String? id,
    Value<String?> optionId = const Value.absent(),
    Value<String?> valueName = const Value.absent(),
    Value<double?> priceAdjustment = const Value.absent(),
    double? stockMultiplier,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => ProductOptionValue(
    id: id ?? this.id,
    optionId: optionId.present ? optionId.value : this.optionId,
    valueName: valueName.present ? valueName.value : this.valueName,
    priceAdjustment: priceAdjustment.present
        ? priceAdjustment.value
        : this.priceAdjustment,
    stockMultiplier: stockMultiplier ?? this.stockMultiplier,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  ProductOptionValue copyWithCompanion(ProductOptionValuesCompanion data) {
    return ProductOptionValue(
      id: data.id.present ? data.id.value : this.id,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
      valueName: data.valueName.present ? data.valueName.value : this.valueName,
      priceAdjustment: data.priceAdjustment.present
          ? data.priceAdjustment.value
          : this.priceAdjustment,
      stockMultiplier: data.stockMultiplier.present
          ? data.stockMultiplier.value
          : this.stockMultiplier,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionValue(')
          ..write('id: $id, ')
          ..write('optionId: $optionId, ')
          ..write('valueName: $valueName, ')
          ..write('priceAdjustment: $priceAdjustment, ')
          ..write('stockMultiplier: $stockMultiplier, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    optionId,
    valueName,
    priceAdjustment,
    stockMultiplier,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductOptionValue &&
          other.id == this.id &&
          other.optionId == this.optionId &&
          other.valueName == this.valueName &&
          other.priceAdjustment == this.priceAdjustment &&
          other.stockMultiplier == this.stockMultiplier &&
          other.createdAt == this.createdAt);
}

class ProductOptionValuesCompanion extends UpdateCompanion<ProductOptionValue> {
  final Value<String> id;
  final Value<String?> optionId;
  final Value<String?> valueName;
  final Value<double?> priceAdjustment;
  final Value<double> stockMultiplier;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const ProductOptionValuesCompanion({
    this.id = const Value.absent(),
    this.optionId = const Value.absent(),
    this.valueName = const Value.absent(),
    this.priceAdjustment = const Value.absent(),
    this.stockMultiplier = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductOptionValuesCompanion.insert({
    required String id,
    this.optionId = const Value.absent(),
    this.valueName = const Value.absent(),
    this.priceAdjustment = const Value.absent(),
    this.stockMultiplier = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ProductOptionValue> custom({
    Expression<String>? id,
    Expression<String>? optionId,
    Expression<String>? valueName,
    Expression<double>? priceAdjustment,
    Expression<double>? stockMultiplier,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (optionId != null) 'option_id': optionId,
      if (valueName != null) 'value_name': valueName,
      if (priceAdjustment != null) 'price_adjustment': priceAdjustment,
      if (stockMultiplier != null) 'stock_multiplier': stockMultiplier,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductOptionValuesCompanion copyWith({
    Value<String>? id,
    Value<String?>? optionId,
    Value<String?>? valueName,
    Value<double?>? priceAdjustment,
    Value<double>? stockMultiplier,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductOptionValuesCompanion(
      id: id ?? this.id,
      optionId: optionId ?? this.optionId,
      valueName: valueName ?? this.valueName,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      stockMultiplier: stockMultiplier ?? this.stockMultiplier,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<String>(optionId.value);
    }
    if (valueName.present) {
      map['value_name'] = Variable<String>(valueName.value);
    }
    if (priceAdjustment.present) {
      map['price_adjustment'] = Variable<double>(priceAdjustment.value);
    }
    if (stockMultiplier.present) {
      map['stock_multiplier'] = Variable<double>(stockMultiplier.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductOptionValuesCompanion(')
          ..write('id: $id, ')
          ..write('optionId: $optionId, ')
          ..write('valueName: $valueName, ')
          ..write('priceAdjustment: $priceAdjustment, ')
          ..write('stockMultiplier: $stockMultiplier, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashReceivedMeta = const VerificationMeta(
    'cashReceived',
  );
  @override
  late final GeneratedColumn<double> cashReceived = GeneratedColumn<double>(
    'cash_received',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeMeta = const VerificationMeta('change');
  @override
  late final GeneratedColumn<double> change = GeneratedColumn<double>(
    'change',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pos_offline'),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalAmount,
    cashReceived,
    change,
    paymentMethod,
    cashierId,
    storeId,
    status,
    source,
    customerName,
    customerId,
    tableNumber,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('cash_received')) {
      context.handle(
        _cashReceivedMeta,
        cashReceived.isAcceptableOrUnknown(
          data['cash_received']!,
          _cashReceivedMeta,
        ),
      );
    }
    if (data.containsKey('change')) {
      context.handle(
        _changeMeta,
        change.isAcceptableOrUnknown(data['change']!, _changeMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      ),
      cashReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_received'],
      ),
      change: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final double? totalAmount;
  final double? cashReceived;
  final double? change;
  final String? paymentMethod;
  final String? cashierId;
  final String? storeId;
  final String status;
  final String source;
  final String? customerName;
  final String? customerId;
  final String? tableNumber;
  final String? notes;
  final DateTime? createdAt;
  const Transaction({
    required this.id,
    this.totalAmount,
    this.cashReceived,
    this.change,
    this.paymentMethod,
    this.cashierId,
    this.storeId,
    required this.status,
    required this.source,
    this.customerName,
    this.customerId,
    this.tableNumber,
    this.notes,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || cashReceived != null) {
      map['cash_received'] = Variable<double>(cashReceived);
    }
    if (!nullToAbsent || change != null) {
      map['change'] = Variable<double>(change);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || cashierId != null) {
      map['cashier_id'] = Variable<String>(cashierId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      cashReceived: cashReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(cashReceived),
      change: change == null && nullToAbsent
          ? const Value.absent()
          : Value(change),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      cashierId: cashierId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      status: Value(status),
      source: Value(source),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      cashReceived: serializer.fromJson<double?>(json['cashReceived']),
      change: serializer.fromJson<double?>(json['change']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      cashierId: serializer.fromJson<String?>(json['cashierId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'cashReceived': serializer.toJson<double?>(cashReceived),
      'change': serializer.toJson<double?>(change),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'cashierId': serializer.toJson<String?>(cashierId),
      'storeId': serializer.toJson<String?>(storeId),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'customerName': serializer.toJson<String?>(customerName),
      'customerId': serializer.toJson<String?>(customerId),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Transaction copyWith({
    String? id,
    Value<double?> totalAmount = const Value.absent(),
    Value<double?> cashReceived = const Value.absent(),
    Value<double?> change = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> cashierId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    String? status,
    String? source,
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    Value<String?> tableNumber = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    cashReceived: cashReceived.present ? cashReceived.value : this.cashReceived,
    change: change.present ? change.value : this.change,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    cashierId: cashierId.present ? cashierId.value : this.cashierId,
    storeId: storeId.present ? storeId.value : this.storeId,
    status: status ?? this.status,
    source: source ?? this.source,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerId: customerId.present ? customerId.value : this.customerId,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      cashReceived: data.cashReceived.present
          ? data.cashReceived.value
          : this.cashReceived,
      change: data.change.present ? data.change.value : this.change,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('cashReceived: $cashReceived, ')
          ..write('change: $change, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('cashierId: $cashierId, ')
          ..write('storeId: $storeId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('customerName: $customerName, ')
          ..write('customerId: $customerId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalAmount,
    cashReceived,
    change,
    paymentMethod,
    cashierId,
    storeId,
    status,
    source,
    customerName,
    customerId,
    tableNumber,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.totalAmount == this.totalAmount &&
          other.cashReceived == this.cashReceived &&
          other.change == this.change &&
          other.paymentMethod == this.paymentMethod &&
          other.cashierId == this.cashierId &&
          other.storeId == this.storeId &&
          other.status == this.status &&
          other.source == this.source &&
          other.customerName == this.customerName &&
          other.customerId == this.customerId &&
          other.tableNumber == this.tableNumber &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<double?> totalAmount;
  final Value<double?> cashReceived;
  final Value<double?> change;
  final Value<String?> paymentMethod;
  final Value<String?> cashierId;
  final Value<String?> storeId;
  final Value<String> status;
  final Value<String> source;
  final Value<String?> customerName;
  final Value<String?> customerId;
  final Value<String?> tableNumber;
  final Value<String?> notes;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.cashReceived = const Value.absent(),
    this.change = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    this.totalAmount = const Value.absent(),
    this.cashReceived = const Value.absent(),
    this.change = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<double>? totalAmount,
    Expression<double>? cashReceived,
    Expression<double>? change,
    Expression<String>? paymentMethod,
    Expression<String>? cashierId,
    Expression<String>? storeId,
    Expression<String>? status,
    Expression<String>? source,
    Expression<String>? customerName,
    Expression<String>? customerId,
    Expression<String>? tableNumber,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (cashReceived != null) 'cash_received': cashReceived,
      if (change != null) 'change': change,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (cashierId != null) 'cashier_id': cashierId,
      if (storeId != null) 'store_id': storeId,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (customerName != null) 'customer_name': customerName,
      if (customerId != null) 'customer_id': customerId,
      if (tableNumber != null) 'table_number': tableNumber,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<double?>? totalAmount,
    Value<double?>? cashReceived,
    Value<double?>? change,
    Value<String?>? paymentMethod,
    Value<String?>? cashierId,
    Value<String?>? storeId,
    Value<String>? status,
    Value<String>? source,
    Value<String?>? customerName,
    Value<String?>? customerId,
    Value<String?>? tableNumber,
    Value<String?>? notes,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      cashReceived: cashReceived ?? this.cashReceived,
      change: change ?? this.change,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashierId: cashierId ?? this.cashierId,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      source: source ?? this.source,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      tableNumber: tableNumber ?? this.tableNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (cashReceived.present) {
      map['cash_received'] = Variable<double>(cashReceived.value);
    }
    if (change.present) {
      map['change'] = Variable<double>(change.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('cashReceived: $cashReceived, ')
          ..write('change: $change, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('cashierId: $cashierId, ')
          ..write('storeId: $storeId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('customerName: $customerName, ')
          ..write('customerId: $customerId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionItemsTable extends TransactionItems
    with TableInfo<$TransactionItemsTable, TransactionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceAtTimeMeta = const VerificationMeta(
    'priceAtTime',
  );
  @override
  late final GeneratedColumn<double> priceAtTime = GeneratedColumn<double>(
    'price_at_time',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPriceMeta = const VerificationMeta(
    'totalPrice',
  );
  @override
  late final GeneratedColumn<double> totalPrice = GeneratedColumn<double>(
    'total_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedOptionsJsonMeta =
      const VerificationMeta('selectedOptionsJson');
  @override
  late final GeneratedColumn<String> selectedOptionsJson =
      GeneratedColumn<String>(
        'selected_options_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    productId,
    productName,
    quantity,
    unitPrice,
    priceAtTime,
    totalPrice,
    notes,
    selectedOptionsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('price_at_time')) {
      context.handle(
        _priceAtTimeMeta,
        priceAtTime.isAcceptableOrUnknown(
          data['price_at_time']!,
          _priceAtTimeMeta,
        ),
      );
    }
    if (data.containsKey('total_price')) {
      context.handle(
        _totalPriceMeta,
        totalPrice.isAcceptableOrUnknown(data['total_price']!, _totalPriceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('selected_options_json')) {
      context.handle(
        _selectedOptionsJsonMeta,
        selectedOptionsJson.isAcceptableOrUnknown(
          data['selected_options_json']!,
          _selectedOptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      ),
      priceAtTime: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_at_time'],
      ),
      totalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      selectedOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_options_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TransactionItemsTable createAlias(String alias) {
    return $TransactionItemsTable(attachedDatabase, alias);
  }
}

class TransactionItem extends DataClass implements Insertable<TransactionItem> {
  final String id;
  final String? transactionId;
  final String? productId;
  final String? productName;
  final int? quantity;
  final double? unitPrice;
  final double? priceAtTime;
  final double? totalPrice;
  final String? notes;
  final String? selectedOptionsJson;
  final DateTime? createdAt;
  const TransactionItem({
    required this.id,
    this.transactionId,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.priceAtTime,
    this.totalPrice,
    this.notes,
    this.selectedOptionsJson,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<int>(quantity);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<double>(unitPrice);
    }
    if (!nullToAbsent || priceAtTime != null) {
      map['price_at_time'] = Variable<double>(priceAtTime);
    }
    if (!nullToAbsent || totalPrice != null) {
      map['total_price'] = Variable<double>(totalPrice);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || selectedOptionsJson != null) {
      map['selected_options_json'] = Variable<String>(selectedOptionsJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TransactionItemsCompanion toCompanion(bool nullToAbsent) {
    return TransactionItemsCompanion(
      id: Value(id),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      priceAtTime: priceAtTime == null && nullToAbsent
          ? const Value.absent()
          : Value(priceAtTime),
      totalPrice: totalPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPrice),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      selectedOptionsJson: selectedOptionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedOptionsJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TransactionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionItem(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productName: serializer.fromJson<String?>(json['productName']),
      quantity: serializer.fromJson<int?>(json['quantity']),
      unitPrice: serializer.fromJson<double?>(json['unitPrice']),
      priceAtTime: serializer.fromJson<double?>(json['priceAtTime']),
      totalPrice: serializer.fromJson<double?>(json['totalPrice']),
      notes: serializer.fromJson<String?>(json['notes']),
      selectedOptionsJson: serializer.fromJson<String?>(
        json['selectedOptionsJson'],
      ),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String?>(transactionId),
      'productId': serializer.toJson<String?>(productId),
      'productName': serializer.toJson<String?>(productName),
      'quantity': serializer.toJson<int?>(quantity),
      'unitPrice': serializer.toJson<double?>(unitPrice),
      'priceAtTime': serializer.toJson<double?>(priceAtTime),
      'totalPrice': serializer.toJson<double?>(totalPrice),
      'notes': serializer.toJson<String?>(notes),
      'selectedOptionsJson': serializer.toJson<String?>(selectedOptionsJson),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TransactionItem copyWith({
    String? id,
    Value<String?> transactionId = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    Value<String?> productName = const Value.absent(),
    Value<int?> quantity = const Value.absent(),
    Value<double?> unitPrice = const Value.absent(),
    Value<double?> priceAtTime = const Value.absent(),
    Value<double?> totalPrice = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> selectedOptionsJson = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TransactionItem(
    id: id ?? this.id,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    productId: productId.present ? productId.value : this.productId,
    productName: productName.present ? productName.value : this.productName,
    quantity: quantity.present ? quantity.value : this.quantity,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    priceAtTime: priceAtTime.present ? priceAtTime.value : this.priceAtTime,
    totalPrice: totalPrice.present ? totalPrice.value : this.totalPrice,
    notes: notes.present ? notes.value : this.notes,
    selectedOptionsJson: selectedOptionsJson.present
        ? selectedOptionsJson.value
        : this.selectedOptionsJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TransactionItem copyWithCompanion(TransactionItemsCompanion data) {
    return TransactionItem(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      priceAtTime: data.priceAtTime.present
          ? data.priceAtTime.value
          : this.priceAtTime,
      totalPrice: data.totalPrice.present
          ? data.totalPrice.value
          : this.totalPrice,
      notes: data.notes.present ? data.notes.value : this.notes,
      selectedOptionsJson: data.selectedOptionsJson.present
          ? data.selectedOptionsJson.value
          : this.selectedOptionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItem(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('priceAtTime: $priceAtTime, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('notes: $notes, ')
          ..write('selectedOptionsJson: $selectedOptionsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    productId,
    productName,
    quantity,
    unitPrice,
    priceAtTime,
    totalPrice,
    notes,
    selectedOptionsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionItem &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.priceAtTime == this.priceAtTime &&
          other.totalPrice == this.totalPrice &&
          other.notes == this.notes &&
          other.selectedOptionsJson == this.selectedOptionsJson &&
          other.createdAt == this.createdAt);
}

class TransactionItemsCompanion extends UpdateCompanion<TransactionItem> {
  final Value<String> id;
  final Value<String?> transactionId;
  final Value<String?> productId;
  final Value<String?> productName;
  final Value<int?> quantity;
  final Value<double?> unitPrice;
  final Value<double?> priceAtTime;
  final Value<double?> totalPrice;
  final Value<String?> notes;
  final Value<String?> selectedOptionsJson;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const TransactionItemsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.priceAtTime = const Value.absent(),
    this.totalPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.selectedOptionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionItemsCompanion.insert({
    required String id,
    this.transactionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.priceAtTime = const Value.absent(),
    this.totalPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.selectedOptionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<TransactionItem> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? priceAtTime,
    Expression<double>? totalPrice,
    Expression<String>? notes,
    Expression<String>? selectedOptionsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (priceAtTime != null) 'price_at_time': priceAtTime,
      if (totalPrice != null) 'total_price': totalPrice,
      if (notes != null) 'notes': notes,
      if (selectedOptionsJson != null)
        'selected_options_json': selectedOptionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? transactionId,
    Value<String?>? productId,
    Value<String?>? productName,
    Value<int?>? quantity,
    Value<double?>? unitPrice,
    Value<double?>? priceAtTime,
    Value<double?>? totalPrice,
    Value<String?>? notes,
    Value<String?>? selectedOptionsJson,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionItemsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      priceAtTime: priceAtTime ?? this.priceAtTime,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      selectedOptionsJson: selectedOptionsJson ?? this.selectedOptionsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (priceAtTime.present) {
      map['price_at_time'] = Variable<double>(priceAtTime.value);
    }
    if (totalPrice.present) {
      map['total_price'] = Variable<double>(totalPrice.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (selectedOptionsJson.present) {
      map['selected_options_json'] = Variable<String>(
        selectedOptionsJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItemsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('priceAtTime: $priceAtTime, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('notes: $notes, ')
          ..write('selectedOptionsJson: $selectedOptionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceLogsTable extends AttendanceLogs
    with TableInfo<$AttendanceLogsTable, AttendanceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clockInMeta = const VerificationMeta(
    'clockIn',
  );
  @override
  late final GeneratedColumn<DateTime> clockIn = GeneratedColumn<DateTime>(
    'clock_in',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clockOutMeta = const VerificationMeta(
    'clockOut',
  );
  @override
  late final GeneratedColumn<DateTime> clockOut = GeneratedColumn<DateTime>(
    'clock_out',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOvertimeMeta = const VerificationMeta(
    'isOvertime',
  );
  @override
  late final GeneratedColumn<bool> isOvertime = GeneratedColumn<bool>(
    'is_overtime',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_overtime" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    storeId,
    clockIn,
    clockOut,
    notes,
    photoUrl,
    status,
    isOvertime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('clock_in')) {
      context.handle(
        _clockInMeta,
        clockIn.isAcceptableOrUnknown(data['clock_in']!, _clockInMeta),
      );
    }
    if (data.containsKey('clock_out')) {
      context.handle(
        _clockOutMeta,
        clockOut.isAcceptableOrUnknown(data['clock_out']!, _clockOutMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_overtime')) {
      context.handle(
        _isOvertimeMeta,
        isOvertime.isAcceptableOrUnknown(data['is_overtime']!, _isOvertimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      clockIn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}clock_in'],
      ),
      clockOut: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}clock_out'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      isOvertime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_overtime'],
      )!,
    );
  }

  @override
  $AttendanceLogsTable createAlias(String alias) {
    return $AttendanceLogsTable(attachedDatabase, alias);
  }
}

class AttendanceLog extends DataClass implements Insertable<AttendanceLog> {
  final String id;
  final String? userId;
  final String? storeId;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String? notes;
  final String? photoUrl;
  final String? status;
  final bool isOvertime;
  const AttendanceLog({
    required this.id,
    this.userId,
    this.storeId,
    this.clockIn,
    this.clockOut,
    this.notes,
    this.photoUrl,
    this.status,
    required this.isOvertime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || clockIn != null) {
      map['clock_in'] = Variable<DateTime>(clockIn);
    }
    if (!nullToAbsent || clockOut != null) {
      map['clock_out'] = Variable<DateTime>(clockOut);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['is_overtime'] = Variable<bool>(isOvertime);
    return map;
  }

  AttendanceLogsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceLogsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      clockIn: clockIn == null && nullToAbsent
          ? const Value.absent()
          : Value(clockIn),
      clockOut: clockOut == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOut),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      isOvertime: Value(isOvertime),
    );
  }

  factory AttendanceLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      clockIn: serializer.fromJson<DateTime?>(json['clockIn']),
      clockOut: serializer.fromJson<DateTime?>(json['clockOut']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      status: serializer.fromJson<String?>(json['status']),
      isOvertime: serializer.fromJson<bool>(json['isOvertime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'storeId': serializer.toJson<String?>(storeId),
      'clockIn': serializer.toJson<DateTime?>(clockIn),
      'clockOut': serializer.toJson<DateTime?>(clockOut),
      'notes': serializer.toJson<String?>(notes),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'status': serializer.toJson<String?>(status),
      'isOvertime': serializer.toJson<bool>(isOvertime),
    };
  }

  AttendanceLog copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    Value<DateTime?> clockIn = const Value.absent(),
    Value<DateTime?> clockOut = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> status = const Value.absent(),
    bool? isOvertime,
  }) => AttendanceLog(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    storeId: storeId.present ? storeId.value : this.storeId,
    clockIn: clockIn.present ? clockIn.value : this.clockIn,
    clockOut: clockOut.present ? clockOut.value : this.clockOut,
    notes: notes.present ? notes.value : this.notes,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    status: status.present ? status.value : this.status,
    isOvertime: isOvertime ?? this.isOvertime,
  );
  AttendanceLog copyWithCompanion(AttendanceLogsCompanion data) {
    return AttendanceLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      clockIn: data.clockIn.present ? data.clockIn.value : this.clockIn,
      clockOut: data.clockOut.present ? data.clockOut.value : this.clockOut,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      status: data.status.present ? data.status.value : this.status,
      isOvertime: data.isOvertime.present
          ? data.isOvertime.value
          : this.isOvertime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('clockIn: $clockIn, ')
          ..write('clockOut: $clockOut, ')
          ..write('notes: $notes, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('status: $status, ')
          ..write('isOvertime: $isOvertime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    storeId,
    clockIn,
    clockOut,
    notes,
    photoUrl,
    status,
    isOvertime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.storeId == this.storeId &&
          other.clockIn == this.clockIn &&
          other.clockOut == this.clockOut &&
          other.notes == this.notes &&
          other.photoUrl == this.photoUrl &&
          other.status == this.status &&
          other.isOvertime == this.isOvertime);
}

class AttendanceLogsCompanion extends UpdateCompanion<AttendanceLog> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> storeId;
  final Value<DateTime?> clockIn;
  final Value<DateTime?> clockOut;
  final Value<String?> notes;
  final Value<String?> photoUrl;
  final Value<String?> status;
  final Value<bool> isOvertime;
  final Value<int> rowid;
  const AttendanceLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.clockIn = const Value.absent(),
    this.clockOut = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.isOvertime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceLogsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.clockIn = const Value.absent(),
    this.clockOut = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.isOvertime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<AttendanceLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? storeId,
    Expression<DateTime>? clockIn,
    Expression<DateTime>? clockOut,
    Expression<String>? notes,
    Expression<String>? photoUrl,
    Expression<String>? status,
    Expression<bool>? isOvertime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (storeId != null) 'store_id': storeId,
      if (clockIn != null) 'clock_in': clockIn,
      if (clockOut != null) 'clock_out': clockOut,
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (status != null) 'status': status,
      if (isOvertime != null) 'is_overtime': isOvertime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? storeId,
    Value<DateTime?>? clockIn,
    Value<DateTime?>? clockOut,
    Value<String?>? notes,
    Value<String?>? photoUrl,
    Value<String?>? status,
    Value<bool>? isOvertime,
    Value<int>? rowid,
  }) {
    return AttendanceLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      isOvertime: isOvertime ?? this.isOvertime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (clockIn.present) {
      map['clock_in'] = Variable<DateTime>(clockIn.value);
    }
    if (clockOut.present) {
      map['clock_out'] = Variable<DateTime>(clockOut.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isOvertime.present) {
      map['is_overtime'] = Variable<bool>(isOvertime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('clockIn: $clockIn, ')
          ..write('clockOut: $clockOut, ')
          ..write('notes: $notes, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('status: $status, ')
          ..write('isOvertime: $isOvertime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionsTable extends Promotions
    with TableInfo<$PromotionsTable, Promotion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('percentage'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    discountType,
    description,
    value,
    isActive,
    storeId,
    startDate,
    endDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Promotion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Promotion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Promotion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $PromotionsTable createAlias(String alias) {
    return $PromotionsTable(attachedDatabase, alias);
  }
}

class Promotion extends DataClass implements Insertable<Promotion> {
  final String id;
  final String? name;
  final String type;
  final String discountType;
  final String? description;
  final double? value;
  final bool isActive;
  final String? storeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  const Promotion({
    required this.id,
    this.name,
    required this.type,
    required this.discountType,
    this.description,
    this.value,
    required this.isActive,
    this.storeId,
    this.startDate,
    this.endDate,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['type'] = Variable<String>(type);
    map['discount_type'] = Variable<String>(discountType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  PromotionsCompanion toCompanion(bool nullToAbsent) {
    return PromotionsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: Value(type),
      discountType: Value(discountType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      isActive: Value(isActive),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Promotion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Promotion(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      discountType: serializer.fromJson<String>(json['discountType']),
      description: serializer.fromJson<String?>(json['description']),
      value: serializer.fromJson<double?>(json['value']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String>(type),
      'discountType': serializer.toJson<String>(discountType),
      'description': serializer.toJson<String?>(description),
      'value': serializer.toJson<double?>(value),
      'isActive': serializer.toJson<bool>(isActive),
      'storeId': serializer.toJson<String?>(storeId),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Promotion copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    String? type,
    String? discountType,
    Value<String?> description = const Value.absent(),
    Value<double?> value = const Value.absent(),
    bool? isActive,
    Value<String?> storeId = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Promotion(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    type: type ?? this.type,
    discountType: discountType ?? this.discountType,
    description: description.present ? description.value : this.description,
    value: value.present ? value.value : this.value,
    isActive: isActive ?? this.isActive,
    storeId: storeId.present ? storeId.value : this.storeId,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Promotion copyWithCompanion(PromotionsCompanion data) {
    return Promotion(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      description: data.description.present
          ? data.description.value
          : this.description,
      value: data.value.present ? data.value.value : this.value,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Promotion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('discountType: $discountType, ')
          ..write('description: $description, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive, ')
          ..write('storeId: $storeId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    discountType,
    description,
    value,
    isActive,
    storeId,
    startDate,
    endDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Promotion &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.discountType == this.discountType &&
          other.description == this.description &&
          other.value == this.value &&
          other.isActive == this.isActive &&
          other.storeId == this.storeId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt);
}

class PromotionsCompanion extends UpdateCompanion<Promotion> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> type;
  final Value<String> discountType;
  final Value<String?> description;
  final Value<double?> value;
  final Value<bool> isActive;
  final Value<String?> storeId;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const PromotionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.discountType = const Value.absent(),
    this.description = const Value.absent(),
    this.value = const Value.absent(),
    this.isActive = const Value.absent(),
    this.storeId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required String type,
    this.discountType = const Value.absent(),
    this.description = const Value.absent(),
    this.value = const Value.absent(),
    this.isActive = const Value.absent(),
    this.storeId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type);
  static Insertable<Promotion> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? discountType,
    Expression<String>? description,
    Expression<double>? value,
    Expression<bool>? isActive,
    Expression<String>? storeId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (discountType != null) 'discount_type': discountType,
      if (description != null) 'description': description,
      if (value != null) 'value': value,
      if (isActive != null) 'is_active': isActive,
      if (storeId != null) 'store_id': storeId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String>? type,
    Value<String>? discountType,
    Value<String?>? description,
    Value<double?>? value,
    Value<bool>? isActive,
    Value<String?>? storeId,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return PromotionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      discountType: discountType ?? this.discountType,
      description: description ?? this.description,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      storeId: storeId ?? this.storeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('discountType: $discountType, ')
          ..write('description: $description, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive, ')
          ..write('storeId: $storeId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionItemsTable extends PromotionItems
    with TableInfo<$PromotionItemsTable, PromotionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promotionIdMeta = const VerificationMeta(
    'promotionId',
  );
  @override
  late final GeneratedColumn<String> promotionId = GeneratedColumn<String>(
    'promotion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    promotionId,
    productId,
    categoryId,
    role,
    quantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotion_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromotionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('promotion_id')) {
      context.handle(
        _promotionIdMeta,
        promotionId.isAcceptableOrUnknown(
          data['promotion_id']!,
          _promotionIdMeta,
        ),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      promotionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promotion_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $PromotionItemsTable createAlias(String alias) {
    return $PromotionItemsTable(attachedDatabase, alias);
  }
}

class PromotionItem extends DataClass implements Insertable<PromotionItem> {
  final String id;
  final String? promotionId;
  final String? productId;
  final String? categoryId;
  final String role;
  final int quantity;
  const PromotionItem({
    required this.id,
    this.promotionId,
    this.productId,
    this.categoryId,
    required this.role,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || promotionId != null) {
      map['promotion_id'] = Variable<String>(promotionId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['role'] = Variable<String>(role);
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  PromotionItemsCompanion toCompanion(bool nullToAbsent) {
    return PromotionItemsCompanion(
      id: Value(id),
      promotionId: promotionId == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      role: Value(role),
      quantity: Value(quantity),
    );
  }

  factory PromotionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionItem(
      id: serializer.fromJson<String>(json['id']),
      promotionId: serializer.fromJson<String?>(json['promotionId']),
      productId: serializer.fromJson<String?>(json['productId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      role: serializer.fromJson<String>(json['role']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'promotionId': serializer.toJson<String?>(promotionId),
      'productId': serializer.toJson<String?>(productId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'role': serializer.toJson<String>(role),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  PromotionItem copyWith({
    String? id,
    Value<String?> promotionId = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? role,
    int? quantity,
  }) => PromotionItem(
    id: id ?? this.id,
    promotionId: promotionId.present ? promotionId.value : this.promotionId,
    productId: productId.present ? productId.value : this.productId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    role: role ?? this.role,
    quantity: quantity ?? this.quantity,
  );
  PromotionItem copyWithCompanion(PromotionItemsCompanion data) {
    return PromotionItem(
      id: data.id.present ? data.id.value : this.id,
      promotionId: data.promotionId.present
          ? data.promotionId.value
          : this.promotionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      role: data.role.present ? data.role.value : this.role,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionItem(')
          ..write('id: $id, ')
          ..write('promotionId: $promotionId, ')
          ..write('productId: $productId, ')
          ..write('categoryId: $categoryId, ')
          ..write('role: $role, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, promotionId, productId, categoryId, role, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionItem &&
          other.id == this.id &&
          other.promotionId == this.promotionId &&
          other.productId == this.productId &&
          other.categoryId == this.categoryId &&
          other.role == this.role &&
          other.quantity == this.quantity);
}

class PromotionItemsCompanion extends UpdateCompanion<PromotionItem> {
  final Value<String> id;
  final Value<String?> promotionId;
  final Value<String?> productId;
  final Value<String?> categoryId;
  final Value<String> role;
  final Value<int> quantity;
  final Value<int> rowid;
  const PromotionItemsCompanion({
    this.id = const Value.absent(),
    this.promotionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.role = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionItemsCompanion.insert({
    required String id,
    this.promotionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String role,
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role);
  static Insertable<PromotionItem> custom({
    Expression<String>? id,
    Expression<String>? promotionId,
    Expression<String>? productId,
    Expression<String>? categoryId,
    Expression<String>? role,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promotionId != null) 'promotion_id': promotionId,
      if (productId != null) 'product_id': productId,
      if (categoryId != null) 'category_id': categoryId,
      if (role != null) 'role': role,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? promotionId,
    Value<String?>? productId,
    Value<String?>? categoryId,
    Value<String>? role,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return PromotionItemsCompanion(
      id: id ?? this.id,
      promotionId: promotionId ?? this.promotionId,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      role: role ?? this.role,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (promotionId.present) {
      map['promotion_id'] = Variable<String>(promotionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionItemsCompanion(')
          ..write('id: $id, ')
          ..write('promotionId: $promotionId, ')
          ..write('productId: $productId, ')
          ..write('categoryId: $categoryId, ')
          ..write('role: $role, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceTypeMeta = const VerificationMeta(
    'recurrenceType',
  );
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceDurationMonthsMeta =
      const VerificationMeta('recurrenceDurationMonths');
  @override
  late final GeneratedColumn<int> recurrenceDurationMonths =
      GeneratedColumn<int>(
        'recurrence_duration_months',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    category,
    amount,
    date,
    notes,
    recurrenceType,
    recurrenceDurationMonths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
        _recurrenceTypeMeta,
        recurrenceType.isAcceptableOrUnknown(
          data['recurrence_type']!,
          _recurrenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_duration_months')) {
      context.handle(
        _recurrenceDurationMonthsMeta,
        recurrenceDurationMonths.isAcceptableOrUnknown(
          data['recurrence_duration_months']!,
          _recurrenceDurationMonthsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      recurrenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_type'],
      ),
      recurrenceDurationMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_duration_months'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String? storeId;
  final String category;
  final double? amount;
  final DateTime? date;
  final String? notes;
  final String? recurrenceType;
  final int? recurrenceDurationMonths;
  const Expense({
    required this.id,
    this.storeId,
    required this.category,
    this.amount,
    this.date,
    this.notes,
    this.recurrenceType,
    this.recurrenceDurationMonths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || recurrenceType != null) {
      map['recurrence_type'] = Variable<String>(recurrenceType);
    }
    if (!nullToAbsent || recurrenceDurationMonths != null) {
      map['recurrence_duration_months'] = Variable<int>(
        recurrenceDurationMonths,
      );
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      category: Value(category),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      recurrenceType: recurrenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceType),
      recurrenceDurationMonths: recurrenceDurationMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDurationMonths),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double?>(json['amount']),
      date: serializer.fromJson<DateTime?>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      recurrenceType: serializer.fromJson<String?>(json['recurrenceType']),
      recurrenceDurationMonths: serializer.fromJson<int?>(
        json['recurrenceDurationMonths'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double?>(amount),
      'date': serializer.toJson<DateTime?>(date),
      'notes': serializer.toJson<String?>(notes),
      'recurrenceType': serializer.toJson<String?>(recurrenceType),
      'recurrenceDurationMonths': serializer.toJson<int?>(
        recurrenceDurationMonths,
      ),
    };
  }

  Expense copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? category,
    Value<double?> amount = const Value.absent(),
    Value<DateTime?> date = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> recurrenceType = const Value.absent(),
    Value<int?> recurrenceDurationMonths = const Value.absent(),
  }) => Expense(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    category: category ?? this.category,
    amount: amount.present ? amount.value : this.amount,
    date: date.present ? date.value : this.date,
    notes: notes.present ? notes.value : this.notes,
    recurrenceType: recurrenceType.present
        ? recurrenceType.value
        : this.recurrenceType,
    recurrenceDurationMonths: recurrenceDurationMonths.present
        ? recurrenceDurationMonths.value
        : this.recurrenceDurationMonths,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      recurrenceDurationMonths: data.recurrenceDurationMonths.present
          ? data.recurrenceDurationMonths.value
          : this.recurrenceDurationMonths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceDurationMonths: $recurrenceDurationMonths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    category,
    amount,
    date,
    notes,
    recurrenceType,
    recurrenceDurationMonths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.recurrenceType == this.recurrenceType &&
          other.recurrenceDurationMonths == this.recurrenceDurationMonths);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> category;
  final Value<double?> amount;
  final Value<DateTime?> date;
  final Value<String?> notes;
  final Value<String?> recurrenceType;
  final Value<int?> recurrenceDurationMonths;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceDurationMonths = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String category,
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.recurrenceDurationMonths = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<String>? recurrenceType,
    Expression<int>? recurrenceDurationMonths,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceDurationMonths != null)
        'recurrence_duration_months': recurrenceDurationMonths,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? category,
    Value<double?>? amount,
    Value<DateTime?>? date,
    Value<String?>? notes,
    Value<String?>? recurrenceType,
    Value<int?>? recurrenceDurationMonths,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDurationMonths:
          recurrenceDurationMonths ?? this.recurrenceDurationMonths,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (recurrenceDurationMonths.present) {
      map['recurrence_duration_months'] = Variable<int>(
        recurrenceDurationMonths.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('recurrenceDurationMonths: $recurrenceDurationMonths, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    phoneNumber,
    email,
    points,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String? storeId;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final int points;
  final DateTime? createdAt;
  const Customer({
    required this.id,
    this.storeId,
    this.name,
    this.phoneNumber,
    this.email,
    required this.points,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['points'] = Variable<int>(points);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      points: Value(points),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String?>(json['name']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      email: serializer.fromJson<String?>(json['email']),
      points: serializer.fromJson<int>(json['points']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String?>(name),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'email': serializer.toJson<String?>(email),
      'points': serializer.toJson<int>(points),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Customer copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> email = const Value.absent(),
    int? points,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Customer(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name.present ? name.value : this.name,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    email: email.present ? email.value : this.email,
    points: points ?? this.points,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      email: data.email.present ? data.email.value : this.email,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, name, phoneNumber, email, points, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.phoneNumber == this.phoneNumber &&
          other.email == this.email &&
          other.points == this.points &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String?> name;
  final Value<String?> phoneNumber;
  final Value<String?> email;
  final Value<int> points;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? phoneNumber,
    Expression<String>? email,
    Expression<int>? points,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String?>? name,
    Value<String?>? phoneNumber,
    Value<String?>? email,
    Value<int>? points,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTable extends PaymentMethods
    with TableInfo<$PaymentMethodsTable, PaymentMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qrisUrlMeta = const VerificationMeta(
    'qrisUrl',
  );
  @override
  late final GeneratedColumn<String> qrisUrl = GeneratedColumn<String>(
    'qris_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    type,
    details,
    username,
    qrisUrl,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('qris_url')) {
      context.handle(
        _qrisUrlMeta,
        qrisUrl.isAcceptableOrUnknown(data['qris_url']!, _qrisUrlMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethod(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      qrisUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qris_url'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $PaymentMethodsTable createAlias(String alias) {
    return $PaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethod extends DataClass implements Insertable<PaymentMethod> {
  final String id;
  final String? storeId;
  final String name;
  final String type;
  final String? details;
  final String? username;
  final String? qrisUrl;
  final bool isActive;
  final DateTime? createdAt;
  const PaymentMethod({
    required this.id,
    this.storeId,
    required this.name,
    required this.type,
    this.details,
    this.username,
    this.qrisUrl,
    required this.isActive,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || qrisUrl != null) {
      map['qris_url'] = Variable<String>(qrisUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      type: Value(type),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      qrisUrl: qrisUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(qrisUrl),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory PaymentMethod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethod(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      details: serializer.fromJson<String?>(json['details']),
      username: serializer.fromJson<String?>(json['username']),
      qrisUrl: serializer.fromJson<String?>(json['qrisUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'details': serializer.toJson<String?>(details),
      'username': serializer.toJson<String?>(username),
      'qrisUrl': serializer.toJson<String?>(qrisUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  PaymentMethod copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? name,
    String? type,
    Value<String?> details = const Value.absent(),
    Value<String?> username = const Value.absent(),
    Value<String?> qrisUrl = const Value.absent(),
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => PaymentMethod(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    type: type ?? this.type,
    details: details.present ? details.value : this.details,
    username: username.present ? username.value : this.username,
    qrisUrl: qrisUrl.present ? qrisUrl.value : this.qrisUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  PaymentMethod copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethod(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      details: data.details.present ? data.details.value : this.details,
      username: data.username.present ? data.username.value : this.username,
      qrisUrl: data.qrisUrl.present ? data.qrisUrl.value : this.qrisUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethod(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('details: $details, ')
          ..write('username: $username, ')
          ..write('qrisUrl: $qrisUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    name,
    type,
    details,
    username,
    qrisUrl,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethod &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.type == this.type &&
          other.details == this.details &&
          other.username == this.username &&
          other.qrisUrl == this.qrisUrl &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethod> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> details;
  final Value<String?> username;
  final Value<String?> qrisUrl;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.details = const Value.absent(),
    this.username = const Value.absent(),
    this.qrisUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String name,
    required String type,
    this.details = const Value.absent(),
    this.username = const Value.absent(),
    this.qrisUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type);
  static Insertable<PaymentMethod> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? details,
    Expression<String>? username,
    Expression<String>? qrisUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (details != null) 'details': details,
      if (username != null) 'username': username,
      if (qrisUrl != null) 'qris_url': qrisUrl,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? details,
    Value<String?>? username,
    Value<String?>? qrisUrl,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      type: type ?? this.type,
      details: details ?? this.details,
      username: username ?? this.username,
      qrisUrl: qrisUrl ?? this.qrisUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (qrisUrl.present) {
      map['qris_url'] = Variable<String>(qrisUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('details: $details, ')
          ..write('username: $username, ')
          ..write('qrisUrl: $qrisUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFractionalMeta = const VerificationMeta(
    'isFractional',
  );
  @override
  late final GeneratedColumn<bool> isFractional = GeneratedColumn<bool>(
    'is_fractional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fractional" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    code,
    isFractional,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(
    Insertable<Unit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('is_fractional')) {
      context.handle(
        _isFractionalMeta,
        isFractional.isAcceptableOrUnknown(
          data['is_fractional']!,
          _isFractionalMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      isFractional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fractional'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final String id;
  final String? storeId;
  final String name;
  final String code;
  final bool isFractional;
  final DateTime? createdAt;
  const Unit({
    required this.id,
    this.storeId,
    required this.name,
    required this.code,
    required this.isFractional,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['is_fractional'] = Variable<bool>(isFractional);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      code: Value(code),
      isFractional: Value(isFractional),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Unit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      isFractional: serializer.fromJson<bool>(json['isFractional']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'isFractional': serializer.toJson<bool>(isFractional),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Unit copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? name,
    String? code,
    bool? isFractional,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Unit(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    code: code ?? this.code,
    isFractional: isFractional ?? this.isFractional,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      isFractional: data.isFractional.present
          ? data.isFractional.value
          : this.isFractional,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isFractional: $isFractional, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, name, code, isFractional, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.code == this.code &&
          other.isFractional == this.isFractional &&
          other.createdAt == this.createdAt);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String> code;
  final Value<bool> isFractional;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.isFractional = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String name,
    required String code,
    this.isFractional = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       code = Value(code);
  static Insertable<Unit> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<bool>? isFractional,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (isFractional != null) 'is_fractional': isFractional,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String>? code,
    Value<bool>? isFractional,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return UnitsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      code: code ?? this.code,
      isFractional: isFractional ?? this.isFractional,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (isFractional.present) {
      map['is_fractional'] = Variable<bool>(isFractional.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isFractional: $isFractional, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreTablesTable extends StoreTables
    with TableInfo<$StoreTablesTable, StoreTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, storeId, name, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $StoreTablesTable createAlias(String alias) {
    return $StoreTablesTable(attachedDatabase, alias);
  }
}

class StoreTable extends DataClass implements Insertable<StoreTable> {
  final String id;
  final String? storeId;
  final String name;
  final String status;
  final DateTime? createdAt;
  const StoreTable({
    required this.id,
    this.storeId,
    required this.name,
    required this.status,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  StoreTablesCompanion toCompanion(bool nullToAbsent) {
    return StoreTablesCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory StoreTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreTable(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  StoreTable copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? name,
    String? status,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => StoreTable(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  StoreTable copyWithCompanion(StoreTablesCompanion data) {
    return StoreTable(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreTable(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, name, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreTable &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class StoreTablesCompanion extends UpdateCompanion<StoreTable> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const StoreTablesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreTablesCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String name,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<StoreTable> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreTablesCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String>? status,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return StoreTablesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreTablesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoresTable stores = $StoresTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductOptionsTable productOptions = $ProductOptionsTable(this);
  late final $ProductOptionValuesTable productOptionValues =
      $ProductOptionValuesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionItemsTable transactionItems = $TransactionItemsTable(
    this,
  );
  late final $AttendanceLogsTable attendanceLogs = $AttendanceLogsTable(this);
  late final $PromotionsTable promotions = $PromotionsTable(this);
  late final $PromotionItemsTable promotionItems = $PromotionItemsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $PaymentMethodsTable paymentMethods = $PaymentMethodsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $StoreTablesTable storeTables = $StoreTablesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stores,
    profiles,
    categories,
    products,
    productOptions,
    productOptionValues,
    transactions,
    transactionItems,
    attendanceLogs,
    promotions,
    promotionItems,
    expenses,
    customers,
    paymentMethods,
    units,
    storeTables,
  ];
}

typedef $$StoresTableCreateCompanionBuilder =
    StoresCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> address,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<String?> logoUrl,
      Value<String?> description,
      Value<String?> operationalHours,
      Value<int> shiftDurationHours,
      Value<String> shiftStartTime,
      Value<bool> isAttendanceEnabled,
      Value<String?> adminName,
      Value<String?> adminAvatar,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$StoresTableUpdateCompanionBuilder =
    StoresCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> address,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<String?> logoUrl,
      Value<String?> description,
      Value<String?> operationalHours,
      Value<int> shiftDurationHours,
      Value<String> shiftStartTime,
      Value<bool> isAttendanceEnabled,
      Value<String?> adminName,
      Value<String?> adminAvatar,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$StoresTableFilterComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationalHours => $composableBuilder(
    column: $table.operationalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shiftDurationHours => $composableBuilder(
    column: $table.shiftDurationHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftStartTime => $composableBuilder(
    column: $table.shiftStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAttendanceEnabled => $composableBuilder(
    column: $table.isAttendanceEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminName => $composableBuilder(
    column: $table.adminName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminAvatar => $composableBuilder(
    column: $table.adminAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoresTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationalHours => $composableBuilder(
    column: $table.operationalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shiftDurationHours => $composableBuilder(
    column: $table.shiftDurationHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftStartTime => $composableBuilder(
    column: $table.shiftStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAttendanceEnabled => $composableBuilder(
    column: $table.isAttendanceEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminName => $composableBuilder(
    column: $table.adminName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminAvatar => $composableBuilder(
    column: $table.adminAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationalHours => $composableBuilder(
    column: $table.operationalHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shiftDurationHours => $composableBuilder(
    column: $table.shiftDurationHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftStartTime => $composableBuilder(
    column: $table.shiftStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAttendanceEnabled => $composableBuilder(
    column: $table.isAttendanceEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adminName =>
      $composableBuilder(column: $table.adminName, builder: (column) => column);

  GeneratedColumn<String> get adminAvatar => $composableBuilder(
    column: $table.adminAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoresTable,
          Store,
          $$StoresTableFilterComposer,
          $$StoresTableOrderingComposer,
          $$StoresTableAnnotationComposer,
          $$StoresTableCreateCompanionBuilder,
          $$StoresTableUpdateCompanionBuilder,
          (Store, BaseReferences<_$AppDatabase, $StoresTable, Store>),
          Store,
          PrefetchHooks Function()
        > {
  $$StoresTableTableManager(_$AppDatabase db, $StoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> operationalHours = const Value.absent(),
                Value<int> shiftDurationHours = const Value.absent(),
                Value<String> shiftStartTime = const Value.absent(),
                Value<bool> isAttendanceEnabled = const Value.absent(),
                Value<String?> adminName = const Value.absent(),
                Value<String?> adminAvatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion(
                id: id,
                name: name,
                address: address,
                email: email,
                phoneNumber: phoneNumber,
                logoUrl: logoUrl,
                description: description,
                operationalHours: operationalHours,
                shiftDurationHours: shiftDurationHours,
                shiftStartTime: shiftStartTime,
                isAttendanceEnabled: isAttendanceEnabled,
                adminName: adminName,
                adminAvatar: adminAvatar,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> operationalHours = const Value.absent(),
                Value<int> shiftDurationHours = const Value.absent(),
                Value<String> shiftStartTime = const Value.absent(),
                Value<bool> isAttendanceEnabled = const Value.absent(),
                Value<String?> adminName = const Value.absent(),
                Value<String?> adminAvatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion.insert(
                id: id,
                name: name,
                address: address,
                email: email,
                phoneNumber: phoneNumber,
                logoUrl: logoUrl,
                description: description,
                operationalHours: operationalHours,
                shiftDurationHours: shiftDurationHours,
                shiftStartTime: shiftStartTime,
                isAttendanceEnabled: isAttendanceEnabled,
                adminName: adminName,
                adminAvatar: adminAvatar,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoresTable,
      Store,
      $$StoresTableFilterComposer,
      $$StoresTableOrderingComposer,
      $$StoresTableAnnotationComposer,
      $$StoresTableCreateCompanionBuilder,
      $$StoresTableUpdateCompanionBuilder,
      (Store, BaseReferences<_$AppDatabase, $StoresTable, Store>),
      Store,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      Value<String?> email,
      Value<String?> password,
      Value<String?> fullName,
      Value<String> role,
      Value<String?> storeId,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<String?> avatarUrl,
      Value<String?> permissions,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String?> email,
      Value<String?> password,
      Value<String?> fullName,
      Value<String> role,
      Value<String?> storeId,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<String?> avatarUrl,
      Value<String?> permissions,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                email: email,
                password: password,
                fullName: fullName,
                role: role,
                storeId: storeId,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                avatarUrl: avatarUrl,
                permissions: permissions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> email = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                email: email,
                password: password,
                fullName: fullName,
                role: role,
                storeId: storeId,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                avatarUrl: avatarUrl,
                permissions: permissions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> iconUrl,
      Value<String?> storeId,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> iconUrl,
      Value<String?> storeId,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                iconUrl: iconUrl,
                storeId: storeId,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                iconUrl: iconUrl,
                storeId: storeId,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      Value<String?> name,
      Value<double?> buyPrice,
      Value<double?> basePrice,
      Value<double?> salePrice,
      Value<String?> wholesalePricesJson,
      Value<double?> stockQuantity,
      Value<bool> isStockManaged,
      Value<bool> isAvailable,
      Value<String?> sku,
      Value<String?> unitId,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> categoryId,
      Value<String?> storeId,
      Value<bool> isDeleted,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<double?> buyPrice,
      Value<double?> basePrice,
      Value<double?> salePrice,
      Value<String?> wholesalePricesJson,
      Value<double?> stockQuantity,
      Value<bool> isStockManaged,
      Value<bool> isAvailable,
      Value<String?> sku,
      Value<String?> unitId,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> categoryId,
      Value<String?> storeId,
      Value<bool> isDeleted,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wholesalePricesJson => $composableBuilder(
    column: $table.wholesalePricesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStockManaged => $composableBuilder(
    column: $table.isStockManaged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wholesalePricesJson => $composableBuilder(
    column: $table.wholesalePricesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStockManaged => $composableBuilder(
    column: $table.isStockManaged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<double> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<String> get wholesalePricesJson => $composableBuilder(
    column: $table.wholesalePricesJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStockManaged => $composableBuilder(
    column: $table.isStockManaged,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<double?> buyPrice = const Value.absent(),
                Value<double?> basePrice = const Value.absent(),
                Value<double?> salePrice = const Value.absent(),
                Value<String?> wholesalePricesJson = const Value.absent(),
                Value<double?> stockQuantity = const Value.absent(),
                Value<bool> isStockManaged = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                buyPrice: buyPrice,
                basePrice: basePrice,
                salePrice: salePrice,
                wholesalePricesJson: wholesalePricesJson,
                stockQuantity: stockQuantity,
                isStockManaged: isStockManaged,
                isAvailable: isAvailable,
                sku: sku,
                unitId: unitId,
                description: description,
                imageUrl: imageUrl,
                categoryId: categoryId,
                storeId: storeId,
                isDeleted: isDeleted,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<double?> buyPrice = const Value.absent(),
                Value<double?> basePrice = const Value.absent(),
                Value<double?> salePrice = const Value.absent(),
                Value<String?> wholesalePricesJson = const Value.absent(),
                Value<double?> stockQuantity = const Value.absent(),
                Value<bool> isStockManaged = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                buyPrice: buyPrice,
                basePrice: basePrice,
                salePrice: salePrice,
                wholesalePricesJson: wholesalePricesJson,
                stockQuantity: stockQuantity,
                isStockManaged: isStockManaged,
                isAvailable: isAvailable,
                sku: sku,
                unitId: unitId,
                description: description,
                imageUrl: imageUrl,
                categoryId: categoryId,
                storeId: storeId,
                isDeleted: isDeleted,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$ProductOptionsTableCreateCompanionBuilder =
    ProductOptionsCompanion Function({
      required String id,
      Value<String?> productId,
      Value<String?> storeId,
      Value<String?> optionName,
      Value<bool> isRequired,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });
typedef $$ProductOptionsTableUpdateCompanionBuilder =
    ProductOptionsCompanion Function({
      Value<String> id,
      Value<String?> productId,
      Value<String?> storeId,
      Value<String?> optionName,
      Value<bool> isRequired,
      Value<DateTime?> createdAt,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });

class $$ProductOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductOptionsTable> {
  $$ProductOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductOptionsTable> {
  $$ProductOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductOptionsTable> {
  $$ProductOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get optionName => $composableBuilder(
    column: $table.optionName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$ProductOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductOptionsTable,
          ProductOption,
          $$ProductOptionsTableFilterComposer,
          $$ProductOptionsTableOrderingComposer,
          $$ProductOptionsTableAnnotationComposer,
          $$ProductOptionsTableCreateCompanionBuilder,
          $$ProductOptionsTableUpdateCompanionBuilder,
          (
            ProductOption,
            BaseReferences<_$AppDatabase, $ProductOptionsTable, ProductOption>,
          ),
          ProductOption,
          PrefetchHooks Function()
        > {
  $$ProductOptionsTableTableManager(
    _$AppDatabase db,
    $ProductOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> optionName = const Value.absent(),
                Value<bool> isRequired = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductOptionsCompanion(
                id: id,
                productId: productId,
                storeId: storeId,
                optionName: optionName,
                isRequired: isRequired,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> productId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> optionName = const Value.absent(),
                Value<bool> isRequired = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductOptionsCompanion.insert(
                id: id,
                productId: productId,
                storeId: storeId,
                optionName: optionName,
                isRequired: isRequired,
                createdAt: createdAt,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductOptionsTable,
      ProductOption,
      $$ProductOptionsTableFilterComposer,
      $$ProductOptionsTableOrderingComposer,
      $$ProductOptionsTableAnnotationComposer,
      $$ProductOptionsTableCreateCompanionBuilder,
      $$ProductOptionsTableUpdateCompanionBuilder,
      (
        ProductOption,
        BaseReferences<_$AppDatabase, $ProductOptionsTable, ProductOption>,
      ),
      ProductOption,
      PrefetchHooks Function()
    >;
typedef $$ProductOptionValuesTableCreateCompanionBuilder =
    ProductOptionValuesCompanion Function({
      required String id,
      Value<String?> optionId,
      Value<String?> valueName,
      Value<double?> priceAdjustment,
      Value<double> stockMultiplier,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$ProductOptionValuesTableUpdateCompanionBuilder =
    ProductOptionValuesCompanion Function({
      Value<String> id,
      Value<String?> optionId,
      Value<String?> valueName,
      Value<double?> priceAdjustment,
      Value<double> stockMultiplier,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$ProductOptionValuesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductOptionValuesTable> {
  $$ProductOptionValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueName => $composableBuilder(
    column: $table.valueName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceAdjustment => $composableBuilder(
    column: $table.priceAdjustment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockMultiplier => $composableBuilder(
    column: $table.stockMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductOptionValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductOptionValuesTable> {
  $$ProductOptionValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueName => $composableBuilder(
    column: $table.valueName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceAdjustment => $composableBuilder(
    column: $table.priceAdjustment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockMultiplier => $composableBuilder(
    column: $table.stockMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductOptionValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductOptionValuesTable> {
  $$ProductOptionValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get optionId =>
      $composableBuilder(column: $table.optionId, builder: (column) => column);

  GeneratedColumn<String> get valueName =>
      $composableBuilder(column: $table.valueName, builder: (column) => column);

  GeneratedColumn<double> get priceAdjustment => $composableBuilder(
    column: $table.priceAdjustment,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockMultiplier => $composableBuilder(
    column: $table.stockMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductOptionValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductOptionValuesTable,
          ProductOptionValue,
          $$ProductOptionValuesTableFilterComposer,
          $$ProductOptionValuesTableOrderingComposer,
          $$ProductOptionValuesTableAnnotationComposer,
          $$ProductOptionValuesTableCreateCompanionBuilder,
          $$ProductOptionValuesTableUpdateCompanionBuilder,
          (
            ProductOptionValue,
            BaseReferences<
              _$AppDatabase,
              $ProductOptionValuesTable,
              ProductOptionValue
            >,
          ),
          ProductOptionValue,
          PrefetchHooks Function()
        > {
  $$ProductOptionValuesTableTableManager(
    _$AppDatabase db,
    $ProductOptionValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductOptionValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductOptionValuesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductOptionValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> optionId = const Value.absent(),
                Value<String?> valueName = const Value.absent(),
                Value<double?> priceAdjustment = const Value.absent(),
                Value<double> stockMultiplier = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductOptionValuesCompanion(
                id: id,
                optionId: optionId,
                valueName: valueName,
                priceAdjustment: priceAdjustment,
                stockMultiplier: stockMultiplier,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> optionId = const Value.absent(),
                Value<String?> valueName = const Value.absent(),
                Value<double?> priceAdjustment = const Value.absent(),
                Value<double> stockMultiplier = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductOptionValuesCompanion.insert(
                id: id,
                optionId: optionId,
                valueName: valueName,
                priceAdjustment: priceAdjustment,
                stockMultiplier: stockMultiplier,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductOptionValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductOptionValuesTable,
      ProductOptionValue,
      $$ProductOptionValuesTableFilterComposer,
      $$ProductOptionValuesTableOrderingComposer,
      $$ProductOptionValuesTableAnnotationComposer,
      $$ProductOptionValuesTableCreateCompanionBuilder,
      $$ProductOptionValuesTableUpdateCompanionBuilder,
      (
        ProductOptionValue,
        BaseReferences<
          _$AppDatabase,
          $ProductOptionValuesTable,
          ProductOptionValue
        >,
      ),
      ProductOptionValue,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      Value<double?> totalAmount,
      Value<double?> cashReceived,
      Value<double?> change,
      Value<String?> paymentMethod,
      Value<String?> cashierId,
      Value<String?> storeId,
      Value<String> status,
      Value<String> source,
      Value<String?> customerName,
      Value<String?> customerId,
      Value<String?> tableNumber,
      Value<String?> notes,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<double?> totalAmount,
      Value<double?> cashReceived,
      Value<double?> change,
      Value<String?> paymentMethod,
      Value<String?> cashierId,
      Value<String?> storeId,
      Value<String> status,
      Value<String> source,
      Value<String?> customerName,
      Value<String?> customerId,
      Value<String?> tableNumber,
      Value<String?> notes,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashReceived => $composableBuilder(
    column: $table.cashReceived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get change =>
      $composableBuilder(column: $table.change, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<double?> cashReceived = const Value.absent(),
                Value<double?> change = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> cashierId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                totalAmount: totalAmount,
                cashReceived: cashReceived,
                change: change,
                paymentMethod: paymentMethod,
                cashierId: cashierId,
                storeId: storeId,
                status: status,
                source: source,
                customerName: customerName,
                customerId: customerId,
                tableNumber: tableNumber,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<double?> totalAmount = const Value.absent(),
                Value<double?> cashReceived = const Value.absent(),
                Value<double?> change = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> cashierId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                totalAmount: totalAmount,
                cashReceived: cashReceived,
                change: change,
                paymentMethod: paymentMethod,
                cashierId: cashierId,
                storeId: storeId,
                status: status,
                source: source,
                customerName: customerName,
                customerId: customerId,
                tableNumber: tableNumber,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$TransactionItemsTableCreateCompanionBuilder =
    TransactionItemsCompanion Function({
      required String id,
      Value<String?> transactionId,
      Value<String?> productId,
      Value<String?> productName,
      Value<int?> quantity,
      Value<double?> unitPrice,
      Value<double?> priceAtTime,
      Value<double?> totalPrice,
      Value<String?> notes,
      Value<String?> selectedOptionsJson,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$TransactionItemsTableUpdateCompanionBuilder =
    TransactionItemsCompanion Function({
      Value<String> id,
      Value<String?> transactionId,
      Value<String?> productId,
      Value<String?> productName,
      Value<int?> quantity,
      Value<double?> unitPrice,
      Value<double?> priceAtTime,
      Value<double?> totalPrice,
      Value<String?> notes,
      Value<String?> selectedOptionsJson,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$TransactionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceAtTime => $composableBuilder(
    column: $table.priceAtTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedOptionsJson => $composableBuilder(
    column: $table.selectedOptionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceAtTime => $composableBuilder(
    column: $table.priceAtTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedOptionsJson => $composableBuilder(
    column: $table.selectedOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionItemsTable> {
  $$TransactionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get priceAtTime => $composableBuilder(
    column: $table.priceAtTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get selectedOptionsJson => $composableBuilder(
    column: $table.selectedOptionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionItemsTable,
          TransactionItem,
          $$TransactionItemsTableFilterComposer,
          $$TransactionItemsTableOrderingComposer,
          $$TransactionItemsTableAnnotationComposer,
          $$TransactionItemsTableCreateCompanionBuilder,
          $$TransactionItemsTableUpdateCompanionBuilder,
          (
            TransactionItem,
            BaseReferences<
              _$AppDatabase,
              $TransactionItemsTable,
              TransactionItem
            >,
          ),
          TransactionItem,
          PrefetchHooks Function()
        > {
  $$TransactionItemsTableTableManager(
    _$AppDatabase db,
    $TransactionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                Value<double?> priceAtTime = const Value.absent(),
                Value<double?> totalPrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> selectedOptionsJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsCompanion(
                id: id,
                transactionId: transactionId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unitPrice: unitPrice,
                priceAtTime: priceAtTime,
                totalPrice: totalPrice,
                notes: notes,
                selectedOptionsJson: selectedOptionsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> transactionId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                Value<double?> priceAtTime = const Value.absent(),
                Value<double?> totalPrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> selectedOptionsJson = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsCompanion.insert(
                id: id,
                transactionId: transactionId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unitPrice: unitPrice,
                priceAtTime: priceAtTime,
                totalPrice: totalPrice,
                notes: notes,
                selectedOptionsJson: selectedOptionsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionItemsTable,
      TransactionItem,
      $$TransactionItemsTableFilterComposer,
      $$TransactionItemsTableOrderingComposer,
      $$TransactionItemsTableAnnotationComposer,
      $$TransactionItemsTableCreateCompanionBuilder,
      $$TransactionItemsTableUpdateCompanionBuilder,
      (
        TransactionItem,
        BaseReferences<_$AppDatabase, $TransactionItemsTable, TransactionItem>,
      ),
      TransactionItem,
      PrefetchHooks Function()
    >;
typedef $$AttendanceLogsTableCreateCompanionBuilder =
    AttendanceLogsCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> storeId,
      Value<DateTime?> clockIn,
      Value<DateTime?> clockOut,
      Value<String?> notes,
      Value<String?> photoUrl,
      Value<String?> status,
      Value<bool> isOvertime,
      Value<int> rowid,
    });
typedef $$AttendanceLogsTableUpdateCompanionBuilder =
    AttendanceLogsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> storeId,
      Value<DateTime?> clockIn,
      Value<DateTime?> clockOut,
      Value<String?> notes,
      Value<String?> photoUrl,
      Value<String?> status,
      Value<bool> isOvertime,
      Value<int> rowid,
    });

class $$AttendanceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clockIn => $composableBuilder(
    column: $table.clockIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clockOut => $composableBuilder(
    column: $table.clockOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOvertime => $composableBuilder(
    column: $table.isOvertime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clockIn => $composableBuilder(
    column: $table.clockIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clockOut => $composableBuilder(
    column: $table.clockOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOvertime => $composableBuilder(
    column: $table.isOvertime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTable> {
  $$AttendanceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<DateTime> get clockIn =>
      $composableBuilder(column: $table.clockIn, builder: (column) => column);

  GeneratedColumn<DateTime> get clockOut =>
      $composableBuilder(column: $table.clockOut, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isOvertime => $composableBuilder(
    column: $table.isOvertime,
    builder: (column) => column,
  );
}

class $$AttendanceLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceLogsTable,
          AttendanceLog,
          $$AttendanceLogsTableFilterComposer,
          $$AttendanceLogsTableOrderingComposer,
          $$AttendanceLogsTableAnnotationComposer,
          $$AttendanceLogsTableCreateCompanionBuilder,
          $$AttendanceLogsTableUpdateCompanionBuilder,
          (
            AttendanceLog,
            BaseReferences<_$AppDatabase, $AttendanceLogsTable, AttendanceLog>,
          ),
          AttendanceLog,
          PrefetchHooks Function()
        > {
  $$AttendanceLogsTableTableManager(
    _$AppDatabase db,
    $AttendanceLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> clockIn = const Value.absent(),
                Value<DateTime?> clockOut = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<bool> isOvertime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceLogsCompanion(
                id: id,
                userId: userId,
                storeId: storeId,
                clockIn: clockIn,
                clockOut: clockOut,
                notes: notes,
                photoUrl: photoUrl,
                status: status,
                isOvertime: isOvertime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> clockIn = const Value.absent(),
                Value<DateTime?> clockOut = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<bool> isOvertime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceLogsCompanion.insert(
                id: id,
                userId: userId,
                storeId: storeId,
                clockIn: clockIn,
                clockOut: clockOut,
                notes: notes,
                photoUrl: photoUrl,
                status: status,
                isOvertime: isOvertime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceLogsTable,
      AttendanceLog,
      $$AttendanceLogsTableFilterComposer,
      $$AttendanceLogsTableOrderingComposer,
      $$AttendanceLogsTableAnnotationComposer,
      $$AttendanceLogsTableCreateCompanionBuilder,
      $$AttendanceLogsTableUpdateCompanionBuilder,
      (
        AttendanceLog,
        BaseReferences<_$AppDatabase, $AttendanceLogsTable, AttendanceLog>,
      ),
      AttendanceLog,
      PrefetchHooks Function()
    >;
typedef $$PromotionsTableCreateCompanionBuilder =
    PromotionsCompanion Function({
      required String id,
      Value<String?> name,
      required String type,
      Value<String> discountType,
      Value<String?> description,
      Value<double?> value,
      Value<bool> isActive,
      Value<String?> storeId,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$PromotionsTableUpdateCompanionBuilder =
    PromotionsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String> type,
      Value<String> discountType,
      Value<String?> description,
      Value<double?> value,
      Value<bool> isActive,
      Value<String?> storeId,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$PromotionsTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromotionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromotionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionsTable> {
  $$PromotionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PromotionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromotionsTable,
          Promotion,
          $$PromotionsTableFilterComposer,
          $$PromotionsTableOrderingComposer,
          $$PromotionsTableAnnotationComposer,
          $$PromotionsTableCreateCompanionBuilder,
          $$PromotionsTableUpdateCompanionBuilder,
          (
            Promotion,
            BaseReferences<_$AppDatabase, $PromotionsTable, Promotion>,
          ),
          Promotion,
          PrefetchHooks Function()
        > {
  $$PromotionsTableTableManager(_$AppDatabase db, $PromotionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> discountType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionsCompanion(
                id: id,
                name: name,
                type: type,
                discountType: discountType,
                description: description,
                value: value,
                isActive: isActive,
                storeId: storeId,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                required String type,
                Value<String> discountType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionsCompanion.insert(
                id: id,
                name: name,
                type: type,
                discountType: discountType,
                description: description,
                value: value,
                isActive: isActive,
                storeId: storeId,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromotionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromotionsTable,
      Promotion,
      $$PromotionsTableFilterComposer,
      $$PromotionsTableOrderingComposer,
      $$PromotionsTableAnnotationComposer,
      $$PromotionsTableCreateCompanionBuilder,
      $$PromotionsTableUpdateCompanionBuilder,
      (Promotion, BaseReferences<_$AppDatabase, $PromotionsTable, Promotion>),
      Promotion,
      PrefetchHooks Function()
    >;
typedef $$PromotionItemsTableCreateCompanionBuilder =
    PromotionItemsCompanion Function({
      required String id,
      Value<String?> promotionId,
      Value<String?> productId,
      Value<String?> categoryId,
      required String role,
      Value<int> quantity,
      Value<int> rowid,
    });
typedef $$PromotionItemsTableUpdateCompanionBuilder =
    PromotionItemsCompanion Function({
      Value<String> id,
      Value<String?> promotionId,
      Value<String?> productId,
      Value<String?> categoryId,
      Value<String> role,
      Value<int> quantity,
      Value<int> rowid,
    });

class $$PromotionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionItemsTable> {
  $$PromotionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promotionId => $composableBuilder(
    column: $table.promotionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromotionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionItemsTable> {
  $$PromotionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promotionId => $composableBuilder(
    column: $table.promotionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromotionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionItemsTable> {
  $$PromotionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get promotionId => $composableBuilder(
    column: $table.promotionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);
}

class $$PromotionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromotionItemsTable,
          PromotionItem,
          $$PromotionItemsTableFilterComposer,
          $$PromotionItemsTableOrderingComposer,
          $$PromotionItemsTableAnnotationComposer,
          $$PromotionItemsTableCreateCompanionBuilder,
          $$PromotionItemsTableUpdateCompanionBuilder,
          (
            PromotionItem,
            BaseReferences<_$AppDatabase, $PromotionItemsTable, PromotionItem>,
          ),
          PromotionItem,
          PrefetchHooks Function()
        > {
  $$PromotionItemsTableTableManager(
    _$AppDatabase db,
    $PromotionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> promotionId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionItemsCompanion(
                id: id,
                promotionId: promotionId,
                productId: productId,
                categoryId: categoryId,
                role: role,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> promotionId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required String role,
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromotionItemsCompanion.insert(
                id: id,
                promotionId: promotionId,
                productId: productId,
                categoryId: categoryId,
                role: role,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromotionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromotionItemsTable,
      PromotionItem,
      $$PromotionItemsTableFilterComposer,
      $$PromotionItemsTableOrderingComposer,
      $$PromotionItemsTableAnnotationComposer,
      $$PromotionItemsTableCreateCompanionBuilder,
      $$PromotionItemsTableUpdateCompanionBuilder,
      (
        PromotionItem,
        BaseReferences<_$AppDatabase, $PromotionItemsTable, PromotionItem>,
      ),
      PromotionItem,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      Value<String?> storeId,
      required String category,
      Value<double?> amount,
      Value<DateTime?> date,
      Value<String?> notes,
      Value<String?> recurrenceType,
      Value<int?> recurrenceDurationMonths,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String> category,
      Value<double?> amount,
      Value<DateTime?> date,
      Value<String?> notes,
      Value<String?> recurrenceType,
      Value<int?> recurrenceDurationMonths,
      Value<int> rowid,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceDurationMonths => $composableBuilder(
    column: $table.recurrenceDurationMonths,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceDurationMonths => $composableBuilder(
    column: $table.recurrenceDurationMonths,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceDurationMonths => $composableBuilder(
    column: $table.recurrenceDurationMonths,
    builder: (column) => column,
  );
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
          Expense,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<DateTime?> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> recurrenceType = const Value.absent(),
                Value<int?> recurrenceDurationMonths = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                storeId: storeId,
                category: category,
                amount: amount,
                date: date,
                notes: notes,
                recurrenceType: recurrenceType,
                recurrenceDurationMonths: recurrenceDurationMonths,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                required String category,
                Value<double?> amount = const Value.absent(),
                Value<DateTime?> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> recurrenceType = const Value.absent(),
                Value<int?> recurrenceDurationMonths = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                storeId: storeId,
                category: category,
                amount: amount,
                date: date,
                notes: notes,
                recurrenceType: recurrenceType,
                recurrenceDurationMonths: recurrenceDurationMonths,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
      Expense,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      Value<String?> storeId,
      Value<String?> name,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<int> points,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String?> name,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<int> points,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                storeId: storeId,
                name: name,
                phoneNumber: phoneNumber,
                email: email,
                points: points,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                phoneNumber: phoneNumber,
                email: email,
                points: points,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$PaymentMethodsTableCreateCompanionBuilder =
    PaymentMethodsCompanion Function({
      required String id,
      Value<String?> storeId,
      required String name,
      required String type,
      Value<String?> details,
      Value<String?> username,
      Value<String?> qrisUrl,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$PaymentMethodsTableUpdateCompanionBuilder =
    PaymentMethodsCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String> name,
      Value<String> type,
      Value<String?> details,
      Value<String?> username,
      Value<String?> qrisUrl,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$PaymentMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrisUrl => $composableBuilder(
    column: $table.qrisUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrisUrl => $composableBuilder(
    column: $table.qrisUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get qrisUrl =>
      $composableBuilder(column: $table.qrisUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PaymentMethodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodsTable,
          PaymentMethod,
          $$PaymentMethodsTableFilterComposer,
          $$PaymentMethodsTableOrderingComposer,
          $$PaymentMethodsTableAnnotationComposer,
          $$PaymentMethodsTableCreateCompanionBuilder,
          $$PaymentMethodsTableUpdateCompanionBuilder,
          (
            PaymentMethod,
            BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod>,
          ),
          PaymentMethod,
          PrefetchHooks Function()
        > {
  $$PaymentMethodsTableTableManager(
    _$AppDatabase db,
    $PaymentMethodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> qrisUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsCompanion(
                id: id,
                storeId: storeId,
                name: name,
                type: type,
                details: details,
                username: username,
                qrisUrl: qrisUrl,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                required String name,
                required String type,
                Value<String?> details = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> qrisUrl = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                type: type,
                details: details,
                username: username,
                qrisUrl: qrisUrl,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentMethodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodsTable,
      PaymentMethod,
      $$PaymentMethodsTableFilterComposer,
      $$PaymentMethodsTableOrderingComposer,
      $$PaymentMethodsTableAnnotationComposer,
      $$PaymentMethodsTableCreateCompanionBuilder,
      $$PaymentMethodsTableUpdateCompanionBuilder,
      (
        PaymentMethod,
        BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod>,
      ),
      PaymentMethod,
      PrefetchHooks Function()
    >;
typedef $$UnitsTableCreateCompanionBuilder =
    UnitsCompanion Function({
      required String id,
      Value<String?> storeId,
      required String name,
      required String code,
      Value<bool> isFractional,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$UnitsTableUpdateCompanionBuilder =
    UnitsCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String> name,
      Value<String> code,
      Value<bool> isFractional,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get isFractional => $composableBuilder(
    column: $table.isFractional,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitsTable,
          Unit,
          $$UnitsTableFilterComposer,
          $$UnitsTableOrderingComposer,
          $$UnitsTableAnnotationComposer,
          $$UnitsTableCreateCompanionBuilder,
          $$UnitsTableUpdateCompanionBuilder,
          (Unit, BaseReferences<_$AppDatabase, $UnitsTable, Unit>),
          Unit,
          PrefetchHooks Function()
        > {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<bool> isFractional = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion(
                id: id,
                storeId: storeId,
                name: name,
                code: code,
                isFractional: isFractional,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                required String name,
                required String code,
                Value<bool> isFractional = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                code: code,
                isFractional: isFractional,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitsTable,
      Unit,
      $$UnitsTableFilterComposer,
      $$UnitsTableOrderingComposer,
      $$UnitsTableAnnotationComposer,
      $$UnitsTableCreateCompanionBuilder,
      $$UnitsTableUpdateCompanionBuilder,
      (Unit, BaseReferences<_$AppDatabase, $UnitsTable, Unit>),
      Unit,
      PrefetchHooks Function()
    >;
typedef $$StoreTablesTableCreateCompanionBuilder =
    StoreTablesCompanion Function({
      required String id,
      Value<String?> storeId,
      required String name,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$StoreTablesTableUpdateCompanionBuilder =
    StoreTablesCompanion Function({
      Value<String> id,
      Value<String?> storeId,
      Value<String> name,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$StoreTablesTableFilterComposer
    extends Composer<_$AppDatabase, $StoreTablesTable> {
  $$StoreTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoreTablesTable> {
  $$StoreTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoreTablesTable> {
  $$StoreTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StoreTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoreTablesTable,
          StoreTable,
          $$StoreTablesTableFilterComposer,
          $$StoreTablesTableOrderingComposer,
          $$StoreTablesTableAnnotationComposer,
          $$StoreTablesTableCreateCompanionBuilder,
          $$StoreTablesTableUpdateCompanionBuilder,
          (
            StoreTable,
            BaseReferences<_$AppDatabase, $StoreTablesTable, StoreTable>,
          ),
          StoreTable,
          PrefetchHooks Function()
        > {
  $$StoreTablesTableTableManager(_$AppDatabase db, $StoreTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreTablesCompanion(
                id: id,
                storeId: storeId,
                name: name,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreTablesCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoreTablesTable,
      StoreTable,
      $$StoreTablesTableFilterComposer,
      $$StoreTablesTableOrderingComposer,
      $$StoreTablesTableAnnotationComposer,
      $$StoreTablesTableCreateCompanionBuilder,
      $$StoreTablesTableUpdateCompanionBuilder,
      (
        StoreTable,
        BaseReferences<_$AppDatabase, $StoreTablesTable, StoreTable>,
      ),
      StoreTable,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db, _db.stores);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductOptionsTableTableManager get productOptions =>
      $$ProductOptionsTableTableManager(_db, _db.productOptions);
  $$ProductOptionValuesTableTableManager get productOptionValues =>
      $$ProductOptionValuesTableTableManager(_db, _db.productOptionValues);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransactionItemsTableTableManager get transactionItems =>
      $$TransactionItemsTableTableManager(_db, _db.transactionItems);
  $$AttendanceLogsTableTableManager get attendanceLogs =>
      $$AttendanceLogsTableTableManager(_db, _db.attendanceLogs);
  $$PromotionsTableTableManager get promotions =>
      $$PromotionsTableTableManager(_db, _db.promotions);
  $$PromotionItemsTableTableManager get promotionItems =>
      $$PromotionItemsTableTableManager(_db, _db.promotionItems);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$PaymentMethodsTableTableManager get paymentMethods =>
      $$PaymentMethodsTableTableManager(_db, _db.paymentMethods);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$StoreTablesTableTableManager get storeTables =>
      $$StoreTablesTableTableManager(_db, _db.storeTables);
}
