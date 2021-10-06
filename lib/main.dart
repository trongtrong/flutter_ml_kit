import 'dart:io';

import 'package:firebase_ml_custom/firebase_ml_custom.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List<Map<dynamic, dynamic>> _labels;

  Future<String> _loaded = loadModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _loaded,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return readyScreen();
          } else if (snapshot.hasError) {
            return errorScreen();
          } else {
            return loadingScreen();
          }
        },
      ),
    );
  }

  /// Gets the model ready for inference on images.
  static Future<String> loadModel() async {
    final modelFile = await loadModelFromFirebase();
    return loadTFLiteModel(modelFile);
  }

  /// Downloads custom model from the Firebase console and return its file.
  /// located on the mobile device.
  static Future<File> loadModelFromFirebase() async {
    try {
      // Create model with a name that is specified in the Firebase console
      final model = FirebaseCustomRemoteModel('model');

      // Specify conditions when the model can be downloaded.
      // If there is no wifi access when the app is started,
      // this app will continue loading until the conditions are satisfied.
      final conditions = FirebaseModelDownloadConditions(
          androidRequireWifi: true, iosAllowCellularAccess: false);

      // Create model manager associated with default Firebase App instance.
      final modelManager = FirebaseModelManager.instance;

      // Begin downloading and wait until the model is downloaded successfully.
      await modelManager.download(model, conditions);
      assert(await modelManager.isModelDownloaded(model) == true);

      // Get latest model file to use it for inference by the interpreter.
      var modelFile = await modelManager.getLatestModelFile(model);
      assert(modelFile != null);
      return modelFile;
    } catch (exception) {
      print('Failed on loading your model from Firebase: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }


  /// Loads the model into some TF Lite interpreter.
  /// In this case interpreter provided by tflite plugin.
  static Future<String> loadTFLiteModel(File modelFile) async {
    try {
      // TODO TFLite plugin is broken, see https://github.com/shaqian/flutter_tflite/issues/139#issuecomment-836596852
      // final appDirectory = await getApplicationDocumentsDirectory();
      // final labelsData =
      //     await rootBundle.load('assets/labels_mobilenet_v1_224.txt');
      // final labelsFile =
      //     await File('${appDirectory.path}/_labels_mobilenet_v1_224.txt')
      //         .writeAsBytes(labelsData.buffer.asUint8List(
      //             labelsData.offsetInBytes, labelsData.lengthInBytes));
      // assert(await Tflite.loadModel(
      //       model: modelFile.path,
      //       labels: labelsFile.path,
      //       isAsset: false,
      //     ) ==
      //     'success');
      return 'Model is loaded';
    } catch (exception) {
      print(
          'Failed on loading your model to the TFLite interpreter: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  /// Shows image selection screen only when the model is ready to be used.
  Widget readyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase ML Custom example app'),
      ),
      body: Column(
        children: [
          if (_image != null)
            Image.file(_image)
          else
            const Text('Please select image to analyze.'),
          Column(
            children: _labels != null
                ? _labels.map((label) {
              return Text("${label["label"]}");
            }).toList()
                : [],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImageLabels,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Triggers selection of an image and the consequent inference.
  Future<void> getImageLabels() async {
    try {
      final pickedFile =
      await ImagePicker().getImage(source: ImageSource.gallery);
      final image = File(pickedFile.path);
      if (image == null) {
        return;
      }
      // TODO TFLite plugin is broken, see https://github.com/shaqian/flutter_tflite/issues/139#issuecomment-836596852
      // var labels = List<Map>.from(await Tflite.runModelOnImage(
      //   path: image.path,
      //   imageStd: 127.5,
      // ));
      var labels = List<Map>.from([]);
      setState(() {
        _labels = labels;
        _image = image;
      });
    } catch (exception) {
      print("Failed on getting your image and it's labels: $exception");
      print('Continuing with the program...');
      rethrow;
    }
  }

  /// In case of error shows unrecoverable error screen.
  Widget errorScreen() {
    return const Scaffold(
      body: Center(
        child: Text('Error loading model. Please check the logs.'),
      ),
    );
  }

  /// In case of long loading shows loading screen until model is ready or
  /// error is received.
  Widget loadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CircularProgressIndicator(),
            ),
            Text('Please make sure that you are using wifi.'),
          ],
        ),
      ),
    );
  }

}
