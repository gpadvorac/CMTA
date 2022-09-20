part of 'report_bloc.dart';

@immutable
abstract class ReportState {}

class ReportInitial extends ReportState {}

class LoadingState extends ReportState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  LoadingState({this.name, this.emailId, this.profileImagePath, this.userType});
}

class ErrorState extends ReportState {
  final String? message;

  ErrorState({this.message});

  // @override
  // List<Object> get props => [message];
}

class LoadedState extends ReportState {
  List? l = [];

  LoadedState({this.l});
}

class DeletedState extends ReportState {
  final String? message;
  DeletedState({this.message});
}
