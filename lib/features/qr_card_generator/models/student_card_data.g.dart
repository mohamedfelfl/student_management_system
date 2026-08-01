// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudentCardData _$StudentCardDataFromJson(Map<String, dynamic> json) =>
    _StudentCardData(
      id: (json['id'] as num).toInt(),
      studentCode: json['studentCode'] as String,
      fullName: json['fullName'] as String,
      stageName: json['stageName'] as String? ?? 'الصف الأول الإعدادي',
      groupName: json['groupName'] as String? ?? '',
      groupSchedule: json['groupSchedule'] as String? ?? '',
      qrPayload: json['qrPayload'] as String,
    );

Map<String, dynamic> _$StudentCardDataToJson(_StudentCardData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentCode': instance.studentCode,
      'fullName': instance.fullName,
      'stageName': instance.stageName,
      'groupName': instance.groupName,
      'groupSchedule': instance.groupSchedule,
      'qrPayload': instance.qrPayload,
    };
