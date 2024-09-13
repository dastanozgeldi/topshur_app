import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart'; // Ensure this is imported

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioRecorderPage(),
    );
  }
}

class AudioRecorderPage extends StatefulWidget {
  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  final record = Record();
  final audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _showMessage = false;
  String _recordingPath = '';
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  final List<String> _recordings = []; // List to store recording paths

  @override
  void dispose() {
    record.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await record.hasPermission()) {
        // Generate a new recording path
        final tempDir = await getTemporaryDirectory();
        String fileName = '${Uuid().v4()}.m4a'; // Unique file name
        _recordingPath = '${tempDir.path}/$fileName';

        _recordingStartTime = DateTime.now(); // Record the start time
        await record.start(
          path: _recordingPath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        setState(() {
          _isRecording = true;
          _showMessage = false; // Hide the message when recording starts
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await record.stop();
      if (_recordingStartTime != null) {
        final recordingEndTime = DateTime.now();
        _recordingDuration = recordingEndTime.difference(_recordingStartTime!);
      }
      // Add the recording path to the list
      _recordings.add(_recordingPath);
      setState(() {
        _isRecording = false;
        _showMessage = true; // Show the message after recording stops
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (File(_recordingPath).existsSync()) {
      try {
        if (_isPlaying) {
          await audioPlayer.stop();
          setState(() {
            _isPlaying = false;
          });
        } else {
          // Reset the player position to the beginning
          await audioPlayer.seek(Duration.zero);
          await audioPlayer.play(DeviceFileSource(_recordingPath));
          setState(() {
            _isPlaying = true;
          });
          audioPlayer.onPlayerComplete.listen((event) {
            setState(() {
              _isPlaying = false;
            });
          });
        }
      } catch (e) {
        print('Error playing recording: $e');
      }
    } else {
      print('Recording file not found: $_recordingPath');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : Colors.blue,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: File(_recordingPath).existsSync()
                        ? _playRecording
                        : null,
                    child: Text(_isPlaying ? 'Stop' : 'Play'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recording Duration: ${_formatDuration(_recordingDuration)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  if (_showMessage)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'как пройти до корпуса?',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Divider(),
          // List of recordings in descending order
          Expanded(
            child: ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                // Reverse the index to display the latest recordings first
                final reverseIndex = _recordings.length - 1 - index;
                final path = _recordings[reverseIndex];
                return ListTile(
                  title: Text('Recording ${reverseIndex + 1}'),
                  // subtitle: Text(path),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () async {
                      if (_isPlaying) {
                        await audioPlayer.stop();
                        setState(() {
                          _isPlaying = false;
                        });
                      } else {
                        await audioPlayer.stop();
                        await audioPlayer.seek(Duration.zero);
                        await audioPlayer.play(DeviceFileSource(path));
                        setState(() {
                          _isPlaying = true;
                          _recordingPath = path; // Update the current path
                        });
                        audioPlayer.onPlayerComplete.listen((event) {
                          setState(() {
                            _isPlaying = false;
                          });
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
