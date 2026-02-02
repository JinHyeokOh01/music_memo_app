// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SummaryAdapter extends TypeAdapter<Summary> {
  @override
  final int typeId = 1;

  @override
  Summary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Summary(
      id: fields[0] as String,
      type: fields[1] as SummaryType,
      date: fields[2] as DateTime,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Summary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SummaryTypeAdapter extends TypeAdapter<SummaryType> {
  @override
  final int typeId = 0;

  @override
  SummaryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SummaryType.daily;
      case 1:
        return SummaryType.weekly;
      case 2:
        return SummaryType.monthly;
      default:
        return SummaryType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, SummaryType obj) {
    switch (obj) {
      case SummaryType.daily:
        writer.writeByte(0);
        break;
      case SummaryType.weekly:
        writer.writeByte(1);
        break;
      case SummaryType.monthly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
