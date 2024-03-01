import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'main.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class TranslateWidget extends StatefulWidget {
  final String text;
  final bool changeFonts;

  TranslateWidget({required this.text, required this.changeFonts});

  @override
  _TranslateWidgetState createState() => _TranslateWidgetState();
}

class _TranslateWidgetState extends State<TranslateWidget> {
  late String translationText = widget.text;
  Text? _fontText;
  String fontFamily = 'self';

  @override
  Future<void> translation() async {
    await changeFont();
    // GoogleTranslatorインスタンス生成
    final translator = GoogleTranslator();
    // translateを使用して、
    // 第一引数に翻訳対象の文言、
    // 第二引数に言語コードを指定
    final translation = await translator.translate(widget.text, to: 'en');

    setState(() {
      translationText = translation.text;
    });
  }

  Future<void> changeFont() async {
    if (widget.changeFonts == true) {
      setState(() {
        fontFamily = 'Itsuki';
      });
    } else {
      setState(() {
        fontFamily = 'one';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              translationText,
              style: TextStyle(fontFamily: fontFamily, fontSize: 20.0),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          translation();
        },
        child: const Icon(Icons.g_translate),
      ));
}
