import 'package:cmta_field_report/core/error/exceptions.dart';
import 'package:cmta_field_report/core/error/failures.dart';
import 'package:cmta_field_report/core/network/network_info.dart';
import 'package:cmta_field_report/feature/data/datasource/local_datasource.dart';
import 'package:cmta_field_report/feature/data/datasource/remote_datasource.dart';
import 'package:cmta_field_report/feature/domain/entities/login_response_entity.dart';
import 'package:cmta_field_report/feature/domain/repositories/repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

class RepositoryImpl implements Repository {
  final LocalDataSource? localDataSource;
  final RemoteDataSource? remoteDataSource;
  final NetworkInfo? networkInfo;

  RepositoryImpl(
      {@required this.networkInfo,
      @required this.localDataSource,
      @required this.remoteDataSource});

  @override
  Future<Either<Failure, LoginEntity>> login(
      {String? emailId, String? password}) async {
    try {
      final loadedDataModel = await remoteDataSource!
          .login(emailId: emailId ?? "", password: password ?? "");

      return Right(LoginEntity(msg: loadedDataModel.msg));
    } on ValidationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
    // } else {
    //   return Left(NetworkFailure());
    // }
  }
}
