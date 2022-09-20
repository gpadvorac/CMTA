part of 'addReport_bloc.dart';

@immutable
abstract class AddReportState {}

class AddReportInitial extends AddReportState {}

class LoadingState extends AddReportState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  LoadingState({this.name, this.emailId, this.profileImagePath, this.userType});
}

class ErrorState extends AddReportState {
  final String? message;

  ErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class CompletedState extends AddReportState {
  bool? isSuccess;
  bool? isError;
  String? strMessage;

  CompletedState({
    this.isSuccess,
    this.isError,
    this.strMessage,
  });
}

class LoadedState extends AddReportState {
  String? rptId;
  String? rptProjectId;
  String? rptPunchListType;
  String? rptPreparedBy;
  String? rptVisitDate;
  String? notes;

  LoadedState(
      {this.rptId,
      this.rptProjectId,
      this.rptPreparedBy,
      this.rptPunchListType,
      this.rptVisitDate,
      this.notes});
}

class AddedState extends AddReportState {
  final String? message;
  AddedState({this.message});
}

class ReportCreated extends AddReportState {}
