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
import 'package:cmta_field_report/models/exception.dart';
import 'package:cmta_field_report/models/issue.dart';
import 'package:cmta_field_report/models/project.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import "package:http/http.dart" as http;
// import 'package:flutter_guid/flutter_guid.dart';

part 'addProject_event.dart';

part 'addProject_state.dart';

class AddProjectBloc extends Bloc<AddProjectEvent, AddProjectState> {
  final AuthenticationBloc? authenticationBloc;

  // AddProjectBloc({
  //   this.authenticationBloc,
  // })  : assert(authenticationBloc != null),
  //       super(AddProjectInitial());

  AddProjectBloc({this.authenticationBloc}) : super(AddProjectInitial()) {
    on<AddProjectEvent>(mapEventToState);
  }

  mapEventToState(AddProjectEvent event, emit) async {
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
        appVersion = authenticationBloc?.sharedPref.getAppVersion();
      } else if (Platform.isIOS) {
        var build = await deviceInfoPlugin.iosInfo;
        id = build.identifierForVendor;
        model = build.utsname.machine;
        version = build.systemVersion;
        osType = "IOS";
        appVersion = authenticationBloc?.sharedPref.getAppVersion();
      }
    } on Exception {
      print('Failed to get Platform Information');
    }

    if (event is AddEvent) {
      //Save to Local
      emit(ProjectLoadingState());
      String? projectLocation = event.projectLocation;
      String? projectNumber = event.projectNumber;
      String? projectName = event.projectName;

      var projectId =
          (event.projectId == null) ? Guid.newGuid : event.projectId;

      print(authenticationBloc?.sharedPref.getUserId());
      var userid = authenticationBloc?.sharedPref.getUserId();
      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

      var body = {
        "Pj_Id": projectId.toString(),
        "Pj_CUsr_Id": userid ?? "",
        "Pj_Number": projectNumber,
        "Pj_Name": projectName,
        "Pj_Location": projectLocation
      };
      print(jsonEncode(body));
      try {
        var isSucceed;

        if (event.projectId != null) {
          isSucceed = await AppDatabase.instance.updateProject(Projects(
              pjId: projectId.toString(),
              pjCUsrId: userid ?? "",
              pjNumber: projectNumber,
              pjName: projectName,
              pjLocation: projectLocation));
        } else {
          isSucceed = await AppDatabase.instance.insertProjectsFromLocal(
              Projects(
                  pjId: projectId.toString().toUpperCase(),
                  pjCUsrId: userid ?? "",
                  pjNumber: projectNumber,
                  pjName: projectName,
                  pjLocation: projectLocation));
        }

        if (isSucceed == 0) {
          emit(ProjectCompletedState(
              isError: false, isSuccess: true, strMessage: "Project saved!"));
        }
      } on Exception catch (e) {
        var mm = "$e";

        Utils.logException(
            className: "AddProjectBloc",
            methodName: "SAVE(AddEvent) Method",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is GetProjectEvent) {
      emit(ProjectLoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));
      print(event.projectId);

      try {
        var projectList = await AppDatabase.instance
            .getProjectFromDB(event.projectId.toString());

        print("im printing response in the loaded data in bloc homehhhhhhhh");
        // var b = json.decode(response.body);
        print("check");
        if (projectList.length == 0) {
          emit(ProjectLoadedState());
        }
        emit(ProjectLoadedState(
            pjCustomerId: projectList["Pj_CUsr_Id"],
            pjId: projectList["Pj_Id"],
            pjNumber: projectList["Pj_Number"],
            pjLocation: projectList["Pj_Location"],
            pjName: projectList["Pj_Name"]));
      } on Exception catch (e) {
        Utils.logException(
            className: "AddProjectBloc",
            methodName: "Project_GetById",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }
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
