import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class DownloadScreen extends StatefulWidget {
  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  Image? _image;
  Text? _text;
  Text? _fontText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Download Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image ?? CircularProgressIndicator(),
            SizedBox(height: 20),
            _text ?? CircularProgressIndicator(),
            SizedBox(height: 20),
            _fontText ?? CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _download,
        tooltip: 'Download',
        child: Icon(Icons.download),
      ),
    );
  }

  Future<void> _download() async {
    // Firebase Storageから画像ファイルとテキストファイルのダウンロード
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference imageRef = storage.ref().child("DL").child("flutter.jpeg");
    String imageUrl = await imageRef.getDownloadURL();
    Reference textRef = storage.ref("DL/hello.txt");
    var textData = await textRef.getData();

    // フォントファイルのダウンロード
    Reference fontRef = storage.ref("fonts/self.ttf");
    String fontUrl = await fontRef.getDownloadURL();
    Uint8List fontData = (await fontRef.getData())!;

    // 画面に反映
    setState(() {
      _image = Image.network(imageUrl);
      _text = Text(utf8.decode(textData!));
      _fontText = Text(
        'this is custom font.',
        style: TextStyle(
          fontFamily: 'gage',
          fontSize: 20,
        ),
      );
    });

    // 画像ファイルはローカルにも保存
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File imageFile = File("${appDocDir.path}/download-image.png");
    try {
      await imageRef.writeToFile(imageFile);
    } catch (e) {
      print(e);
    }

    // フォントファイルはローカルに保存
    File fontFile = File("${appDocDir.path}/custom-font.ttf");
    await fontFile.writeAsBytes(fontData);
  }
}

Future<void> main() async {
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
  runApp(MaterialApp(
    title: 'Download Example',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: DownloadScreen(),
  ));
}
