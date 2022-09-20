class Project {
  String? name;
  String? email;
  String? number;
  String? location;
  String? projectId;

  Project({this.name, this.number, this.location, this.projectId});

  Project.fromJson(Map<String, dynamic> json) {
    projectId = json['Pj_Id'];

    number = json['Pj_Number'];
    name = json['Pj_Name'];
    location = json['Pj_Location'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Pj_Id'] = projectId;
    _data['Pj_Number'] = number;
    _data['Pj_Name'] = number;
    _data['Pj_Location'] = location;
    return _data;
  }
}
