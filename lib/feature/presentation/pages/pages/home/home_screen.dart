import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cmta_field_report/app/flavour_config.dart';
import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addProject/add-project.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_screen.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/report/reports_screen.dart';

import 'package:cmta_field_report/items/project_item.dart';
import 'package:cmta_field_report/models/project.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_bloc.dart';

class MyHomePage extends StatefulWidget {
  static const String routeName = '/home_page';

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer = null;
  int _start = 100000;

  Future<void> startTimer() async {
    SharedPreferences? _preff = await SharedPreferences.getInstance();

    const oneSec = const Duration(seconds: 20);

    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _start = 100000;
          });
        } else {
          bool _isloggedIn = (_preff.getBool('USER_LOGGEDIN') ?? false);

          if (!_isloggedIn) {
            _timer!.cancel();
            return;
          }
          print("Refreshing screen");
          BlocProvider.of<HomeBloc>(context).add(RefreshEvent());

          setState(() {
            _start--;
          });
        }
      },
    );
  }

  loadList() {
    BlocProvider.of<HomeBloc>(context)
        .add(GetAllProjectListEvent(context: context));
  }

  @override
  void initState() {
    super.initState();
    // startTimer();
    // database = FirebaseDatabase(app: widget.app);
    // database.setPersistenceEnabled(true);
    // database.setPersistenceCacheSizeBytes(10000000);

    AppDatabase.instance.insertClientLogsToLocalDB("Home screen opened.");

    sessionCheck();
  }

  sessionCheck() async {
    String hoursDifference = await BlocProvider.of<HomeBloc>(context)
        .calculateDateDifferenceInHour();

    if (int.parse(hoursDifference) < 24) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        Utils.showToast(
            "Session will expire in $hoursDifference hours, need to login again.",
            context,
            isCenter: true,
            duration: 15);
      });
    }
  }

  int i = 0;
  var argument;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    i++;
    if (i == 1) {
      // BlocProvider.of<HomeBloc>(context).add(GetProjectListEvent());
      BlocProvider.of<HomeBloc>(context)
          .add(GetAllProjectListEvent(context: context));
      BlocProvider.of<HomeBloc>(context).add(RefreshEvent());
      BlocProvider.of<HomeBloc>(context).add(UpdateCount());

      Utils.showToast(
          "All data and images will begin downloading and this will take some time.",
          context);
    }

    argument = ModalRoute.of(context)!.settings.arguments;
  }

  @override
  void dispose() {
    print("object dispose");
    super.dispose();
  }

  final project =
      Project(number: "123456", name: "demo", location: "Bangalore");

  List projects = [];

  @override
  Widget build(BuildContext contextt) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        // TODO: implement listener
        if (state is LogoutState) {
          print("LogoutState");
          BlocProvider.of<HomeBloc>(context).add(LogoutEvent());
        }
        print("State : $state");
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Projects',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Utils.appPrimaryColor,
          leading: IconButton(
            icon: Icon(
              Icons.info,
              color: Colors.white,
            ),
            onPressed: () {
              BlocProvider.of<HomeBloc>(context)
                  .add(GetAllProjectListEvent(context: context));
              showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext contex) {
                    return AlertDialog(
                      title: Text("App Info"),
                      content: Text(
                          "App Version: ${FlavorConfig.instance?.name} ${FlavorConfig.instance?.values.appVersion}"),
                      actions: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                              ),
                              child: Text(
                                "OK",
                                style: TextStyle(
                                  color: Utils.appPrimaryColor,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    );
                  });
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Utils.appPrimaryColor),
              ),
              child: Wrap(
                children: <Widget>[
                  Icon(
                    Icons.logout_outlined,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ],
              ),
              onPressed: () {
                AppDatabase.instance
                    .insertClientLogsToLocalDB("Logout button tapped.");

                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext con) {
                      return AlertDialog(
                        title: Text("Are you sure you want to logout?"),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            child: Text(
                              "NO",
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Utils.appPrimaryColor),
                            ),
                            child: Text("YES"),
                            onPressed: () async {
                              BlocProvider.of<HomeBloc>(context)
                                  .add(LogoutEvent());
                            },
                          )
                        ],
                      );
                    });
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Utils.appPrimaryColor,
          onPressed: () {
            Navigation.intentWithData(context, AddProjectPage.routeName, null)
                .then((value) {
              BlocProvider.of<HomeBloc>(context)
                  .add(GetAllProjectListEvent(context: context));
            });
          },
          // tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
        body: BlocConsumer<HomeBloc, HomeState>(listener: (context, state) {
          if (state is UpdateCount) {
            print("Hellooo count ");
          }

          if (state is ErrorState &&
              state.message != null &&
              !state.message!.isEmpty) {
            Utils.showErrorToast(state.message ?? "", context);
            Navigation.back(context);
          } else if (state is LoadingState) {
            Utils.showProgressDialog(context);
          } else if (state is LoadedState) {
            /// Dismissing the progress screen
            print("sttae in screen");
            print(state.l);
            projects = state.l ?? [];
            Navigator.pop(context);
            startTimer();
            if (argument != null) {
              (argument == "new") ? () {} : Navigator.pop(context);
            }
          } else if (state is DeletedState) {
            Navigator.pop(context);
            print("im in delete");
            BlocProvider.of<HomeBloc>(context).add(GetProjectListEvent());
          } else if (state is LogoutState) {
            Navigation.intentWithClearAllRoutes(context, LoginPage.routeName);
          }
        }, builder: (context, state) {
          print(state);
          return Container(
            color: Colors.grey[200],
            child: ListView(
              children: getListofProject(projects),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> getListofProject(List projects) {
    List<Widget> child = [];
    print("im in the method getlist ");
    // print(projects);

    projects.forEach((element) {
      print("im inside the for each");

      final project = Project(
          number: element["Pj_Number"] ?? "",
          name: element["Pj_Name"] ?? "",
          location: element["Pj_Location"] ?? "",
          projectId: element["Pj_Id"] ?? "");

      Widget widget = GestureDetector(
          onTap: () {
            print("on project clicked");
            Navigation.intentWithData(
                context, ReportsPage.routeName, element["Pj_Id"] ?? "");
          },
          // onLongPress: () {
          //   showDialog(
          //     context: context,
          //     builder: (BuildContext context) =>
          //         _buildOptionsDialog(context, element["Pj_Id"] ?? ""),
          //   );
          // },
          child: Slidable(
              // Specify a key if the Slidable is dismissible.
              key: const ValueKey(0),

              // The start action pane is the one at the left or the top side.
              endActionPane: ActionPane(
                // A motion is a widget used to control how the pane animates.
                motion: const ScrollMotion(),

                // A pane can dismiss the Slidable.
                // dismissible: DismissiblePane(onDismissed: () {}),

                // All actions are defined in the children parameter.
                children: [
                  // A SlidableAction can have an icon and/or a label.
                  SlidableAction(
                    autoClose: true,
                    spacing: 10,
                    onPressed: (context) {
                      AppDatabase.instance.insertClientLogsToLocalDB(
                          "Project delete button tapped.");
                      BlocProvider.of<HomeBloc>(context).add(
                          DeleteProjectEvent(projectId: project.projectId));
                    },
                    backgroundColor: Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                  SlidableAction(
                    autoClose: true,
                    spacing: 10,
                    onPressed: (context) async {
                      var context1 = context;

                      AppDatabase.instance.insertClientLogsToLocalDB(
                          "Project edit button tapped.");

                      await Navigation.intentWithData(
                          context, AddProjectPage.routeName, project.projectId);

                      // setState(() {
                      loadList();
                      print("object helloooooo");
                      // });
                    },
                    backgroundColor: Color(0xFF21B7CA),
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                ],
              ),
              child: ProjectListItem(project)));
      child.add(widget);
    });

    return child;
  }

  void editClicked(BuildContext context) {
    print("Edit ");
  }

  void deleteClicked(BuildContext context) {
    print("Delete");
  }

  _buildOptionsDialog(BuildContext conte, String projectId) {
    print("i am in the buildoption dialog");
    print(projectId);
    Widget cancelButton = ElevatedButton(
      child: Text("CANCEL"),
      onPressed: () {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Project cancel button tapped.");
        Navigator.of(context).pop();
      },
    );

    Widget editButton = ElevatedButton(
      child: Text("EDIT"),
      onPressed: () {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Project edit button tapped.");
        Navigator.of(context).pop();
        Navigation.intentWithData(context, AddProjectPage.routeName, projectId)
            .then((value) {
          print("object");
          BlocProvider.of<HomeBloc>(context)
              .add(GetAllProjectListEvent(context: context));
        });
      },
    );

    Widget deleteButton = ElevatedButton(
      child: Text(
        "DELETE",
        style: new TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Project delete button tapped.");
        print(projectId);
        BlocProvider.of<HomeBloc>(context)
            .add(DeleteProjectEvent(projectId: projectId));
        Navigator.of(context).pop();
      },
    );

    return new AlertDialog(
        title: new Text("Project Options"),
        content: new Text("What would you like to do with your project?"),
        actions: [cancelButton, editButton, deleteButton]);
  }

  _openReportsScreen(Project project) {
    print("Open reports for project: ");

    WidgetBuilder builder;
    builder = (BuildContext _) => ReportsPage();

    Navigator.of(context).push(
        new MaterialPageRoute<void>(builder: builder, fullscreenDialog: false));
  }
}
