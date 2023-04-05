import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:webrtc/signaling.dart';
import './firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final platform = const MethodChannel('samples.flutter.dev/battery');
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');
  bool speakerphone = false;

  MediaDeviceInfo? selectedInput;
  final List<MediaDeviceInfo> inputs = [];

  MediaDeviceInfo? selectedOutput;
  final List<MediaDeviceInfo> outputs = [];

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    checkOutputs();

    platform
        .invokeMethod('getBatteryLevel')
        .then((value) => print('RESULT = $value'));

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    navigator.mediaDevices.ondevicechange = (device) {
      print('event = $device');
    };

    initIO();

    ProximitySensor.events.listen((int event) {
      final isNear = (event > 0) ? true : false;
      print('IS NEAR = $isNear');
    });

    super.initState();
  }

  void initIO() {
    navigator.mediaDevices.enumerateDevices().then((list) {
      outputs.clear();
      inputs.clear();
      selectedOutput = null;
      selectedInput = null;
      for (final device in list) {
        if (device.kind == 'audioinput') {
          inputs.add(device);
          selectedInput ??= device;
          print(
              'INPUT: ${device.deviceId}, ${device.groupId}, ${device.kind}, ${device.label}');
        } else if (device.kind == 'audiooutput') {
          outputs.add(device);
          selectedOutput ??= device;
          print(
              'OUTPUT: ${device.deviceId}, ${device.groupId}, ${device.kind}, ${device.label}');
        }
      }
      setState(() {});
    });
  }

  Future checkOutputs() async {
    final session = await AudioSession.instance;
    session.devicesChangedEventStream.listen((event) {
      print('DEVICE ADDED = ${event.devicesAdded}');
      print('DEVICE REMOVED = ${event.devicesRemoved}');
      initIO();
    });
    final devices = await session.getDevices();
    print('DEVICES = $devices');
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  signaling.openUserMedia();
                  // signaling.openUserMedia(_localRenderer, _remoteRenderer);
                },
                child: const Text("Open camera & microphone"),
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () async {
                  roomId = await signaling.createRoom();
                  textEditingController.text = roomId!;
                  setState(() {});
                },
                child: const Text("Create room"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Add roomId
                  signaling.joinRoom(textEditingController.text);
                },
                child: const Text("Join room"),
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () {
                  // signaling.hangUp();
                },
                child: const Text("Hangup"),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Add roomId
                  signaling.mute();
                },
                child: const Text("Mute"),
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () {
                  signaling.unmute();
                },
                child: const Text("Unmute"),
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () {
                  signaling.switchSpeakerphone(speakerphone);
                  speakerphone = !speakerphone;
                },
                child: const Text("Switch"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<MediaDeviceInfo>(
                  value: selectedInput,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (device) {
                    // This is called when the user selects an item.
                    setState(() {
                      selectedInput = device;
                    });
                  },
                  items: inputs.map<DropdownMenuItem<MediaDeviceInfo>>(
                      (MediaDeviceInfo value) {
                    return DropdownMenuItem<MediaDeviceInfo>(
                      value: value,
                      child: Text(value.label),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<MediaDeviceInfo>(
                  value: selectedOutput,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (device) {
                    // This is called when the user selects an item.
                    setState(() {
                      selectedOutput = device;
                    });
                    if (device != null) {
                      signaling.switchOutput(device.deviceId);
                    }
                  },
                  items: outputs.map<DropdownMenuItem<MediaDeviceInfo>>(
                      (MediaDeviceInfo value) {
                    return DropdownMenuItem<MediaDeviceInfo>(
                      value: value,
                      child: Text(value.label),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Expanded(
          //   child: Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          //         Expanded(child: RTCVideoView(_remoteRenderer)),
          //       ],
          //     ),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Join the following Room: "),
                Flexible(
                  child: TextFormField(
                    controller: textEditingController,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8)
        ],
      ),
    );
  }
}
