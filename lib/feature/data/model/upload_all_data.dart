class UploadAllDataModel {
  UploadAllDataModel(
      {required this.projects, required this.reports, required this.issues});
  late final String projects;
  late final String reports;
  late final String issues;

  UploadAllDataModel.fromJson(Map<String, dynamic> json) {
    projects = json['Projects'];
    reports = json['Reports'];
    issues = json['Issues'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Projects'] = projects;
    _data['Reports'] = reports;
    _data['Issues'] = reports;

    return _data;
  }
}
