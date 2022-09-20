import 'dart:async';

import 'dart:io';
import 'dart:isolate';
// import 'dart:isolate';
import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/feature/data/model/project_list_db_model.dart';
import 'package:cmta_field_report/models/exception.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../injector_container.dart';
import 'databse_class.dart';

class AppDatabase {
  static final AppDatabase _singleton = AppDatabase._();
  static AppDatabase get instance => _singleton;
  String projectTableName = "Project";
  String reportsTableName = "Reports";
  String issuesTableName = "Issues";
  String exceptionTableName = "Exception";
  static String clientDeviceActivityLog = "ClientDeviceActivityLog";
  // static String userId = "";

  Isolate? isolate;
  static int downloadedCount = 0;
  ReceivePort? receivePort;

  AppDatabase._();

  String getCurrTimeStamp() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(now);
    // print("Time now : $formattedDate");
    return formattedDate; //'${DateTime.now().millisecondsSinceEpoch}';

    //
  }

  getCurrentDownloadedCount() {
    print("object PRAGMA user_version;");
    return downloadedCount;
  }

  static downloadImagesInBackgroud(Map map) async {
    var allProjectData = map["allProjectData"];
    var pref = map["pref"];

    bool _seen = (pref.getBool('USER_LOGGEDIN') ?? false);

    for (Issues issueData in allProjectData.issues) {
      if (!_seen) {
        break;
      }
      try {
        String imageURL = issueData.issueImagePathOriginal ?? "";
        bool _validURL = Uri.parse(imageURL).isAbsolute;

        if (issueData.issueImagePathOriginal != "" && _validURL) {
          await Utils.downloadFile(imageURL);
        }
      } catch (e) {
        Utils.logException(
            className: "AppDatabase",
            methodName: "downloadImagesInBackgroud",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("error on ${issueData.isuId}");
      }
    }
  }

  dowloadOnIsolateMissingFile(List<Issues> allIssuesData) async {
    try {
      final pref = sl<SharedPreferences>();
      Map map = Map();
      map["allProjectData"] = allIssuesData;
      map["pref"] = pref;
      if (allIssuesData.length != 0) {
        await downloadMissingImagesInBackgroud(map);
      }
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "dowloadOnIsolateMissingFile",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Error: $e");
    }
  }

  static downloadMissingImagesInBackgroud(Map map) async {
    // SharedPreferences _preff = await SharedPreferences.getInstance();

    List<Issues> allIssuesData = map["allProjectData"];
    var pref = map["pref"];
    List<String> arrayImages =
        pref.getStringList(MySharedPref.imageUrlList) ?? [];

    bool isUsserLoggedIn = (pref.getBool('USER_LOGGEDIN') ?? false);
    var remainingData = allIssuesData.where((element) =>
        !arrayImages.contains(element.issueImagePathOriginal?.split("/").last));
    for (Issues issueData in remainingData) {
      if (issueData.issueImagePathOriginal == null) {
        continue;
      }

      if (!isUsserLoggedIn) {
        break;
      }
      try {
        String imageURL = issueData.issueImagePathOriginal ?? "";
        bool _validURL = Uri.parse(imageURL).isAbsolute;

        if (issueData.issueImagePathOriginal != "" && _validURL) {
          await Utils.downloadFile(imageURL);
        } else {
          if (imageURL.contains("Containers/Data")) {
            continue;
          }
          await AppDatabase.instance.updateIsImageDownloadedOnLocalIssue(
              imageURL.split('/').last.split('.').first,
              is404Error: '1');
        }
      } catch (e) {
        Utils.logException(
            className: "AppDatabase",
            methodName: "downloadMissingImagesInBackgroud",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("error on ${issueData.isuId}");
      }
    }
  }

  void spawnNewIsolate(allProjectData, documentsDirectory) async {
    try {
      final pref = sl<SharedPreferences>();
      Map map = Map();
      map["allProjectData"] = allProjectData;
      map["pref"] = pref;

      await downloadImagesInBackgroud(map);
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "spawnNewIsolate",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Error: $e");
    }
  }

//# Insert Operations
  addProject(allProjectData) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    try {
      print("object1");

      await insertAllProjectsFromSever(allProjectData?.projects, userId);
      await insertAllReportsFromSever(allProjectData?.reports, userId);
      await insertAllIssuesFromSever(allProjectData?.issues, userId);
      print("object finished");

      spawnNewIsolate(allProjectData, documentsDirectory);
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "addProject",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("object Erro");
    }

    print("object2");
  }

  insertAllProjectsFromSever(List<Projects>? projects, String userId) async {
    Database dbProject = await DB.instance.database;
    if (!dbProject.isOpen) {
      print("DB is closed");

      return;
    }

    if (projects != null && projects.length != 0) {
      for (var newProject in projects) {
        // print("Inserted in Project");
        try {
          final projectObjectValues = <String, dynamic>{
            'user_id': userId,
            'Pj_Id': newProject.pjId,
            'Pj_CUsr_Id': newProject.pjCUsrId,
            'Pj_Number': newProject.pjNumber,
            'Pj_Name': newProject.pjName,
            'Pj_Location': newProject.pjLocation,
            'Pj_CreatedDate': newProject.pjCreateDate,
            'Pj_LastModifiedDate': newProject.pjLastModifiedDate
          };

          await dbProject.insert('$projectTableName', projectObjectValues,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (e) {
          // dbProject.close();
          Utils.logException(
              className: "AppDatabase",
              methodName: "insertAllProjectsFromSever",
              exceptionInfor: e.toString(),
              information1: e.toString());
          print("Failed isertion: projects ");
          print(e);
        }
      }
    }

    // dbProject.close();
  }

  insertAllReportsFromSever(List<Reports>? reports, String userId) async {
    Database dbReport = await DB.instance.database;
    if (!dbReport.isOpen) {
      print("DB is closed");

      return;
    }
    if (reports != null && reports.length != 0) {
      for (var newReport in reports) {
        print("Inserted in reports");
        if (!dbReport.isOpen) {
          print("ReportDB is closed");
          dbReport = await DB.instance.database;
        }
        try {
          final reportValue = <String, dynamic>{
            'user_id': userId,
            'Rpt_Id': newReport.rptId,
            'Rpt_Pj_Id': newReport.rptPjId,
            'Rpt_PreparedBy': newReport.rptPreparedBy,
            'Rpt_PunchListType': newReport.rptPunchListType,
            'Rpt_VisitDate': newReport.rptVisitDate,
            'Rpt_Remarks': newReport.rptRemarks,
            'Rpt_CreatedDate':
                newReport.rptCreatedDate ?? "${getCurrTimeStamp()}",
            'Rpt_LastModifiedDate': newReport.rptLastModifiedDate
          };

          await dbReport.insert('$reportsTableName', reportValue,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (e) {
          print("Failed isertion: reports ");
          print(e);
        }
      }
    }
    // dbReport.close();
  }

  insertAllIssuesFromSever(List<Issues>? issues, String userId) async {
    Database dbIssue = await DB.instance.database;
    Directory dir = await getApplicationDocumentsDirectory();

    if (!dbIssue.isOpen) {
      print("DB is closed");
      return;
    }
    if (issues != null && issues.length != 0) {
      for (var newIssue in issues) {
        print("Inserted in issues");
        if (!dbIssue.isOpen) {
          print("IssueDB is closed");
          dbIssue = await DB.instance.database;
        }
        try {
          final issueValue = <String, dynamic>{
            'user_id': userId,
            'IssueImagePath_Original': newIssue.issueImagePathOriginal,
            'Isu_Details': newIssue.isuDetails,
            'Isu_Id': newIssue.isuId,
            'Isu_Location': newIssue.isuLocation,
            'Isu_Rpt_Id': newIssue.isuRptId,
            'Isu_Status': newIssue.isuStatus,
            'Issu_Image_Loca_Path': newIssue.issueImagePathOriginal,
            'Isu_HasImage': newIssue.isuHasImage == true ? '1' : '0',
            'Isu_CreatedDate':
                newIssue.isuCreatedDate ?? '${getCurrTimeStamp()}',
            'Issu_Is_Image_downloaded': '0',
            'Isu_LastModifiedDate': newIssue.isuLastModifiedDate
          };

          var result = await dbIssue.insert('$issuesTableName', issueValue,
              conflictAlgorithm: ConflictAlgorithm.ignore);

          print("Resuult : $result");
        } catch (e) {
          // dbIssue.close();
          Utils.logException(
              className: "AppDatabase",
              methodName: "insertAllIssuesFromSever",
              exceptionInfor: e.toString(),
              information1: e.toString());
          print("Failed iserting All issues: issues ");
          // print(newIssue.isuRptId);
          print(e);
        }
      }
    }
    // dbIssue.close();
  }

  insertAllMissingIssuesFromSever(
      List<MissingIssuesModel>? issues, String userId) async {
    Database dbIssue = await DB.instance.database;
    Directory dir = await getApplicationDocumentsDirectory();

    if (!dbIssue.isOpen) {
      print("DB is closed");
      return;
    }
    if (issues != null && issues.length != 0) {
      for (var newIssue in issues) {
        print("Inserted in issues");
        if (!dbIssue.isOpen) {
          print("IssueDB is closed");
          dbIssue = await DB.instance.database;
        }
        try {
          final issueValue = <String, dynamic>{
            'user_id': userId,
            'IssueImagePath_Original': newIssue.issueImagePathOriginal,
            'Isu_Details': newIssue.isuDetails,
            'Isu_Id': newIssue.isuId,
            'Isu_Location': newIssue.isuLocation,
            'Isu_Rpt_Id': newIssue.isuRptId,
            'Isu_Status': newIssue.isuStatus,
            'Issu_Image_Loca_Path': newIssue.issueImagePathOriginal,
            'Isu_HasImage': newIssue.isuHasImage == true ? '1' : '0',
            'Isu_CreatedDate':
                newIssue.isuCreatedDate ?? '${getCurrTimeStamp()}',
            'Isu_Deleted_Flag': newIssue.isIssueDeletedFlag,
            'Issu_Is_Image_downloaded': '0',
            'Isu_LastModifiedDate': newIssue.isuLastModifiedDate
          };

          String parameters =
              "user_id = '${userId.toString()}',IssueImagePath_Original = '${newIssue.issueImagePathOriginal}',Isu_Details = '${newIssue.isuDetails}',Isu_Id = '${newIssue.isuId}',Isu_Location = '${newIssue.isuLocation}',Isu_Rpt_Id = '${newIssue.isuRptId}',Isu_Status = '${newIssue.isuStatus}',Issu_Image_Loca_Path = '${newIssue.issueImagePathOriginal}',Isu_HasImage = ${newIssue.isuHasImage == true ? '1' : '0'},Isu_CreatedDate = '${newIssue.isuCreatedDate ?? getCurrTimeStamp()}',Issu_Is_Image_downloaded = '0',Isu_LastModifiedDate = '${newIssue.isuLastModifiedDate}',Isu_Deleted_Flag = ${newIssue.isIssueDeletedFlag == true ? '1' : '0'}";

          List<String> columnsToSelect = [
            'Isu_Id',
          ];
          String whereString = 'Isu_Id = ? AND user_id = ? COLLATE NOCASE';

          List<dynamic> whereArguments = [newIssue.isuId, userId];
          var result = await dbIssue.query(issuesTableName,
              columns: columnsToSelect,
              where: whereString,
              whereArgs: whereArguments);

          if (result.isNotEmpty) {
            await dbIssue.rawUpdate(
                "UPDATE $issuesTableName SET $parameters WHERE(Isu_Id = '${newIssue.isuId}') ");
          } else {
            await dbIssue.insert('$issuesTableName', issueValue,
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          // print("Resuult : $result");
        } catch (e) {
          // dbIssue.close();
          Utils.logException(
              className: "AppDatabase",
              methodName: "insertAllIssuesFromSever",
              exceptionInfor: e.toString(),
              information1: e.toString());
          print("Failed iserting All issues: issues ");
          // print(newIssue.isuRptId);
          print(e);
        }
      }
    }
    // dbIssue.close();
  }

  Future<int> insertProjectsFromLocal(Projects newProject) async {
    Database dbProject = await DB.instance.database;
    if (!dbProject.isOpen) {
      print("DB is closed");

      return 1;
    }
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    try {
      final projectObjectValues = <String, dynamic>{
        'user_id': userId,
        'Pj_Id': newProject.pjId,
        'Pj_CUsr_Id': newProject.pjCUsrId,
        'Pj_Number': newProject.pjNumber,
        'Pj_Name': newProject.pjName,
        'Pj_Location': newProject.pjLocation,
        'Pj_Is_Dirty': '1',
        'Pj_CreatedDate': getCurrTimeStamp(),
        'Pj_LastModifiedDate': getCurrTimeStamp()
      };

      await dbProject.insert('$projectTableName', projectObjectValues,
          conflictAlgorithm: ConflictAlgorithm.ignore);
      return 0;
    } catch (e) {
      // dbProject.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "insertProjectsFromLocal",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: projects ");
      print(e);

      return 1;
    }
  }

  Future<int> insertReportsFromLocalDB(Reports newReport) async {
    Database dbReport = await DB.instance.database;
    if (!dbReport.isOpen) {
      print("DB is closed");

      return 1;
    }
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    try {
      final reportValue = <String, dynamic>{
        'user_id': userId,
        'Rpt_Id': newReport.rptId,
        'Rpt_Pj_Id': newReport.rptPjId,
        'Rpt_PreparedBy': newReport.rptPreparedBy,
        'Rpt_PunchListType': newReport.rptPunchListType,
        'Rpt_VisitDate': newReport.rptVisitDate,
        'Rpt_Remarks': newReport.rptRemarks ?? "",
        'Rpt_Is_Dirty': 1,
        'Rpt_CreatedDate': getCurrTimeStamp(),
        'Rpt_LastModifiedDate': getCurrTimeStamp()
      };

      await dbReport.insert('$reportsTableName', reportValue,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      // dbReport.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "insertReportsFromLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: reports ");
      print(e);

      return 1;
    }

    // dbReport.close();
    return 0;
  }

  Future<int> insertIssueFromLocal(Issues newIssue) async {
    Database dbIssueLocal = await DB.instance.database;
    Directory dir = await getApplicationDocumentsDirectory();

    if (!dbIssueLocal.isOpen) {
      print("DB is closed");
      return 1;
    }
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    if (newIssue != null) {
      print("Inserted in issues");
      try {
        final issueValue = <String, dynamic>{
          'user_id': userId,
          'IssueImagePath_Original': newIssue.issueImagePathOriginal,
          'Isu_Details': newIssue.isuDetails,
          'Isu_Id': newIssue.isuId,
          'Isu_Location': newIssue.isuLocation,
          'Isu_Rpt_Id': newIssue.isuRptId,
          'Isu_Status': newIssue.isuStatus,
          'Issu_Image_Loca_Path': newIssue.issueImagePathOriginal,
          'Issu_Is_Dirty': '1',
          'Isu_HasImage': newIssue.isuHasImage == true ? '1' : '0',
          'Issu_Is_Image_Dirty': newIssue.isuHasImage == true ? '1' : '0',
          'Isu_CreatedDate': getCurrTimeStamp(),
          'Isu_LastModifiedDate': getCurrTimeStamp()
        };

        await dbIssueLocal
            .insert('$issuesTableName', issueValue,
                conflictAlgorithm: ConflictAlgorithm.ignore)
            .then((value) {
          print("insertIssueFromLocal : $value");
        });
      } catch (e) {
        // dbIssueLocal.close();
        Utils.logException(
            className: "AppDatabase",
            methodName: "insertIssueFromLocal",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed isertion: issues ");
        // print(newIssue.isuRptId);
        print(e);

        return 1;
      }
    }
    print("Closed in issues");
    // dbIssueLocal.close();
    return 0;
  }

  Future<int> insertClientLogsToLocalDB(String activity) async {
    Database dbClientReports = await DB.instance.clientDatabase;
    if (!dbClientReports.isOpen) {
      print("DB is closed");

      return 1;
    }

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    try {
      final clientLogValue = <String, dynamic>{
        'user_id': userId,
        'Cdal_Id': "${Guid.newGuid}",
        'Cdal_TransactionId': "0",
        'Cdal_Activity': activity,
        'Cdal_DateTimeStamp': getCurrTimeStamp()
      };

      await dbClientReports.insert('$clientDeviceActivityLog', clientLogValue,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      // dbClientReports.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "insertClientLogsToLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: insert ClientLogs");
      print(e);

      return 1;
    }

    // dbClientReports.close();
    return 0;
  }

  Future<int> updateProject(Projects updateProject) async {
    Database dbProjectTable = await DB.instance.database;

    if (!dbProjectTable.isOpen) {
      print("DB is closed");
      return 1;
    }

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    if (updateProject != null) {
      try {
        Map<String, dynamic> row = {
          'user_id': userId,
          'Pj_Id': updateProject.pjId,
          'Pj_CUsr_Id': updateProject.pjCUsrId,
          'Pj_Number': updateProject.pjNumber,
          'Pj_Name': updateProject.pjName,
          'Pj_Location': updateProject.pjLocation,
          'Pj_Is_Dirty': '1',
          'Pj_LastModifiedDate': getCurrTimeStamp()
        };

        await dbProjectTable.update(projectTableName, row,
            where: 'Pj_Id = ? AND user_id = ?',
            whereArgs: [updateProject.pjId, userId]);
      } catch (e) {
        Utils.logException(
            className: "AppDatabase",
            methodName: "updateProject",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Delete: deleteReportsFromLocal ");

        print(e);

        return 1;
      } finally {
        // dbProjectTable.close();
        print("Closed in delete");
      }
    }

    return 0;
  }

  Future<int> updateReport(Reports updatereport) async {
    Database dbProjectTable = await DB.instance.database;

    if (!dbProjectTable.isOpen) {
      print("DB is closed");
      return 1;
    }

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    if (updatereport != null) {
      try {
        Map<String, dynamic> row = {
          'Rpt_Id': updatereport.rptId,
          'Rpt_Pj_Id': updatereport.rptPjId,
          'Rpt_PreparedBy': updatereport.rptPreparedBy,
          'Rpt_PunchListType': updatereport.rptPunchListType,
          'Rpt_VisitDate': updatereport.rptVisitDate,
          'Rpt_Remarks': updatereport.rptRemarks ?? "",
          'Rpt_Is_Dirty': 1,
          'Rpt_LastModifiedDate': getCurrTimeStamp()
        };

        await dbProjectTable.update(reportsTableName, row,
            where: 'Rpt_Id = ? AND user_id = ?',
            whereArgs: [updatereport.rptId, userId]);
      } catch (e) {
        Utils.logException(
            className: "AppDatabase",
            methodName: "updateProject",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Delete: deleteReportsFromLocal ");

        print(e);

        return 1;
      } finally {
        // dbProjectTable.close();
        print("Closed in delete");
      }
    }

    return 0;
  }

  Future<int> insertExceptionFromLocal(ExceptionModel newExpection) async {
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    Database dbException = await DB.instance.database;
    if (!dbException.isOpen) {
      print("DB is closed");

      return 1;
    }

    try {
      final exceptionValue = <String, dynamic>{
        'user_id': userId,
        'MethodName': newExpection.methodName,
        'ExcpetionId': newExpection.excpetionId,
        'UserName': newExpection.userName,
        'DeviceId': newExpection.deviceId,
        'OsType': newExpection.osType,
        'OsVersion': newExpection.osVersion,
        'ClassName': newExpection.className,
        'Information1': newExpection.information1,
        'ExceptionInfo': newExpection.exceptionInfo,
        'information2': newExpection.information2,
        'IsUploaded': 1,
        'TimeStamp': '${DateTime.now().millisecondsSinceEpoch}'
      };

      await dbException.insert('$exceptionTableName', exceptionValue,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      // Utils.logException(
      //     className: "AppDatabase",
      //     methodName: "insertExceptionFromLocal",
      //     exceptionInfor: jsonEncode(e.toString()),
      //     information1: jsonEncode(e.toString()));
      print("Failed isertion: exceptionTableName : ${newExpection.methodName}");
      print(e);

      return 1;
    }
    // dbException.close();
    return 0;
  }

  Future<int> updateIssueFromLocal(Issues newIssue) async {
    Database dbIssueLocal = await DB.instance.database;
    Directory dir = await getApplicationDocumentsDirectory();

    if (!dbIssueLocal.isOpen) {
      print("DB is closed");
      return 1;
    }
    if (newIssue != null) {
      print("updated in issues");
      try {
        await dbIssueLocal.rawInsert(
            "UPDATE $issuesTableName SET Isu_Details = '${newIssue.isuDetails?.replaceAll("'", "_")}',Isu_Location = '${newIssue.isuLocation}',Isu_HasImage = '${newIssue.isuHasImage == true ? '1' : '0'}',Isu_Status = '${newIssue.isuStatus}',Issu_Image_Loca_Path = '${dir.path}',Issu_Is_Dirty = '1',Issu_Is_Image_Dirty = '${newIssue.isImageDirty == true ? '1' : '0'}',Isu_LastModifiedDate = '${getCurrTimeStamp()}' WHERE(Isu_Id = '${newIssue.isuId}') ");
      } catch (e) {
        // dbIssueLocal.close();
        Utils.logException(
            className: "AppDatabase",
            methodName: "UpdateIssueFromLocal",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Update: issues ");
        // print(newIssue.isuRptId);
        print(e);

        return 1;
      } finally {
        // dbIssueLocal.close();
      }
    }
    print("Closed in issues");
    // dbIssueLocal.close();
    return 0;
  }

  Future<int> deleteProjectFromLocal(String projectId) async {
    Database dbProjectLocal = await DB.instance.database;

    if (!dbProjectLocal.isOpen) {
      print("DB is closed");
      return 1;
    }
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    if (projectId.isNotEmpty) {
      print("Inserted in issues");
      try {
        Map<String, dynamic> row = {
          "Pj_Deleted_Flag": '1',
          'Pj_Is_Dirty': '1',
          'Pj_LastModifiedDate': getCurrTimeStamp()
        };

        await dbProjectLocal.update(projectTableName, row,
            where: 'Pj_Id = ? AND user_id = ?', whereArgs: [projectId, userId]);
      } catch (e) {
        // dbIssueLocal.close();
        Utils.logException(
            className: "AppDatabase",
            methodName: "deleteProjectFromLocal",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Delete: Project ");
        // print(newIssue.isuRptId);
        print(e);

        return 1;
      } finally {
        // dbProjectLocal.close();
        print("Closed in delete");
      }
    }
    // dbProjectLocal.close();
    return 0;
  }

  Future<int> deleteReportsFromLocal(String reportId) async {
    Database dbReportsLocal = await DB.instance.database;

    if (!dbReportsLocal.isOpen) {
      print("DB is closed");
      return 1;
    }

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    if (reportId.isNotEmpty) {
      try {
        Map<String, dynamic> row = {
          "Rpt_Deleted_Flag": '1',
          'Rpt_Is_Dirty': 1,
          'Rpt_LastModifiedDate': getCurrTimeStamp()
        };

        await dbReportsLocal.update(reportsTableName, row,
            where: 'Rpt_Id = ? AND user_id = ?', whereArgs: [reportId, userId]);
      } catch (e) {
        Utils.logException(
            className: "AppDatabase",
            methodName: "deleteReportsFromLocal",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Delete: deleteReportsFromLocal ");

        print(e);

        return 1;
      } finally {
        // dbReportsLocal.close();
        print("Closed in delete");
      }
    }

    return 0;
  }

  Future<int> deleteIssuessFromLocal(String issueId) async {
    Database dbIssuesLocal = await DB.instance.database;

    if (!dbIssuesLocal.isOpen) {
      print("DB is closed");
      return 1;
    }

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    if (issueId.isNotEmpty) {
      print("deleteIssuessFromLocal");
      try {
        Map<String, dynamic> row = {
          "Isu_Deleted_Flag": '1',
          'Issu_Is_Dirty': '1',
          'Isu_LastModifiedDate': getCurrTimeStamp()
        };

        await dbIssuesLocal.update(issuesTableName, row,
            where: 'Isu_Id = ? AND user_id = ? COLLATE NOCASE',
            whereArgs: [issueId, userId]);
      } catch (e) {
        // dbIssueLocal.close();
        Utils.logException(
            className: "AppDatabase",
            methodName: "deleteIssuessFromLocal",
            exceptionInfor: e.toString(),
            information1: e.toString());
        print("Failed Delete: Issue ");
        // print(newIssue.isuRptId);
        print(e);

        return 1;
      } finally {
        // dbIssuesLocal.close();
        print("Closed in delete");
      }
    }
    // dbProjectLocal.close();
    return 0;
  }

//#Fetch operations
  getProjectListFromDB() async {
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    Database dbProjects = await DB.instance.database;
    try {
      List<String> columnsToSelect = [
        'user_id',
        'Pj_Id',
        'Pj_CUsr_Id',
        'Pj_Number',
        'Pj_Name',
        'Pj_Location'
      ];
      String whereString = 'Pj_Deleted_Flag = 0 AND user_id = ? COLLATE NOCASE';

      List<dynamic> whereArguments = [userId];
      var result = await dbProjects.query(
        projectTableName,
        columns: columnsToSelect,
        where: whereString,
        whereArgs: whereArguments,
      );

      // List<Map<String, dynamic>> result = await dbProjects.rawQuery(
      //     "SELECT Pj_Id, Pj_CUsr_Id, Pj_Number, Pj_Name, Pj_Location FROM $projectTableName WHERE(Pj_Deleted_Flag = 0 AND user_id = $userId) ORDER BY Pj_Number");

      List<Projects?> jsonData =
          result.map((i) => Projects.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();
      // dbProjects.close();
      return someData;
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getProjectListFromDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);

      print(e);
    }
    // dbProjects.close();
  }

  getProjectFromDB(String projectId) async {
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    Database dbProjects = await DB.instance.database;
    try {
      List<String> columnsToSelect = [
        'Pj_Id',
        'Pj_CUsr_Id',
        'Pj_Number',
        'Pj_Name',
        'Pj_Location'
      ];
      String whereString =
          'Pj_Deleted_Flag = 0 AND user_id = ? AND Pj_Id = ? COLLATE NOCASE';

      List<dynamic> whereArguments = [userId, projectId];
      var result = await dbProjects.query(projectTableName,
          columns: columnsToSelect,
          where: whereString,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbProjects.rawQuery(
      //     "SELECT Pj_Id, Pj_CUsr_Id, Pj_Number, Pj_Name, Pj_Location FROM $projectTableName WHERE(Pj_Deleted_Flag = 0 AND user_id = $userId) ORDER BY Pj_Number");

      List<Projects?> jsonData =
          result.map((i) => Projects.fromJson(i)).toList();

      if (jsonData.length == 0) {
        return null;
      }

      var someData = jsonData.map((e) => e?.toJson()).toList();
      // dbProjects.close();
      return someData.first;
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getProjectFromDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);

      print(e);
    }
    // dbProjects.close();
  }

  getReportListFromDB(String reportId) async {
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    Database dbProjects = await DB.instance.database;
    try {
      List<String> columnsToSelect = [
        'Rpt_Id',
        'Rpt_Pj_Id',
        'Rpt_PreparedBy',
        'Rpt_PunchListType',
        'Rpt_VisitDate',
        'Rpt_Remarks',
        'Rpt_Is_Dirty'
      ];
      String whereString = 'Rpt_Id = ? AND user_id = ? COLLATE NOCASE';

      List<dynamic> whereArguments = [reportId, userId];
      var result = await dbProjects.query(reportsTableName,
          columns: columnsToSelect,
          where: whereString,
          whereArgs: whereArguments);

      List<Reports?> jsonData = result.map((i) => Reports.fromJson(i)).toList();

      if (jsonData.length == 0) {
        return null;
      }

      return jsonData.first;
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getProjectListFromDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      return null;
      print(e);
    }
    // dbProjects.close();
  }

  getDataToUploadExceptionListFromDB() async {
    Database dbProjects = await DB.instance.database;

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    try {
      List<String> columnsToSelect = [
        'ExcpetionId',
        'MethodName',
        'UserName',
        'DeviceId',
        'OsType',
        'OsVersion',
        'ClassName',
        'Information1',
        'Information2',
        'ExceptionInfo'
      ];
      String whereString = 'IsUploaded = 1 AND user_id = ? COLLATE NOCASE';
      List<dynamic> whereArguments = [userId];
      var result = await dbProjects.query(exceptionTableName,
          columns: columnsToSelect,
          where: whereString,
          whereArgs: whereArguments);
      // List<Map<String, dynamic>> result = await dbProjects.rawQuery(
      //     "SELECT ExcpetionId, UserName, DeviceId, OsType, OsVersion,ClassName,Information1,Information2,ExceptionInfo FROM $exceptionTableName WHERE(IsUploaded = 1)");

      List<ExceptionModel> jsonData =
          result.map((i) => ExceptionModel.fromJson(i)).toList();
      // dbProjects.close();
      return jsonData;
    } catch (e) {
      dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getDataToUploadExceptionListFromDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
  }

  getDataToUploadProjectListFromDB() async {
    Database dbProjects = await DB.instance.database;

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    try {
      List<String> columnsToSelect = [
        'Pj_Id',
        'Pj_CUsr_Id',
        'Pj_Number',
        'Pj_Name',
        'Pj_Location',
        'Pj_Deleted_Flag',
        'Pj_CreatedDate',
        'Pj_LastModifiedDate',
      ];
      String whereString = "Pj_Is_Dirty = '1' AND user_id = ? COLLATE NOCASE";
      String orderBy = "Pj_Number";
      List<dynamic> whereArguments = [userId];
      var result = await dbProjects.query(projectTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbProjects.rawQuery(
      //     "SELECT Pj_Id, Pj_CUsr_Id, Pj_Number, Pj_Name, Pj_Location FROM $projectTableName WHERE(Pj_Is_Dirty = 1) ORDER BY Pj_Number");

      List<Projects?> jsonData =
          result.map((i) => Projects.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();
      // dbProjects.close();
      return someData;
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getDataToUploadProjectListFromDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      return [];
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
  }

  getReports(String RptPjId) async {
    Database dbProjects = await DB.instance.database;

    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

    try {
      List<String> columnsToSelect = [
        'Rpt_Id',
        'Rpt_Pj_Id',
        'Rpt_PunchListType',
        'Rpt_PreparedBy',
        'Rpt_VisitDate',
        'Rpt_Remarks'
      ];
      String whereString =
          'Rpt_Pj_Id = ? AND Rpt_Deleted_Flag = 0 AND user_id = ? COLLATE NOCASE';
      String orderBy = "Rpt_VisitDate";
      List<dynamic> whereArguments = [RptPjId, userId];
      var result = await dbProjects.query(reportsTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbProjects.rawQuery(
      //     "SELECT Rpt_Id, Rpt_Pj_Id, Rpt_PunchListType, Rpt_PreparedBy, Rpt_VisitDate,Rpt_Remarks FROM $reportsTableName WHERE(Rpt_Pj_Id = '$RptPjId') AND (Rpt_Deleted_Flag = 0) ORDER BY Rpt_VisitDate");

      List<Reports?> jsonData = result.map((i) => Reports.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return someData;
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getReports",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      return [];
      print(e);
    }
    // dbProjects.close();
  }

  getDataToUploadReportsFromLocalDB() async {
    Database dbReports = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = [
        'Rpt_Id',
        'Rpt_Pj_Id',
        'Rpt_PunchListType',
        'Rpt_PreparedBy',
        'Rpt_VisitDate',
        'Rpt_Remarks',
        'Rpt_Deleted_Flag',
        'Rpt_CreatedDate',
        'Rpt_LastModifiedDate'
      ];
      String whereString = "Rpt_Is_Dirty = ? AND user_id = ? COLLATE NOCASE";
      String orderBy = "Rpt_VisitDate";
      List<dynamic> whereArguments = [1, userId];
      var result = await dbReports.query(reportsTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbReports.rawQuery(
      //     "SELECT Rpt_Id, Rpt_Pj_Id, Rpt_PunchListType, Rpt_PreparedBy, Rpt_VisitDate,Rpt_Remarks FROM $reportsTableName WHERE(Rpt_Is_Dirty = 1) ORDER BY Rpt_VisitDate");

      List<Reports?> jsonData = result.map((i) => Reports.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      // dbReports.close();
      return someData;
    } catch (e) {
      // dbReports.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getDataToUploadReportsFromLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return [];
    }
  }

  getIssues(String issueRptId) async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_Rpt_Id',
        'Isu_Location',
        'Isu_Details',
        'Isu_Status',
        'Isu_HasImage',
        'Issu_Is_Image_Dirty',
        'IssueImagePath_Original',
        'Issu_Image_Loca_Path',
      ];
      String whereString =
          'Isu_Rpt_Id = ? AND user_id = ? AND Isu_Deleted_Flag = 0 COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [issueRptId, userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      List<Issues?> jsonData = result.map((i) => Issues.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return someData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getIssues",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      return [];
      print(e);
    }
    // dbIssue.close();
  }

  getExportIssues(String issueRptId) async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_HasImage',
      ];
      String whereString =
          'Isu_Rpt_Id = ? AND user_id = ? AND Isu_Deleted_Flag = 0 COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [issueRptId, userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      List<IssuesExportRequestModel?> jsonData =
          result.map((i) => IssuesExportRequestModel.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return someData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getIssues",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      return [];
      print(e);
    }
    // dbIssue.close();
  }

  Future<int> updateIsUploadedException(String expectionId) async {
    Database dbProjects = await DB.instance.database;
    if (!dbProjects.isOpen) {
      print("DB is closed");
      dbProjects = await DB.instance.database;
    }
    try {
      Map<String, dynamic> row = {"IsUploaded": '0'};

      await dbProjects.update(exceptionTableName, row,
          where: 'ExcpetionId = ?',
          whereArgs: [expectionId]).then((value) => print(value));

      // await dbProjects.rawQuery(
      //     "UPDATE $exceptionTableName SET IsUploaded = 0 WHERE(ExcpetionId = '$expectionId')");
    } catch (e) {
      // Utils.logException(
      //     className: "AppDatabase",
      //     methodName: "updateIsUploadedException",
      //     exceptionInfor: e.toString(),
      //     information1: e.toString());
      // print("Failed updateIsUploadedException: issues ");
      // dbProjects.close();
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> updateIsDirtyDownloadImageIssue(String issueId) async {
    Database dbProjects = await DB.instance.database;
    try {
      await dbProjects.rawQuery(
          "UPDATE $issuesTableName SET Issu_Is_Image_Dirty = 0 WHERE(Isu_Id = '$issueId') COLLATE NOCASE");
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyDownloadImageIssue",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> exportUpdateIsImageDirtyTrue(String issueId) async {
    final path = await getApplicationDocumentsDirectory();
    String updatedImageName = '${path.path}/${issueId.toUpperCase()}.jpg';

    var isValid = await File(updatedImageName).exists();

    if (!isValid) {
      print("Invalide Path: $updatedImageName");
      return 1;
    }
    print("issue: $issueId");
    Database dbIssueLocal = await DB.instance.database;
    try {
      await dbIssueLocal.rawQuery(
          "UPDATE $issuesTableName SET Issu_Is_Image_Dirty = 1 WHERE(Isu_Id = '${issueId.toUpperCase()}') COLLATE NOCASE");
      print(
          "UPDATE $issuesTableName SET Issu_Is_Image_Dirty = 1  WHERE(Isu_Id = '${issueId.toUpperCase()}') COLLATE NOCASE");
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyDownloadImageIssue",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> exportUpdateIsIssueDirtyTrue(String issueId) async {
    print("issue: $issueId");
    Database dbIssueLocal = await DB.instance.database;
    try {
      await dbIssueLocal.rawQuery(
          "UPDATE $issuesTableName SET Issu_Is_Dirty = 1 WHERE(Isu_Id = '${issueId.toUpperCase()}') COLLATE NOCASE");
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyDownloadImageIssue",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> updateIs404DownloadImageIssueUpdated(String issueId) async {
    Database dbProjects = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      Map<String, dynamic> row = {
        'Issu_Image_404': '0',
        'Isu_LastModifiedDate': getCurrTimeStamp()
      };

      await dbProjects.update(issuesTableName, row,
          where: 'user_id = ?', whereArgs: [userId]);
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyDownloadImageIssue",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> updateIsImageDownloadedOnLocalIssue(String issueId,
      {String is404Error = '0'}) async {
    //is404Erro = 0 ---> only need to update image downloaded flag
    Database dbIssue = await DB.instance.database;
    try {
      // Issu_Image_404
      Map<String, dynamic> row = {
        'Issu_Image_404': is404Error,
        'Isu_LastModifiedDate': getCurrTimeStamp()
      };

      await dbIssue.update(issuesTableName, row,
          where: 'Isu_Id = ?', whereArgs: [issueId]);
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsImageDownloadedOnLocalIssue",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed UPDATE: issues ");
      // print(newIssue.isuRptId);
      print(e);
      // dbIssue.close();

      return 1;
    }
    // dbIssue.close();

    return 0;
  }

  // Future<int> updateAllImageDownloadedFlagOnLocalDB(
  //     List<String> listOfIssueId) async {
  //   Database dbIssue = await DB.instance.database;
  //   try {
  //     String dataToPass = listOfIssueId.map((i) => "'$i'").join(",");
  //     await dbIssue.rawQuery(
  //         "UPDATE $issuesTableName SET Issu_Is_Image_downloaded = 1 WHERE Isu_Id IN($dataToPass)");
  //     // dbIssue.close();
  //   } catch (e) {
  //     dbIssue.close();
  //     Utils.logException(
  //         className: "AppDatabase",
  //         methodName: "updateAllImageDownloadedFlagOnLocalDB",
  //         exceptionInfor: e.toString(),
  //         information1: e.toString());
  //     print("Failed updateAllImageDownloadedFlagOnLocalDB: issues ");
  //     // print(newIssue.isuRptId);
  //     print(e);
  //     // dbIssue.close();

  //     return 1;
  //   }
  //   // dbIssue.close();

  //   return 0;
  // }

  Future<int> updateIsDirtyProject(String projectId) async {
    Database dbProjects = await DB.instance.database;
    try {
      Map<String, dynamic> row = {
        "Pj_Is_Dirty": 0.toString(),
        'Pj_LastModifiedDate': getCurrTimeStamp()
      };

      await dbProjects.update(projectTableName, row,
          where: 'Pj_Id = ?', whereArgs: [projectId.toUpperCase()]);

      // await dbProjects.rawQuery(
      //     "UPDATE $projectTableName SET Pj_Is_Dirty = 0 AND Pj_LastModifiedDate = '${getCurrTimeStamp()}'  WHERE(Pj_Id = '$projectId')");
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyProject",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> updateIsDirtyReports(String reportId) async {
    Database dbProjects = await DB.instance.database;
    try {
      Map<String, dynamic> row = {
        "Rpt_Is_Dirty": 0,
        'Rpt_LastModifiedDate': getCurrTimeStamp()
      };

      await dbProjects.update(reportsTableName, row,
          where: 'Rpt_Id = ?', whereArgs: [reportId.toUpperCase()]);

      // await dbProjects.rawQuery(
      //     "UPDATE $reportsTableName SET Rpt_Is_Dirty = 0 WHERE(Rpt_Id = '$reportId')");
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyReports",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  Future<int> updateIsDirtyIssues(String issueId) async {
    Database dbProjects = await DB.instance.database;
    try {
      Map<String, dynamic> row = {
        "Issu_Is_Dirty": '0',
        'Isu_LastModifiedDate': getCurrTimeStamp()
      };

      await dbProjects.update(issuesTableName, row,
          where: 'Isu_Id = ?', whereArgs: [issueId.toUpperCase()]);

      // await dbProjects.rawQuery(
      //     "UPDATE $issuesTableName SET Issu_Is_Dirty = 0 WHERE(Isu_Id = '${issueId.toString()}')");
      print("Data updated for issue");
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateIsDirtyIssues",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
      // dbProjects.close();

      return 1;
    }
    // dbProjects.close();

    return 0;
  }

  getDataToUploadIssuesFromLocalDB() async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_Rpt_Id',
        'Isu_Location',
        'Isu_Details',
        'Isu_Status',
        'Isu_Deleted_Flag',
        'Isu_HasImage',
        'Isu_CreatedDate',
        'Isu_LastModifiedDate',
      ];
      String whereString = 'user_id = ? AND Issu_Is_Dirty = 1 COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbIssue.rawQuery(
      //     "SELECT Isu_Id, Isu_Rpt_Id, Isu_Location, Isu_Details, Isu_Status FROM $issuesTableName WHERE(Issu_Is_Dirty = 1) ORDER BY Isu_SortOrder");

      List<UploadIssues?> jsonData =
          result.map((i) => UploadIssues.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return someData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getDataToUploadIssuesFromLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);

      return [];
      print(e);
    }
    // dbIssue.close();
  }

  // updateDownloadedImagesFlag(List listOfIssue) async {
  //   var pref = sl<SharedPreferences>();
  //   var arrayImages = pref.getStringList("IMAGE_LIST") ?? [];
  //   if (listOfIssue.length <= arrayImages.length) {
  //     return;
  //   }
  //   if (listOfIssue.length / 2 >= arrayImages.length) {
  //     await AppDatabase.instance
  //         .updateAllImageDownloadedFlagOnLocalDB(arrayImages);
  //   }
  // }

  Future<List<Issues>?> getMissingIssueImagesFromLocalDB() async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_Rpt_Id',
        'Isu_Location',
        'Isu_Details',
        'Isu_Status',
        'IssueImagePath_Original'
      ];
      String whereString =
          'user_id = ? AND Isu_HasImage = 1 AND Issu_Image_404 = 0 COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      List<Issues> jsonData = result.map((i) => Issues.fromJson(i)).toList();

      // var someData = jsonData.map((e) => e.toJson()).toList();
      // dbIssue.close();

      // updateDownloadedImagesFlag(jsonData);
      return jsonData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getMissingIssueImagesFromLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
    // dbIssue.close();
  }

  getDataToUploadIssueImagesFromLocalDB() async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_Rpt_Id',
        'Isu_Location',
        'Isu_Details',
        'Isu_Status',
      ];
      String whereString =
          'user_id = ? AND Issu_Is_Image_Dirty = 1 COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbIssue.rawQuery(
      //     "SELECT Isu_Id, Isu_Rpt_Id, Isu_Location, Isu_Details, Isu_Status FROM $issuesTableName WHERE(Issu_Is_Image_Dirty = 1) ORDER BY Isu_SortOrder");

      List<Issues?> jsonData = result.map((i) => Issues.fromJson(i)).toList();

      // var someData = jsonData.map((e) => e?.toJson()).toList();

      print("Images to upload count: ${jsonData.length}");
      return jsonData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
        className: "AppDatabase",
        methodName: "getDataToUploadIssueImagesFromLocalDB",
        exceptionInfor: e.toString(),
        information1: e.toString(),
      );
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
    // dbIssue.close();
  }

  getDataToUploadIssue404ImagesFromLocalDB() async {
    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = ['Isu_Id', 'IssueImagePath_Original'];
      String whereString =
          "user_id = ? AND Issu_Image_404 = '1' COLLATE NOCASE";
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [userId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      List<Issues?> jsonData = result.map((i) => Issues.fromJson(i)).toList();

      return jsonData;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getDataToUploadIssueImagesFromLocalDB",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
    // dbIssue.close();
  }

  Future<Issues?> getAddedIssues(String issueId) async {
// SELECT
// Isu_Id,
// Isu_Rpt_Id,
// Isu_Location,
// Isu_Details,
// Isu_Status,
// 'Path' AS IssueImagePath_Original
// FROM   Issue
// WHERE  (Isu_Id = '5b0af97f-5ec7-4037-9eb2-8c25b9c5db1b')

    Database dbIssue = await DB.instance.database;
    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      List<String> columnsToSelect = [
        'Isu_Id',
        'Isu_Rpt_Id',
        'Isu_Location',
        'Isu_Details',
        'Isu_Status',
        'IssueImagePath_Original'
      ];
      String whereString = 'user_id = ? AND Isu_Id = ? COLLATE NOCASE';
      String orderBy = "Isu_SortOrder";
      List<dynamic> whereArguments = [userId, issueId];
      var result = await dbIssue.query(issuesTableName,
          columns: columnsToSelect,
          where: whereString,
          orderBy: orderBy,
          whereArgs: whereArguments);

      // List<Map<String, dynamic>> result = await dbIssue.rawQuery(
      //     "SELECT Isu_Id, Isu_Rpt_Id, Isu_Location, Isu_Details, Isu_Status,IssueImagePath_Original FROM $issuesTableName WHERE(Isu_Id = '$issueId')");

      List<Issues?> jsonData = result.map((i) => Issues.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return jsonData.first;
    } catch (e) {
      // dbIssue.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "getAddedIssues",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);
    }
    // dbIssue.close();
  }

  getImageDataToUpload() async {
    try {
      List<Issues?> issueList = await getDataToUploadIssueImagesFromLocalDB();

      return issueList;
      // }
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "getImageDataToUpload",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print(e);
    }
  }

  get404ImageDataToUpload() async {
    try {
      List<Issues?> issueList =
          await getDataToUploadIssue404ImagesFromLocalDB();

      var tempList = [];
      for (var issue in issueList) {
        if (issue == null) {
          continue;
        }
        if (issue.issueImagePathOriginal!.contains('data/user/')) {
          print(issue.issueImagePathOriginal);
        }
        if (!issue.issueImagePathOriginal!.contains('Application/') &&
            !issue.issueImagePathOriginal!.contains('data/user/')) {
          var body = {
            "Isu_Id": issue.isuId,
            "Isu_404Url": issue.issueImagePathOriginal!.contains('Application/')
                ? ""
                : issue.issueImagePathOriginal,
          };
          tempList.add(body);
        }
      }

      return tempList;
      // }
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "getImageDataToUpload",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print(e);
    }
  }

  getAllDataToUpload() async {
    try {
      var projectList = await getDataToUploadProjectListFromDB();
      var issueList = await getDataToUploadIssuesFromLocalDB();
      var reportList = await getDataToUploadReportsFromLocalDB();

      var body = {
        "Projects": projectList,
        "Issues": issueList,
        "Reports": reportList,
      };

      if (projectList.length == 0 &&
          issueList?.length == 0 &&
          reportList?.length == 0) {
        return null;
      }
      return body;
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "getAllDataToUpload",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print(e);
    }
  }

  getAllClientLogstoUpload() async {
    Database dbClientReports = await DB.instance.clientDatabase;
    if (!dbClientReports.isOpen) {
      print("DB is closed");

      return 1;
    }
    final pref = sl<SharedPreferences>();
    String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    try {
      List<String> columnsToSelect = [
        'Cdal_Id',
        'Cdal_Activity',
        'Cdal_DateTimeStamp',
      ];
      String whereString =
          "Cdal_TransactionId = '0' AND user_id = ? COLLATE NOCASE";

      List<dynamic> whereArguments = [userId];
      var result = await dbClientReports.query(clientDeviceActivityLog,
          columns: columnsToSelect,
          where: whereString,
          whereArgs: whereArguments);

      List<ClientDeviceLogs?> jsonData =
          result.map((i) => ClientDeviceLogs.fromJson(i)).toList();

      var someData = jsonData.map((e) => e?.toJson()).toList();

      return someData.length == 0 ? null : someData;
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "getAllClientLogstoUpload",
          exceptionInfor: e.toString(),
          information1: e.toString());
      return [];
    }
  }

  updateAllClientTransacgtionId(String transactionId) async {
    Database dbClientReports = await DB.instance.clientDatabase;
    if (!dbClientReports.isOpen) {
      print("DB is closed");

      return;
    }

    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      Map<String, dynamic> row = {"Cdal_TransactionId": transactionId};

      await dbClientReports.update(clientDeviceActivityLog, row,
          where: "user_id = ? AND Cdal_TransactionId = '0'",
          whereArgs: [userId]);
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateAllClientTransacgtionId",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }

    return 0;
  }

  updateResetAllClientTransacgtionId(String transactionId) async {
    Database dbClientReports = await DB.instance.clientDatabase;
    if (!dbClientReports.isOpen) {
      print("DB is closed");

      return;
    }

    try {
      final pref = sl<SharedPreferences>();
      String userId = pref.getString(MySharedPref.USER_NAME) ?? " ";

      Map<String, dynamic> row = {"Cdal_TransactionId": "1"};

      await dbClientReports.update(clientDeviceActivityLog, row,
          where: "user_id = ? AND Cdal_TransactionId = ?",
          whereArgs: [userId, transactionId]);
    } catch (e) {
      // dbProjects.close();
      Utils.logException(
          className: "AppDatabase",
          methodName: "updateAllClientTransacgtionId",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed isertion: issues ");
      // print(newIssue.isuRptId);
      print(e);

      return 1;
    }

    return 0;
  }

  updateAllSyncData(List listdata) async {
    for (var data in listdata) {
      var id = data["Id"];
      // if (data["SyncStatus"] == 0) {
      switch (data["Type"]) {
        case "Project":
          await updateIsDirtyProject(id);
          break;
        case "Report":
          await updateIsDirtyReports(id);
          break;
        case "Issue":
          await updateIsDirtyIssues(id);
          break;
        default:
      }
      // }
    }
  }
}
