import 'dart:math';

import 'package:cmta_field_report/core/utils/guid.dart';
import 'package:cmta_field_report/core/utils/my_shared_pref.dart';
import 'package:cmta_field_report/core/utils/utils.dart';
import 'package:cmta_field_report/database/app_database.dart';
import 'package:cmta_field_report/database/databse_class.dart';
import 'package:cmta_field_report/feature/presentation/pages/pages/issue/issue_screen.dart';
import 'package:cmta_field_report/models/exception.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

import 'package:flutter_picker/flutter_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:image_picker/image_picker.dart' as imagePicker;
import 'package:cmta_field_report/core/utils/navigation.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../models/issue.dart';
import 'addIssue_bloc.dart';

import 'package:flutter/painting.dart';
import 'package:permission_handler/permission_handler.dart';

class AddIssuePage extends StatefulWidget {
  static const String routeName = '/addIssue_page';

  @override
  _AddIssuePageState createState() {
    return new _AddIssuePageState();
  }
}

class _AddIssuePageState extends State<AddIssuePage> {
  TextEditingController? _detailsTextController, _locationTextController;
  String? _details, _location, _image;
  String _status = "OPEN";
  File? _imageFile;
  var localImageToShow;

  bool isUpdate = false;
  Issue? issue;
  bool picUpdated = false;
  String? _orientatation;
  String issueId = Guid.newGuid.toString().toUpperCase();
  String imageToShow = "";
  bool showLoadder = false;
  bool isImageUpdated = false;
  var tempImage;
  bool? hasIssue = false;
  bool? _isImageDirty = false;

  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    issue = ModalRoute.of(context)!.settings.arguments as Issue;
    String issueId = issue?.issueId ?? "";
    _getImageFromLocal(issue!.issueId.toString());

    hasIssue = issue?.hasImage == null ? false : issue?.hasImage;
    _isImageDirty = issue?.isImageDirty == null ? false : issue?.isImageDirty;
    if (issueId.isNotEmpty) {
      // BlocProvider.of<AddIssueBloc>(context).add(GetIssue(issueId: issueId));
      BlocProvider.of<AddIssueBloc>(context)
          .add(GetIssueFromDB(issueId: issueId));

      setState(() {
        isUpdate = true;
      });
    } else {
      print("new issue adding");
    }
  }

  String? image;
  bool isVertical = false;
  bool isOneEighty = false;
  bool loading = true;
  bool isNinty = false;
  bool landscape = false;
  bool camera = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() => {imageCache.clear(), imageCache.clearLiveImages()});

    AppDatabase.instance.insertClientLogsToLocalDB("Add Issue screen opned.");
  }

  deleteimage() async {
    if (isImageUpdated == false) {
      return;
    }
    final path = await getApplicationDocumentsDirectory();

    String updatedImageName = '';
    if (isUpdate) {
      updatedImageName = '${path.path}/${issue!.issueId}-temp.jpg';
    } else {
      updatedImageName = '${path.path}/${issueId}-temp.jpg';
    }

    final dir = Directory(updatedImageName);
    var isValid = await File(updatedImageName).exists();
    if (isValid) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          leading: BackButton(
            color: Colors.white,
            onPressed: () async {
              await deleteimage();
              AppDatabase.instance
                  .insertClientLogsToLocalDB("Issue back button tapped.");
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Utils.appPrimaryColor,
          title: new Text("Add Issue"),
          actions: [
            new TextButton(
                onPressed: () async {
                  AppDatabase.instance
                      .insertClientLogsToLocalDB("Issue save button tapped.");
                  picUpdated ? print("pic updated") : print("pic not updated");
                  if (Platform.isAndroid || landscape || camera) {
                    if (_imageFile != null) {
                      List<int> imageBytes = _imageFile!.readAsBytesSync();

                      _image = base64.encode(imageBytes);
                    }
                  }

                  if (_status == null ||
                      _location == null ||
                      _details == null) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure  all  fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else if (_status.isEmpty ||
                      _location!.isEmpty ||
                      _details!.isEmpty) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure  all  fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else if (_status.trim() == "" ||
                      _location!.trim() == "" ||
                      _details!.trim() == "") {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Please make sure  all  fields are not empty."),
                            actions: <Widget>[
                              TextButton(
                                child: Text("DONE"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                  } else {
                    if (_imageFile != null) {
                      List<int> imageBytes = await _imageFile!.readAsBytes();
                      print("_isImageDirty : $_isImageDirty");
                      await generateImage(
                          imageBytes: imageBytes,
                          imageFile: _imageFile,
                          rotatedImage: File(_imageFile!.path),
                          isTemp: false,
                          isImageDirty: _isImageDirty ?? false);
                    }
                    await deleteimage();

                    if (isUpdate) {
                      BlocProvider.of<AddIssueBloc>(context).add(AddIssue(
                          isuStatus: _status,
                          isuReportId: issue?.issueReportId ?? "",
                          isuLocation: _locationTextController?.text ?? "",
                          isuDetails: _detailsTextController?.text ?? "",
                          issueImage: picUpdated ? _image : null,
                          isuId: issue?.issueId ?? "",
                          isUpdate: true,
                          hasImage: hasIssue,
                          imageFile: (Platform.isIOS) ? _imageFile : _imageFile,
                          orientation: (Platform.isIOS) ? _orientatation : null,
                          isImageDirty: _isImageDirty));
                    } else {
                      BlocProvider.of<AddIssueBloc>(context).add(
                        AddIssue(
                            isuStatus: _status,
                            isuReportId: issue?.issueReportId,
                            isuLocation: _location,
                            isuDetails: _details,
                            issueImage: _image,
                            isuId: issueId,
                            hasImage: hasIssue,
                            imageFile:
                                (Platform.isIOS) ? _imageFile : _imageFile,
                            orientation:
                                (Platform.isIOS) ? _orientatation : null,
                            isUpdate: false,
                            isImageDirty: _isImageDirty),
                      );
                    }
                  }
                },
                child: Icon(
                  Icons.check_circle_outlined,
                  color: Colors.white,
                )

                //new Text("SAVE", style: TextStyle(color: Colors.white)),
                )
          ]),
      body:
          BlocConsumer<AddIssueBloc, AddIssueState>(listener: (context, state) {
        if (state is CompletedIssueState) {
          Utils.showToast(state.strMessage ?? "", context);
          Navigation.back(context);
          Navigation.back(context);
        }

        if (state is ErrorState &&
            state.message != null &&
            !state.message!.isEmpty) {
          Utils.showErrorToast(state.message ?? "", context);
          Navigation.back(context);
        } else if (state is LoadingState) {
          Utils.showProgressDialog(context);
        } else if (state is LoadedState) {
          /// Dismissing the progress screen

          _detailsTextController =
              new TextEditingController(text: state.isuDetails);
          _location = state.isuLocation;
          _details = state.isuDetails;
          _locationTextController =
              new TextEditingController(text: state.isuLocation);
          _status = state.isuStatus ?? "";
          print(state.isuStatus);
          print(_status + "hdhhhhhhhhdchdbhdb");
          image = state.issueImage;
          Navigator.pop(context);
        } else if (state is AddIssueSucccessState) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigation.intentWithDatated(
              context, IssuesPage.routeName, issue?.issueReportId ?? "");
        }
      }, builder: (context, stateIssue) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              // shrinkWrap: true,
              // padding: EdgeInsets.all(8.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: TextField(
                    autocorrect: true,
                    controller: _locationTextController,
                    onChanged: (value) => _location = value,
                    decoration: InputDecoration(
                        hintStyle: TextStyle(
                          height:
                              1.4, // sets the distance between label and input
                        ),
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 18),
                        labelText: "Issue Location",
                        hintText: "Issue Location"),
                  ),
                ),
                new ListTile(
                  // leading: new Text(
                  //   "Issue Details   ",
                  //   textScaleFactor: 1.4,
                  // ),
                  title: new TextField(
                    autocorrect: true,
                    controller: _detailsTextController,
                    onChanged: (value) => _details = value,
                    decoration: InputDecoration(
                        hintStyle: TextStyle(
                          height:
                              1.4, // sets the distance between label and input
                        ),
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 18),
                        labelText: "Issue Details",
                        hintText: "Enter Issue Details"),
                  ),
                ),
                new ListTile(
                  title: new Text(
                    "Issue Status    ",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: new Text(
                      "$_status",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(new FocusNode());

                    await new Future.delayed(new Duration(milliseconds: 100),
                        () {
                      _showPunchTypePicker(context);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: Divider(
                    color: Colors.black,
                  ),
                ),
                new ListTile(
                  leading: new ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Utils.appPrimaryColor,
                    ),
                    // new Text(
                    //   "CHOOSE PHOTO",
                    //   style: TextStyle(color: Colors.white),
                    // ),
                    onPressed: () async {
                      Map<Permission, PermissionStatus> statuses = await [
                        Permission.storage,
                      ].request();
                      (Platform.isIOS)
                          ? getImageFromGalleryIos()
                          : getImageFromGallery();
                    },
                  ),
                  trailing: new ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    child: Icon(
                      Icons.camera,
                      color: Utils.appPrimaryColor,
                    ),
                    // new Text("TAKE PHOTO",
                    //     style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      Map<Permission, PermissionStatus> statuses = await [
                        Permission.camera,
                        Permission.storage
                      ].request();

                      getImageFromCamera();
                    },
                  ),
                ),
                _imageFile == null ? Container() : _getImage(),
                image == null
                    ? showLoadder == false
                        ? Container()
                        : CircularProgressIndicator()
                    : Container(
                        margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topLeft,
                          child: new Image.file(new File(imageToShow),
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                            return Image.asset(
                              'assets/cmta_logo_loading.png',
                              fit: BoxFit.contain,
                            );
                          }, fit: BoxFit.cover),
                        ), //new Image.network(image ?? ""),
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width + 20,
                      ),
              ],
            ),
          ),
        );
      }),
    );
  }

  _getImageFromLocal(String imageName) {
    getApplicationDocumentsDirectory().then((value) {
      setState(() {
        print(value.path);

        imageToShow = "${value.path}/${issue!.issueId.toString()}.jpg";
      });
    });
  }

  Widget _getImage() {
    if (localImageToShow != null) {
      return new Center(child: localImageToShow);
    }
    if (_image != "" && _imageFile == null) {
      Uint8List bytes1 = Base64Decoder().convert(_image ?? "");

      return Center(child: Image.memory(bytes1, fit: BoxFit.fill));
    } else if (_imageFile != null) {
      return Center(
        child: Image.file(
          tempImage,
          fit: BoxFit.cover,
        ),
      ); //Center(child: Image.file(_imageFile!, fit: BoxFit.fill));
    } else {
      return Center(child: Text("No Image Selected"));
    }
  }

  Future<File> fixExifRotation(String imagePath, File image) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    // We'll use the exif package to read exif data
    // This is map of several exif properties
    // Let's check 'Image Orientation'
    final exifData = await readExifFromBytes(imageBytes);

    img.Image fixedImage;

    // rotate
    if (exifData['Image Orientation']!.printable.contains('Horizontal')) {
      fixedImage = originalImage!;
      setState(() {
        landscape = true;
      });
    } else if (exifData['Image Orientation']!.printable.contains('180')) {
      fixedImage = img.copyRotate(originalImage!, 0);
      //this is -90 need to change degrees
      setState(() {
        isOneEighty = true;
        _orientatation = "isOneEighty";
      });
      //no coordination 180 degrees/upside down
      //0 display correct
    } else if (exifData['Image Orientation']!
        .printable
        .contains('Rotated 90 CW')) {
      //working
      fixedImage = img.copyRotate(originalImage!, 0);
      setState(() {
        isVertical = true;
        _orientatation = "isVertical";
      });
    } else {
      fixedImage = img.copyRotate(originalImage!, 0);
      setState(() {
        isNinty = true;
        _orientatation = "isNinty";
      });
    }
    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  Future<File> isvertical(String imagePath, File image) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);
    final fixedImage = img.copyRotate(originalImage!, 90);
    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
    return fixedFile;
  }

  Future<File> isNintyy(String imagePath, File image) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);
    final fixedImage = img.copyRotate(originalImage!, -90);
    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
    return fixedFile;
  }

  Future<File> isOneEightyy(String imagePath, File image) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);
    final fixedImage = img.copyRotate(originalImage!, 180);
    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));
    return fixedFile;
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  Future getImageFromGalleryIos() async {
    try {
      setState(() {
        showLoadder = true;
      });
      final imageFile = await imagePicker.ImagePicker()
          .pickImage(
        source: imagePicker.ImageSource.gallery,
      )
          .onError((error, stackTrace) {
        print("Error Selcting image :$error");
      });

      if (imageFile == null) {
        Utils.showToast("Something went wrong!", context);
        setState(() {
          showLoadder = false;
        });
        return;
      }

      List<int> imageBytes = await imageFile.readAsBytes();
      generateImage(
          imageBytes: imageBytes,
          imageFile: imageFile,
          rotatedImage: File(imageFile.path),
          isTemp: true,
          isImageDirty: true);
    } catch (e) {
      print("selecting image from Gallary error : $e");

      Utils.logException(
          className: "AddIssuePage",
          methodName: "getImageFromGalleryIos",
          exceptionInfor: e.toString(),
          information1: e.toString());
    }
  }

  double? getMaxHeight() {}

  Future getImageFromGallery() async {
    try {
      setState(() {
        showLoadder = true;
      });
      final path = await getApplicationDocumentsDirectory();

      var imageFile = await imagePicker.ImagePicker().pickImage(
        source: imagePicker.ImageSource.gallery,
        // maxHeight: 1500.0,
        // maxWidth: 3000.0,
      );
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        generateImage(
            imageBytes: imageBytes,
            imageFile: imageFile,
            rotatedImage: File(imageFile.path),
            isTemp: true,
            isImageDirty: true);
      } else {
        Utils.showToast("Something went wrong!", context);
      }
    } catch (e) {
      Utils.logException(
          className: "AddIssuePage",
          methodName: "getImageFromGallery",
          exceptionInfor: e.toString(),
          information1: e.toString());
    }
  }

  resizeMyImage(File resizeThisFile) async {
    print("im inside rsize");
    final originalFile = File(resizeThisFile.path);
    // Directory tempDir = await getTemporaryDirectory();
    // var tempPath = tempDir.path;

    // decodeImage will identify the format of the image and use the appropriate
    // decoder.
    File? myCompressedFile;
    final image1 = img.decodeImage(resizeThisFile.readAsBytesSync());
    print(image1?.height);
    print(image1?.width);
    var fixedFile;

    fixedFile = await originalFile.writeAsBytes(img.encodeJpg(image1!));

    setState(() {
      _imageFile = fixedFile;
    });

    // Save the thumbnail as a PNG.
    return myCompressedFile;
  }

  deleteTempImage() async {
    final path = await getApplicationDocumentsDirectory();
    String updatedImageName = '${path.path}/${issue!.issueId}-temp.jpg';

    final dir = Directory(updatedImageName);
    var isValid = await File(updatedImageName).exists();
    if (isValid) {
      dir.deleteSync(recursive: true);
    }
  }

  generateImage(
      {required List<int> imageBytes,
      imageFile,
      rotatedImage,
      required bool isTemp,
      required bool isImageDirty}) async {
    // isTemp = true ---> When you want to save image as temp, we user it for edit operation.
    // so that if user click on back button, then it will not replace new image with older image.
    // isTemp = false ---> that means it is a new entry of the iamge and issue.
    String rotational = _orientatation ?? "";

    isImageUpdated = true;

    img.Image? image1 = img.decodeImage(imageBytes);
    final height = image1!.height;
    final width = image1.width;
    print("original in ios gallery $height $width ");

    File fixedFile;

    fixedFile = await File(imageFile.path).writeAsBytes(img.encodeJpg(image1));
    print(fixedFile.path);

    final path = await getApplicationDocumentsDirectory();

    File newImage;
    String currentImageName = '';
    String updatedImageName = '';
    if (isTemp) {
      currentImageName = '${path.path}/$issueId-temp.jpg';
      updatedImageName = '${path.path}/${issue!.issueId}-temp.jpg';
    } else {
      currentImageName = '${path.path}/$issueId.jpg';
      updatedImageName = '${path.path}/${issue!.issueId}.jpg';
    }

    if (isUpdate == false) {
      newImage = await fixedFile.copy(currentImageName);
    } else {
      final dir = Directory(updatedImageName);
      var isValid = await File(updatedImageName).exists();
      if (isValid) {
        dir.deleteSync(recursive: true);
      }

      newImage = await fixedFile.copy(updatedImageName);
    }
    tempImage = File(imageFile.path);

    print("original finished ios gallery $height $width ");

    setState(() {
      showLoadder = false;
      imageCache.clear();
      imageCache.clearLiveImages();

      picUpdated = true;
      _image = "";
      image = null;
      hasIssue = true;
      _orientatation = rotational;
      _isImageDirty = isImageDirty;

      List<int> imageBytes = newImage.readAsBytesSync();

      _image = base64.encode(imageBytes);
      print("newImage path  is $newImage.path");
      _imageFile = newImage;
      imageCache.clear();
      imageCache.clearLiveImages();
    });
  }

  Future getImageFromCamera() async {
    try {
      var imageFile = await imagePicker.ImagePicker().pickImage(
        source: imagePicker.ImageSource.camera,
      );
      await ImageGallerySaver.saveImage(
          Uint8List.fromList(File(imageFile!.path).readAsBytesSync()));

      final file = File(imageFile.path);

      File rotatedImage =
          await FlutterExifRotation.rotateAndSaveImage(path: file.path);

      List<int> imageBytes = await file.readAsBytes();

      generateImage(
          imageBytes: imageBytes,
          imageFile: imageFile,
          rotatedImage: rotatedImage,
          isTemp: true,
          isImageDirty: true);
    } catch (e) {
      // final SharedPreferences _pref = await SharedPreferences.getInstance();

      Utils.logException(
          className: "AddIssuePage",
          methodName: "getImageFromCamera",
          exceptionInfor: e.toString(),
          information1: e.toString());

      print("Error while clicking image : $e");
    }
    // }
  }

  _showPunchTypePicker(BuildContext context) {
    List<String> punchTypes = ["OPEN", "CLOSED", "N/A"];

    new Picker(
        adapter: PickerDataAdapter<String>(pickerdata: punchTypes),
        hideHeader: true,
        textAlign: TextAlign.center,
        title: new Text("Select Punch List Type"),
        columnPadding: const EdgeInsets.all(8.0),
        onConfirm: (Picker picker, List value) {
          setState(() => _status = picker.getSelectedValues()[0]);
        }).showDialog(context);
  }
}
