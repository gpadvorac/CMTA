class LoginV2Model {
  LoginV2Model(
      {required this.cmtaUserId,
      required this.token,
      required this.expirationDate});
  late final String cmtaUserId;
  late final String token;
  late final String expirationDate;

  LoginV2Model.fromJson(Map<String, dynamic> json) {
    cmtaUserId = json['CmtaUserId'];
    token = json['Token'];
    expirationDate = json['ExpirationDate'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['CmtaUserId'] = cmtaUserId;
    _data['Token'] = token;
    _data['ExpirationDate'] = expirationDate;
    return _data;
  }
}
