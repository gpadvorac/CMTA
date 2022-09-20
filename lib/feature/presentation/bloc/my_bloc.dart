import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'my_event.dart';

part 'my_state.dart';

class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(Empty());

  @override
  Stream<MyState> mapEventToState(
    MyEvent event,
  ) async* {}
}
