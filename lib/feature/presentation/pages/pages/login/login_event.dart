part of 'login_bloc.dart';

@immutable
abstract class LoginEvent extends Equatable {}

class LoginUserEvent extends LoginEvent {
  final String? userId;
  final String? password;

  LoginUserEvent({this.userId, this.password});

  @override
  List<Object> get props => [userId ?? "", password ?? ""];
}
