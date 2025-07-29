import 'dart:typed_data';

import 'package:dart_msgpack/dart_msgpack.dart';
import 'package:dart_rpc/src/exception.dart';
import 'package:dart_websocket/dart_websocket.dart';
import 'package:logger/logger.dart';

import 'call.dart';

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
    final l = Logger();
    l.t('sending cid ${bytes[0]}');
    l.t('sending flags ${bytes[1]}');
    l.t('sending hid ${bytes[2]}');
    _socket.writeBinary(bytes);
  }

  final _calls = <int, RpcCall>{};

  var _closing = false;

  var _nextId = 0;

  final WebSocket _socket;

  int _getCid() {
    final l = Logger();
    l.t('allocating id $_nextId');
    return _nextId++;
  }

  void _init() async {
    _doInput();
  }

  void _doInput() async {
    final l = Logger();
    l.i('starting');
    try {
      await for (final msg in _socket.stream) {
        _doInputMsg(msg);
      }
    } on RpcException catch(e) {
      l.e('an error occurred: $e');
    }
    l.i('shutting down connection');
    _closing = true;
  }

  void _doInputMsg(dynamic msg) {
    final l = Logger();
    l.t('read message ${msg.runtimeType}');
    if (msg is! Uint8List) {
      throw RpcException('can\'t handle ${msg.runtimeType} msgs');
    }
    l.t('read binary message ${msg.length} bytes');
    final mpd = MsgPackDecoder(msg);

    l.t('reading call id (cid)');
    final cid = mpd.getUint();
    l.t('call id $cid');

    l.t('reading flags');
    final flags = mpd.getUint();
    l.t('flags $flags');
      
    RpcCall call;
    if (flags & newFlag == newFlag) {
      l.t('new flag set');
      if (_calls.containsKey(cid)) {
        final mesg = 'cid $cid already in use';
        throw RpcException(mesg);
      }

      final hid = mpd.getUint();
      l.t('his is $hid');
      // TODO
      final mesg = 'not implemented';
      throw RpcException(mesg);
    } else {
      if (!_calls.containsKey(cid)) {
        final mesg = 'cid $cid does not exist';
        throw RpcException(mesg);
      }
      call = _calls[cid]!;
      call.recv(flags, mpd);
    }
  }
}