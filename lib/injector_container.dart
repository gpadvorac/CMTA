// import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart';
import 'core/utils/my_shared_pref.dart';
import 'feature/data/client/client.dart';
import 'feature/data/datasource/local_datasource.dart';
import 'feature/data/datasource/remote_datasource.dart';
import 'feature/data/repositories/repository_impl.dart';
import 'feature/domain/repositories/repository.dart';
import 'feature/domain/usecase/login_usecase.dart';
import 'feature/presentation/bloc/authentication/authentication_bloc.dart';
import 'feature/presentation/bloc/my_bloc.dart';
import 'feature/presentation/pages/pages/addIssue/addIssue_bloc.dart';
import 'feature/presentation/pages/pages/addProject/addProject_bloc.dart';
import 'feature/presentation/pages/pages/addReport/addReport_bloc.dart';
import 'feature/presentation/pages/pages/home/home_bloc.dart';
import 'feature/presentation/pages/pages/issue/issue_bloc.dart';
import 'feature/presentation/pages/pages/login/login_bloc.dart';
import 'feature/presentation/pages/pages/report/report_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => MyBloc());

  sl.registerFactory(() => AuthenticationBloc(sharedPref: sl()));

  sl.registerFactory(() =>
      LoginBloc(AuthenticationBloc(sharedPref: sl()), LoginUseCase(sl())));

  sl.registerFactory(() => HomeBloc(sl()));
//  HomeBloc(
//         authenticationBloc: sl(),
//       )
  sl.registerFactory(() => ReportBloc(
        authenticationBloc: sl(),
      ));

  sl.registerFactory(() => IssueBloc(
        authenticationBloc: sl(),
      ));

  sl.registerFactory(() => AddReportBloc(
        authenticationBloc: sl(),
      ));
  sl.registerFactory(() => AddIssueBloc(
        authenticationBloc: sl(),
      ));

  sl.registerFactory(() => AddProjectBloc(
        authenticationBloc: sl(),
      ));

  // UseCase
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // repository
  sl.registerLazySingleton<Repository>(() => RepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSourceImpl(
        client: sl(),
      ));
  // No access to DB provider, job of LocalDataSource to choose which source
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(
        mySharedPref: sl(),
      ));

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<MySharedPref>(() => MySharedPref(sl()));

  // initializing dio
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton(() => RestClient(dio, sl()));
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
