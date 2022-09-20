import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/models/project.dart';
import 'package:flutter/material.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;

  ProjectListItem(this.project);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: new Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(children: [
                new Expanded(
                    child: new Column(
                  children: <Widget>[
                    new Text(
                      project.name ?? "",
                      textScaleFactor: 1.4,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Utils.appPrimaryColor),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Container(
                      child: Text(
                        project.number ?? "",
                        textScaleFactor: 1.4,
                        // softWrap: false,
                        textAlign: TextAlign.left,
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.fade,
                          // color: Utils.appPrimaryColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          height: 30,
                          width: MediaQuery.of(context).size.width - 100,
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_pin,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Flexible(
                                child: Text(
                                  project.location ?? "",
                                  textScaleFactor: 1.4,
                                  textAlign: TextAlign.right,
                                  softWrap: false,
                                  style: new TextStyle(
                                    overflow: TextOverflow.fade,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
