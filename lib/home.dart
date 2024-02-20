// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'details.dart';
import 'vision_detector_views/digital_ink_recognizer_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  File? _imageFile;
  bool _isEmpty = true;
  bool _isProcessing = false;

  final List<String> _ocrResults = [];

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to Clipboard'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _recognizeHandwriting() async {
    if (_imageFile == null) {
      // Show an alert or message to prompt the user to select an image first
      return;
    }

    var url = Uri.parse(
        "https://pen-to-print-handwriting-ocr.p.rapidapi.com/recognize/");

    var request = http.MultipartRequest("POST", url)
      ..headers.addAll({
        "X-RapidAPI-Host": "pen-to-print-handwriting-ocr.p.rapidapi.com",
        "X-RapidAPI-Key": "77d35e8fafmsh1ae4de8c6747708p11938fjsncff81ba8d956",
      })
      ..files.add(await http.MultipartFile.fromPath("srcImg", _imageFile!.path))
      ..fields['Session'] = 'string';

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        String result = await response.stream.bytesToString();
        setState(() {
          _isProcessing = false;
        });
        _showResultSnackBar(result);
      } else {
        setState(() {
          _isProcessing = false; // Set to false on failure
        });
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isProcessing = false; // Set to false on error
      });
      print("Error: $e");
    }
  }

  bool isLoading = false;

  var renderOverlay = true;
  var visible = true;
  var switchLabelPosition = false;
  var extend = false;
  var mini = false;
  var rmicons = false;
  var customDialRoot = false;
  var closeManually = false;
  var useRAnimation = true;
  var isDialOpen = ValueNotifier<bool>(false);
  var speedDialDirection = SpeedDialDirection.up;
  var buttonSize = const Size(56.0, 56.0);
  var childrenButtonSize = const Size(56.0, 56.0);
  var selectedfABLocation = FloatingActionButtonLocation.endDocked;
  var items = [
    FloatingActionButtonLocation.startFloat,
    FloatingActionButtonLocation.startDocked,
    FloatingActionButtonLocation.centerFloat,
    FloatingActionButtonLocation.endFloat,
    FloatingActionButtonLocation.endDocked,
    FloatingActionButtonLocation.startTop,
    FloatingActionButtonLocation.centerTop,
    FloatingActionButtonLocation.endTop,
  ];

  @override
  void initState() {
    super.initState();
    _loadOcrResults(); // Load stored OCR results when the app starts
  }

  Future<void> _loadOcrResults() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ocrResults.clear(); // Clear existing results
      _ocrResults.addAll(prefs.getStringList('ocrResults') ?? []);
      _isEmpty = _ocrResults.isEmpty;
    });
  }

  Future<void> _saveOcrResults() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('ocrResults', _ocrResults);
  }

  void _showResultSnackBar(String result) {
    Map<String, dynamic> jsonResult = jsonDecode(result);

    // Extract the specific value from the JSON object
    String extractedValue = jsonResult['value'];
    _ocrResults.add(extractedValue);
    _saveOcrResults();
    setState(() {
      _isEmpty = false; // Update _isEmpty when a result is added
    });
    // Display the extracted value
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Handwriting Converted'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isEmpty = false; // Set to false when an image is selected
        _isProcessing = true; // Set to true when processing starts
      });
      _recognizeHandwriting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 13, 19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Center(
          child: Text(
            'ocrX',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: _isEmpty
          ? SingleChildScrollView(
              child: Center(
                child: _isProcessing
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: LoadingAnimationWidget.inkDrop(
                            color: const Color.fromARGB(255, 209, 213, 214),
                            size: 200,
                          ),
                        ),
                      )
                    : Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Lottie.asset(
                                  'assets/notfound.json'),
                            ),
                            const SizedBox(height: 5),
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Please select an image using the button below ',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                    ),
              ),
            )
          : ListView.builder(
              itemCount: _ocrResults.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    // Remove the item from the data source
                    setState(() {
                      _ocrResults.removeAt(index);
                    });

                    // Delete the item from local storage
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String> updatedResults =
                        List.from(prefs.getStringList('ocrResults') ?? []);
                    updatedResults.removeAt(index);
                    prefs.setStringList('ocrResults', updatedResults);
                    setState(() {
                      _isEmpty = true;
                    });
                    
                  },
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    color: Colors.red,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to DetailsPage when a list item is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsPage(ocrResult: _ocrResults[index]),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            _ocrResults[index],
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Column(
                            children: [
                              const SizedBox(
                                height: 5,
                              ),
                              GestureDetector(
                                onTap: () {
                                  _copyToClipboard(_ocrResults[index], context);
                                },
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          thickness: 1,
                          height: 5,
                          color: Color.fromARGB(255, 1, 13, 19),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: SpeedDial(
        activeBackgroundColor: Colors.transparent,
        activeForegroundColor: Colors.transparent,
        overlayColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        // animatedIcon: AnimatedIcons.menu_close,
        // animatedIconTheme: IconThemeData(size: 22.0),
        // / This is ignored if animatedIcon is non null
        // child: Text("open"),
        // activeChild: Text("close"),
        backgroundColor: const Color.fromRGBO(5, 89, 109, 1),
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 3,
        mini: mini,
        openCloseDial: isDialOpen,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        dialRoot: customDialRoot
            ? (ctx, open, toggleChildren) {
                return ElevatedButton(
                  onPressed: toggleChildren,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 18),
                  ),
                  child: const Text(
                    "Custom Dial Root",
                    style: TextStyle(fontSize: 17),
                  ),
                );
              }
            : null,
        buttonSize:
            buttonSize, // it's the SpeedDial size which defaults to 56 itself
        // iconTheme: IconThemeData(size: 22),
        label:
            extend ? const Text("Open") : null, // The label of the main button.
        /// The active label of the main button, Defaults to label if not specified.
        activeLabel: extend ? const Text("Close") : null,

        /// Transition Builder between label and activeLabel, defaults to FadeTransition.
        // labelTransitionBuilder: (widget, animation) => ScaleTransition(scale: animation,child: widget),
        /// The below button size defaults to 56 itself, its the SpeedDial childrens size
        childrenButtonSize: childrenButtonSize,
        visible: visible,
        direction: speedDialDirection,
        switchLabelPosition: switchLabelPosition,

        /// If true user is forced to close dial manually
        closeManually: closeManually,

        /// If false, backgroundOverlay will not be rendered.
        renderOverlay: renderOverlay,
        // overlayColor: Colors.black,
        // overlayOpacity: 0.5,
        onOpen: () => debugPrint('OPENING DIAL'),
        onClose: () => debugPrint('DIAL CLOSED'),
        useRotationAnimation: useRAnimation,
        tooltip: 'Open Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        // foregroundColor: Colors.black,
        // backgroundColor: Colors.white,
        // activeForegroundColor: Colors.red,
        // activeBackgroundColor: Colors.blue,
        elevation: 8.0,
        animationCurve: Curves.elasticInOut,
        isOpenOnStart: false,
        shape: customDialRoot
            ? const RoundedRectangleBorder()
            : const StadiumBorder(),
        // childMargin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        children: [
          SpeedDialChild(
            child: !rmicons ? const Icon(Icons.timelapse_outlined) : null,
            backgroundColor: const Color.fromRGBO(5, 89, 109, 1),
            foregroundColor: Colors.white,
            label: 'Digital Ink Recognition',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => const DigitalInkView())));
            },
          ),
          SpeedDialChild(
            child: !rmicons ? const Icon(Icons.image) : null,
            backgroundColor: const Color.fromRGBO(5, 89, 109, 1),
            foregroundColor: Colors.white,
            label: 'Handwriting to Text Recognition',
            onTap: _getImage,
          ),
          SpeedDialChild(
            child: !rmicons ? const Icon(Icons.camera) : null,
            backgroundColor: const Color.fromRGBO(5, 89, 109, 1),
            foregroundColor: Colors.white,
            label: 'Handwriting to Text Recognition',
            onTap: _getImage,
          ),
        ],
      ),
    );
  }
}
