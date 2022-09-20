// ignore_for_file: must_be_immutable

part of 'home_bloc.dart';

@immutable
abstract class HomeEvent extends Equatable {}

class GetProjectListEvent extends HomeEvent {
  @override
  List<Object> get props => [];
}

class GetAllProjectListEvent extends HomeEvent {
  @override
  List<Object> get props => [];
  BuildContext context;
  GetAllProjectListEvent({
    required this.context,
  });
}

class LogoutEvent extends HomeEvent {
  @override
  List<Object> get props => [];
}

class RefreshEvent extends HomeEvent {
  @override
  List<Object> get props => [];
}

class UpdateCount extends HomeEvent {
  final int? downloadedCount;

  UpdateCount({this.downloadedCount});

  @override
  List<Object> get props => [downloadedCount ?? 0];
}

class GetMyProfileDetails extends HomeEvent {
  @override
  List<Object> get props => [];
}

class DeleteProjectEvent extends HomeEvent {
  final String? projectId;

  DeleteProjectEvent({this.projectId});

  @override
  List<Object> get props => [projectId ?? ""];
}
