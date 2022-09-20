part of 'addIssue_bloc.dart';

@immutable
abstract class AddIssueState {}

class AddIssueInitial extends AddIssueState {}

class LoadingState extends AddIssueState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  LoadingState({this.name, this.emailId, this.profileImagePath, this.userType});
}

class ErrorState extends AddIssueState {
  final String? message;

  ErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class CompletedIssueState extends AddIssueState {
  bool? isSuccess;
  bool? isError;
  String? strMessage;

  CompletedIssueState({
    this.isSuccess,
    this.isError,
    this.strMessage,
  });
}

class LoadedState extends AddIssueState {
  String? isuId;
  String? isuReportId;
  String? isuLocation;
  String? isuDetails;
  String? isuStatus;
  String? issueImage;

  LoadedState(
      {this.issueImage,
      this.isuDetails,
      this.isuId,
      this.isuLocation,
      this.isuReportId,
      this.isuStatus,
      l});
}

class AddIssueSucccessState extends AddIssueState {
  final int? message;
  AddIssueSucccessState({this.message});
}
