import 'package:equatable/equatable.dart';

class LoginEntity extends Equatable {
  final String? msg;

  LoginEntity({this.msg});

  @override
  List<Object> get props => [msg ?? ""];
}
