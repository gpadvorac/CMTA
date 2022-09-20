class UploadImageModel {
  UploadImageModel({
    required this.isuId,
    required this.imageData,
  });
  late final String isuId;
  late final String imageData;

  UploadImageModel.fromJson(Map<String, dynamic> json) {
    isuId = json['Isu_Id'];
    imageData = json['ImageData'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Isu_Id'] = isuId;
    _data['ImageData'] = imageData;
    return _data;
  }
}
