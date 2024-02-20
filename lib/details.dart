// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class DetailsPage extends StatefulWidget {

  final String ocrResult;

  const DetailsPage({Key? key,  required this.ocrResult}) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.ocrResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 1, 13, 19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Details',style: TextStyle(color: Colors.white),),
       
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textEditingController,
              style: const TextStyle(fontSize: 18,color: Colors.white),
              maxLines: null, // Allow multiple lines for editing
            ),
          ],
        ),
      ),
    );
  }

 
}
