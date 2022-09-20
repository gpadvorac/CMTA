part of 'login_bloc.dart';

@immutable
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoadingState extends LoginState {}

class ErrorState extends LoginState {
  final String? message;

  ErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class LoadedState extends LoginState {
  final int? userInformation;

  LoadedState({this.userInformation});
}
