part of 'home_bloc.dart';

@immutable
abstract class HomeState {}

class HomeInitial extends HomeState {}

class LoadingState extends HomeState {
  final String? name;
  final String? emailId;
  final String? profileImagePath;
  final String? userType;

  LoadingState({this.name, this.emailId, this.profileImagePath, this.userType});
}

class ErrorState extends HomeState {
  final String? message;

  ErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class LoadedState extends HomeState {
  List? l = [];

  LoadedState({this.l});
}

class ApproveState extends HomeState {
  final String? message;

  ApproveState({this.message});
}

class DeletedState extends HomeState {
  final String? message;
  DeletedState({this.message});
}

class LogoutState extends HomeState {}
