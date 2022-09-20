import 'dart:async';

import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/database/databse_class.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../injector_container.dart';
import 'LifeCycleManager.dart';
import 'flavour_config.dart';
import 'app.dart';
import 'package:cmta_field_report/injector_container.dart' as di;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  const values = FlavorValues(
    // baseUrl: "https://cmtafr-dev.crocodiledigital.net/api",
    baseUrl: "https://cmtafr-dev.nwis.net/api",
    logNetworkInfo: true,
    authProvider: ' ',
    appVersion: Utils.appVersion,
  );

  FlavorConfig(
    flavor: Flavor.uat,
    name: 'Dev',
    color: Colors.white,
    values: values,
  );

  await commitDev();

  runApp(LifeCycleManager(child: AppEntryPoint()));
}


Future<bool> commitDev() async {
  // Utils.firebaseSetup();
  DB.instance.database;

  const BASE_URL = "baseUrl";
  String url = FlavorConfig.instance!.values.baseUrl;
  var _preff = sl<SharedPreferences>();
  await _preff.setString(BASE_URL, url);
  _preff.setString(MySharedPref.PROJECT_FLAVOUR, "dev");

  return false;
}
