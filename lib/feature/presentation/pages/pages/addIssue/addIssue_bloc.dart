import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/data/model/project_list_db_model.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addProject/addProject_bloc.dart';
import 'package:cmta_field_report/models/exception.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_guid/flutter_guid.dart';
import 'package:meta/meta.dart';
import 'package:image/image.dart' as img;
import "package:http/http.dart" as http;
import 'package:path_provider/path_provider.dart';

part 'addissue_event.dart';

part 'addIssue_state.dart';

class AddIssueBloc extends Bloc<AddIssueEvent, AddIssueState> {
  final AuthenticationBloc? authenticationBloc;

  // AddIssueBloc({
  //   this.authenticationBloc,
  // })  : assert(authenticationBloc != null),
  //       super(AddIssueInitial());

  AddIssueBloc({this.authenticationBloc}) : super(AddIssueInitial()) {
    on<AddIssueEvent>(mapEventToState);
  }

  mapEventToState(AddIssueEvent event, emit) async {
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String id;
    var version;
    String? osType;
    String? appVersion;
    var deviceId = await getDeviceId();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        id = build.androidId;
        model = build.model;
        version = build.version.sdkInt;
        osType = "Android";
        appVersion = authenticationBloc?.sharedPref.getAppVersion() ?? "";
      } else if (Platform.isIOS) {
        var build = await deviceInfoPlugin.iosInfo;
        id = build.identifierForVendor;
        model = build.utsname.machine;
        version = build.systemVersion;
        osType = "IOS";
        appVersion = authenticationBloc?.sharedPref.getAppVersion() ?? "";
      }
    } on Exception {
      print('Failed to get Platform Information');
    }

    if (event is GetIssueFromDB) {
      emit(LoadingState());

      var t = event.issueId;

      try {
        Issues? issueList = await AppDatabase.instance.getAddedIssues(t!);

        if (issueList != null) {
          print(1);
          emit(LoadedState(
              issueImage: issueList.issueImagePathOriginal,
              isuDetails: issueList.isuDetails,
              isuId: issueList.isuId,
              isuLocation: issueList.isuLocation,
              isuReportId: issueList.isuRptId,
              isuStatus: issueList.isuStatus));

          // emit(LoadedState(l: (b.length < 0) ? [] : b));
        } else {
          print(2);
          emit(LoadedState(l: []));
        }
      } on Exception catch (e) {
        Utils.logException(
            className: "AddIssueBloc",
            methodName: "Get Issue Details Method",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    Future<File> isvertical(String imagePath, File image) async {
      final originalFile = File(imagePath);
      List<int> imageBytes = await originalFile.readAsBytes();

      final originalImage = img.decodeImage(imageBytes);
      final fixedImage = img.copyRotate(originalImage!, 90);
      // Here you can select whether you'd like to save it as png
      // or jpg with some compression
      // I choose jpg with 100% quality
      final fixedFile =
          await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
      return fixedFile;
    }

    Future<File> isNintyy(String imagePath, File image) async {
      final originalFile = File(imagePath);
      List<int> imageBytes = await originalFile.readAsBytes();

      final originalImage = img.decodeImage(imageBytes);
      final fixedImage = img.copyRotate(originalImage!, -90);
      // Here you can select whether you'd like to save it as png
      // or jpg with some compression
      // I choose jpg with 100% quality
      final fixedFile =
          await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
      return fixedFile;
    }

    Future<File> isOneEightyy(String imagePath, File image) async {
      final originalFile = File(imagePath);
      List<int> imageBytes = await originalFile.readAsBytes();

      final originalImage = img.decodeImage(imageBytes);
      final fixedImage = img.copyRotate(originalImage!, 180);
      // Here you can select whether you'd like to save it as png
      // or jpg with some compression
      // I choose jpg with 100% quality
      final fixedFile =
          await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
      return fixedFile;
    }

    if (event is AddIssue) {
      emit(LoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));
      String issueReportId = event.isuReportId ?? "";
      String issueStatus = event.isuStatus ?? "";
      String issueDetails = event.isuDetails ?? "";
      String issueLocation = event.isuLocation ?? "";
      String image = event.issueImage ?? "";
      print("im in the add issue bloc printing image");
      print(image);

      var issueId = (event.isuId == null) ? Guid.newGuid : event.isuId;

      String userName = authenticationBloc?.sharedPref.getUserName() ?? "";
      var _imageFile = event.imageFile;

      Map<String, String> headers = {
        "content-type": "application/json",
        "accept": "application/json",
        "apiKey": "05ED5C03-648D-447A-8D04-8F35D30124BD",
        "userName": userName,
        "deviceId": deviceId,
        "deviceBrand": osType ?? "",
        "deviceModel": model ?? "",
        "osVersion": version.toString(),
        "appVersion": appVersion ?? "",
      };
//
      // var url = "$baseUrl/IssueController/ExecuteIssueSaveV2/$trasactionId";
      var response;
      String j = event.orientation ?? "";

      if (Platform.isIOS) {
        if (j == "isVertical" && _imageFile != null) {
          File ri = await isvertical(_imageFile.path, _imageFile);
          _imageFile = ri;

          List<int> imageBytes = _imageFile.readAsBytesSync();

          image = base64.encode(imageBytes);
        } else if (j == "isOneEighty" && _imageFile != null) {
          File ri = await isOneEightyy(_imageFile.path, _imageFile);
          _imageFile = ri;

          List<int> imageBytes = _imageFile.readAsBytesSync();

          image = base64.encode(imageBytes);
        } else if (j == "isNinty" && _imageFile != null) {
          File ri = await isNintyy(_imageFile.path, _imageFile);
          _imageFile = ri;
          List<int> imageBytes = _imageFile.readAsBytesSync();

          image = base64.encode(imageBytes);
        }
      }

      var path = await getApplicationDocumentsDirectory();
      try {
        // if (event.issueImage != null) {
        //   final File newImage =
        //       await _imageFile!.copy('${path.path}/${issueId.toString()}.jpg');
        // }
        if (event.isUpdate == false) {
          var isSucceed = await AppDatabase.instance.insertIssueFromLocal(
            Issues(
                isuId: issueId.toString().toUpperCase(),
                isuRptId: issueReportId.toString(),
                isuLocation: issueLocation,
                isuDetails: issueDetails,
                isuStatus: issueStatus,
                isImageDirty: event.isImageDirty,
                // isImageDownloaded: 0,
                issueImagePathOriginal:
                    '${path.path}/${issueId.toString()}.jpg',
                isuHasImage: event.hasImage,
                issuImageLocaPath: path.path),
          );
          if (isSucceed == 0) {
            emit(CompletedIssueState(
                isError: false, isSuccess: true, strMessage: "Project saved!"));
          }

          // emit(CompletedState(
          //     isError: false, isSuccess: true, strMessage: "Project saved!"));

        } else {
          var isSucceed = await AppDatabase.instance.updateIssueFromLocal(
              Issues(
                  isuId: issueId.toString().toUpperCase(),
                  isuRptId: issueReportId.toString(),
                  isuLocation: issueLocation,
                  isuDetails: issueDetails,
                  isuStatus: issueStatus,
                  // isImageDownloaded: 0,
                  issueImagePathOriginal:
                      '${path.path}/${issueId.toString()}.jpg',
                  isuHasImage: event.hasImage,
                  isImageDirty: event.isImageDirty,
                  issuImageLocaPath: path.path));
          if (isSucceed == 0) {
            emit(CompletedIssueState(
                isError: false, isSuccess: true, strMessage: "Project saved!"));
          } else {
            emit(CompletedIssueState(
                isError: true,
                isSuccess: false,
                strMessage: "Project Not saved!"));
          }
        }
      } on Exception catch (e) {
        Utils.logException(
            className: "AddIssueBloc",
            methodName: "Add Issue Method",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }
  }

  saveExceptionInDB(ExceptionModel expection) {
    AppDatabase.instance.insertExceptionFromLocal(expection);
  }

  Future<String> getDeviceId() async {
    String? id;

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        id = build.androidId;

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
