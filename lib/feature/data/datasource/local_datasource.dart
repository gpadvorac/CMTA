import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:flutter/cupertino.dart';

abstract class LocalDataSource {}

class LocalDataSourceImpl extends LocalDataSource {
  final MySharedPref? mySharedPref;

  LocalDataSourceImpl({@required this.mySharedPref});
}
