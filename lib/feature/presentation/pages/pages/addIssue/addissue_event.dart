part of 'addIssue_bloc.dart';

@immutable
abstract class AddIssueEvent extends Equatable {}

class AddIssue extends AddIssueEvent {
  final String? isuId;
  final String? isuReportId;
  final String? isuLocation;
  final String? isuDetails;
  final String? isuStatus;
  final String? issueImage;
  final bool? isUpdate;
  final String? orientation;
  final File? imageFile;
  final bool? hasImage;
  final bool? isImageDirty;

  AddIssue(
      {this.issueImage,
      this.isuDetails,
      this.isuId,
      this.isuLocation,
      this.isuReportId,
      this.isuStatus,
      this.isUpdate,
      this.orientation,
      this.imageFile,
      required this.hasImage,
      required this.isImageDirty});

  @override
  List<Object> get props => [
        issueImage ?? "",
        isuLocation ?? "",
        isuDetails ?? "",
        isuStatus ?? "",
        isuReportId ?? "",
        isuId ?? "",
        hasImage ?? false,
        isImageDirty ?? false
      ];
}

class GetIssue extends AddIssueEvent {
  final String? issueId;

  GetIssue({this.issueId});

  @override
  List<Object> get props => [issueId ?? ""];
}

class GetIssueFromDB extends AddIssueEvent {
  final String? issueId;

  GetIssueFromDB({this.issueId});

  @override
  List<Object> get props => [issueId ?? ""];
}

class LogoutEvent extends AddIssueEvent {
  @override
  List<Object> get props => [];
}

class GetMyProfileDetails extends AddIssueEvent {
  @override
  List<Object> get props => [];
}
