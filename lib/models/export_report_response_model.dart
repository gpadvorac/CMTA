class ExportReportReponseModel {
  bool? missingReportOnServer;
  List<String>? missingIssuesOnClient;
  List<String>? missingIssuesOnServer;
  List<String>? issuesWithHasImageDiscrepancies;
  List<String>? issuesWithNoImages;
  bool? isSynced;

  ExportReportReponseModel(
      {this.missingReportOnServer,
      this.missingIssuesOnClient,
      this.missingIssuesOnServer,
      this.issuesWithHasImageDiscrepancies,
      this.issuesWithNoImages,
      this.isSynced});

  ExportReportReponseModel.fromJson(Map<String, dynamic> json) {
    missingReportOnServer = json['MissingReportOnServer'];
    missingIssuesOnClient = json['MissingIssuesOnClient'].cast<String>();
    missingIssuesOnServer = json['MissingIssuesOnServer'].cast<String>();
    issuesWithHasImageDiscrepancies =
        json['IssuesWithHasImageDiscrepancies'].cast<String>();
    issuesWithNoImages = json['IssuesWithNoImages'].cast<String>();
    isSynced = json['IsSynced'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['MissingReportOnServer'] = this.missingReportOnServer;
    data['MissingIssuesOnClient'] = this.missingIssuesOnClient;
    data['MissingIssuesOnServer'] = this.missingIssuesOnServer;
    data['IssuesWithHasImageDiscrepancies'] =
        this.issuesWithHasImageDiscrepancies;
    data['IssuesWithNoImages'] = this.issuesWithNoImages;
    data['IsSynced'] = this.isSynced;
    return data;
  }
}
