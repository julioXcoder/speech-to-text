import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Press the button and start speaking";
  List<Map<String, dynamic>> _speeches = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadSpeeches();
  }

  void _loadSpeeches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? speechesString = prefs.getString('speeches');
    if (speechesString != null) {
      setState(() {
        _speeches =
            List<Map<String, dynamic>>.from(json.decode(speechesString));
      });
    }
  }

  void _saveSpeeches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('speeches', json.encode(_speeches));
  }

  void _deleteSpeech(int index) {
    setState(() {
      _speeches.removeAt(index);
    });
    _saveSpeeches();
  }

  Widget _buildLogo() {
    File file = File('assets/images/logo.png');
    if (file.existsSync()) {
      return Image.asset(
        'assets/images/logo.png',
        height: 40.0,
      );
    } else {
      return SizedBox(); // Returns an empty SizedBox if image doesn't exist
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/EchoScript_transparent.png',
              height: 60.0,
            ),
            SizedBox(width: 10.0),
            Text('EchoScript'),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  _text,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              SizedBox(height: 20.0),
              ..._speeches.map((s) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ListTile(
                      title: Text(
                        s['text'],
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text(
                        _formatDateTime(DateTime.parse(s['time'])),
                        style: TextStyle(fontSize: 14.0, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteSpeech(_speeches.indexOf(s)),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 36.0),
      ),
    );
  }

  void _listen() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() => _isListening = val == 'listening'),
        onError: (val) => setState(() {
          _isListening = false;
        }),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.finalResult) {
              _speeches.insert(0, {
                'text': val.recognizedWords,
                'time': DateTime.now().toIso8601String()
              });
              _text = "Press the button and start speaking";
              _saveSpeeches();
            }
          }),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }
}
