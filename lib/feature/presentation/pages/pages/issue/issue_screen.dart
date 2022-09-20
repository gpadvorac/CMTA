import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addIssue/add-issue.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/login/login_screen.dart';
import 'package:cmta_field_report/injector_container.dart';
import 'package:cmta_field_report/models/issue.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../items/issue_item.dart';

import 'issue_bloc.dart';

class IssuesPage extends StatefulWidget {
  static const String routeName = '/issue_page';

  @override
  _IssuesPageState createState() {
    return new _IssuesPageState();
  }
}

class _IssuesPageState extends State<IssuesPage> {
  List projects = [];
  TextEditingController emailController = TextEditingController();
  int i = 0;
  String? r;
  Directory? path;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppDatabase.instance
        .insertClientLogsToLocalDB("Issue listing screen opned.");

    setState(() {
      print("In setstate");
      imageCache.clear();
      imageCache.clearLiveImages();
    });
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    getPath();
    print(path);
    i++;
    if (i == 1) {
      setState(() {
        imageCache.clear();
        imageCache.clearLiveImages();
        r = ModalRoute.of(context)?.settings.arguments as String?;
        final pref = sl<SharedPreferences>();
        emailController.text = pref.getString(MySharedPref.USER_NAME) ?? " ";

        // BlocProvider.of<IssueBloc>(context).add(GetIssueListEvent(reportId: r));
        BlocProvider.of<IssueBloc>(context)
            .add(GetIssueListFromDBEvent(reportId: r));
      });
    }
  }

  getPath() async {
    path = await getApplicationDocumentsDirectory();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IssueBloc, IssueState>(listener: (context, state) {
      if (state is LogoutState) {
        print("Logout");

        Navigation.intentWithClearAllRoutes(context, LoginPage.routeName);
      }
      if (state is ErrorState &&
          state.message != null &&
          !state.message!.isEmpty) {
        Utils.showErrorToast(state.message ?? "", context);
        // Navigation.back(context);
      } else if (state is LoadingState) {
        Utils.showProgressDialog(context);
      } else if (state is LoadedState) {
        /// Dismissing the progress screen

        projects = state.l ?? [];

        Navigator.pop(context);
      } else if (state is EmailSentState) {
        Navigator.pop(context);
      } else if (state is DeletedIssueState) {
        Navigator.pop(context);
        BlocProvider.of<IssueBloc>(context)
            .add(GetIssueListFromDBEvent(reportId: r));
      }
    }, builder: (context, state) {
      return Scaffold(
          appBar: new AppBar(
            elevation: 0,
            centerTitle: false,
            leading: BackButton(
              color: Colors.white,
              onPressed: () {
                AppDatabase.instance.insertClientLogsToLocalDB(
                    "Issue-listing back button tapped.");
                Navigator.of(context).pop();
              },
            ),
            backgroundColor: Utils.appPrimaryColor,
            title: new Text(
              "Issues",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              new BlocConsumer<IssueBloc, IssueState>(
                listener: (context, state) {
                  // TODO: implement listener

                  if (state is ExportLoadedState) {
                    AppDatabase.instance.insertClientLogsToLocalDB(
                        "Issue export button tapped.");
                    showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          _showExportDialog(context),
                    );
                  }

                  if (state is RefreshPageState) {
                    print("object");
                    BlocProvider.of<IssueBloc>(context)
                        .add(GetIssueListFromDBEvent(reportId: r));
                  }
                  if (state is ExportErrorState) {
                    showAlertDialog(context);
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Utils.appPrimaryColor),
                      ),
                      onPressed: () {
                        BlocProvider.of<IssueBloc>(context).add(
                            ExportCheckEvent(
                                emailId: emailController.text,
                                fileName: filename,
                                reportId: r));

                        // AppDatabase.instance.insertClientLogsToLocalDB(
                        //     "Issue export button tapped.");
                        // showDialog(
                        //   context: context,
                        //   builder: (BuildContext context) =>
                        //       _showExportDialog(context),
                        // );
                      },
                      child: state is ExportLoadingState
                          ? Container(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : new Text(
                              "EXPORT",
                              style: TextStyle(color: Colors.white),
                            ));
                },
              )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Utils.appPrimaryColor,
            onPressed: () {
              var issue = Issue(
                  issueId: null,
                  locaFilePath: path?.path,
                  hasImage: false,
                  issueReportId:
                      ModalRoute.of(context)?.settings.arguments as String);

              Navigation.intentWithData(context, AddIssuePage.routeName, issue)
                  .then((value) {
                r = ModalRoute.of(context)!.settings.arguments as String;
                // BlocProvider.of<IssueBloc>(context).add(GetIssueListEvent(reportId: r));
                BlocProvider.of<IssueBloc>(context)
                    .add(GetIssueListFromDBEvent(reportId: r));
              });
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          body: Container(
            color: Colors.grey[200],
            child: ListView(
              children: getListofProject(projects),
            ),
          ));
    });
  }

  loadListing() {
    r = ModalRoute.of(context)!.settings.arguments as String;
    // BlocProvider.of<IssueBloc>(context).add(GetIssueListEvent(reportId: r));
    BlocProvider.of<IssueBloc>(context)
        .add(GetIssueListFromDBEvent(reportId: r));
  }

  List<Widget> getListofProject(List projects) {
    List<Widget> child = [];

    projects.forEach((element) {
      Widget widget = GestureDetector(
          onTap: () async {
            var issue = Issue(
                issueReportId: element["Isu_Rpt_Id"],
                issueId: element["Isu_Id"],
                hasImage: element["Isu_HasImage"],
                isImageDirty: element["Issu_Is_Image_Dirty"] ?? false);
            await Navigation.intentWithData(
                context, AddIssuePage.routeName, issue);
            loadListing();
          },
          // onLongPress: () {
          //   showDialog(
          //       context: context,
          //       builder: (BuildContext context) =>
          //           _buildOptionsDialog(context, element["Isu_Id"]));
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
                          "Issue delete button tapped.");
                      BlocProvider.of<IssueBloc>(context)
                          .add(DeleteIssueEvent(issueId: element["Isu_Id"]));
                    },
                    backgroundColor: Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              child: IssueListItem(
                  location: element["Isu_Location"],
                  isImageDownloaded: element["Issu_Is_Image_downloaded"],
                  image:
                      "${path?.path ?? ""}/${element["IssueImagePath_Original"].split('/').last}",
                  status: element["Isu_Status"],
                  details: element["Isu_Details"])));
      child.add(widget);
    });
    return child;
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Contact support"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Export Report"),
      content: Text("Please wait while, data sync is in progress."),
      actions: [
        // cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  String? filename, email = "";
  final _formKey = GlobalKey<FormState>();

  _showExportDialog(BuildContext contextt) {
    return SimpleDialog(
      title: new Text("Export Report"),
      contentPadding: EdgeInsets.all(16.0),
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            children: [
              new TextFormField(
                textAlign: TextAlign.left,
                onChanged: (value) {
                  this.filename = value;
                },
                validator: (value) {
                  var mes = '*?"|<>:\/ are not allowed';

                  final validCharacters =
                      RegExp(r'^[a-z*/\s*A-Z*/\s*0-9*/\s*&%=#$%,.;@!()-]+$');
                  if (value == null || value.isEmpty) {
                    return "File name should not be empty";
                  } else if (!validCharacters.hasMatch(value)) {
                    return mes;
                  }

                  return null;
                },
                decoration: new InputDecoration(hintText: "Filename"),
              ),
              new TextFormField(
                textAlign: TextAlign.left,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  this.email = value;
                },
                validator: (value) {
                  final validCharacters = RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                  if (value == null ||
                      value.isEmpty ||
                      !validCharacters.hasMatch(value)) {
                    return 'Please enter valid email-id';
                  }
                  return null;
                },
                decoration: new InputDecoration(hintText: "Email"),
              ),
            ],
          ),
        ),
        new Divider(),
        new ElevatedButton(
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor:
                MaterialStateProperty.all<Color>(Utils.appPrimaryColor),
          ),
          child: new Text("SEND"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // If the form is valid, display a snackbar. In the real world,
              // you'd often call a server or save the information in a database.

//               var bytesInLatin1 = latin1.encode(filename ?? "");
// // [68, 97, 114, 116, 32, 105, 115, 32, 97, 119, 101, 115, 111, 109, 101]

//               var base64encoded = base64.encode(bytesInLatin1);
              BlocProvider.of<IssueBloc>(context).add(ExportPdfEvent(
                  emailId: emailController.text,
                  fileName: filename,
                  reportId: r));
              Navigator.pop(context);
            }
          },
        )
      ],
    );
  }

  _buildOptionsDialog(BuildContext conte, String g) {
    Widget cancelButton = ElevatedButton(
      child: Text("CANCEL"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget deleteButton = ElevatedButton(
      child: Text("DELETE"),
      onPressed: () {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Issue delete button tapped.");
        BlocProvider.of<IssueBloc>(context).add(DeleteIssueEvent(issueId: g));
        Navigation.back(context);
      },
    );

    return new AlertDialog(
        title: new Text(
          "Issue Options",
          textScaleFactor: 1.4,
        ),
        content: new Text("What would you like to do with your issue?"),
        actions: [cancelButton, deleteButton]);
  }
}
