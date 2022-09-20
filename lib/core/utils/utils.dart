import 'dart:convert';
import 'dart:io';

import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_screen.dart';
import 'package:cmta_field_report/models/exception.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:dio/dio.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../injector_container.dart';
import 'guid.dart';
import 'my_shared_pref.dart';
import 'package:path/path.dart' as path;

class Utils {
  static const String FONT_FAMILY = "Nunito";

  static const String ERROR_NO_RESPONSE = "No response from server";
  static const String ERROR_NO_INTERNET = "Internet not connected";
  static const String ERROR_UNKNOWN = "Unknown error occurred";

  /// Header information
  static const String AUTHORIZATION = "Authorization";
  static const String AUTHORIZATION_TOKEN =
      "Basic bWNhY2FyZS1zZ3c6TWNhQ2FyZUAyMDIw";
  static const String X_MESSAGE_ID = "X-Message-Id";
  static const String X_MESSAGE_ID_TOKEN = "22334";
  static const String CONTENT_TYPE = "Content-Type";
  static const String CONTENT_APPLICATION_JSON = "application/json";

  /// Helper channel to call native Android/iOS code
  static const platform = const MethodChannel('flutter.native/helper');

  /// Params
  static const String PARAM_STATE = "state";
  static const String PARAM_STATE_CODE = "stateCd";
  static const String PARAM_REQUEST = "request";
  static const String PARAM_MEMBER_SEC_TYPE_KEY = "mtdtType";
  static const String PARAM_MEMBER_SEC_TYPE_VALUE = "SECTION_TYPE";

  static const String PARAM_USERID = "userId";
  static const String PARAM_PASSWORD = "currPword";
  static const String PARAM_NEW_PASSWORD = "newPword";

  static const String PARAM_STATUSCD = "statusCd";

  static const String PARAM_ORGANIZATION_TYPE = "ORGTYPE";

  /// Constants
  static const String USER_TYPE_RAKYAT = "RKYT";
  static const String USER_TYPE_MEMBER = "MEMBR";
  static const String META_DATA_TYPE = "mtdtType";
  static const String ORGANIZATION_TYPE_GOVERNMENT = "GOV";
  static const String appVersion = "2.21.7";
  static const String serverDataFomate = "yyyy-MM-dd'T'HH:mm:ss.SSS";
  static const String serverReportDataFomate = "yyyy-MM-dd'T'HH:mm:ss";
  static const String appDateFomate = "MM/dd/yyyy";
  static const Color appPrimaryColor = Color(0xff0C8350);

  // static Dio dio = Dio();
  static List<String> arrayImages = [];
  static List<String> arrayTempImages = [];

  static Future<String> getDeviceId() async {
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

  /// Function to show the error toast message
  static void showErrorToast(
    String message,
    BuildContext context, {
    int duration = 1,
  }) {
    // Toast.show(message, context, duration: duration);

    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Color(0xAA000000),
        textColor: Colors.white,
        fontSize: 16.0);
  }

  String getCurrTimeStamp() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(now);
    // print("Time now : $formattedDate");
    return formattedDate; //'${DateTime.now().millisecondsSinceEpoch}';

    //
  }

  static Future<Map<String, dynamic>> getFilePath(uniqueFileName) async {
    String path = '';

    Directory dir = await getApplicationDocumentsDirectory();

    path = '${dir.path}/$uniqueFileName';

    return {"dirPath": "${dir.path}", "imageLocalPath": path};
  }

  static Future<bool> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile) {
      // print(" connected to mobile internet.");
      return true;
      // I am connected to a mobile network.
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // print(" connected to wifi internet.");
      return true;
      // I am connected to a wifi network.
    } else {
      print("Not connected to internet.");
      return false;
    }
  }

  static downloadFile(String imageUrl) async {
    // _downloadImage(imageUrl);
    // print("downloadFile start : $imageUrl");
    if (!(await checkInternet())) {
      print("Internet is not available");
      return;
    }
    var pref = sl<SharedPreferences>();
    arrayImages = pref.getStringList(MySharedPref.imageUrlList) ?? [];

    Dio? dio = Dio();

    bool _isloggedIn = pref.getBool(MySharedPref.isUserLoggedIn)!;
    if (!_isloggedIn) {
      // If user log out then we dont need to download iamges
      return;
    }
    try {
      String fileName = imageUrl.split('/').last;

      String tempFileName =
          "${fileName.split('.').first}-temp.jpg"; // to save image as temp
      Map<String, dynamic> savePath =
          await getFilePath(tempFileName); // this will be temp image path

      if (arrayTempImages.contains(tempFileName)) {
        // If image is already downloaded, we kept this check just to avoid file check operation
        return;
      }
      String filePath = '${savePath["dirPath"]}/$fileName';

      bool fileExists = await File(filePath).exists();
      if (fileExists) {
        // print("File exist: $fileName");
        return;
      }

      print("image downloading start");

      await dio
          .download(imageUrl, savePath["imageLocalPath"],
              onReceiveProgress: (rec, total) {})
          .then((value) {
        if (_isloggedIn) {
          if (!arrayImages.contains(fileName)) {
            arrayImages.add(fileName.toString());
            pref.setStringList(MySharedPref.imageUrlList, arrayImages);
          }

          if (!arrayTempImages.contains(tempFileName)) {
            arrayTempImages.add(tempFileName.toString());
            changeFileNameOnly(File(savePath["imageLocalPath"]), fileName);
            // print("Download completed : $imageUrl");
          }

          // await AppDatabase.instance.updateIsImageDownloadedOnLocalIssue(
          //     imageUrl.split('/').last.split('.').first, '0');
        }

        dio?.close();

        dio = null;
      }).onError((error, stackTrace) async {
        if (!arrayImages.contains(fileName)) {
          arrayImages.add(fileName.toString());
          pref.setStringList(MySharedPref.imageUrlList, arrayImages);
        }
        if (_isloggedIn) {
          if (error.toString().contains("Http status error [404]")) {
            await AppDatabase.instance.updateIsImageDownloadedOnLocalIssue(
                imageUrl.split('/').last.split('.').first,
                is404Error: '1');
          } else {
            await Utils.logException(
                className: "Utils",
                methodName: "downloadFile",
                exceptionInfor: jsonEncode(error.toString()),
                information1: imageUrl.toString());
          }
        }

        dio?.clear();
        dio?.close();
        print(error.toString());
      });
    } catch (e) {
      print("Failed isertion: downloadFile");
      dio?.close();
    }
  }

  static changeFileNameOnly(File file, String newFileName) {
    try {
      var path = file.path;
      var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
      var newPath = path.substring(0, lastSeparator + 1) + newFileName;
      file.renameSync(newPath);
    } catch (e) {
      print("ChangeFIlename issue : $e");
    }
  }

  /// Function to show the error toast message
  static void showToast(String message, BuildContext context,
      {int duration = 5, bool isCenter = false}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: duration <= 5 ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
        gravity: isCenter == false ? ToastGravity.BOTTOM : ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
  }

  static logException(
      {String? className,
      String? methodName,
      String? exceptionInfor,
      String? information1,
      String? information2 = ""}) async {
    var deviceId = await getDeviceId();
    final _pref = sl<SharedPreferences>();

    AppDatabase.instance.insertExceptionFromLocal(ExceptionModel(
        className: "$className",
        methodName: "$methodName",
        userName: _pref.getString(MySharedPref.USER_NAME) ?? " ",
        exceptionInfo: exceptionInfor,
        deviceId: deviceId,
        excpetionId: Guid.newGuid.toString(),
        information1: information1,
        information2: information2 ?? "",
        osType: Platform.isAndroid ? "Android" : "iOS",
        osVersion: _pref.getString(MySharedPref.VERSION) ?? " "));
  }

  static void showProgressDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            onWillPop: () {
              return Future.value(false);
            });
      },
    );
  }

  /// Dismiss the keyboard
  static void dismissKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  static getErrorFromDio(Response<dynamic> response) {
    if (response.data != null) {
      return response.data["message"];
    }
    return ERROR_UNKNOWN;
  }

  static printObject(Object object) {
    // Encode your object and then decode your object to Map variable
    Map jsonMapped = json.decode(json.encode(object));

    // Using JsonEncoder for spacing
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');

    // encode it to string
    String prettyPrint = encoder.convert(jsonMapped);

    // print or debugPrint your object
  }

  static firebaseSetup() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  logoutSessionExpiration(BuildContext context) {
    Navigation.intentWithClearAllRoutes(context, LoginPage.routeName);
  }
}
