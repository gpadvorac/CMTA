import 'dart:io';
import 'dart:isolate';

import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../injector_container.dart';

class DB {
  static final DB _db = new DB._internal();
  DB._internal();
  static DB get instance => _db;
  static Database? _database;

  String dbName = "cmta_${FlavorConfig.instance?.name.toLowerCase() }.db";
  String clientLogDB = "clientLog.db";
  static String projectTableName = "Project";
  static String reportsTableName = "Reports";
  static String issuesTableName = "Issues";
  static String exceptionTableName = "Exception";
  static String issuesTempTableName = "Issues_temp";

  static String clientDeviceActivityLog = "ClientDeviceActivityLog";
  static String userId = "";
  static Database? _clientDatabase;

  List<String> initScript = [
    createProjectTableStmnt(),
    createReportTalbe(),
    craeteIssueTable(),
    createExeptionTable()
  ]; // Initialization script split into seperate statements

  Future<Database> _init() async {
    final pref = sl<SharedPreferences>();
    userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
    dbName = "cmta_${FlavorConfig.instance?.name.toLowerCase()}.db";

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    print("DB : $path");

    return await openDatabase(path,
        version: migrationScripts.length + 2,
        onOpen: (db) {}, onCreate: (Database db, int version) async {
      initScript.forEach((script) async => await db.execute(script));
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      print("oldVersion : $oldVersion");
      print("newVersion : $newVersion");
      for (var i = oldVersion - 1; i < newVersion - 1; i++) {
        await db.execute(migrationScripts[i]);
      }
    });
  }

  List<String> migrationScripts = [
    // migrationScriptV1(),
    // migrationScriptV2(),
    // migrationScriptV3()
  ]; // Migration sql  migrationScripts, containing a single statements per migration

  static migrationScriptV1() {
    return craeteUpdatedIssueTabl1();
  }

  static migrationScriptV2() {
    return craeteUpdatedIssueTable2();
  }

  static migrationScriptV3() {
    return craeteUpdatedIssueTable3();
    // dropOldIssueTable();
    // renameTempIssueTable();
  }

  closeDB() {
    _database?.close();
  }

  static String getCurrTimeStamp() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(now);
    return formattedDate;

    //
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    // getversion();
    return _database!;
  }

  // getversion() {
  //   // _database!.execute("PRAGMA user_version = 6");

  //   _database!.getVersion().then((value) {
  //     print("Old version: $value");
  //   });
  //   // _database!.setVersion(2);

  //   _database!.getVersion().then((value) {
  //     print("New version: $value");
  //   });
  // }

  initClientLogDB() async {
    try {
      final pref = sl<SharedPreferences>();

      userId = pref.getString(MySharedPref.USER_NAME) ?? " ";
      clientLogDB =
          'cmta_clientLog_${pref.getString(MySharedPref.PROJECT_FLAVOUR) ?? ""}.db';

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, clientLogDB);
      print("DB : $path");

      return await openDatabase(path, version: 1, onOpen: (dbClientLog) {},
          onCreate: (Database dbClientLog, int version) async {
        createClientAcivityLogTable(dbClientLog);
      });
    } catch (e) {
      print("Error CleintDb: $e");
    }
  }

  Future<Database> get clientDatabase async {
    if (_clientDatabase != null) return _clientDatabase!;

    // if _database is null we instantiate it
    _clientDatabase = await initClientLogDB();

    return _clientDatabase!;
  }

  static String createProjectTableStmnt() {
    return "CREATE TABLE $projectTableName ("
        "user_id,"
        "Pj_Id TEXT PRIMARY KEY,"
        "Pj_CUsr_Id TEXT,"
        "Pj_ProjectId TEXT,"
        "Pj_Number TEXT,"
        "Pj_Name TEXT,"
        "Pj_Location TEXT,"
        "Pj_Remarks TEXT,"
        "Pj_Enabled_Flag bit,"
        "Pj_Deleted_Flag bit DEFAULT 0,"
        "Pj_CreatedUserId TEXT,"
        "Pj_CreatedDate TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Pj_LastModifiedUserId TEXT,"
        "Pj_LastModifiedDate TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Pj_Stamp timestamp,"
        "Pj_Email TEXT,"
        "Pj_DeviceId TEXT,"
        "Pj_Is_Dirty bit DEFAULT 0"
        ")";
  }

  createProjectsTable(Database db) async {
    await db.execute(createProjectTableStmnt());
  }

  static String createReportTalbe() {
    return "CREATE TABLE $reportsTableName ("
        "user_id,"
        "Rpt_Id PRIMARY KEY UNIQUE  NOT NULL,"
        "Rpt_Pj_Id   NOT NULL,"
        "Rpt_CUsr_Id NULL   ,"
        "Rpt_ReportId   ,"
        "Rpt_ProjectId TEXT,"
        "Rpt_PunchListType  TEXT,"
        "Rpt_PreparedBy   TEXT,"
        "Rpt_VisitDateText  TEXT,"
        "Rpt_VisitDate   TEXT,"
        "Rpt_Remarks   TEXT,"
        "Rpt_Remarks_tmp  TEXT,"
        "Rpt_Remarks_bu   TEXT,"
        "Rpt_Enabled_Flag  Bool  ,"
        "Rpt_Deleted_Flag  Bool DEFAULT 0,"
        "Rpt_CreatedUserId NULL ,"
        "Rpt_CreatedDate   TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Rpt_LastModifiedUserId NULL   ,"
        "Rpt_LastModifiedDate  TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Rpt_Stamp  TEXT,"
        "Rpt_Is_Dirty DEFAULT 0"
        ")";
  }

  createReportsTable(Database db) async {
    try {
      await db.execute(createReportTalbe());
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "createReportsTable",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed to create $reportsTableName : $e");
    }
  }

  static String craeteUpdatedIssueTabl() {
    String strQuery = '''
    CREATE TABLE issue_table1 AS SELECT user_id,Isu_Id,Isu_Rpt_Id,Isu_Location,Isu_Details,Isu_Status,Isu_HasImage,Isu_SortOrder,Isu_Enabled_Flag,Isu_Deleted_Flag,Isu_CreatedUserId,Isu_CreatedDate,Isu_LastModifiedUserId,Isu_LastModifiedDate,Isu_Stamp,tmpCounter,Isu_IsImageProcessed,IsOriginalImageMissing,IsReportImageMissing,IsThumImageMissing,Isu_IssueId,Isu_ReportId,Isu_CUsr_Id,IssueImagePath_Original,Issu_Image_Loca_Path,Issu_Is_Dirty,Issu_Is_Image_Dirty,Issu_Image_404 from $issuesTableName  
    ''';
    return strQuery;
  }

  static String craeteUpdatedIssueTabl1() {
    String strQuery = '''
    CREATE TABLE issue_table1 AS SELECT user_id,Isu_Id,Isu_Rpt_Id,Isu_Location,Isu_Details,Isu_Status,Isu_HasImage,Isu_SortOrder,Isu_Enabled_Flag,Isu_Deleted_Flag,Isu_CreatedUserId,Isu_CreatedDate,Isu_LastModifiedUserId,Isu_LastModifiedDate,Isu_Stamp,tmpCounter,Isu_IsImageProcessed,IsOriginalImageMissing,IsReportImageMissing,IsThumImageMissing,Isu_IssueId,Isu_ReportId,Isu_CUsr_Id,IssueImagePath_Original,Issu_Image_Loca_Path,Issu_Is_Dirty,Issu_Is_Image_Dirty,Issu_Image_404 from $issuesTableName  
    ''';
    return strQuery;
  }

  static String craeteUpdatedIssueTable2() {
    String strQuery = '''
    CREATE TABLE issue_table2 AS SELECT user_id,Isu_Id,Isu_Rpt_Id,Isu_Location,Isu_Details,Isu_Status,Isu_HasImage,Isu_SortOrder,Isu_Enabled_Flag,Isu_Deleted_Flag,Isu_CreatedUserId,Isu_CreatedDate,Isu_LastModifiedUserId,Isu_LastModifiedDate,Isu_Stamp,tmpCounter,Isu_IsImageProcessed,IsOriginalImageMissing,IsReportImageMissing,IsThumImageMissing,Isu_IssueId,Isu_ReportId,Isu_CUsr_Id,IssueImagePath_Original,Issu_Image_Loca_Path,Issu_Is_Dirty,Issu_Is_Image_Dirty,Issu_Image_404 from $issuesTableName  
    ''';
    return strQuery;
  }

  static String craeteUpdatedIssueTable3() {
    String strQuery = '''
    CREATE TABLE issue_table3 AS SELECT user_id,Isu_Id,Isu_Rpt_Id,Isu_Location,Isu_Details,Isu_Status,Isu_HasImage,Isu_SortOrder,Isu_Enabled_Flag,Isu_Deleted_Flag,Isu_CreatedUserId,Isu_CreatedDate,Isu_LastModifiedUserId,Isu_LastModifiedDate,Isu_Stamp,tmpCounter,Isu_IsImageProcessed,IsOriginalImageMissing,IsReportImageMissing,IsThumImageMissing,Isu_IssueId,Isu_ReportId,Isu_CUsr_Id,IssueImagePath_Original,Issu_Image_Loca_Path,Issu_Is_Dirty,Issu_Is_Image_Dirty,Issu_Image_404 from $issuesTableName  
    ''';
    return strQuery;
  }

  static String craeteIssueTable() {
    return "CREATE TABLE $issuesTableName ("
        "user_id,"
        "Isu_Id PRIMARY KEY UNIQUE  NOT NULL,"
        "Isu_Rpt_Id NULL,"
        "Isu_Location TEXT,"
        "Isu_Details TEXT,"
        "Isu_Status TEXT,"
        "Isu_HasImage Bool DEFAULT 1,"
        "Isu_SortOrder TEXT,"
        "Isu_Enabled_Flag Bool  ,"
        "Isu_Deleted_Flag Bool DEFAULT 0,"
        "Isu_CreatedUserId TEXT,"
        "Isu_CreatedDate TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Isu_LastModifiedUserId TEXT,"
        "Isu_LastModifiedDate TEXT DEFAULT '${getCurrTimeStamp()}',"
        "Isu_Stamp timestamp,"
        "tmpCounter INT,"
        "Isu_IsImageProcessed Bool  ,"
        "IsOriginalImageMissing Bool  ,"
        "IsReportImageMissing Bool  ,"
        "IsThumImageMissing Bool  ,"
        "Isu_IssueId TEXT,"
        "Isu_ReportId TEXT,"
        "Isu_CUsr_Id  NULL,"
        "IssueImagePath_Original TEXT,"
        "Issu_Image_Loca_Path TEXT,"
        "Issu_Is_Dirty Bool DEFAULT 0,"
        "Issu_Is_Image_Dirty Bool DEFAULT 0,"
        "Issu_Is_Image_downloaded Bool DEFAULT 0,"
        "Issu_Image_404 DEFAULT 0"
        ")";
  }

  static String renameTempIssueTable() {
    return '''
        ALTER TABLE $issuesTempTableName RENAME TO $issuesTableName
        ''';
  }

  static String dropOldIssueTable() {
    return '''
        DROP TABLE $issuesTableName
        ''';
  }

  createIssueTable(Database db) async {
    try {
      await db.execute(craeteIssueTable());
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "createIssueTable",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed to create $issuesTableName : $e");
    }
  }

  static String createExeptionTable() {
    return "CREATE TABLE $exceptionTableName ("
        "user_id,"
        "ExcpetionId PRIMARY KEY UNIQUE  NOT NULL,"
        "UserName TEXT,"
        "DeviceId  TEXT,"
        "OsType TEXT,"
        "OsVersion TEXT,"
        "ClassName TEXT,"
        "MethodName TEXT,"
        "Information1 TEXT,"
        "Information2 TEXT,"
        "ExceptionInfo TEXT,"
        "IsUploaded DEFAULT 0,"
        "TimeStamp TEXT"
        ")";
  }

  createExpectionTable(Database db) async {
    try {
      await db.execute(createExeptionTable());
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "createExpectionTable",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed to create $exceptionTableName : $e");
    }
  }

  createClientAcivityLogTable(Database clientLogDB) async {
    try {
      await clientLogDB.execute("CREATE TABLE $clientDeviceActivityLog ("
          "user_id,"
          "Cdal_Id PRIMARY KEY UNIQUE NOT NULL,"
          "Cdal_TransactionId NOT NULL,"
          "Cdal_Activity NULL ,"
          "Cdal_DateTimeStamp DATETIME DEFAULT '${getCurrTimeStamp()}',"
          "Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP"
          ")");
    } catch (e) {
      Utils.logException(
          className: "AppDatabase",
          methodName: "createClientAcivityLogTable",
          exceptionInfor: e.toString(),
          information1: e.toString());
      print("Failed to create $clientDeviceActivityLog : $e");
    }
  }
}
