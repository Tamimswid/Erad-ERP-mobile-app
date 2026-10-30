// import 'dart:async';

// abstract class NetworkInfo {
//   Future<bool> get isConnected;
//   Stream<bool> get connectionStream;
// }

// class NetworkInfoImpl implements NetworkInfo {
//   NetworkInfoImpl();

//   @override
//   Future<bool> get isConnected => Future.value(false);

//   @override
//   Stream<bool> get connectionStream => Stream.value(false);
// }


import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;
  
  NetworkInfoImpl(this.connectionChecker);
  
  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
  
  @override
  Stream<bool> get connectionStream => connectionChecker.onStatusChange
      .map((status) => status == InternetConnectionStatus.connected);
}
