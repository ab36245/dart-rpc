import 'dart:typed_data';

import 'package:dart_msgpack/dart_msgpack.dart';

import 'call.dart';

class RpcResponse extends MsgPackDecoder {
  RpcResponse(this.call, Uint8List bytes): super(bytes);

  final RpcCall call;
}