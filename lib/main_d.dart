import 'package:cmta_field_report/database/databse_class.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/add-report.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/addReport_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/home/home_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/issue/issue_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/splash/splash_screen.dart';
import 'package:cmta_field_report/injector_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/utils/my_shared_pref.dart';
import 'core/utils/utils.dart';
import 'database/app_database.dart';
import 'feature/presentation/bloc/authentication/authentication_event.dart';
import 'feature/presentation/bloc/my_bloc.dart';
import 'feature/presentation/pages/pages/addIssue/add-issue.dart';
import 'feature/presentation/pages/pages/addIssue/addIssue_bloc.dart';
import 'feature/presentation/pages/pages/addProject/add-project.dart';
import 'feature/presentation/pages/pages/addProject/addProject_bloc.dart';
import 'feature/presentation/pages/pages/home/home_bloc.dart';
import 'feature/presentation/pages/pages/issue/issue_bloc.dart';
import 'feature/presentation/pages/pages/login/login_bloc.dart';
import 'feature/presentation/pages/pages/login/login_screen.dart';
import 'feature/presentation/pages/pages/report/report_bloc.dart';
import 'feature/presentation/pages/pages/report/reports_screen.dart';
import 'injector_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  runApp(MainPage());
}

class MainPage extends StatefulWidget {
  MainPage();

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DB.instance.database;

    commit();
  }

  String h = "LoginPage.routeName";

  Future<bool> commit() async {
    const BASE_URL = "baseUrl";
    // String url = "https://cmtafr-qa.crocodiledigital.net/api";

    String url = "https://cmtafr-dev.crocodiledigital.net/api";

    var _preff = sl<SharedPreferences>();
    // _preff ??= await SharedPreferences.getInstance();

    await _preff.setString(BASE_URL, url);
    // _preff.setString(MySharedPref.PROJECT_FLAVOUR, "qa");
    _preff.setString(MySharedPref.PROJECT_FLAVOUR, "dev");

    return false;
  }

  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      create: (context) => AuthenticationBloc(sharedPref: MySharedPref(null))
        ..add(AppStarted(url: "https://cmtafr-qa.crocodiledigital.net/api")),
      child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Utils.appPrimaryColor,
            fontFamily: "Roboto",
          ),
          debugShowCheckedModeBanner: false,
          routes: {
            MyHomePage.routeName: (context) => BlocProvider<HomeBloc>(
                  create: (context) => sl<HomeBloc>(),
                  child: MyHomePage(),
                ),
            SplashScreen.routeName: (context) => BlocProvider<MyBloc>(
                  create: (context) => sl<MyBloc>(),
                  child: SplashScreen(),
                ),
            LoginPage.routeName: (context) => BlocProvider<LoginBloc>(
                  create: (context) => sl<LoginBloc>(),
                  child: LoginPage(),
                ),
            ReportsPage.routeName: (context) => BlocProvider<ReportBloc>(
                  create: (context) => sl<ReportBloc>(),
                  child: ReportsPage(),
                ),
            IssuesPage.routeName: (context) => BlocProvider<IssueBloc>(
                  create: (context) => sl<IssueBloc>(),
                  child: IssuesPage(),
                ),
            AddReportPage.routeName: (context) => BlocProvider<AddReportBloc>(
                  create: (context) => sl<AddReportBloc>(),
                  child: AddReportPage(),
                ),
            AddIssuePage.routeName: (context) => BlocProvider<AddIssueBloc>(
                  create: (context) => sl<AddIssueBloc>(),
                  child: AddIssuePage(),
                ),
            AddProjectPage.routeName: (context) => BlocProvider<AddProjectBloc>(
                  create: (context) => sl<AddProjectBloc>(),
                  child: AddProjectPage(),
                ),
          },
          initialRoute: MyHomePage.routeName),
    );
  }

// checkPreferences() async {
//   prefs = await SharedPreferences.getInstance();
//
//   if (prefs.getBool("LOGGED_IN") != null) {
//     print("LOGGED_IN Exists");
//     return prefs.getBool("LOGGED_IN");
//   } else {
//     print("LOGGED_IN Does Not Exist");
//
//     prefs.setBool("LOGGED_IN", false);
//     return false;
//   }

}
