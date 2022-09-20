import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/feature/data/model/login_response_model.dart';
import 'package:dio/dio.dart';

import 'package:retrofit/http.dart';

part 'client.g.dart';

@RestApi(baseUrl: "https://createllc.dev/")
abstract class RestClient {
  /// flutter pub run build_runner build --delete-conflicting-outputs

  factory RestClient(final Dio dio, final MySharedPref sharedPref) {
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions option, header) {
      /// Additional headers information
      option.headers[Utils.AUTHORIZATION] = Utils.AUTHORIZATION_TOKEN;
      option.headers[Utils.X_MESSAGE_ID] = Utils.X_MESSAGE_ID_TOKEN;
      option.headers[Utils.CONTENT_TYPE] = Utils.CONTENT_APPLICATION_JSON;
      /*if (sharedPref.getAuthToken() != null &&
          sharedPref.getAuthToken().isNotEmpty) {
        option.headers[Constants.AUTHORIZATION] =
        "Bearer " + sharedPref.getAuthToken();

      }
  */
      // return option;
    }));
    return _RestClient(dio);
  }

  @POST("/login")
  Future<LoginRequestData> login(
    @Field("emailid") String emailId,
    @Field("password") String password,
  );
}
