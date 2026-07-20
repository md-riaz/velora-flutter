import 'dart:io';

/// IO implementation: recognizes a genuine [SocketException] (dart:io).
bool isSocketException(Object error) => error is SocketException;
