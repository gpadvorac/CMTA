import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/report/report_bloc.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../issue/issue_screen.dart';
import '../addReport/add-report.dart';

import '../../../../../items/report_item.dart';

import '../../../../../models/report.dart';

class ReportsPage extends StatefulWidget {
  static const String routeName = '/report_page';

  final String? profileId;

  ReportsPage({this.profileId});

  @override
  _ReportsPageState createState() {
    return new _ReportsPageState();
  }
}

class _ReportsPageState extends State<ReportsPage> {
  int? i;
  String? r;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppDatabase.instance
        .insertClientLogsToLocalDB("Report listing screen opned.");
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    // i++;
    // if (i == 1) {
    r = ModalRoute.of(context)?.settings.arguments
        as String?; //null safety changes

    // BlocProvider.of<ReportBloc>(context).add(GetProjectListEvent(profileId: r));
    BlocProvider.of<ReportBloc>(context)
        .add(GetProjectFromDBListEvent(profileId: r));

    // }
  }

  List projects = [];

  loadReports(String reportProjectId) {
    BlocProvider.of<ReportBloc>(context)
        .add(GetProjectFromDBListEvent(profileId: reportProjectId));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        elevation: 0,
        centerTitle: false,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            AppDatabase.instance.insertClientLogsToLocalDB(
                "Report-listing back button tapped.");
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Utils.appPrimaryColor,
        title: new Text(
          "Reports",
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.appPrimaryColor,
        onPressed: () {
          // Navigator.of(context).pop();

          Report r = Report(
              reportProjectId:
                  ModalRoute.of(context)!.settings.arguments as String,
              reportId: null);
          Navigation.intentWithData(context, AddReportPage.routeName, r).then(
              (value) => BlocProvider.of<ReportBloc>(context).add(
                  GetProjectFromDBListEvent(profileId: r.reportProjectId)));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ReportBloc, ReportState>(listener: (context, state) {
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
        } else if (state is DeletedState) {
          // Navigator.pop(context);
          Navigator.pop(context);
          BlocProvider.of<ReportBloc>(context)
              .add(GetProjectFromDBListEvent(profileId: r));
        }
      }, builder: (context, state) {
        return Container(
          color: Colors.grey[200],
          child: ListView(
            children: getListofProject(projects),
          ),
        );
      }),
    );
  }

  List<Widget> getListofProject(List projects) {
    List<Widget> child = [];

    projects.forEach((element) {
      List<String> n = [];
      Report report = Report(
          reportId: element["Rpt_Id"], reportProjectId: element["Rpt_Pj_Id"]);
      Widget widget = GestureDetector(
          onTap: () {
            // Navigation.intentWithData(
            //     context, AddReportPage.routeName, element["Rpt_Id"]);

            Navigation.intentWithData(
                context, IssuesPage.routeName, element["Rpt_Id"]);
          },
          // onLongPress: () {
          //   Report report = Report(
          //       reportId: element["Rpt_Id"],
          //       reportProjectId: element["Rpt_Pj_Id"]);
          //   showDialog(
          //       context: context,
          //       builder: (BuildContext context) =>
          //           _buildOptionsDialog(context, report));
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
                          "Report delete button tapped.");
                      BlocProvider.of<ReportBloc>(context)
                          .add(DeleteReportEvent(reportId: report.reportId));
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
                      AppDatabase.instance.insertClientLogsToLocalDB(
                          "Report edit button tapped.");

                      await Navigation.intentWithData(
                          context, AddReportPage.routeName, report);

                      loadReports(report.reportProjectId.toString());
                    },
                    backgroundColor: Color(0xFF21B7CA),
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                ],
              ),
              child: ReportListItem(
                notes: n,
                preparedBy: element["Rpt_PreparedBy"],
                punchListType: element["Rpt_PunchListType"],
                siteVisitDate: element["Rpt_VisitDate"],
              )));
      child.add(widget);
    });
    return child;
  }

  _buildOptionsDialog(BuildContext conte, Report report) {
    Widget cancelButton = TextButton(
      child: Text("CANCEL"),
      onPressed: () {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Report cancel button tapped.");
        Navigator.of(context).pop();
      },
    );

    Widget editButton = TextButton(
      child: Text("EDIT"),
      onPressed: () {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Report edit button tapped.");
        Navigator.of(context).pop();
        Navigation.intentWithData(context, AddReportPage.routeName, report)
            .then((value) => BlocProvider.of<ReportBloc>(context).add(
                GetProjectFromDBListEvent(profileId: report.reportProjectId)));
      },
    );

    Widget deleteButton = TextButton(
      child: Text(
        "DELETE",
        style: new TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        AppDatabase.instance
            .insertClientLogsToLocalDB("Report delete button tapped.");
        BlocProvider.of<ReportBloc>(context)
            .add(DeleteReportEvent(reportId: report.reportId));
      },
    );

    return new AlertDialog(
        title: new Text("Report Options"),
        content: new Text("What would you like to do with your report?"),
        actions: [cancelButton, editButton, deleteButton]);
  }
}
