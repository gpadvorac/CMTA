import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/error/failures.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/data/model/login_responseV2_model.dart';
import 'package:cmta_field_report/feature/domain/entities/login_response_entity.dart';
import 'package:cmta_field_report/feature/domain/usecase/login_usecase.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../publish_trace.dart';

part 'login_event.dart';

part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthenticationBloc? authenticationBloc;
  final LoginUseCase? loginUseCase;

  // LoginBloc(
  //     {@required AuthenticationBloc? authenticationBloc,
  //     @required LoginUseCase? loginUseCase})
  //     : assert(authenticationBloc != null),
  //       authenticationBloc = authenticationBloc,
  //       loginUseCase = loginUseCase,
  //       super(LoginInitial());

  LoginBloc(this.authenticationBloc, this.loginUseCase)
      : super(LoginInitial()) {
    on<LoginUserEvent>((event, emit) => setData(event, emit));
  }

  setData(event, emit) async {
    // if (event is LoginUserEvent) {

    if (event.password.toString().trim().isEmpty ||
        event.userId.toString().isEmpty) {
      emit(ErrorState(message: "Please enter valid credentials."));

      // emit(LoadedState());

      return;
    }
    emit(LoadingState());
    // await AppDatabase.instance.truncateTabkeData();
    authenticationBloc?.sharedPref.saveIsDataDownloadedAfterLogin(false);

    print("Helllooo");
    const USER_LOGGEDIN = "";
    SharedPreferences? _preff;
    _preff ??= await SharedPreferences.getInstance();
    print("in the bloc");
    print(event.password);
    print(event.userId);
    String uuserId = event.userId ?? "";
    String password = event.password ?? "";
    print(authenticationBloc?.sharedPref.getBaseUrl());
    var baseurl = authenticationBloc?.sharedPref.getBaseUrl();
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String id;
    var version;

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        id = build.androidId;
        model = build.model;
        version = build.version.sdkInt;
      } else if (Platform.isIOS) {
        var build = await deviceInfoPlugin.iosInfo;
        id = build.identifierForVendor;
        model = build.utsname.machine;
        version = build.systemVersion;
      }
    } on Exception {
      print('Failed to get Platform Information');
    }
    var deviceId = await getDeviceId();
    String osType = Platform.isIOS ? "IOS" : "Android";
    String osVersion = "12";

    Map<String, String>? headers = {
      "content-type": "application/json",
      "accept": "application/json",
      "apiKey": "13DD4209-F275-4471-BBBB-9B4F193DADF1",
      "userName": uuserId,
      "password": password,
      "deviceId": deviceId,
      "deviceBrand": osType,
      "deviceModel": model ?? "",
      "osVersion": version.toString(),
      "appVersion": FlavorConfig.instance?.values.appVersion.toString() ??"",
    };

    var guId = Guid.newGuid;

    var url = "$baseurl/CmtaUserController/AuthenticateV2/$guId";
    var response;
    print(url);
    print(headers);
/*
https://cmtafr-dev.crocodiledigital.net/api/CmtaUserController/Authenticate/c4323bef-fd5c-4692-a78e-d916b17d25d5
( 6858): {content-type: application/json, accept: application/json, apiKey: 13DD4209-F275-4471-BBBB-9B4F193DADF1, userName: cafr1@cmtaegrs.com, password: Cr0cod1le@, deviceId: 87e17edce92ebefe, deviceBrand: Android, deviceModel: Android SDK built for x86, osVersion: 30, appVersion: 1.0.9}

*/
    try {
      response = await http.Client().get(Uri.parse(url), headers: headers);
      print(response.statusCode);
      print(response.body);
      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.body != null) {
        print("im printing response in the loaded data in bloc login");

        if (response.statusCode == 200) {
          authenticationBloc?.sharedPref.saveUserName(event.userId ?? "");
          authenticationBloc?.sharedPref.savePassword(event.password ?? "");
          authenticationBloc?.sharedPref
              .saveAppVersion(FlavorConfig.instance?.values.appVersion.toString()??"");
          authenticationBloc?.sharedPref.saveEmailName(event.userId ?? "");

          var jsonData = json.decode(response.body);
          var result = LoginV2Model.fromJson(jsonData);

          authenticationBloc?.sharedPref.saveUserId(result.cmtaUserId);
          authenticationBloc?.sharedPref.saveAuthToken(result.token);

          authenticationBloc?.sharedPref
              .saveTokenExpirationDate(result.expirationDate);

          _updatePreferences(true);
          authenticationBloc?.sharedPref.userLoggedIn(true);

          await _preff.setBool("USER_LOGGEDIN", true);

          print(_preff.getBool("USER_LOGGEDIN"));
        } else {
          var m = json.decode(response.body);
          var mm = m["Message"];
          print("hhhfgdg");
          print(m["Message"]);
          getExceptionMethod(
              className: "Login Screen",
              methodName: "login user event",
              appversion: authenticationBloc?.sharedPref.getAppVersion() ?? "",
              userId: "null",
              baseUrl: baseurl ?? "",
              exceptionInfo: mm);
        }

        emit(LoadedState(userInformation: response.statusCode));
      }
    } on Exception catch (e) {
      Utils.logException(
          className: "LoginBloc",
          methodName: "LoginUserEvent",
          exceptionInfor: e.toString(),
          information1: e.toString());

      emit(LoadedState(userInformation: 204));
      getExceptionMethod(
          className: "Login Screen",
          methodName: "login user event",
          userId: "null",
          baseUrl: baseurl,
          exceptionInfo: e.toString());
      print("serviece Error ${e.toString()}");

      throw ServerException(message: Utils.ERROR_NO_RESPONSE);
    }
    // }
  }

  _updatePreferences(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("LOGGED_IN", value);
  }

  getExceptionMethod(
      {String? userId,
      String? className,
      String? methodName,
      String? information1 = "",
      String? information2 = "",
      String? exceptionInfo,
      String? appversion,
      String? baseUrl}) async {
    var trasactionId = Guid.newGuid;
    var deviceId = await getDeviceId();
    String osType = Platform.isIOS ? "IOS" : "Android";
    String osVersion = "12";
    String userName = authenticationBloc?.sharedPref.getUserName() ?? "";
    print("calling exception method");
    Map<String, String>? headers = {
      "content-type": "application/json",
      "accept": "application/json",
      "apiKey": "480CFB8B-9628-481A-AB98-0002567D75A0",
      "userName": userName,
      "deviceId": deviceId,
      "deviceBrand": osType,
      "deviceModel": osVersion,
      "osVersion": osVersion,
      "appVersion": appversion ?? ""
    };
    String url =
        "$baseUrl/ExceptionLogController/ExecuteExceptionLogLineSave/$trasactionId/hhh/$deviceId/$osType/$osVersion/$className/$methodName/$information1/$information2/$exceptionInfo";
    var response =
        await http.Client().get(Uri.parse(url), headers: headers).then((value) {
      print(url);
      print("resi");
      print(value.statusCode);
    }).onError((error, stackTrace) {
      print("ExecuteExceptionLogLineSave : $error");
    });
  }

  Future<String> getDeviceId() async {
    String? id;

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        id = build.androidId;
        var jh = build.model;
        print("laksjjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjjk");
        print(jh);
        print(build.hardware);
        print(build.host);

        print("printing device id");
        print(id);
      } else if (Platform.isIOS) {
        var build = await deviceInfoPlugin.iosInfo;
        id = build.identifierForVendor;
      }
    } on Exception {
      print('Failed to get Platform Information');
    }

    return id ?? "";
  }
}
