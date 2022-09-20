class ExceptionModel {
  String? excpetionId;
  String? userName;
  String? deviceId;
  String? osType;
  String? osVersion;
  String? className;
  String? methodName;
  String? information1;
  String? information2;
  String? exceptionInfo;

  ExceptionModel(
      {this.excpetionId,
      this.userName,
      this.deviceId,
      this.osType,
      this.osVersion,
      this.className,
      this.methodName,
      this.information1,
      this.information2,
      this.exceptionInfo});

  ExceptionModel.fromJson(Map<String, dynamic> json) {
    excpetionId = json['ExcpetionId'];
    userName = json['UserName'];
    deviceId = json['DeviceId'];
    osType = json['OsType'];
    osVersion = json['OsVersion'];
    className = json['ClassName'];
    methodName = json['MethodName'];
    information1 = json['Information1'];
    information2 = json['Information2'];
    exceptionInfo = json['ExceptionInfo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ExcpetionId'] = this.excpetionId;
    data['UserName'] = this.userName;
    data['DeviceId'] = this.deviceId;
    data['OsType'] = this.osType;
    data['OsVersion'] = this.osVersion;
    data['ClassName'] = this.className;
    data['MethodName'] = this.methodName;
    data['Information1'] = this.information1;
    data['Information2'] = this.information2;
    data['ExceptionInfo'] = this.exceptionInfo;
    return data;
  }
}
