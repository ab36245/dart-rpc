import 'dart:async';

import 'package:dart_msgpack/dart_msgpack.dart';

import 'client.dart';
import 'request.dart';
import 'response.dart';

class RpcCall {
  RpcCall(this.client, this.cid, this.hid);

  final int cid;

  final RpcClient client;

  final int hid;

  RpcRequest request([int flags = 0]) =>
    RpcRequest(this, flags);

  Stream<RpcResponse> get responses =>
    _responses.stream;
      
  void close() {
    _responses.sink.close();
    client.close(this);
  }

  void recv(int flags, MsgPackDecoder mpd) {
    final response = RpcResponse(this, mpd.bytes);
    _responses.sink.add(response);
    if (flags & closedFlag == closedFlag) {
      close();
    }
  }

  void send(RpcRequest req) {
    final mpe = MsgPackEncoder();
    mpe.putUint(cid);
    var flags = req.flags;
    if (_isNew) {
      flags |= newFlag;
    }
    mpe.putUint(flags);
    if (_isNew) {
      mpe.putUint(hid);
    }
    mpe.putBytes(req.bytes);
    client.send(mpe.bytes);
    _isNew = false;
  }

  var _isNew = true;
  final _responses = StreamController<RpcResponse>();
}

