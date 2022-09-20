class AllProjectData {
  AllProjectData({
    required this.projects,
    required this.reports,
    required this.issues,
  });
  late final List<Projects>? projects;
  late final List<Reports>? reports;
  late final List<Issues>? issues;

  AllProjectData.fromJson(Map<String, dynamic> json) {
    projects = json['Projects'] == null
        ? []
        : List.from(json['Projects']).map((e) => Projects.fromJson(e)).toList();
    reports = json['Reports'] == null
        ? []
        : List.from(json['Reports']).map((e) => Reports.fromJson(e)).toList();
    issues = json['Issues'] == null
        ? []
        : List.from(json['Issues']).map((e) => Issues.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Projects'] = projects?.map((e) => e.toJson()).toList();
    _data['Reports'] = reports?.map((e) => e.toJson()).toList();
    _data['Issues'] = issues?.map((e) => e.toJson()).toList();
    return _data;
  }
}

class Projects {
  Projects(
      {required this.pjId,
      required this.pjCUsrId,
      required this.pjNumber,
      required this.pjName,
      required this.pjLocation,
      this.pjDeletedFlag,
      this.pjCreateDate,
      this.pjLastModifiedDate});

  late final String? pjId;
  late final String? pjCUsrId;
  late final String? pjNumber;
  late final String? pjName;
  late final String? pjLocation;
  late final String? pjCreateDate;
  late final String? pjLastModifiedDate;
  late final int? pjDeletedFlag;

  Projects.fromJson(Map<String, dynamic> json) {
    pjId = json['Pj_Id'];
    pjCUsrId = json['Pj_CUsr_Id'];
    pjNumber = json['Pj_Number'];
    pjName = json['Pj_Name'];
    pjLocation = json['Pj_Location'];
    pjCreateDate = json['Pj_CreatedDate'];
    pjLastModifiedDate = json['Pj_LastModifiedDate'];
    pjDeletedFlag = json['Pj_Deleted_Flag'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Pj_Id'] = pjId;
    _data['Pj_CUsr_Id'] = pjCUsrId;
    _data['Pj_Number'] = pjNumber;
    _data['Pj_Name'] = pjName;
    _data['Pj_Location'] = pjLocation;
    _data['Pj_CreatedDate'] = pjCreateDate;
    _data['Pj_LastModifiedDate'] = pjLastModifiedDate;
    _data['Pj_Deleted_Flag'] = pjDeletedFlag;

    return _data;
  }
}

class Reports {
  Reports({
    required this.rptId,
    required this.rptPjId,
    required this.rptPunchListType,
    required this.rptPreparedBy,
    required this.rptVisitDate,
    required this.rptRemarks,
    this.rptDeletedFlag,
  });
  late final String? rptId;
  late final String? rptPjId;
  late final String? rptPunchListType;
  late final String? rptPreparedBy;
  late final String? rptVisitDate;
  // late final String? rptRemark;
  late final String? rptCreatedDate;
  late final String? rptLastModifiedDate;
  late final String? rptRemarks;
  late final int? rptDeletedFlag;

  Reports.fromJson(Map<String, dynamic> json) {
    rptId = json['Rpt_Id'];
    rptPjId = json['Rpt_Pj_Id'];
    rptPunchListType = json['Rpt_PunchListType'];
    rptPreparedBy = json['Rpt_PreparedBy'];
    rptVisitDate = json['Rpt_VisitDate'];
    rptRemarks = json['Rpt_Remarks'];
    rptCreatedDate = json['Rpt_CreatedDate'];
    rptLastModifiedDate = json['Rpt_LastModifiedDate'];
    rptDeletedFlag = json['Rpt_Deleted_Flag'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Rpt_Id'] = rptId;
    _data['Rpt_Pj_Id'] = rptPjId;
    _data['Rpt_PunchListType'] = rptPunchListType;
    _data['Rpt_PreparedBy'] = rptPreparedBy;
    _data['Rpt_VisitDate'] = rptVisitDate;
    _data['Rpt_CreatedDate'] = this.rptCreatedDate;
    _data['Rpt_LastModifiedDate'] = this.rptLastModifiedDate;
    _data['Rpt_Remarks'] = this.rptRemarks;
    _data['Rpt_Deleted_Flag'] = this.rptDeletedFlag;

    return _data;
  }
}

class Issues {
  Issues(
      {required this.isuId,
      required this.isuRptId,
      required this.isuLocation,
      required this.isuDetails,
      required this.isuStatus,
      required this.issuImageLocaPath,
      // required this.isImageDownloaded,
      required this.isuHasImage,
      required this.issueImagePathOriginal,
      this.isuCreatedDate,
      required this.isImageDirty,
      this.isuLastModifiedDate});

  late final String? isuId;
  late final String? isuRptId;
  late final String? isuLocation;
  late final String? isuDetails;
  late final String? isuStatus;
  late final String? issuImageLocaPath;
  // late final int? isImageDownloaded;
  late final bool? isuHasImage;
  late final String? issueImagePathOriginal;
  late final String? isuCreatedDate;
  late final String? isuLastModifiedDate;
  late final bool? isImageDirty;

  Issues.fromJson(Map<String, dynamic> json) {
    isuId = json['Isu_Id'];
    isuRptId = json['Isu_Rpt_Id'];
    isuLocation = json['Isu_Location'];
    isuDetails = json['Isu_Details'];
    isuStatus = json['Isu_Status'];
    issuImageLocaPath = json['Issu_Image_Loca_Path'];
    // isImageDownloaded = json['Issu_Is_Image_downloaded'];
    if (json['Isu_HasImage'] is bool) {
      isuHasImage = json['Isu_HasImage'] == true ? true : false;
    } else {
      isuHasImage = json['Isu_HasImage'] == 1 ? true : false;
    }
    issueImagePathOriginal = json['IssueImagePath_Original'];
    isuCreatedDate = json['Isu_CreatedDate'];
    isuLastModifiedDate = json['Isu_LastModifiedDate'];
    // isImageDirty = json['Issu_Is_Image_Dirty'];

    if (json['Issu_Is_Image_Dirty'] is bool) {
      isImageDirty = json['Issu_Is_Image_Dirty'] == true ? true : false;
    } else {
      isImageDirty = json['Issu_Is_Image_Dirty'] == 1 ? true : false;
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Isu_Id'] = isuId;
    _data['Isu_Rpt_Id'] = isuRptId;
    _data['Isu_Location'] = isuLocation;
    _data['Isu_Details'] = isuDetails;
    _data['Isu_Status'] = isuStatus;
    _data['Issu_Image_Loca_Path'] = issuImageLocaPath;
    // _data['Issu_Is_Image_downloaded'] = isImageDownloaded;
    _data['Isu_HasImage'] = this.isuHasImage;
    _data['IssueImagePath_Original'] = this.issueImagePathOriginal;
    _data['Isu_CreatedDate'] = this.isuCreatedDate;
    _data['Isu_LastModifiedDate'] = this.isuLastModifiedDate;
    _data['Issu_Is_Image_Dirty'] = this.isImageDirty;

    return _data;
  }
}

class MissingIssuesModel {
  MissingIssuesModel(
      {required this.isuId,
      required this.isuRptId,
      required this.isuLocation,
      required this.isuDetails,
      required this.isuStatus,
      required this.issuImageLocaPath,
      // required this.isImageDownloaded,
      required this.isuHasImage,
      required this.issueImagePathOriginal,
      this.isuCreatedDate,
      required this.isImageDirty,
      this.isuLastModifiedDate,
      this.isIssueDeletedFlag});

  late final String? isuId;
  late final String? isuRptId;
  late final String? isuLocation;
  late final String? isuDetails;
  late final String? isuStatus;
  late final String? issuImageLocaPath;
  // late final int? isImageDownloaded;
  late final bool? isuHasImage;
  late final String? issueImagePathOriginal;
  late final String? isuCreatedDate;
  late final String? isuLastModifiedDate;
  late final bool? isImageDirty;
  late final bool? isIssueDeletedFlag;

  MissingIssuesModel.fromJson(Map<String, dynamic> json) {
    isuId = json['Isu_Id'];
    isuRptId = json['Isu_Rpt_Id'];
    isuLocation = json['Isu_Location'];
    isuDetails = json['Isu_Details'];
    isuStatus = json['Isu_Status'];
    issuImageLocaPath = json['Issu_Image_Loca_Path'];
    // isImageDownloaded = json['Issu_Is_Image_downloaded'];
    if (json['Isu_HasImage'] is bool) {
      isuHasImage = json['Isu_HasImage'] == true ? true : false;
    } else {
      isuHasImage = json['Isu_HasImage'] == 1 ? true : false;
    }
    issueImagePathOriginal = json['IssueImagePath_Original'];
    isuCreatedDate = json['Isu_CreatedDate'];
    isuLastModifiedDate = json['Isu_LastModifiedDate'];
    isIssueDeletedFlag = json['Isu_Deleted_Flag'];

    if (json['Issu_Is_Image_Dirty'] is bool) {
      isImageDirty = json['Issu_Is_Image_Dirty'] == true ? true : false;
    } else {
      isImageDirty = json['Issu_Is_Image_Dirty'] == 1 ? true : false;
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Isu_Id'] = isuId;
    _data['Isu_Rpt_Id'] = isuRptId;
    _data['Isu_Location'] = isuLocation;
    _data['Isu_Details'] = isuDetails;
    _data['Isu_Status'] = isuStatus;
    _data['Issu_Image_Loca_Path'] = issuImageLocaPath;
    // _data['Issu_Is_Image_downloaded'] = isImageDownloaded;
    _data['Isu_HasImage'] = this.isuHasImage;
    _data['IssueImagePath_Original'] = this.issueImagePathOriginal;
    _data['Isu_CreatedDate'] = this.isuCreatedDate;
    _data['Isu_LastModifiedDate'] = this.isuLastModifiedDate;
    _data['Issu_Is_Image_Dirty'] = this.isImageDirty;
    _data['Isu_Deleted_Flag'] = this.isIssueDeletedFlag;

    return _data;
  }
}

class IssuesExportRequestModel {
  IssuesExportRequestModel({
    required this.isuId,
    required this.isuHasImage,
  });

  late final String? isuId;
  late final bool? isuHasImage;

  IssuesExportRequestModel.fromJson(Map<String, dynamic> json) {
    isuId = json['Isu_Id'];

    if (json['Isu_HasImage'] is bool) {
      isuHasImage = json['Isu_HasImage'] == true ? true : false;
    } else {
      isuHasImage = json['Isu_HasImage'] == 1 ? true : false;
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Isu_Id'] = isuId;
    _data['Isu_HasImage'] = this.isuHasImage;

    return _data;
  }
}

class UploadIssues {
  UploadIssues(
      {required this.isuId,
      required this.isuRptId,
      required this.isuLocation,
      required this.isuDetails,
      required this.isuStatus,
      required this.isuHasImage,
      this.isuDeletedFlag,
      this.isuCreatedDate,
      this.isuLastModifiedDate});

  late final String? isuId;
  late final String? isuRptId;
  late final String? isuLocation;
  late final String? isuDetails;
  late final String? isuStatus;
  late final int? isuHasImage;
  late final int? isuDeletedFlag;

  late final String? isuCreatedDate;
  late final String? isuLastModifiedDate;

  UploadIssues.fromJson(Map<String, dynamic> json) {
    isuId = json['Isu_Id'];
    isuRptId = json['Isu_Rpt_Id'];
    isuLocation = json['Isu_Location'];
    isuDetails = json['Isu_Details'];
    isuStatus = json['Isu_Status'];

    isuHasImage = json['Isu_HasImage'];
    isuCreatedDate = json['Isu_CreatedDate'];
    isuLastModifiedDate = json['Isu_LastModifiedDate'];
    isuDeletedFlag = json['Isu_Deleted_Flag'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Isu_Id'] = isuId;
    _data['Isu_Rpt_Id'] = isuRptId;
    _data['Isu_Location'] = isuLocation;
    _data['Isu_Details'] = isuDetails;
    _data['Isu_Status'] = isuStatus;
    _data['Isu_HasImage'] = this.isuHasImage;
    _data['Isu_CreatedDate'] = this.isuCreatedDate;
    _data['Isu_LastModifiedDate'] = this.isuLastModifiedDate;
    _data['Isu_Deleted_Flag'] = this.isuDeletedFlag;

    return _data;
  }
}

class ClientDeviceLogs {
  ClientDeviceLogs({
    required this.cdalId,
    required this.cdalTransactionId,
    required this.cdalActivity,
    this.cdalDateTimeStamp,
  });
  late final String? cdalId;
  late final String? cdalTransactionId;
  late final String? cdalActivity;
  late final String? cdalDateTimeStamp;

  ClientDeviceLogs.fromJson(Map<String, dynamic> json) {
    cdalId = json['Cdal_Id'];
    cdalTransactionId = json['Cdal_TransactionId'];
    cdalActivity = json['Cdal_Activity'];
    cdalDateTimeStamp = json['Cdal_DateTimeStamp'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['Cdal_Id'] = cdalId;
    _data['Cdal_TransactionId'] = cdalTransactionId;
    _data['Cdal_Activity'] = cdalActivity;
    _data['Cdal_DateTimeStamp'] = cdalDateTimeStamp;

    return _data;
  }
}
