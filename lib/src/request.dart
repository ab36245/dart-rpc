import 'package:dart_msgpack/dart_msgpack.dart';

import 'call.dart';
import 'client.dart';

class RpcRequest extends MsgPackEncoder {
  RpcRequest(this.call, this.flags) : super();

  final RpcCall call;

  int flags;

  void send() {
    call.send(this);
  }

  void sendAndClose() {
    flags |= closedFlag;
    send();
  }
}