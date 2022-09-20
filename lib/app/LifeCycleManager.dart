import 'package:cmta_field_report/database/databse_class.dart';
import 'package:flutter/material.dart';

class LifeCycleManager extends StatefulWidget {
  final Widget child;

  LifeCycleManager({Key? key, required this.child}) : super(key: key);

  _LifeCycleManagerState createState() => _LifeCycleManagerState();
}

class _LifeCycleManagerState extends State<LifeCycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print("State ::: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        // await DB.instance.database;
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        // await DB.instance.closeDB();
        break;
      case AppLifecycleState.inactive:
        // await DB.instance.closeDB();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
