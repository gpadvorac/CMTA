part of 'addProject_bloc.dart';

@immutable
abstract class AddProjectEvent extends Equatable {}

class AddEvent extends AddProjectEvent {
  String? projectNumber;
  String? projectName;
  String? projectId;
  String? projectCurId;

  String? projectLocation;

  AddEvent(
      {this.projectLocation,
      this.projectName,
      this.projectNumber,
      this.projectId,
      this.projectCurId});

  @override
  List<Object> get props => [
        projectLocation ?? "",
        projectName ?? "",
        projectNumber ?? "",
        projectId ?? "",
        projectCurId ?? ""
      ];
}

class GetProjectEvent extends AddProjectEvent {
  final String? projectId;

  GetProjectEvent({this.projectId});

  @override
  List<Object> get props => [projectId ?? ""];
}

class LogoutEvent extends AddProjectEvent {
  @override
  List<Object> get props => [];
}

class GetMyProfileDetails extends AddProjectEvent {
  @override
  List<Object> get props => [];
}
