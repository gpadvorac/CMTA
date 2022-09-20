import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class AppStarted extends AuthenticationEvent {
  final String? url;

  AppStarted({this.url});

  @override
  List<Object> get props => [url ?? ""];
}

class CompletedState extends AuthenticationEvent {
  bool? isSuccess;
  bool? isError;
  String? strMessage;

  CompletedState({
    this.isSuccess,
    this.isError,
    this.strMessage,
  });
}

class LoggedIn extends AuthenticationEvent {
  final String? token;
  final String? userName;

  LoggedIn({this.token, this.userName});

  @override
  List<Object> get props => [token ?? "", userName ?? ""];
}

class LoggedOut extends AuthenticationEvent {}
