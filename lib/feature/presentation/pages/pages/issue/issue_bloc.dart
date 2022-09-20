import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/data/model/project_list_db_model.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/models/export_report_response_model.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:meta/meta.dart';
import "package:http/http.dart" as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'issue_event.dart';

part 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  final AuthenticationBloc? authenticationBloc;

  // IssueBloc({
  //   this.authenticationBloc,
  // })  : assert(authenticationBloc != null),
  //       super(IssueInitial());

  IssueBloc({this.authenticationBloc}) : super(IssueInitial()) {
    on<IssueEvent>(mapEventToState);
  }

  mapEventToState(IssueEvent event, emit) async {
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

    Map<String, String>? headers = {
      "cap2.0_tokenkey":
          await authenticationBloc?.sharedPref.getAuthToken() ?? "",
      "deviceId": deviceId,
      "deviceBrand": osType ?? "",
      "deviceModel": model ?? "",
      "osVersion": version.toString(),
      "appVersion": appVersion ?? "",
      "content-type": "application/json",
      "Accept-Encoding": "gzip, deflate, br",
    };

    if (event is GetIssueListFromDBEvent) {
      emit(LoadingState());

      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
      var userid = authenticationBloc?.sharedPref.getUserId();

      var t = event.reportId;
      print(t);

      try {
        List<Map<String, dynamic>?> issueList =
            await AppDatabase.instance.getIssues(t?? "");

        if (issueList != null || issueList != " " || issueList.length != 0) {
          print(1);
          emit(LoadedState(l: (issueList.length < 0) ? [] : issueList));
        } else {
          print(2);
          emit(LoadedState(l: []));
        }
      } on SocketException catch (e) {
        try {
          var listIssue = await AppDatabase.instance.getIssues(t!);

          if (listIssue != null || listIssue != " ") {
            print(1);
            emit(LoadedState(l: (listIssue.length < 0) ? [] : listIssue));
          } else {
            print(2);
            emit(LoadedState(l: []));
          }
        } on Exception catch (e) {
          emit(LoadedState(l: []));
          Utils.logException(
              className: "IssueBloc",
              methodName: "GetIssueListFromDBEvent",
              exceptionInfor: e.toString(),
              information1: e.toString());

          throw ServerException(message: Utils.ERROR_NO_RESPONSE);
        }
      } on Exception catch (e) {
        // emit( ErrorState(message: "Something Went wrong");
        emit(LoadedState(l: []));

        Utils.logException(
            className: "IssueBloc",
            methodName: "GetIssueListFromDBEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        var mm = "$e";
        getExceptionMethod(
            className: "issue Screen",
            methodName: "Delete Issue Method",
            userId: userid,
            baseUrl: baseUrl,
            exceptionInfo: mm);
        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is DeleteIssueEvent) {
      emit(LoadingState());

      try {
        int result = await AppDatabase.instance
            .deleteIssuessFromLocal(event.issueId.toString());
        if (result == 0) {
          emit(DeletedIssueState());
          return;
        } else {
          emit(DeletedIssueState());
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
            className: "IssueBloc",
            methodName: "DeleteIssueEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    //Export Report check
    if (event is ExportCheckEvent) {
      emit(ExportLoadingState());

      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

      print(event.emailId);

      var reportId = event.reportId;

      List listOfReports =
          await AppDatabase.instance.getExportIssues(reportId ?? "");

      // if (listOfReports.isEmpty) {
      //   return;
      // }
      var tt = Guid.newGuid;

      var url = "$baseUrl/ReportController/Report_ConfirmSyncWithServer/$tt";
      var response;
      print(url);
      print(headers);

      try {
        var body = {
          "Rpt_Id": reportId ?? "",
          "Issues": listOfReports,
        };
        response = await http.Client()
            .post(Uri.parse(url), headers: headers, body: json.encode(body));

        emit(ExportLoadingState());
        logOutEmit(emit: emit, response: response);

        print(response.statusCode);
        print(response.body);
        if (response.body == null) {
          throw ValidationException(message: response.body);
        } else if (response.statusCode == 200) {
          Map<String, dynamic> decodeJson = json.decode(response.body);

          var data = ExportReportReponseModel.fromJson(decodeJson);

          if (data.isSynced == false) {
            if (data.missingReportOnServer == false) {
              if (data.missingIssuesOnClient!.isNotEmpty) {
                add(GetAllMissingissuesEvent(
                    listOfIssueId: data.missingIssuesOnClient));
                // setIsIssueDirtyTrueInLocal(data.missingIssuesOnClient);
              }
              if (data.missingIssuesOnServer!.isNotEmpty) {
                setIsIssueDirtyTrueInLocal(data.missingIssuesOnServer);
              }
              if (data.issuesWithHasImageDiscrepancies!.isNotEmpty) {
                setIsIssueDirtyTrueInLocal(
                    data.issuesWithHasImageDiscrepancies);
              }
              if (data.issuesWithNoImages!.isNotEmpty) {
                for (var item in data.issuesWithNoImages!) {
                  await AppDatabase.instance.exportUpdateIsImageDirtyTrue(item);
                }
              }

              emit(ExportErrorState());
            } else {
              emit(ExportLoadedState(l: []));
            }
          } else {
            emit(ExportLoadedState(l: []));
          }

          print("im printing response in the loaded data in bloc home");
          print(response.body);
          print("im printing us");
        } else {
          emit(ExportErrorState());
          print("im in else");
          print(response.statusCode);
        }
      } on Exception catch (e) {
        emit(EmailSentState(l: true));

        Utils.logException(
            className: "IssueBloc",
            methodName: "ExportPdfEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is GetAllMissingissuesEvent) {
      // authenticationBloc?.sharedPref
      //     .saveAuthToken("KaK0Y9rUoDilbyPTyibbLGPJWcia73VRIPsgp5fw");

      var userid = authenticationBloc?.sharedPref.getUserName();
      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

      var trasactionId = Guid.newGuid;

      Map<String, String>? headers1 = headers;

      var url =
          "$baseUrl/ReportController/Report_Sync_DownloadMissingIssues/$trasactionId";
      var response;

      var body = {
        "Issues": event.listOfIssueId,
      };

      print(url);
      print(headers1);
      try {
        response = await http.Client()
            .post(Uri.parse(url), headers: headers1, body: json.encode(body));

        logOutEmit(emit: emit, response: response);
        if (response.body == null) {
          throw ValidationException(message: response.body);
        } else if (response.statusCode == 200) {
          print("im printing response in the loaded data in bloc home");
          print(response.body);
          authenticationBloc?.sharedPref.saveIsDataDownloadedAfterLogin(true);

          var userMap = jsonDecode(response.body);

          List<MissingIssuesModel> listOfIssues = List<MissingIssuesModel>.from(
              userMap.map((model) => MissingIssuesModel.fromJson(model)));

          await AppDatabase.instance
              .insertAllMissingIssuesFromSever(listOfIssues, userid ?? "");

          emit(RefreshPageState());
          // }
        } else {
          print(3);
          emit(LoadedState(l: []));

          getExceptionMethod(
              className: "Home Screen",
              methodName: "Get project List",
              userId: userid,
              baseUrl: baseUrl,
              exceptionInfo: response.statusCode);
        }

        print(response.statusCode);
        print(response.body);
      } on SocketException catch (_) {
        print('not connected');
        var projectList = await AppDatabase.instance.getProjectListFromDB();

        if (projectList != null || projectList != " ") {
          print(1);
          emit(LoadedState(l: (projectList.length < 0) ? [] : projectList));
        } else {
          print(2);
          emit(LoadedState(l: []));
        }
      } on Exception catch (e) {
        emit(LoadedState(l: []));

        Utils.logException(
            className: "HomeBloc",
            methodName: "Get project List",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is ExportPdfEvent) {
      emit(LoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));

      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

      print("im calling pdf api");
      print(event.emailId);
      var email = event.emailId;
      var fileName = event.fileName;
      var reportId = event.reportId;

      Map<String, String>? headers = {
        "cap2.0_tokenkey":
            await authenticationBloc?.sharedPref.getAuthToken() ?? "",
        "emailTo": email ?? "",
        "fileName": fileName ?? "",
        "deviceId": deviceId,
        "deviceBrand": osType ?? "",
        "deviceModel": model ?? "",
        "osVersion": version.toString(),
        "appVersion": appVersion ?? "",
        "content-type": "application/json",
        "Accept-Encoding": "gzip, deflate, br",
      };

      var tt = Guid.newGuid;

      var url = "$baseUrl/CmtaUserController/EmailReport/$tt";
      var response;
      print(url);
      print(headers);

      try {
        var body = {
          "ReportId": reportId ?? "",
          "FileName": fileName,
          "EmailTo": email
        };
        response = await http.Client()
            .put(Uri.parse(url), headers: headers, body: json.encode(body));

        logOutEmit(emit: emit, response: response);
        print(response.statusCode);
        print(response.body);
        emit(EmailSentState(l: true));
        if (response.body == null) {
          throw ValidationException(message: response.body);
        } else if (response.statusCode == 200) {
          print("im printing response in the loaded data in bloc home");
          print(response.body);
          print("im printing us");
        } else {
          print("im in else");
          print(response.statusCode);
        }
      } on Exception catch (e) {
        emit(EmailSentState(l: true));

        Utils.logException(
            className: "IssueBloc",
            methodName: "ExportPdfEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is LogoutEvent) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("LOGGED_IN", false);
      authenticationBloc?.sharedPref.userLoggedIn(false);
      SharedPreferences? _preff;
      _preff ??= await SharedPreferences.getInstance();
      _preff.setBool("USER_LOGGEDIN", false);
      print("logout");
      print(_preff.getBool("USER_LOGGEDIN"));
      emit(LogoutState());
    }
  }

  logOutEmit({emit, response}) {
    if (response.statusCode == 500) {
      if (response.body.contains("Token Has Expired")) {
        print("object : Token Expired");
        // emit(LogoutState());
        add(LogoutEvent());
      }
    }
  }

  setIsIssueDirtyTrueInLocal(List<String>? listIssueId) async {
    if (listIssueId!.isNotEmpty) {
      for (var item in listIssueId) {
        await AppDatabase.instance.exportUpdateIsIssueDirtyTrue(item);
      }
    }
  }

  getExceptionMethod(
      {String? userId,
      String? className,
      String? methodName,
      String? information1,
      String? information2,
      String? exceptionInfo,
      String? baseUrl}) async {
    var trasactionId = Guid.newGuid;

    String userName = authenticationBloc?.sharedPref.getUserName() ?? "";

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

    var headers = {
      "content-type": "application/json",
      "accept": "application/json",
      "apiKey": "480CFB8B-9628-481A-AB98-0002567D75A0",
      "userName": userName,
      "deviceId": deviceId,
      "deviceBrand": osType ?? "",
      "deviceModel": model ?? "",
      "osVersion": version.toString(),
      "appVersion": appVersion ?? "",
    };
    String url =
        "$baseUrl/ExceptionLogController/ExecuteExceptionLogLineSave/$trasactionId/$userId/$deviceId/$osType/$version/$className/$methodName/$information1/$information2/$exceptionInfo";
    var response = await http.Client().get(Uri.parse(url), headers: headers);

    logOutEmit(emit: emit, response: response);

    print(response);
    print(url);
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
