import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/data/model/project_list_db_model.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/injector_container.dart';
import 'package:cmta_field_report/models/exception.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_guid/flutter_guid.dart';
import 'package:meta/meta.dart';
import "package:http/http.dart" as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_event.dart';

part 'home_state.dart';

int countTimer = 0;

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthenticationBloc? authenticationBloc;

  HomeBloc(this.authenticationBloc) : super(HomeInitial()) {
    on<HomeEvent>(mapEventToState);
    on<RefreshEvent>(uploadTaskBackground);
  }

  calculateDateDifferenceInHour() async {
    String expirationDate =
        await authenticationBloc?.sharedPref.getExpirationDate() ?? "";
    print("expirationDate : $expirationDate");

    try {
      String currentDateTime = Utils().getCurrTimeStamp();

      DateTime dtCurrentDate = DateTime.parse(currentDateTime);
      DateTime dtExpiration = DateTime.parse(expirationDate);

      Duration diff = dtExpiration.difference(dtCurrentDate);

      return diff.inHours.toString();
    }
    on Exception catch (_) {
      return "0";
    }
  }

  mapEventToState(HomeEvent event, emit) async {
    // authenticationBloc?.sharedPref
    //     .saveAuthToken("KaK0Y9rUoDilbyPTyibbLGPJWcia73VRIPsgp5fw");

    // authenticationBloc?.sharedPref
    //     .saveAuthToken("SNwpaZRiNL7Yzzn2gRYWoMiCka1cp6p1Ya9k2oOo");

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String? id;
    var version;
    String? osType;
    String? appVersion;
    var deviceId = await getDeviceId();
    print("object hellloooo");
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
//DO CHANGES HERE
    if (event is GetProjectListEvent) {
      emit(LoadingState());

      try {
        List projectList = await AppDatabase.instance.getProjectListFromDB();

        if (projectList != null || projectList.length != 0) {
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
            methodName: "GetProjectListEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
    }

    if (event is GetAllProjectListEvent) {
      emit(LoadingState());
      if (authenticationBloc?.sharedPref.isDataDownloadedFromAPI() == true) {
        var listProjects = await AppDatabase.instance.getProjectListFromDB();
        authenticationBloc?.sharedPref.saveIsDataDownloadedAfterLogin(true);

        if (listProjects != null || listProjects != " ") {
          print(1);
          emit(LoadedState(l: (listProjects.length < 0) ? [] : listProjects));
        } else {
          print(2);
          emit(LoadedState(l: []));
        }
        return;
      }
      // await postManAPiCall();
      print(authenticationBloc?.sharedPref.getUserId());
      var userid = authenticationBloc?.sharedPref.getUserId();
      var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
      String authToken =
          await authenticationBloc?.sharedPref.getAuthToken() ?? "";
      var trasactionId = Guid.newGuid;

      Map<String, String>? headers1 = await getHeader();

      var url =
          "$baseUrl/ProjectController/Project_Sync_DownloadAllDataFromServerV2/$trasactionId";
      var response;

      print(url);
      print(headers1);
      try {
        response = await http.Client().get(Uri.parse(url), headers: headers1);

        logOutEmit(emit: emit, response: response);
        if (response.body == null) {
          throw ValidationException(message: response.body);
        } else if (response.statusCode == 200) {
          print("im printing response in the loaded data in bloc home");
          print(response.body);
          authenticationBloc?.sharedPref.saveIsDataDownloadedAfterLogin(true);

          var userMap = jsonDecode(response.body);

          var allProjectData = AllProjectData.fromJson(userMap);

          await AppDatabase.instance.addProject(allProjectData);
          var listOfProject = await AppDatabase.instance.getProjectListFromDB();

          if (listOfProject != null || listOfProject != " ") {
            print(1);
            emit(LoadedState(
                l: (listOfProject.length < 0) ? [] : listOfProject));
          } else {
            print(2);

            emit(LoadedState(l: []));
          }
        } else {
          print(3);
          emit(LoadedState(l: []));
          //   var m = json.decode(response.body);
          //   var mm = m["Message"];
          //   print(m["Message"]);
          getExceptionMethod(
              className: "Home Screen",
              methodName: "Get project List",
              userId: userid,
              baseUrl: baseUrl,
              exceptionInfo: response.statusCode.toString());
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

    if (event is LogoutEvent) {
      _updatePreferences(false);
      authenticationBloc?.sharedPref.userLoggedIn(false);
      SharedPreferences? _preff;
      _preff ??= await SharedPreferences.getInstance();
      _preff.setBool("USER_LOGGEDIN", false);
      print("logout");
      print(_preff.getBool("USER_LOGGEDIN"));
      emit(LogoutState());
    }

    if (event is DeleteProjectEvent) {
      emit(LoadingState());
      // final useCase = await loginUseCase.call(LoginParam(
      //   emailId: event.userId,
      //   password: event.password,
      // ));

      print(authenticationBloc?.sharedPref.getUserId());

      try {
        int result = await AppDatabase.instance
            .deleteProjectFromLocal(event.projectId.toString());
        if (result == 0) {
          emit(DeletedState(message: "Done"));
          return;
        } else {
          emit(ErrorState(message: "Fail to Delete"));
          Utils.logException(
              className: "HomeBloc",
              methodName: "DeleteProjectEvent",
              exceptionInfor: "Fail to Delete",
              information1: "");
        }
      } on Exception catch (e) {
        // var m = json.decode(response.body);
        // var mm = m["Message"];
        // print("hhhfgdg");
        // print(m["Message"]);
        emit(ErrorState(message: e.toString()));
        Utils.logException(
            className: "HomeBloc",
            methodName: "DeleteProjectEvent",
            exceptionInfor: e.toString(),
            information1: e.toString());

        throw ServerException(message: Utils.ERROR_NO_RESPONSE);
      }
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

  updateCount(HomeEvent event, emit) async {
    if (event == UpdateCount) {
      emit(await AppDatabase.instance.getCurrentDownloadedCount());
    }
  }

  uploadTaskBackground(HomeEvent event, emits) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // print(" connected to mobile internet.");

      // I am connected to a mobile network.
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // print(" connected to wifi internet.");

      // I am connected to a wifi network.
    } else {
      print("Not connected to internet.");
      return;
    }

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String? id;
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
    // print("Timer to call client : $countTimer");
    // print("Data background uploading Timer: ${DateTime.now()}");
    var headerToPass = {
      "cap2.0_tokenkey":
          await authenticationBloc?.sharedPref.getAuthToken() ?? "",
      "deviceId": deviceId,
      "deviceBrand": osType ?? "",
      "deviceModel": model ?? "",
      "osVersion": version.toString(),
      "appVersion": appVersion ?? "",
    };

    await _updateDataInBackground(headers: headerToPass, emit: emits);

    countTimer++;
    if (countTimer == 0 || countTimer % 2 == 0) {
      List<Issues>? listIssueData =
          await AppDatabase.instance.getMissingIssueImagesFromLocalDB();
      if (listIssueData != null && listIssueData.length != 0) {
        AppDatabase.instance.dowloadOnIsolateMissingFile(listIssueData);
      }

      var pref = sl<SharedPreferences>();
      var arrayImages = pref.getStringList(MySharedPref.imageUrlList) ?? [];
      if (arrayImages.length >= listIssueData!.length) {
        await _upload404Images(headers: headerToPass, emit: emits);
      }
    }

    await _uploadImages(headers: headerToPass, emit: emits);
    await _uploadExceptions(headers: headerToPass, emit: emits);

    if (countTimer == 0 || countTimer % 3 == 0) {
      await _updateClientLogsInBackground(headers: {
        "cap2.0_tokenkey":
            await authenticationBloc?.sharedPref.getAuthToken() ?? "",
        "userName": authenticationBloc?.sharedPref.getUserName() ?? "",
        "deviceId": deviceId,
        "deviceBrand": osType ?? "",
        "deviceModel": model ?? "",
        "osVersion": version.toString(),
        "appVersion": appVersion ?? "",
      }, emit: emits);
    }
  }

  static int numberOfImageToUpload = 0;

  _uploadImages({Map<String, String>? headers, emit}) async {
    List<Issues?> issueList = await AppDatabase.instance.getImageDataToUpload();

    Directory dir = await getApplicationDocumentsDirectory();
    print("numberOfImageToUpload flag count: $numberOfImageToUpload");

    if (numberOfImageToUpload == 0) {
      print("In numberOfImageToUpload condition: $numberOfImageToUpload");

      numberOfImageToUpload = issueList.length;
      for (var issue in issueList) {
        print("In a LOOOOp $numberOfImageToUpload");
        print("issueList count : ${issueList.length}");
        numberOfImageToUpload = numberOfImageToUpload - 1;
        var imagePath = "${dir.path}/${issue!.isuId}.jpg";
        var isValid = await File(imagePath).exists();
        if (!isValid) {
          continue;
        }
        final bytes = File(imagePath).readAsBytesSync();

        var body = {
          "Isu_Id": issue.isuId ?? "",
          "ImageData": base64Encode(bytes).toString(),
        };

        print(authenticationBloc?.sharedPref.getUserId());
        var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
        var trasactionId = Guid.newGuid;

        var url =
            "$baseUrl/IssueController/ExecuteIssue_UploadImageV2/$trasactionId";
        var response;
        print(url);
        print("Data background uploading updated Images: ${DateTime.now()}");

        try {
          print("Uploading Start");
          await http.Client()
              .put(Uri.parse(url), headers: headers, body: json.encode(body))
              .then((response) {
            print(response.statusCode);
            print(response.body);

            logOutEmit(emit: emit, response: response);
            print("Uploaded with ${response.statusCode}: ${issue.isuId}");
            if (response.body == null) {
              throw ValidationException(message: response.body);
            } else if (response.statusCode == 200) {
              print("im printing response in the loaded data in bloc home");
              print(response.body);
              AppDatabase.instance
                  .updateIsDirtyDownloadImageIssue(issue.isuId ?? "");
            } else {
              numberOfImageToUpload = 0;

              Utils.logException(
                  className: "home_bloc",
                  methodName: "_uploadImages",
                  exceptionInfor: response.statusCode.toString(),
                  information1: "Issues id: ${issue.isuId}",
                  information2:
                      "Total Images are uploading: ${issueList.length}");
            }
          });
        } on Exception catch (e) {
          print("uploadImages $e");
          numberOfImageToUpload = 0;

          if (e.toString().contains("SocketException")) {
            return;
          }

          Utils.logException(
              className: "HomeBloc",
              methodName: "uploadImages",
              exceptionInfor: "Error while uploading image",
              information1: e.toString());

          throw ServerException(message: Utils.ERROR_NO_RESPONSE);
        }
      }
    } else {
      print("Next to upload : $numberOfImageToUpload");
    }
  }

  _upload404Images({Map<String, String>? headers, emit}) async {
    var body = await AppDatabase.instance.get404ImageDataToUpload();

    if (body.length == 0 || body.length == null) {
      return;
    }

    var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
    var trasactionId = Guid.newGuid;

    var url =
        "$baseUrl/IssueController/Issue_UploadImage404ErrorsV2/$trasactionId";
    var response;
    print(url);

    try {
      response = await http.Client()
          .put(Uri.parse(url), headers: headers, body: json.encode(body));
      print(response.statusCode);
      print(response.body);

      logOutEmit(emit: emit, response: response);
      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.statusCode == 200) {
        print("im printing response in upload404Images in bloc home");
        print(response.body);
        AppDatabase.instance.updateIs404DownloadImageIssueUpdated("");
      } else {
        Utils.logException(
            className: "HomeBloc",
            methodName: "_upload404Images",
            exceptionInfor: response.statusCode.toString(),
            information1: "Error while uploading 404 images");
      }
    } on Exception catch (e) {
      Utils.logException(
          className: "HomeBloc",
          methodName: "_upload404Images",
          exceptionInfor: "Error while uploading 404 images",
          information1: e.toString());

      throw ServerException(message: Utils.ERROR_NO_RESPONSE);
    }

    print("upload404");
  }

  _uploadExceptions({Map<String, String>? headers, emit}) async {
    List<ExceptionModel?> exceptionList =
        await AppDatabase.instance.getDataToUploadExceptionListFromDB();

    var arrayExceptions = [];
    for (var exception in exceptionList) {
      arrayExceptions.add({
        "ExcpetionId": exception!.excpetionId,
        "UserName": exception.userName,
        "DeviceId": exception.deviceId,
        "OsType": exception.osType,
        "OsVersion": exception.osVersion,
        "ClassName": exception.className,
        "MethodName": exception.methodName ?? "",
        "Information1": exception.information1 ?? "",
        "Information2": exception.information2 ?? "",
        "ExceptionInfo": exception.exceptionInfo ?? "",
      });
    }

    if (arrayExceptions.length == 0) {
      print("No exception to log");
      return;
    }
    print("${arrayExceptions.length} exceptions to log");
    var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
    var trasactionId = Guid.newGuid;

    var url =
        "$baseUrl/ExceptionLogController/ExecuteExceptionLog_UploadToServerV2/$trasactionId";
    var response;
    print(url);

    try {
      response = await http.Client().put(Uri.parse(url),
          headers: headers, body: json.encode(arrayExceptions));
      print(response.statusCode);
      print(response.body);

      logOutEmit(emit: emit, response: response);
      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.statusCode == 200) {
        print("im printing response in the loaded data in bloc home");
        print(response.body);

        for (var exception in exceptionList) {
          AppDatabase.instance
              .updateIsUploadedException(exception?.excpetionId ?? "");
        }
      } else {
        var body = {
          "UserName": authenticationBloc?.sharedPref.getUserName() ?? "",
          "DeviceId": headers?['deviceId'].toString() ?? "",
          "OsType": headers?['deviceBrand'].toString() ?? "",
          "OsVersion": headers?['osVersion'].toString() ?? "",
          "ClassName": "HomeBloc",
          "MethodName": "_uploadExceptions",
          "Information1": response.body,
          "Information2": "",
          "ExceptionInfo": response.statusCode
        };
        await _uploadExceptionLogLineSave(
            headers: headers, body: json.encode(body), emit: emit);
      }
    } on Exception catch (e) {
      Utils.logException(
          className: "HomeBloc",
          methodName: "uploadExceptions Method",
          exceptionInfor: e.toString(),
          information1: e.toString());

      // AppDatabase.instance.insertExceptionFromLocal(ExceptionModel(
      //     className: "UpdateExcelotion To Server",
      //     methodName: "uploadExceptions Method",
      //     userName: userName,
      //     exceptionInfo: e.toString(),
      //     deviceId: deviceId,
      //     excpetionId: Guid.newGuid.toString(),
      //     information1: e.toString(),
      //     information2: "",
      //     osType: Platform.isAndroid ? "Android" : "iOS",
      //     osVersion: ""));

      throw ServerException(message: Utils.ERROR_NO_RESPONSE);
    }

    print("object");
  }

  _uploadExceptionLogLineSave(
      {Map<String, String>? headers, body, emit}) async {
    var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();
    var trasactionId = Guid.newGuid;

    var url =
        "$baseUrl/ExceptionLogController/ExecuteExceptionLogLineSaveV2/$trasactionId";
    var response;
    print(url);

    try {
      response =
          await http.Client().put(Uri.parse(url), headers: headers, body: body);
      print(response.statusCode);
      print(response.body);
      logOutEmit(emit: emit, response: response);
      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.statusCode == 200) {
        print(
            "im printing uploadExceptionLogLineSave in the loaded data in bloc home");
        print(response.body);
      } else {}
    } on Exception catch (e) {
      Utils.logException(
          className: "HomeBloc",
          methodName: "uploadExceptionLogLineSave",
          exceptionInfor: e.toString(),
          information1: e.toString());

      throw ServerException(message: Utils.ERROR_NO_RESPONSE);
    }

    print("object");
  }

  _updateDataInBackground({Map<String, String>? headers, emit}) async {
    var userid = authenticationBloc?.sharedPref.getUserId();
    var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

    var trasactionId = Guid.newGuid;

    String url =
        "$baseUrl/ProjectController/Project_Sync_UploadAllNewDataToServerV2/$trasactionId";
    var response;
    Map<String, dynamic>? body = await AppDatabase.instance.getAllDataToUpload()
        as Map<String, dynamic>?;

    if (body == null) {
      return;
    }
    print(url);
    print(headers);

    try {
      var body1 = {
        "Projects": body["Projects"],
        "Issues": body["Issues"],
        "Reports": body["Reports"],
      };
      print("Issues to upload ${body1["Issues"]}");

      print("Data background uploading updated Data: ${DateTime.now()}");
      response = await http.Client()
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body1));

      print(response.statusCode);
      print(response.body);

      logOutEmit(emit: emit, response: response);
      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.statusCode == 200) {
        print(
            "im printing response in the loaded data in Project_Sync_UploadAllNewDataToServer");
        print(response.body);

        List result = json.decode(utf8.decode(response.bodyBytes));

        if (result != null || result.length != 0) {
          print(1);

          await AppDatabase.instance.updateAllSyncData(result);
        }
      } else {
        print(3);
        // emit(LoadedState(l: []));
        var m = json.decode(response.body);
        var mm = m["Message"];
        print(m["Message"]);
        getExceptionMethod(
            className: "Home Screen",
            methodName: "Get project List",
            userId: userid ?? "",
            baseUrl: baseUrl,
            exceptionInfo: mm);
      }
    } catch (e) {
      Utils.logException(
          className: "HomeBloc",
          methodName: "updateDataInBackground Method",
          exceptionInfor: e.toString(),
          information1: e.toString());

      print("Error uploading Dat: $e");
    }
  }

  _updateClientLogsInBackground({Map<String, String>? headers, emit}) async {
    var baseUrl = authenticationBloc?.sharedPref.getBaseUrl();

    var trasactionId = Guid.newGuid;

    String url =
        "$baseUrl/CmtaUserController/UploadClientDeviceActivityLogV2/$trasactionId";
    var response;
    try {
      var body = await AppDatabase.instance.getAllClientLogstoUpload();

      if (body == null) {
        return;
      }
      print(url);
      print(headers);

      await AppDatabase.instance
          .updateAllClientTransacgtionId(trasactionId.toString());

      response = await http.Client()
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body));

      print(response.statusCode);
      print(response.body);

      logOutEmit(emit: emit, response: response);

      if (response.body == null) {
        throw ValidationException(message: response.body);
      } else if (response.statusCode == 200) {
        print(
            "im printing response in the loaded data in _updateClientLogsInBackground");

        await AppDatabase.instance
            .updateResetAllClientTransacgtionId(trasactionId.toString());
        print("Done");
      }
    } catch (e) {
      Utils.logException(
          className: "HomeBloc",
          methodName: "_updateClientLogsInBackground",
          exceptionInfor: e.toString(),
          information1: e.toString());

      print("Error uploading Dat: $e");
    }
  }

  _updatePreferences(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("LOGGED_IN", value);
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
    var deviceId = await getDeviceId();

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String id;
    var version;
    String? osType;
    String? appVersion;

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

    Map<String, String> headers = await getHeader();

    String url =
        "$baseUrl/ExceptionLogController/ExecuteExceptionLogLineSaveV2/$trasactionId/$userId/$deviceId/$osType/$version/$className/$methodName/$information1/$information2/$exceptionInfo";
    var response = await http.Client().get(Uri.parse(url), headers: headers);

    print(response.statusCode);
    print(url);
  }

  getHeader() async {
    var deviceId = await getDeviceId();

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    String? model;
    String id;
    var version;
    String? osType;
    String? appVersion;

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
    } catch (e) {
      print(e);
    }
    return {
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
  }

  Future<String> getDeviceId() async {
    String? id;

    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        id = build.androidId;
        // var jh = build.model;
        // print("laksjjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjkjjk");
        // print(jh);
        // print(build.hardware);
        // print(build.host);
        // print(build.product);
        // print(build.manufacturer);

        print("printing device id");
        print(id);
      } else if (Platform.isIOS) {
        var build = await deviceInfoPlugin.iosInfo;
        id = build.identifierForVendor;
      }
    } on Exception {
      print('Failed to get Platform Information');
      return "";
    }

    return id ?? "";
  }
}
