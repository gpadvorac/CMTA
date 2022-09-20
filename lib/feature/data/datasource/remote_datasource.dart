import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/feature/data/client/client.dart';
import 'package:cmta_field_report/feature/data/model/login_response_model.dart';

import 'package:flutter/material.dart';

abstract class RemoteDataSource {
  // Future<LoginResponseModel> registration({
  //   String name,
  //   String emiRatedSid,
  //   String passPortNumber,
  //   String mobileNumber,
  //   String emailId,
  //   int dateOfBirth,
  //   int languageId,
  //   int mobileApplicationId,
  //   int mobileOsType,
  // });

  Future<LoginRequestData> login({final String emailId, final String password});
}

class RemoteDataSourceImpl extends RemoteDataSource {
  final RestClient? client;

  RemoteDataSourceImpl({@required this.client});

//   @override
//   Future<RegistrationResponseData> registration(
//       {String name,
//       String emiRatedSid,
//       String passPortNumber,
//       String mobileNumber,
//       String emailId,
//       int dateOfBirth,
//       int languageId,
//       int mobileApplicationId,
//       int mobileOsType})  async {
//   try {
//     final response = await client.registration(
//         name,
//         emiRatedSid,
//         passPortNumber,
//         mobileNumber,
//         emailId,
//         dateOfBirth,
//         languageId,
//         mobileApplicationId,
//         mobileOsType);
//     if(response.active!=null){
//       return response;
//     }
//     if (response.active == null) {
//       if (response.active == null) {
//         throw ValidationException(message: "Sucessful");
//       }
//       throw ServerException();
//     } else if (response.assetid == null)
//       return response;
//     else
//       return response;
//   } on Exception {
//     throw ServerException(message: Utils.ERROR_NO_RESPONSE);
//   }
// }

  @override
  Future<LoginRequestData> login(
      {final String? emailId, final String? password}) async {
    try {
      final response = await client!.login(
        emailId ?? " ",
        password ?? "",
      );

      if (response.msg == null) {
        if (response.msg != null) {
          throw ValidationException(message: response.msg);
        }
        throw ServerException();
      } else if (response.msg != null)
        return response;
      else
        return response;
    } on Exception {
      throw ServerException(message: Utils.ERROR_NO_RESPONSE);
    }
  }
}
