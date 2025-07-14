// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertAdapter extends TypeAdapter<Alert> {
  @override
  final int typeId = 0;

  @override
  Alert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alert(
      type: fields[0] as String,
      message: fields[1] as String,
      value: fields[2] as String,
      time: fields[3] as DateTime,
      isCritical: fields[4] as bool,
      read: fields[5] as bool,
      tagNumber: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Alert obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.isCritical)
      ..writeByte(5)
      ..write(obj.read)
      ..writeByte(6)
      ..write(obj.tagNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
