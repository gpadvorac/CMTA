import 'package:equatable/equatable.dart';

class RegistrationResponseEntity extends Equatable {
  final String? active;
  final String? assetgeofenceradius;
  final String? assetid;
  final List? healthsymptom;
  final String? mobilenumber;
  final int? dateofbirth;
  final String? useruid;
  final int? communicationlanguageid;
  final int? mobileostype;

  RegistrationResponseEntity(
      {this.useruid,
      this.healthsymptom,
      this.communicationlanguageid,
      this.assetid,
      this.assetgeofenceradius,
      this.active,
      this.dateofbirth,
      this.mobilenumber,
      this.mobileostype});

  @override
  List<Object> get props => [
        active ?? "",
        assetgeofenceradius ?? "",
        assetid ?? "",
        healthsymptom ?? "",
        mobileostype ?? "",
        dateofbirth ?? "",
        useruid ?? "",
        communicationlanguageid ?? "",
        mobileostype ?? ""
      ];
}
