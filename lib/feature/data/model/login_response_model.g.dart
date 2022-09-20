// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseModel _$LoginResponseModelFromJson(Map<String, dynamic> json) =>
    LoginResponseModel(
      request: json['request'] == null
          ? null
          : LoginRequestData.fromJson(json['request'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseModelToJson(LoginResponseModel instance) =>
    <String, dynamic>{
      'request': instance.request,
    };

LoginRequestData _$LoginRequestDataFromJson(Map<String, dynamic> json) =>
    LoginRequestData(
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$LoginRequestDataToJson(LoginRequestData instance) =>
    <String, dynamic>{
      'msg': instance.msg,
    };
