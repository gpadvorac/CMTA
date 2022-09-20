part of 'issue_bloc.dart';

@immutable
abstract class IssueEvent extends Equatable {}

class GetIssueListEvent extends IssueEvent {
  final String? reportId;

  GetIssueListEvent({this.reportId});

  @override
  List<Object> get props => [reportId ?? ""];
}

class GetAllMissingissuesEvent extends IssueEvent {
  @override
  List<Object> get props => [];
  List<String>? listOfIssueId;

  GetAllMissingissuesEvent({required this.listOfIssueId});
}

class GetIssueListFromDBEvent extends IssueEvent {
  final String? reportId;

  GetIssueListFromDBEvent({this.reportId});

  @override
  List<Object> get props => [reportId ?? ""];
}

class LogoutEvent extends IssueEvent {
  @override
  List<Object> get props => [];
}

class GetMyProfileDetails extends IssueEvent {
  @override
  List<Object> get props => [];
}

class RefreshPageEvent extends IssueEvent {
  @override
  List<Object> get props => [];
}

class DeleteIssueEvent extends IssueEvent {
  final String? issueId;

  DeleteIssueEvent({this.issueId});

  @override
  List<Object> get props => [issueId ?? ""];
}

class ExportPdfEvent extends IssueEvent {
  final String? fileName;
  final String? emailId;
  final String? reportId;
  ExportPdfEvent({this.emailId, this.fileName, this.reportId});
  @override
  List<Object> get props => [fileName ?? "", emailId ?? "", reportId ?? ""];
}

class ExportCheckEvent extends IssueEvent {
  final String? fileName;
  final String? emailId;
  final String? reportId;
  ExportCheckEvent({this.emailId, this.fileName, this.reportId});
  @override
  List<Object> get props => [fileName ?? "", emailId ?? "", reportId ?? ""];
}
