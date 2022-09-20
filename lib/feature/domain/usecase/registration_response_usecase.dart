// import 'package:dartz/dartz.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter_app/core/error/failures.dart';
// import 'package:flutter_app/core/usecase/usecase.dart';
// import 'package:flutter_app/feature/domain/entities/registation_response_entity.dart';
// import 'package:flutter_app/feature/domain/repositories/repository.dart';
//
// /// Usecase for handling login of user
// class RegistrtionResponseUseCase
//     extends UseCase<RegistrationResponseEntity, RegistationResponseParams> {
//   final Repository _repository;
//
//   RegistrtionResponseUseCase(this._repository);
//
//   @override
//   Future<Either<Failure, RegistrationResponseEntity>> call(
//       RegistationResponseParams params) async {
//     return await _repository.registration(
//         dateOfBirth: params.dateOfBirth,
//         emailId: params.emailId,
//         emiRatedSid: params.emiRatedSid,
//         languageId: params.languageId,
//         mobileApplicationId: params.mobileApplicationId,
//         mobileNumber: params.mobileNumber,
//         mobileOsType: params.mobileOsType,
//         name: params.name,
//         passPortNumber: params.passPortNumber);
//   }
// }
//
// class RegistationResponseParams extends Equatable {
//   final String name;
//   final String emiRatedSid;
//   final String passPortNumber;
//   final String mobileNumber;
//   final String emailId;
//   final int dateOfBirth;
//   final int languageId;
//   final int mobileApplicationId;
//   final int mobileOsType;
//
//   RegistationResponseParams(
//       {this.name,
//       this.emailId,
//       this.mobileNumber,
//       this.dateOfBirth,
//       this.emiRatedSid,
//       this.languageId,
//       this.mobileApplicationId,
//       this.mobileOsType,
//       this.passPortNumber});
//
//   @override
//   // TODO: implement props
//   List<Object> get props => [
//         name,
//         emiRatedSid,
//         passPortNumber,
//         mobileOsType,
//         dateOfBirth,
//         emailId,
//         languageId,
//         mobileApplicationId,
//       ];
// }
