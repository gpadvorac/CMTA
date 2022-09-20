import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/database/databse_class.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addProject/addProject_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/home/home_screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class AddProjectPage extends StatefulWidget {
  static const String routeName = '/addProject_page';

  @override
  _AddProjectPageState createState() {
    return new _AddProjectPageState();
  }
}

class _AddProjectPageState extends State<AddProjectPage> {
  TextEditingController? _nameController,
      _numberController,
      _locationController;
  String? _name, _number, _location;

  String? arguments;
  bool f = false;
  FocusNode nameFocusNode = new FocusNode();
  FocusNode locationFocusNode = new FocusNode();
  FocusNode numberFocusNode = new FocusNode();

  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    // i++;
    // if (i == 1) {
    arguments = ModalRoute.of(context)?.settings.arguments as String?;
    if (arguments != null) {
      BlocProvider.of<AddProjectBloc>(context)
          .add(GetProjectEvent(projectId: arguments));
    } else {
      print("new project create");
      setState(() {
        f = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              AppDatabase.instance
                  .insertClientLogsToLocalDB("Add-project back button tapped.");
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Utils.appPrimaryColor,
          title: _name == ""
              ? new Text(
                  "Add Project",
                  style: TextStyle(color: Colors.white),
                )
              : new Text(
                  "Edit Project",
                  style: TextStyle(color: Colors.white),
                ),
          actions: [
            new TextButton(
                onPressed: () {
                  AppDatabase.instance
                      .insertClientLogsToLocalDB("Project Save button tapped.");

                  // print(_location.isEmpty || _name.isEmpty || _number.isEmpty);
                  if (_location == null || _name == null || _number == null) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure all fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else if (_location!.trim() == "" ||
                      _name!.trim() == "" ||
                      _number!.trim() == "") {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure all fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else if (_location!.isEmpty ||
                      _name!.isEmpty ||
                      _number!.isEmpty) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure all fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else {
                    if (arguments == null) {
                      BlocProvider.of<AddProjectBloc>(context).add(AddEvent(
                          projectLocation: _location,
                          projectId: null,
                          projectName: _name,
                          projectNumber: _number));
                    } else {
                      BlocProvider.of<AddProjectBloc>(context).add(AddEvent(
                          projectLocation: _locationController!.text,
                          projectId: (arguments == null) ? null : arguments,
                          projectName: _nameController!.text,
                          projectNumber: _numberController!.text));
                    }
                  }
                },
                child: Icon(
                  Icons.check_circle_outlined,
                  color: Colors.white,
                )
                //  new Text("SAVE", style: TextStyle(color: Colors.white)),
                )
          ]),
      body: BlocConsumer<AddProjectBloc, AddProjectState>(
          listener: (context, state) {
        if (state is ProjectCompletedState) {
          Utils.showToast(
            state.strMessage ?? "",
            context,
          );
          Navigation.back(context);
          Navigation.back(context);
        }
        if (state is ProjectErrorState &&
            state.message != null &&
            !state.message!.isEmpty) {
          Utils.showErrorToast(
            state.message ?? "",
            context,
          );
          Navigation.back(context);
        } else if (state is ProjectLoadingState) {
          Utils.showProgressDialog(context);
        } else if (state is ProjectLoadedState) {
          /// Dismissing the progress screen

          _nameController = new TextEditingController(text: state.pjName);
          _numberController = new TextEditingController(text: state.pjNumber);
          _locationController =
              new TextEditingController(text: state.pjLocation);
          _number = state.pjNumber;
          _location = state.pjLocation;
          _name = state.pjName;

          Navigator.pop(context);
        } else if (state is ProjectCreatedState) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          // Navigator.of(context).pop();

          // (r==null)?Navigation.intentWithDatated(context, MyHomePage.routeName,"new"):
          // Navigation.intentWithDatated(context, MyHomePage.routeName,"created");

          Navigation.intent(
            context,
            MyHomePage.routeName,
          );
        }
      }, builder: (context, state) {
        return new Column(
          children: [
            new ListTile(
                title: new TextField(
              focusNode: nameFocusNode,
              autocorrect: true,
              decoration: InputDecoration(
                  hintStyle: TextStyle(
                    height: 1.4, // sets the distance between label and input
                  ),
                  labelStyle: TextStyle(
                      color: nameFocusNode.hasFocus
                          ? Utils.appPrimaryColor
                          : Colors.black),
                  labelText: "Project Name",
                  hintText: "Enter Project Name"),
              controller: _nameController,
              onChanged: (value) => _name = value,
            )),
            new ListTile(
                title: new TextField(
              autocorrect: true,
              focusNode: numberFocusNode,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  hintStyle: TextStyle(
                    height: 1.4, // sets the distance between label and input
                  ),
                  labelStyle: TextStyle(
                      // fontWeight: FontWeight.bold,
                      color: locationFocusNode.hasFocus
                          ? Utils.appPrimaryColor
                          : Colors.black),
                  labelText: "Project Number",
                  hintText: "Enter Project Number"),
              controller: _numberController,
              onChanged: (value) => _number = value,
            )),
            new ListTile(
                title: new TextField(
              focusNode: locationFocusNode,
              autocorrect: true,
              decoration: InputDecoration(
                  hintStyle: TextStyle(
                    height: 1.4, // sets the distance between label and input
                  ),
                  labelStyle: TextStyle(
                      // fontWeight: FontWeight.bold,
                      color: locationFocusNode.hasFocus
                          ? Utils.appPrimaryColor
                          : Colors.black),
                  labelText: "Project Location",
                  hintText: "Enter Project Location"),
              controller: _locationController,
              onChanged: (value) => _location = value,
            )),
          ],
        );
      }),
    );
  }
}
