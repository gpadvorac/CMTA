import 'dart:io';

import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class IssueListItem extends StatefulWidget {
  final String? details;
  final String? location;
  final String? status;
  final String? image;
  final int? isImageDownloaded;

  IssueListItem(
      {this.details,
      this.location,
      this.status,
      this.image,
      this.isImageDownloaded});

  @override
  State<IssueListItem> createState() => _IssueListItemState();
}

class _IssueListItemState extends State<IssueListItem> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() => {imageCache.clear(), imageCache.clearLiveImages()});
  }

  @override
  Widget build(BuildContext context) {
    // var imageToShow = FileImage(File(image ?? ""));
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: new Padding(
          padding: EdgeInsets.all(16.0),
          child: new Row(children: [
            new Column(
              children: <Widget>[
                new Container(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(
                        widget.image ?? "",
                      ),
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Image.asset(
                          'assets/cmta_logo_loading.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  //new Image.network(image ?? ""),
                  height: 100,
                  width: 100,
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            new Expanded(
                child: new Padding(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                    widget.details ?? "",
                    textScaleFactor: 1.4,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.appPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    widget.location ?? "",
                    textScaleFactor: 1.4,
                    textAlign: TextAlign.left,
                    style: new TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  new Text(
                    widget.status ?? "",
                    textScaleFactor: 1.4,
                    textAlign: TextAlign.right,
                    style: new TextStyle(
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            )),
          ]),
        ),
      ),
    );
  }
}
