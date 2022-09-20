import 'package:json_annotation/json_annotation.dart';

part 'login_response_model.g.dart';

@JsonSerializable()
class LoginResponseModel {
  final LoginRequestData? request;

  LoginResponseModel({this.request});

  factory LoginResponseModel.fromJson(json) =>
      _$LoginResponseModelFromJson(json);

  toJson() => _$LoginResponseModelToJson(this);

  // factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
  //     _$LoginResponseModelFromJson(json);

  // Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}

@JsonSerializable()
class LoginRequestData {
  final String? msg;

  LoginRequestData({this.msg});

  factory LoginRequestData.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDataFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDataToJson(this);
}
