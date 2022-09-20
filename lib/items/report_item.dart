import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportListItem extends StatelessWidget {
  final String? fid;
  final String? projectFid;
  final List<String>? notes;
  final String? preparedBy;
  final String? punchListType;
  final String? siteVisitDate;

  ReportListItem(
      {this.fid,
      this.notes,
      this.preparedBy,
      this.projectFid,
      this.punchListType,
      this.siteVisitDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: new Padding(
          padding: EdgeInsets.all(16.0),
          child: new Row(children: [
            new Expanded(
                child: new Column(
              children: <Widget>[
                new Text(
                  preparedBy ?? "",
                  textScaleFactor: 1.4,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Utils.appPrimaryColor),
                ),
                SizedBox(height: 8),
                new Text(
                  punchListType ?? "",
                  textScaleFactor: 1.4,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontWeight: FontWeight.normal, color: Colors.black),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: Colors.grey,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    new Text(
                      DateFormat(Utils.appDateFomate)
                          .format(DateTime.parse(siteVisitDate.toString())),
                      // siteVisitDate ?? '',
                      textScaleFactor: 1.4,
                      textAlign: TextAlign.right,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    )
                  ],
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ))
          ]),
        ),
      ),
    );
  }
}
