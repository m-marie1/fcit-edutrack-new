import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AllowedMacProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<String> _allowedMacs = [];
  bool _isLoading = false;

  List<String> get allowedMacs => _allowedMacs;
  bool get isLoading => _isLoading;

  Future<void> fetchAllowedMacs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getAllowedMacAddresses();
      if (response['success'] == true && response['data'] != null) {
        _allowedMacs = List<String>.from(response['data']);
      } else {
        _allowedMacs = [];
      }
    } catch (e) {
      _allowedMacs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMac(String macAddress) async {
    final res = await _apiService.addAllowedMacAddress(macAddress);
    if (res['success'] == true) {
      await fetchAllowedMacs();
    }
  }

  Future<void> deleteMac(String macAddress) async {
    final res = await _apiService.deleteAllowedMacAddress(macAddress);
    if (res['success'] == true) {
      _allowedMacs
          .removeWhere((mac) => mac.toUpperCase() == macAddress.toUpperCase());
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    final res = await _apiService.clearAllowedMacAddresses();
    if (res['success'] == true) {
      _allowedMacs = [];
      notifyListeners();
    }
  }
}
