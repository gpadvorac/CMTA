import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySharedPref {
  static const LAST_LOADED_DATE = "last_loaded_date";
  static const TOKEN = "token";
  static const USER_NAME = "user_name";
  static const USER_ID = "user_id";
  static const PROJECT_FLAVOUR = "project_flavour";

  static const USER_STATUS = "status";
  static const USER_PROFILE_ID = "profileId";
  static const NAME = "fullName";
  static const VERSION = "version";
  static const EMAIL_ID = "email";
  static const AUTH_TOKEN = "auth_token";
  static const EXPIRATIONDATE = "expirationDate";

  static const PROFILE_PICTURE = "image";
  static const USER_TYPE = "userType";
  static const USER_LOGGEDIN = "";
  static const BASE_URL = "baseUrl";
  static const DATA_SYNC = "dataSync";
  static const isUserLoggedIn = "USER_LOGGEDIN";
  static const imageUrlList = "IMAGE_LIST";

  final SharedPreferences? _pref;

  MySharedPref(this._pref);

  void saveLastLoadedState(String dateTime) {
    _pref?.setString(LAST_LOADED_DATE, dateTime);
  }

  String getLastLoadedState() {
    return _pref?.getString(LAST_LOADED_DATE) ?? "";
  }

  void saveBaseUrl(String token) {
    _pref?.setString(BASE_URL, token);
  }

  String getBaseUrl() {
    return _pref?.getString(BASE_URL) ?? "";
  }

  // String getEncodedAuthToken(){
  //   var token = getToken();
  //   var str = "mcacare-sgw:$token";
  //   var bytes = utf8.encode(str);
  //   var base64Str = base64.encode(bytes);
  //
  //   print(" Token $token Base64 $base64Str");
  //   return "Basic $base64Str";
  // }

  void userLoggedIn(bool val) {
    _pref?.setBool(USER_LOGGEDIN, val);
  }

  bool checkUserLoggedin() {
    return _pref?.getBool("USER_LOGGEDIN") ?? false;
  }

  void saveUserName(String userName) {
    _pref?.setString(USER_NAME, userName);
  }

  void saveUserId(String userId) {
    _pref?.setString(USER_ID, userId);
  }

  String getUserId() {
    return _pref?.getString(USER_ID) ?? "";
  }

  String getUserName() {
    return _pref?.getString(USER_NAME) ?? "";
  }

  void savePassword(String name) {
    _pref?.setString(NAME, name);
  }

  void saveIsDataDownloadedAfterLogin(bool isDataSync) {
    _pref?.setBool(DATA_SYNC, isDataSync);
  }

  bool? isDataDownloadedFromAPI() {
    return _pref?.getBool(DATA_SYNC);
  }

  String getPassword() {
    return _pref?.getString(NAME) ?? "";
  }

  void saveAppVersion(String version) {
    _pref!.setString(VERSION, version);
  }

  String getAppVersion() {
    return _pref?.getString(VERSION) ?? "";
  }

  void saveEmailName(String email) {
    _pref?.setString(EMAIL_ID, email);
  }

  String getEmailName() {
    return _pref?.getString(EMAIL_ID) ?? "";
  }

  Future<String> getExpirationDate() async {
    final storage = new FlutterSecureStorage();

    return await storage.read(key: EXPIRATIONDATE) ?? "";
  }

  Future<void> saveAuthToken(String email) async {
    final storage = new FlutterSecureStorage();
    await storage.write(key: AUTH_TOKEN, value: email);
  }

  Future<void> saveTokenExpirationDate(String strDate) async {
    final storage = new FlutterSecureStorage();
    await storage.write(key: EXPIRATIONDATE, value: strDate);
  }

  Future<String?> getAuthToken() async {
    final storage = new FlutterSecureStorage();

    return await storage.read(key: AUTH_TOKEN) ?? "";
  }

  void saveUserType(String userType) {
    _pref?.setString(USER_TYPE, userType);
  }

  String getUserType() {
    return _pref?.getString(USER_TYPE) ?? "";
  }

  void saveUserStatus(String userstatus) {
    _pref?.setString(USER_STATUS, userstatus);
  }

  void logout() {
    _pref!.clear();
  }
}
