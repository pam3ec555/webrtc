import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_incall_manager/flutter_incall_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
      {
        'url': 'turn:relay1.expressturn.com:3478',
        'credential': 'L1zCBw5ovSmPi1EZ',
        'username': 'efR5MH0KWY1HNA7M4T'
      },
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  MediaRecorder? mediaRecorder;

  Future<String> createRoom() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    // Создаем комнату в бд
    DocumentReference roomRef = db.collection('rooms').doc();

    print('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    print('New room created with SDK offer. Room ID: $roomId');
    currentRoomText = 'Current room is $roomId - You are the caller!';
    // Created a Room

    // Listening for remote session description below
    roomRef.snapshots().listen((snapshot) async {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        print("Someone tried to connect");
        await peerConnection?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          print('Got new remote ICE candidate: ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data?['candidate'],
              data?['sdpMid'],
              data?['sdpMLineIndex'],
            ),
          );
        }
      }
    });
    // Listen for remote ICE candidates above

    return roomId;
  }

  Future<void> joinRoom(
    String roomId,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) async {
        print(
            'BEFORE REMOTE STREAMS = ${peerConnection?.getRemoteStreams().length}');
        print(
            'BEFORE LOCAL STREAMS = ${peerConnection?.getLocalStreams().length}');
        peerConnection?.addTrack(track, localStream!);
        print(
            'AFTER REMOTE STREAMS = ${peerConnection?.getRemoteStreams().length}');
        print(
            'AFTER LOCAL STREAMS = ${peerConnection?.getLocalStreams().length}');
      });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate == null) {
          print('onIceCandidate: complete!');
          return;
        }
        print('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      print('Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data();
          print(data);
          print('Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data?['candidate'],
              data?['sdpMid'],
              data?['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  void mute() async {
    localStream?.getAudioTracks().first.enabled = false;
  }

  void unmute() async {
    localStream?.getAudioTracks().first.enabled = true;
  }

  void switchOutput(String deviceId) {
    navigator.mediaDevices
        .selectAudioOutput(AudioOutputOptions(deviceId: deviceId));
  }

  void switchSpeakerphone(bool val) async {
    if (kIsWeb) return;
    final incallManager = IncallManager();
    if (Platform.isIOS) {
      if (val) {
        incallManager.setForceSpeakerphoneOn(flag: ForceSpeakerType.FORCE_ON);
      } else {
        incallManager.setForceSpeakerphoneOn(flag: ForceSpeakerType.FORCE_OFF);
      }
      incallManager.setSpeakerphoneOn(val);
    } else {
      incallManager.setSpeakerphoneOn(val);
    }
  }

  Future<void> openUserMedia(
      // RTCVideoRenderer localVideo,
      // RTCVideoRenderer remoteVideo,
      ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': false, 'audio': true});

    // localVideo.srcObject = stream;
    localStream = stream;

    // remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    mediaRecorder?.stop();
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }

    localStream!.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
    };
  }
}
