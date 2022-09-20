import 'package:cmta_field_report/core/error/failures.dart';
import 'package:cmta_field_report/feature/domain/entities/login_response_entity.dart';
import 'package:dartz/dartz.dart';

abstract class Repository {
  Future<Either<Failure, LoginEntity>> login({String emailId, String password});
}
