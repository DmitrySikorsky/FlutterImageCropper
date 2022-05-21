// Copyright © 2022 Dmitry Sikorsky. All rights reserved.
// Licensed under the Apache License, Version 2.0. See License.txt in the project root for license information.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_cropper/cropping.dart';
import 'package:flutter_image_cropper/defaults.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Image Cropper',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isImageSelected = false;
  String? _imageFilepath;
  Uint8List? _imageData;
  final GlobalKey _key = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  Size? _imageSize;
  Cropping? _cropping;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      Size sourceSize = _imageSize!;
      RenderBox renderBox = _key.currentContext?.findRenderObject() as RenderBox;
      Size cropperSize = renderBox.size;
      double cropperScale = _transformationController.value.entry(0, 0);
      double cropperX = _transformationController.value.entry(0, 3) * -1.0;
      double cropperY = _transformationController.value.entry(1, 3) * -1.0;

      setState(() {
        _cropping = Cropping(
          source: Rect.fromLTWH(
            cropperX / cropperSize.width / cropperScale * sourceSize.width,
            cropperY / cropperSize.width / cropperScale * sourceSize.width,
            sourceSize.shortestSide / cropperScale,
            sourceSize.shortestSide / cropperScale,
          ),
          destination: const Size(
            1920,
            1920,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: _isImageSelected
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _createImageCropper(),
                  const SizedBox(height: Defaults.spacing),
                  _createCropping(),
                  const SizedBox(height: Defaults.spacing),
                  _createDoneResetButtons(),
                ],
              )
            : _createSelectImageButton(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _transformationController.dispose();
  }

  Widget _createSelectImageButton() {
    return IconButton(
      onPressed: _onSelectImageButtonPressed,
      icon: const Icon(Icons.image_search),
    );
  }

  Widget _createImageCropper() {
    ImageProvider provider;

    if (_imageFilepath != null) {
      provider = FileImage(File(_imageFilepath!));
    } else {
      provider = MemoryImage(_imageData!);
    }

    Completer<ui.Image> completer = Completer<ui.Image>();

    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
          completer.complete(info.image);
        },
      ),
    );

    double size = MediaQuery.of(context).size.shortestSide * 0.75;

    return FutureBuilder<ui.Image>(
      future: completer.future,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const CircularProgressIndicator();
        }

        return SizedBox.square(
          dimension: size,
          child: ClipRRect(
            borderRadius: BorderRadius.all(
              Radius.circular(size / 2.0),
            ),
            child: InteractiveViewer(
              key: _key,
              constrained: false,
              minScale: 0.1,
              maxScale: 10.0,
              transformationController: _transformationController,
              child: Image(
                image: provider,
                width: snapshot.data!.width < snapshot.data!.height ? size : null,
                height: snapshot.data!.width >= snapshot.data!.height ? size : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createCropping() {
    if (_cropping == null) {
      return Container();
    }

    return Text('X: ${_cropping!.source!.left.toInt()}, '
        'Y: ${_cropping!.source!.top.toInt()}, '
        'width: ${_cropping!.source!.width.toInt()}, '
        'height: ${_cropping!.source!.height.toInt()}');
  }

  Widget _createDoneResetButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _createDoneButton(),
        const SizedBox(width: Defaults.spacing),
        _createResetButton(),
      ],
    );
  }

  Widget _createDoneButton() {
    return IconButton(
      onPressed: _onDoneButtonPressed,
      icon: const Icon(
        Icons.done,
        color: Defaults.positive,
      ),
    );
  }

  Widget _createResetButton() {
    return IconButton(
      onPressed: _onResetButtonPressed,
      icon: const Icon(
        Icons.clear,
        color: Defaults.negative,
      ),
    );
  }

  // TODO: Please consider this method as a sample ONLY!
  Future<bool> upload(String formField) async {
    /*
    http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('https://host/upload${_getUrlParamsFromCropping()}'),
    );

    request.files.add(_imageFilepath != null
        ? await http.MultipartFile.fromPath(
            formField,
            _imageFilepath!,
          )
        : http.MultipartFile.fromBytes(
            formField,
            _imageData!,
            filename: 'image.tmp',
          ));

    return (await request.send()).statusCode == 200;
    */
    return true;
  }

  // TODO: Please consider this method as a sample ONLY!
  String _getUrlParamsFromCropping() {
    if (_cropping != null) {
      return '?cropping.source.x=${_cropping!.source!.left.toInt()}'
          '&cropping.source.y=${_cropping!.source!.top.toInt()}'
          '&cropping.source.width=${_cropping!.source!.width.toInt()}'
          '&cropping.source.height=${_cropping!.source!.height.toInt()}'
          '&cropping.destination.width=${_cropping!.destination!.width.toInt()}'
          '&cropping.destination.height=${_cropping!.destination!.height.toInt()}';
    }

    return '';
  }

  void _onSelectImageButtonPressed() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Image selection',
      type: FileType.image,
      lockParentWindow: true,
    );

    if (result != null) {
      if (kIsWeb) {
        _imageData = result.files.first.bytes!;
      } else {
        _imageFilepath = result.files.first.path!;
      }

      setState(() {
        _isImageSelected = true;
      });
    }
  }

  void _onDoneButtonPressed() async {
    if (await upload('uploadedImage')) {
      setState(() {
        _isImageSelected = false;
      });
    }
  }

  void _onResetButtonPressed() {
    setState(() {
      _isImageSelected = false;
    });
  }
}
