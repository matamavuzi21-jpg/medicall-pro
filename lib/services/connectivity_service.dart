import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Expose l'état de connexion réseau de l'appareil (Wi-Fi de l'hôpital,
/// données mobiles, ou aucune connexion). Ne préjuge pas de la joignabilité
/// réelle du serveur Supabase : sert de signal pour déclencher la
/// synchronisation de la file d'attente locale (voir [OfflineQueueService]).
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> start() async {
    final initial = await _connectivity.checkConnectivity();
    _updateStatus(initial);
    _sub = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
