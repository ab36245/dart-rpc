class RpcException implements Exception {
  final String mesg;

  const RpcException(this.mesg);

  @override
  String toString() =>
    '$runtimeType: $mesg';
}