part of 'issue_bloc.dart';

@immutable
abstract class IssueState {}

class IssueInitial extends IssueState {}

class LoadingState extends IssueState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  LoadingState({this.name, this.emailId, this.profileImagePath, this.userType});
}

class GetAllMissingissues extends IssueState {
  @override
  List<Object> get props => [];
  final List<String>? listOfIssueId;

  GetAllMissingissues({this.listOfIssueId});
}

class RefreshPageState extends IssueState {}

class LogoutState extends IssueState {}

class ErrorState extends IssueState {
  final String? message;

  ErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class LoadedState extends IssueState {
  List? l = [];

  LoadedState({this.l});
}

class DeletedIssueState extends IssueState {}

class EmailSentState extends IssueState {
  final bool? l;

  EmailSentState({this.l});
}

//Export states
class IssueExportInitial extends IssueState {}

class ExportLoadingState extends IssueState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  ExportLoadingState(
      {this.name, this.emailId, this.profileImagePath, this.userType});
}

class ExportErrorState extends IssueState {
  final String? message;

  ExportErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class ExportLoadedState extends IssueState {
  List? l = [];

  ExportLoadedState({this.l});
}
