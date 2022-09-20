import 'package:bloc/bloc.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';

import 'package:flutter/cupertino.dart';

import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final MySharedPref sharedPref;

  // AuthenticationBloc({@required MySharedPref? sharedPref})
  //     : assert(sharedPref != null),
  //       sharedPref = sharedPref!,
  //       super(Uninitialized());
  AuthenticationBloc({required this.sharedPref}) : super(Uninitialized()) {
    on<AuthenticationEvent>(mapEventToState);
  }
  mapEventToState(AuthenticationEvent event, emit) async {
    // app start
    if (event is AppStarted) {
      await _saveBaseUrl(event.url ?? "");

      if (event.url != '') {
        // Storage().token = token;
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    }

    if (event is LoggedIn) {
      // Storage().token = event.token;

      await _saveUserName(event.userName ?? "");
      emit(Authenticated());
    }

    if (event is LoggedOut) {
      // Storage().token = '';
      await _deleteToken();
      emit(Unauthenticated());
    }
  }

  /// delete from keystore/keychain
  Future<void> _deleteToken() async {
    // await Storage().secureStorage.delete(key: 'access_token');
  }

  /// write to keystore/keychain
  Future<void> _saveBaseUrl(String baseUrl) async {
    // await Storage().secureStorage.write(key: 'access_token', value: token);
    sharedPref.saveBaseUrl(baseUrl);
  }

  /// read to keystore/keychain
  Future<String> _getBaseUrl() async {
    return sharedPref.getBaseUrl();
    // return await Storage().secureStorage.read(key: 'access_token') ?? '';
  }

  /// write to keystore/keychain
  Future<void> _saveUserName(String userName) async {
    // await Storage().secureStorage.write(key: 'access_token', value: token);
    sharedPref.saveUserName(userName);
  }

  /// read to keystore/keychain
  Future<String> getUserName() async {
    return sharedPref.getUserName();
    // return await Storage().secureStorage.read(key: 'access_token') ?? '';
  }
}
