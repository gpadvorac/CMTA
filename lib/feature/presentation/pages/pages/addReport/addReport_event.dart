part of 'addReport_bloc.dart';

@immutable
abstract class AddReportEvent extends Equatable {}

class GetReportEvent extends AddReportEvent {
  final String? reportId;

  GetReportEvent({this.reportId});

  @override
  List<Object> get props => [reportId ?? ""];
}

class AddReport extends AddReportEvent {
  final String? rptId;
  final String? rptProjectId;
  final String? rptPunchListType;
  final String? rptPreparedBy;
  final String? rptVisitDate;
  final String? notes;

  AddReport(
      {this.rptPreparedBy,
      this.rptPunchListType,
      this.rptVisitDate,
      this.rptId,
      this.notes,
      this.rptProjectId});

  @override
  List<Object> get props => [
        rptProjectId ?? "",
        rptId ?? "",
        rptPunchListType ?? "",
        rptVisitDate ?? "",
        rptPreparedBy ?? "",
        notes ?? ""
      ];
}

class GetMyProfileDetails extends AddReportEvent {
  @override
  List<Object> get props => [];
}
