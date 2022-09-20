part of 'report_bloc.dart';

@immutable
abstract class ReportEvent extends Equatable {}

class GetProjectListEvent extends ReportEvent {
  final String? profileId;

  GetProjectListEvent({this.profileId});

  @override
  List<Object> get props => [profileId ?? ""];
}

class GetProjectFromDBListEvent extends ReportEvent {
  final String? profileId;

  GetProjectFromDBListEvent({this.profileId});

  @override
  List<Object> get props => [profileId ?? ""];
}

class LogoutEvent extends ReportEvent {
  @override
  List<Object> get props => [];
}

class DeleteReportEvent extends ReportEvent {
  final String? reportId;

  DeleteReportEvent({this.reportId});
  @override
  List<Object> get props => [reportId ?? ""];
}

class GetMyProfileDetails extends ReportEvent {
  @override
  List<Object> get props => [];
}
