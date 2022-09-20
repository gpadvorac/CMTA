import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_event.dart';
import 'package:cmta_field_report/feature/presentation/bloc/my_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addIssue/add-issue.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addIssue/addIssue_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addProject/add-project.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addProject/addProject_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/add-report.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/addReport_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/home/home_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/home/home_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/issue/issue_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/issue/issue_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/report/report_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/report/reports_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/splash/splash_screen.dart';
import 'package:cmta_field_report/injector_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({Key? key}) : super(key: key);

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint>
    with WidgetsBindingObserver {
  @override
  void dispose() {
    // TODO: implement dispose
    print("object dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      create: (context) => AuthenticationBloc(sharedPref: MySharedPref(null))
        ..add(AppStarted(url: FlavorConfig.instance!.values.baseUrl)),
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
          initialRoute: SplashScreen.routeName),
    );
  }
}
