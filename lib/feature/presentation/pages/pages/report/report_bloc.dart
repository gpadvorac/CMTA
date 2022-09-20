import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/addReport_bloc.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:meta/meta.dart';
import "package:http/http.dart" as http;

part 'report_event.dart';

part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final AuthenticationBloc? authenticationBloc;

  // ReportBloc({
  //   this.authenticationBloc,
  // })  : assert(authenticationBloc != null),
  //       super(ReportInitial());

  ReportBloc({this.authenticationBloc}) : super(ReportInitial()) {
    on<ReportEvent>(mapEventToState);
  }

  mapEventToState(ReportEvent event, emit) async {
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

    if (event is GetProjectFromDBListEvent) {
      emit(LoadingState());

      print("im printing profile id");
      print(event.profileId);
      String r = event.profileId ?? "";
      // String userName = authenticationBloc?.sharedPref.getUserName() ?? "";
      // var transactionId = Guid.newGuid;

      try {
        List<Map<String, dynamic>?>? listReport =
            await AppDatabase.instance.getReports(r);

        if (listReport != null || listReport?.length != 0) {
          print(1);
          emit(LoadedState(l: (listReport!.length < 0) ? [] : listReport));
        } else {
          print(2);
          emit(LoadedState(l: []));
        }
      } on Exception catch (e) {
        Utils.logException(
            className: "ReportBloc",
            methodName: "GetProjectFromDBListEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        emit(LoadedState(l: []));

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is DeleteReportEvent) {
      emit(LoadingState());

      try {
        int result = await AppDatabase.instance
            .deleteReportsFromLocal(event.reportId.toString());
        if (result == 0) {
          emit(DeletedState(message: "Done"));
          return;
        } else {
          emit(ErrorState(message: "Fail to Delete"));
          Utils.logException(
              className: "ReportBloc",
              methodName: "DeleteReportEvent",
              exceptionInfor: "Fail to Delete Report",
              information1: "");
        }
      } on Exception catch (e) {
        emit(ErrorState(message: "Fail to Delete"));
        Utils.logException(
            className: "ReportBloc",
            methodName: "DeleteReportEvent",
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
