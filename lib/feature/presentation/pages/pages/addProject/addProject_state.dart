part of 'addProject_bloc.dart';

@immutable
abstract class AddProjectState {}

class AddProjectInitial extends AddProjectState {}

class ProjectLoadingState extends AddProjectState {
  ProjectLoadingState();
}

class ProjectErrorState extends AddProjectState {
  final String? message;

  ProjectErrorState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class ProjectCreatedState extends AddProjectState {
  final String? message;

  ProjectCreatedState({this.message});

  @override
  List<Object> get props => [message ?? ""];
}

class ProjectLoadedState extends AddProjectState {
  String? pjId;
  String? pjCustomerId;
  String? pjNumber;

  String? pjName;
  String? pjLocation;

  ProjectLoadedState(
      {this.pjCustomerId,
      this.pjId,
      this.pjLocation,
      this.pjName,
      this.pjNumber});
}

class ProjectCompletedState extends AddProjectState {
  bool? isSuccess;
  bool? isError;
  String? strMessage;

  ProjectCompletedState({
    this.isSuccess,
    this.isError,
    this.strMessage,
  });
}
