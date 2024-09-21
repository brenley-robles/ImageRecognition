import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter with Machine Learning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black54, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.blueAccent,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
      ),
      home: const MLDemo(title: "What's this badeng?"),
    );
  }
}

class MLDemo extends StatefulWidget {
  const MLDemo({super.key, required this.title});
  final String title;

  @override
  State<MLDemo> createState() => _MLDemo();
}

class _MLDemo extends State<MLDemo> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? file;
  var _recognitions;
  String displayResult = "";

  @override
  void initState() {
    super.initState();
    loadmodel().then((value) {
      setState(() {});
    });
  }

  loadmodel() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      setState(() {
        _image = image;
        file = File(image!.path);
      });
      detectimage(file!);
    } catch (e) {
      print('Error picking image');
    }
  }

  Future detectimage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _recognitions = recognitions;
      displayResult = _formatRecognition(_recognitions);
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  String _formatRecognition(var recognitions) {
    if (recognitions != null && recognitions.isNotEmpty) {
      return recognitions.map<String>((rec) {
        return "${rec['label']} - ${(rec['confidence'] * 100).toStringAsFixed(2)}%";
      }).join("\n");
    } else {
      return "No recognitions found.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(_image!.path),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Text(
                  'No image selected',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Image from Gallery'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take New Photo to Check'),
              ),
              const SizedBox(height: 30),
              Text(
                displayResult,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
