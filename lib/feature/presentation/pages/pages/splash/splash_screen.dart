import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:cmta_field_report/feature/presentation/bloc/my_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/home/home_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash_screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  VoidCallback? callback;

  AuthenticationBloc? authenticationBloc;
  MySharedPref? sharedPref;
  SharedPreferences? preff;

  bool? l;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    // print(preff.getBool("USER_LOGGEDIN"));
    await checkFirstSeen();
  }

  Future checkFirstSeen() async {
    SharedPreferences? _preff = await SharedPreferences.getInstance();
    bool _seen =
        (_preff.getBool('USER_LOGGEDIN') ?? false); //null safety changes
    print(_preff.getBool('USER_LOGGEDIN'));
    if (_seen == false || _seen == null) {
      print("1");
      Navigation.intentWithClearAllRoutes(context, LoginPage.routeName);
    } else {
      print("2");
      await _preff.setBool('USER_LOGGEDIN', true);
      Navigation.intentWithClearAllRoutes(context, MyHomePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: BlocConsumer<MyBloc, MyState>(
          listener: (context, state) {
            if (state is Loaded) {
              // (l == null || l == false)
              //     ?
              Navigation.intentWithClearAllRoutes(context, LoginPage.routeName);

              // : Navigation.intentWithClearAllRoutes(
              //     context, HomeScreen.routeName);
            } else if (state is Error) {}
          },
          builder: (context, state) => _getBody(),
        ),
      ),
    );
  }

  Widget _getBody() {
    return BlocBuilder<MyBloc, MyState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
              height: 155.0,
              child: Image.asset("assets/cmta_logo.png", fit: BoxFit.contain)),
        ),
      );
    });
  }
}
