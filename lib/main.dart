import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'result_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

bool changeFonts = false;
int count = 0;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: 'AIzaSyAK3NtH1MqAmWKMXc79U-sVjM-0x3JeCjg',
              appId: '1:248315500994:android:ef7c58339d4719895ade5b',
              messagingSenderId: '248315500994',
              projectId: 'tobahack-de5bb',
              storageBucket: 'tobahack-de5bb.appspot.com'))
      : await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Text Recognition Flutter',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _cameraController;

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  @override
  void _pickImageFromGallery() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final File file = File(result.files.single.path!);
      _processImage(file);
    }
  }

  // 画像処理とテキスト認識
  void _processImage(File file) async {
    final navigator = Navigator.of(context);
    try {
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);
      String cleanedText = recognizedText.text.replaceAll(RegExp(r'\n'), '');
      await navigator.push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              TranslateWidget(text: cleanedText, changeFonts: changeFonts),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

  @override
  // アップロード処理
  void _upload() async {
    changeFonts = !changeFonts;
    // imagePickerで画像を選択する
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    File file = File(result.files.single.path!);
    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      await storage.ref("fonts/self.ttf").putFile(file);
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            if (_isPermissionGranted)
              FutureBuilder<List<CameraDescription>>(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _initCameraController(snapshot.data!);

                    return Center(child: CameraPreview(_cameraController!));
                  } else {
                    return const LinearProgressIndicator();
                  }
                },
              ),
            Scaffold(
              appBar: AppBar(
                title: Text(
                  'EIRAKU',
                  style: GoogleFonts.grandstander(
                    textStyle: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                leading: IconButton(
                  onPressed: () {
                    _pickImageFromGallery();
                  },
                  icon: Icon(
                    Icons.image,
                    color: Colors.white,
                  ),
                ),

                centerTitle: true, // タイトルを中央に配置する
                actions: <Widget>[
                  // 右側のアイコン一覧
                  IconButton(
                    onPressed: () {
                      _upload();
                    },
                    icon: Icon(
                      Icons.folder_open,
                      color: Colors.white,
                    ),
                  ),
                ],
                backgroundColor: Color.fromARGB(255, 35, 35, 35),
              ),
              backgroundColor: _isPermissionGranted
                  ? Color.fromARGB(0, 255, 255, 255)
                  : null,
              body: _isPermissionGranted
                  ? Column(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        Row(
                          children: <Widget>[],
                        ),
                        Container(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white70,
                              fixedSize: const Size(64, 64),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 4.0,
                              ),
                              shape: const CircleBorder(),
                            ),
                            onPressed: _scanImage,
                            child: const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 70),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                        child: const Text(
                          'Camera permission denied',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
  }

  void _startCamera() {
    if (_cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController?.dispose();
    }
  }

  void _initCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null) {
      return;
    }

    // 最初のリアカメラを選択します
    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      _cameraSelected(camera);
    }
  }

  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _scanImage() async {
    if (_cameraController == null) return;

    final navigator = Navigator.of(context);

    try {
      final pictureFile = await _cameraController!.takePicture();

      final file = File(pictureFile.path);

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);
      // 撮影後、画面遷移して次のページへ値を渡す
      String cleanedText = recognizedText.text.replaceAll(RegExp(r'\n'), '');

      await navigator.push(
        MaterialPageRoute(
          builder: (BuildContext context) => TranslateWidget(
              text: cleanedText, changeFonts: changeFonts), // changeFontsを渡す
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }
}
