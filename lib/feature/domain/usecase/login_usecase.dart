import 'package:cmta_field_report/core/error/failures.dart';
import 'package:cmta_field_report/core/usecase/usecase.dart';
import 'package:cmta_field_report/feature/domain/entities/login_response_entity.dart';
import 'package:cmta_field_report/feature/domain/repositories/repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

/// Usecase for handling login of user
class LoginUseCase extends UseCase<LoginEntity, LoginParam> {
  final Repository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, LoginEntity>> call(LoginParam params) async {
    return await _repository.login(
        emailId: params.emailId ?? "", password: params.password ?? "");
  }
}

class LoginParam extends Equatable {
  final String? emailId;
  final String? password;

  LoginParam({this.emailId, this.password});

  @override
  List<Object> get props => [emailId ?? "", password ?? ""];
}
