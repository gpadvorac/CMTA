import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/database/databse_class.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/addReport/addReport_bloc.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/report/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../models/report.dart';

class AddReportPage extends StatefulWidget {
  static const String routeName = '/addReport_page';

  @override
  _AddReportPageState createState() {
    return new _AddReportPageState();
  }
}

class _AddReportPageState extends State<AddReportPage> {
  TextEditingController? _preparedByController;
  TextEditingController? _noteController;
  String? _preparedBy;
  String _siteVisitDate =
      DateFormat(Utils.serverDataFomate).format(DateTime.now());
  String _punchListType = "IN WALL PUNCH LIST";
  String _note = "";
  List<String> _notes = [];
  String dateToSave = DateFormat.yMMMd().format(DateTime.now());
  Report? report;
  bool isUpdate = false;
  String? reportProjectId;
  String? reportId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppDatabase.instance
        .insertClientLogsToLocalDB("Add Report listing screen opned.");
  }

  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    // i++;
    // if (i == 1) {

    Report report = ModalRoute.of(context)!.settings.arguments as Report;
    reportId = report.reportId;
    reportProjectId = report.reportProjectId;

    setState(() {
      isUpdate = true;
      reportProjectId = report.reportProjectId;
      reportId = report.reportId;
    });
    if (reportId != null) {
      BlocProvider.of<AddReportBloc>(context)
          .add(GetReportEvent(reportId: reportId ?? ""));
    } else {
      setState(() {
        isUpdate = false;
        reportProjectId = report.reportProjectId;
        reportId = report.reportId;
      });
    }
  }

  convertDateFomate() {
    try {
      return DateFormat(Utils.appDateFomate)
          .format(DateFormat(Utils.appDateFomate).parse(_siteVisitDate));
    } catch (e) {
      return DateFormat(Utils.appDateFomate)
          .format(DateTime.parse(_siteVisitDate.toString()));
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
                  .insertClientLogsToLocalDB("Report-add back button tapped.");
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Utils.appPrimaryColor,
          title: new Text("Add Report"),
          actions: [
            new ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Utils.appPrimaryColor),
                ),
                onPressed: () {
                  AppDatabase.instance
                      .insertClientLogsToLocalDB("Report Save button tapped.");
                  if (_preparedBy == null ||
                      _punchListType == null ||
                      _siteVisitDate == null) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure all fields are not empty."),
                            actions: <Widget>[
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                ),
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else if (_preparedBy?.trim() == "" ||
                      _punchListType.trim() == "" ||
                      _siteVisitDate.trim() == "") {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure all fields are not empty."),
                            actions: <Widget>[
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                ),
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else {
                    if (_siteVisitDate ==
                        DateFormat.yMMMd().format(DateTime.now())) {
                      setState(() {
                        _siteVisitDate =
                            DateTime.now().toString().split(" ").first;
                      });
                    }
                    if (_siteVisitDate.endsWith("T00:00:00")) {
                      setState(() {
                        _siteVisitDate = _siteVisitDate.split("T").first;
                      });
                    }
                    if (isUpdate == false) {
                      BlocProvider.of<AddReportBloc>(context).add(AddReport(
                          rptVisitDate: DateFormat(Utils.serverReportDataFomate)
                              .format(DateTime.parse(_siteVisitDate)),
                          rptPunchListType: _punchListType,
                          rptPreparedBy: _preparedBy ?? "",
                          rptId: null,
                          rptProjectId: reportProjectId,
                          notes: _note));
                    } else {
                      BlocProvider.of<AddReportBloc>(context).add(AddReport(
                          rptVisitDate: DateFormat(Utils.serverReportDataFomate)
                              .format(DateTime.parse(_siteVisitDate)),
                          rptPunchListType: _punchListType,
                          rptPreparedBy: _preparedBy,
                          rptProjectId: reportProjectId,
                          rptId: reportId,
                          notes: _note));
                    }
                  }
                },
                child: Icon(
                  Icons.check_circle_outlined,
                  color: Colors.white,
                )
                // new Text("SAVE", style: TextStyle(color: Colors.white)),
                )
          ]),
      body: BlocConsumer<AddReportBloc, AddReportState>(
          listener: (context, state) {
        if (state is CompletedState) {
          Utils.showToast(state.strMessage ?? "", context);
          Navigation.back(context);
          Navigation.back(context);
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

          _siteVisitDate = state.rptVisitDate ?? "";
          _punchListType = state.rptPunchListType ?? "";
          _preparedByController =
              new TextEditingController(text: state.rptPreparedBy);
          _notes = _notes;
          _noteController = new TextEditingController(text: state.notes);
          _preparedBy = state.rptPreparedBy;
          _note = ((state.notes == null) ? "" : state.notes)!;
          _noteController!.text = _note;
          Navigator.pop(context);
        } else if (state is AddedState) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigation.intentWithDatated(
              context, ReportsPage.routeName, reportProjectId ?? "");
        }
      }, builder: (context, state) {
        return ListView(
          children: [
            new ListTile(
                title: new TextField(
              maxLines: null,
              decoration: InputDecoration(
                hintStyle: TextStyle(
                  height: 1.4, // sets the distance between label and input
                ),
                labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                labelText: "Prepared By",
                hintText: "Enter Prepared By",
              ),
              autocorrect: true,
              controller: _preparedByController,
              onChanged: (value) => _preparedBy = value,
            )),

            new ListTile(
              title: new Text(
                "Punch Type",
                textScaleFactor: 1.2,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: new Text(
                  "$_punchListType",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());

                await new Future.delayed(new Duration(milliseconds: 100), () {
                  _showPunchTypePicker(context);
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18),
              child: Divider(
                color: Colors.black,
              ),
            ),
            new ListTile(
              title: new Text(
                "Site Visit Date",
                textScaleFactor: 1.2,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: new Text(
                  convertDateFomate(),
                  // "$_siteVisitDate",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());

                await new Future.delayed(new Duration(milliseconds: 100), () {
                  _showDatePicker(context);
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18),
              child: Divider(
                color: Colors.black,
              ),
            ),
            // new Divider(),
            // new ListTile(
            //   leading: new Text(
            //     "Notes",
            //     textScaleFactor: 1.4,
            //   ),
            // trailing: new ElevatedButton(
            //   style: ButtonStyle(
            //     backgroundColor:
            //         MaterialStateProperty.all<Color>(Utils.appPrimaryColor),
            //   ),
            //   child: new Text("ADD NOTE"),
            //   onPressed: () {
            //     //Add Note
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) =>
            //           _showNoteDialog(context, _note),
            //     );
            //   },
            // ),
            // ),
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18),
              child: new TextField(
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    height: 1.4, // sets the distance between label and input
                  ),
                  labelStyle: TextStyle(color: Colors.black, fontSize: 24),
                  labelText: "Notes",
                  hintText: "Enter Notes",
                ),
                textAlignVertical: TextAlignVertical.top,
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textAlign: TextAlign.left,
                controller: _noteController,
                onChanged: (value) => this._note = value,
              ),
            ),
            new SizedBox(
              height: 16,
            ),
            // new Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: <Widget>[
            //     new ElevatedButton(
            //       style: ButtonStyle(
            //         backgroundColor:
            //             MaterialStateProperty.all<Color>(Utils.appPrimaryColor),
            //       ),
            //       child: new Text(
            //         "Save note",
            //       ),
            //       onPressed: () {
            //         setState(() {
            //           // if (this._note != "" && noteIndex == -1) {
            //           //   _notes.add(this._note);
            //           // } else {
            //           //   _notes[noteIndex] = this._note;
            //           // }
            //         });
            //         // Navigator.of(context).pop();
            //       },
            //     ),
            //   ],
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: new Text(_note),
            // ),
          ],
        );
      }),
    );
  }

  // _buildRow(String note, int noteIndex) {
  //   return new Column(children: [
  //     ListTile(
  //       contentPadding:
  //           new EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
  //       title: new Text(note),
  //       onTap: () {
  //         showDialog(
  //             context: context,
  //             builder: (BuildContext context) =>
  //                 _showNoteDialog(context, ));
  //       },
  //     ),
  //     new Divider()
  //   ]);
  // }D

  _showNoteDialog(BuildContext context, String n) {
    _noteController = new TextEditingController(text: n);

    return new SimpleDialog(
      title: new Text("Add Note"),
      contentPadding: EdgeInsets.all(24.0),
      children: <Widget>[
        new TextField(
          autocorrect: true,
          keyboardType: TextInputType.multiline,
          maxLines: 15,
          textAlign: TextAlign.left,
          controller: _noteController,
          onChanged: (value) => this._note = value,
        ),
        new Divider(),
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new ElevatedButton(
              child: new Text("FINISH"),
              onPressed: () {
                setState(() {
                  // if (this._note != "" && noteIndex == -1) {
                  //   _notes.add(this._note);
                  // } else {
                  //   _notes[noteIndex] = this._note;
                  // }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }

  _isEditing(int noteIndex) {
    if (noteIndex != -1) {
      return new ElevatedButton(
          child: new Text(
            "DELETE",
            style: new TextStyle(color: Colors.red),
          ),
          onPressed: () {
            setState(() {
              _notes.removeAt(noteIndex);
              Navigator.of(context).pop();
            });
          });
    } else {
      return SizedBox(
        width: 0.0,
        height: 0.0,
      );
    }
  }

  _showPunchTypePicker(BuildContext context) {
    List<String> punchTypes = [
      "IN WALL PUNCH LIST",
      "ABOVE CEILING PUNCH LIST",
      "FINAL PUNCH LIST",
      "SITE OBSERVATION"
    ];

    new Picker(
        adapter: PickerDataAdapter<String>(pickerdata: punchTypes),
        hideHeader: true,
        textAlign: TextAlign.center,
        title: new Text("Select Punch List Type"),
        columnPadding: const EdgeInsets.all(4.0),
        onConfirm: (Picker picker, List value) {
          setState(() => _punchListType = picker.getSelectedValues()[0]);
        }).showDialog(context);
  }

  _showDatePicker(BuildContext context) {
    new Picker(
        adapter: DateTimePickerAdapter(),
        hideHeader: true,
        title: new Text("Select Site Visit Date"),
        onConfirm: (Picker picker, List value) {
          var date = (picker.adapter as DateTimePickerAdapter).value;

          var formattedDate = DateFormat.yMMMd().format(date!);

          setState(() {
            _siteVisitDate = date.toString();
            // _siteVisitDate = date.toString().split(" ")[0];

            dateToSave = date.toString();
          });
        }).showDialog(context);
  }
}
