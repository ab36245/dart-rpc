import 'dart:async';
import 'dart:typed_data';

import 'package:dart_msgpack/dart_msgpack.dart';
import 'package:dart_websocket/dart_websocket.dart';

import 'call.dart';
import 'util.dart';

const controlChannelId = 0; // Must agree with server

// These must agree with the rpc server
const newFlag     = 0x01;
const closeFlag   = 0x02;
const closedFlag  = 0x04;

class RpcClient {
  RpcClient(this._socket) {
    _init();
  }

  RpcCall call(int hid) {
    final cid = _getCid();
    final call = RpcCall(this, cid, hid);
    _calls[cid] = call;
    return call;
  }

  void send(Uint8List bytes) {
    _output.sink.add(bytes);
  }

  final _calls = <int, RpcCall>{};

  var _closing = false;

  var _nextId = 0;

  final _output = StreamController<Uint8List>();
  
  final _readers = <int, StreamController<Uint8List>>{};

  final WebSocket _socket;

  int _getCid() {
    return _nextId++;
  }

  void _init() async {
    _doInput();
    _doOutput();
  }

  void _doInput() async {
    final m = 'Client._doInput';
    print('$m: starting');
    await for (final msg in _socket.stream) {
      print('$m: read message ${msg.runtimeType}');
      if (msg is! Uint8List) {
        print('$m: can\'t handle ${m.runtimeType} msgs');
        break;
      }
      print('$m: read binary message ${msg.length} bytes');
      final mpd = MsgPackDecoder(msg);

      print('$m: reading call id (cid)');
      final cid = mpd.getUint();
      print('$m: call id $cid');

      print('$m: reading flags');
      final flags = mpd.getUint();
      print('$m: flags $flags');
      
      RpcCall call;
      if (flags & newFlag == newFlag) {
        print('$m: new flag set');
        if (_calls.containsKey(cid)) {
          print('$m: cid $cid already in use');
          throw 'yikes';
        }

        final hid = mpd.getUint();
        print('$m: his is $hid');
        // TODO
      } else {
        if (!_calls.containsKey(cid)) {
          print('$m: unknown cid $cid');
          throw 'yikes';
        }
        call = _calls[cid]!;
        call.recv(flags, mpd);
      }
    }
    print('$m: shutting down connection');
    _closing = true;
    for (final entry in _readers.entries) {
      print('$m: closing channel ${entry.key} reader');
      await entry.value.close();
    }
  }

  void _doOutput() async {
    final m = 'Client._doOutput';
    print('$m: starting');
    await for (final bytes in _output.stream) {
      print('$m: output ${bytes.length} bytes');
      _socket.writeBinary(bytes);
    }
    print('$m: output stream is closed');
  }
}