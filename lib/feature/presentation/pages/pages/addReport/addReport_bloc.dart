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
import 'package:cmta_field_report/models/report.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_guid/flutter_guid.dart';
import 'package:meta/meta.dart';
import "package:http/http.dart" as http;

part 'addReport_event.dart';

part 'addReport_state.dart';

class AddReportBloc extends Bloc<AddReportEvent, AddReportState> {
  final AuthenticationBloc? authenticationBloc;

  // AddReportBloc({
  //   this.authenticationBloc,
  // })  : assert(authenticationBloc != null),
  //       super(AddReportInitial());

  AddReportBloc({this.authenticationBloc}) : super(AddReportInitial()) {
    on<AddReportEvent>(mapEventToState);
  }
  mapEventToState(AddReportEvent event, emit) async {
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

    if (event is GetReportEvent) {
      emit(LoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));

      try {
        Reports report = await AppDatabase.instance
            .getReportListFromDB(event.reportId ?? "");

        emit(LoadedState(
            rptId: report.rptId,
            rptPreparedBy: report.rptPreparedBy,
            rptProjectId: report.rptPjId,
            rptPunchListType: report.rptPunchListType,
            notes: report.rptRemarks.toString(),
            rptVisitDate: report.rptVisitDate.toString()));
      } on Exception catch (e) {
        Utils.logException(
            className: "AddReportBloc",
            methodName: "Report_GetById",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }
    if (event is AddReport) {
      emit(LoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));
      String preparedBy = event.rptPreparedBy ?? "";
      String reportVisitDate = event.rptVisitDate ?? "";
      String punchListType = event.rptPunchListType ?? "";

      var reportId = (event.rptId == null) ? Guid.newGuid : event.rptId;
      var reportProjectId = event.rptProjectId;
      print("printing in add report bloc");
      print(event.notes!.isEmpty);
      var notes = (event.notes!.isEmpty) ? null : event.notes;

      var body = {
        "Rpt_Id": reportId.toString(),
        "Rpt_Pj_Id": reportProjectId.toString(),
        "Rpt_PunchListType": punchListType,
        "Rpt_VisitDate": reportVisitDate,
        "Rpt_PreparedBy": preparedBy,
        "Rpt_Remarks": notes
      };

      print(body);

      try {
        var isSucceed = 0;

        if (event.rptId != null) {
          isSucceed = await AppDatabase.instance.updateReport(Reports(
              rptId: reportId.toString().toUpperCase(),
              rptPjId: reportProjectId.toString(),
              rptPunchListType: punchListType,
              rptPreparedBy: preparedBy,
              rptVisitDate: reportVisitDate,
              rptRemarks: notes));
        } else {
          isSucceed = await AppDatabase.instance.insertReportsFromLocalDB(
              Reports(
                  rptId: reportId.toString().toUpperCase(),
                  rptPjId: reportProjectId.toString(),
                  rptPunchListType: punchListType,
                  rptPreparedBy: preparedBy,
                  rptVisitDate: reportVisitDate,
                  rptRemarks: notes));
        }

        if (isSucceed == 0) {
          emit(CompletedState(
              isError: false, isSuccess: true, strMessage: "Report saved!"));
        }
      } on Exception catch (e) {
        Utils.logException(
            className: "AddReportBloc",
            methodName: "SAVE(AddReport) Method",
            exceptionInfor: e.toString(),
            information1: e.toString());

        // AppDatabase.instance.insertExceptionFromLocal(ExceptionModel(
        //     className: "Add Report",
        //     methodName: "SAVE(AddReport) Method",
        //     userName: userName,
        //     exceptionInfo: e.toString(),
        //     deviceId: deviceId,
        //     excpetionId: Guid.newGuid.toString(),
        //     information1: e.toString(),
        //     information2: "",
        //     osType: osType,
        //     osVersion: version));
        // getExceptionMethod(
        //     className: "Add Report",
        //     methodName: "Add Report",
        //     userId: userid ?? "",
        //     baseUrl: baseUrl ?? "",
        //     exceptionInfo: e.toString());
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
