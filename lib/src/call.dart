import 'package:dart_msgpack/dart_msgpack.dart';

import 'client.dart';
import 'request.dart';

class RpcCall {
  RpcCall(this.client, this.cid, this.hid);

  final int cid;

  final RpcClient client;

  final int hid;

  var isNew = true;

  RpcRequest request([int flags = 0]) =>
    RpcRequest(this, flags);

  void recv(int flags, MsgPackDecoder mpd) {
    print('call recv!!');
  }

  void send(RpcRequest req) {
    final mpe = MsgPackEncoder();
    mpe.putUint(cid);
    var flags = req.flags;
    if (isNew) {
      flags |= newFlag;
    }
    mpe.putUint(flags);
    if (isNew) {
      mpe.putUint(hid);
    }
    mpe.putBytes(req.bytes);
    client.send(mpe.bytes);
    isNew = false;
  }
}

