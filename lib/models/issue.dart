class Issue {
  String? issueId;
  String? issueReportId;
  String? locaFilePath;
  bool? isImageDownloaded;
  bool? hasImage;
  bool? isImageDirty;

  Issue(
      {this.issueId,
      this.issueReportId,
      this.locaFilePath,
      this.isImageDownloaded,
      this.hasImage,
      this.isImageDirty});
}
