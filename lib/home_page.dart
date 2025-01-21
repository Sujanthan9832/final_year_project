import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stress_management_app/main.dart';
import 'package:tflite/tflite.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  int k = 0;

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
    startTimer();
  }

  startTimer() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      runModel();
    });
  }

  loadCamera() {
    cameraController = CameraController(cameras![1], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((ImageStream) {
            cameraImage = ImageStream;
          });
        });
      }
    });
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      if (predictions != null && predictions.isNotEmpty) {
        setState(() {
          output = predictions[0]['label'];
          if (output.toLowerCase() == '5 sad') {
            k++;
            if (k == 3) {
              showAlertDialog(context);
              k = 0;
            }
          } else {
            k = 0;
          }
        });
      }
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('you are so sad lets have a break.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Stress management app",
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0), // Set the desired text color
            ),
          ),
          backgroundColor: Color.fromARGB(255, 45, 212, 81)
          //backgroundColor: Color.fromARGB(255, 10, 177, 177),
          ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(
            output,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            '$k', // Use the variable inside the curly braces
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: runModel,
            child: Text("Run Model"),
          ),
        ],
      ),
    );
  }
}
