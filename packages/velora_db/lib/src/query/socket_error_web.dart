/// Web implementation: `SocketException` (dart:io) doesn't exist on web, so
/// there's nothing to recognize -- always false.
bool isSocketException(Object error) => false;
