import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether a network interface is available and emits state changes.
///
/// A network interface does not guarantee Internet access. API requests remain
/// the source of truth for reachability when a Wi-Fi network has no Internet.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Checks the current network interface, treating plugin errors as unknown.
  ///
  /// Unknown connectivity is treated as potentially online so Dio can verify
  /// access; the repository handles request failures with its SQLite fallback.
  Future<bool> hasNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasNetwork(results);
    } catch (_) {
      return true;
    }
  }

  /// Emits whether any network interface is available when connectivity changes.
  Stream<bool> get onConnectionChanged =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
