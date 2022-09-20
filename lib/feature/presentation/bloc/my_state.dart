part of 'my_bloc.dart';

@immutable
abstract class MyState extends Equatable {
  @override
  List<Object> get props => [];
}

/// Initial State
class Empty extends MyState {}

/// Loading State, to show Loader
class Loading extends MyState {}

/// Called when user data is loaded
class Loaded extends MyState {
  Loaded();
}

/// Called when there is Error
class Error extends MyState {
  final String? message;

  Error({this.message});
}
