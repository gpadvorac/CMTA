import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/data/model/project_list_db_model.dart';
import 'package:cmta_field_report/publish_trace.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "dart:convert";

import '../../../../../injector_container.dart';
import 'login_bloc.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/login_page';

  LoginPage();

  @override
  _LoginPageState createState() {
    return new _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController? emailTextEditingController,
      passwordTextEditingController;
  // String? email = "Cafr2@cmta.com", password = "Abcd123!"; //Test Account Prod
  // String? email = "cafr2@cmta.com", password = "Abcd123!"; // Test Dev/QA

  String? email = "", password = "";

  final client = new http.Client();
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppDatabase.instance.insertClientLogsToLocalDB("Login page opened.");
    emailTextEditingController = TextEditingController(text: email);
    passwordTextEditingController = TextEditingController(text: password);
  }

  getDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Invalid Username or Password"),
            //content: Center(child: Text("Please try again.")),
            actions: <Widget>[
              ElevatedButton(
                child: Text("DONE"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => sl<LoginBloc>(),
        ),
      ],
      child: new Scaffold(
          floatingActionButton: Text(
              "Version: ${FlavorConfig.instance?.name} ${FlavorConfig.instance?.values.appVersion}"),
          body: BlocConsumer<LoginBloc, LoginState>(listener: (context, state) {
            if (state is ErrorState &&
                state.message != null &&
                state.message!.isEmpty) {
              Utils.showErrorToast(state.message ?? "", context);
              // Navigation.back(context);
            } else if (state is LoadingState) {
              Utils.showProgressDialog(context);
            } else if (state is LoadedState) {
              /// Dismissing the progress screen
              print(state.userInformation);
              // showDialog(
              //     context: context,
              //     builder: (BuildContext context) {
              //       return AlertDialog(
              //         title: Text(state.userInformation.toString()),
              //         //content: Center(child: Text("Please try again.")),
              //         actions: <Widget>[
              //           ElevatedButton(
              //             child: Text("DONE"),
              //             onPressed: () {
              //               Navigator.of(context).pop();
              //             },
              //           )
              //         ],
              //       );
              //     });
              // Navigation.back(context)
              Navigator.pop(context);
              if (state.userInformation == 200) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home_page', (_) => false);
              } else {
                getDialog();
              }
            }
          }, builder: (context, state) {
            return Center(
              child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: ListView(
                      children: <Widget>[
                        SizedBox(
                            height: 155.0,
                            child: Image.asset("assets/cmta_logo.png",
                                fit: BoxFit.contain)),
                        SizedBox(height: 45.0),
                        TextField(
                          decoration: InputDecoration(hintText: "CMTA Email"),
                          controller: emailTextEditingController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => this.email = value,
                        ),
                        SizedBox(height: 25.0),
                        TextField(
                          decoration: InputDecoration(hintText: "Password"),
                          controller: passwordTextEditingController,
                          onChanged: (value) => this.password = value,
                          obscureText: true,
                        ),
                        SizedBox(height: 35.0),
                        ElevatedButton(
                          // color: Color(0xff0C8350),

                          style: ElevatedButton.styleFrom(
                            primary: Color(0xff0C8350),
                          ),
                          child: Text(
                            "LOGIN",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            var pref = sl<SharedPreferences>();
                            pref.setStringList("IMAGE_LIST", []);
                            var loginobject = LoginUserEvent(
                                userId: emailTextEditingController?.text ?? "",
                                password: password);
                            BlocProvider.of<LoginBloc>(context)
                                .add(loginobject);

                            AppDatabase.instance.insertClientLogsToLocalDB(
                                "Login button clicked");
                            this.emailTextEditingController!.clear();
                            this.passwordTextEditingController!.clear();

                            // _login();
                          },
                        )
                      ],
                    ),
                  )),
            );
          })),
    );
  }

  _updatePreferences(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setBool("LOGGED_IN", value);
  }

  _login() async {
    var body = {"email": this.email, "password": this.password};

    var headers = {
      "content-type": "application/json",
      "accept": "application/json"
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[CircularProgressIndicator()],
        );
      },
    );

    var url = "https://createllc.dev/login";
    var response;

    try {
      response = await this
          .client
          .post(Uri.parse(url), body: json.encode(body), headers: headers);

      Navigator.pop(context);
    } on Exception catch (e) {
      Utils.logException(
          className: "LoginPage",
          methodName: "login",
          exceptionInfor: e.toString(),
          information1: e.toString());

      PublishTrace(
          className: "LoginPage",
          exceptionInformation: e.toString(),
          methodName: "login");
    }

    if (response.statusCode == 200) {
      print("SUCCESFUL LOGIN");
      //Update sharedpreferences, save username and pass, replace route

      _updatePreferences(true);

      await storage.write(key: "email", value: this.email);
      await storage.write(key: "password", value: this.password);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("userKey", this.email?.replaceAll(".", ",") ?? "");
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      print("LOGIN NOT SUCCESFUL");
      _updatePreferences(false);
      //Present error handlin
    }
  }
}
