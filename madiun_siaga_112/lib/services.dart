import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'package:connectivity_plus/connectivity_plus.dart'
    show ConnectivityResult, Connectivity;

// Ganti URL ini dengan URL server Node.js Anda
const String baseUrl = "http://10.101.14.165:3000"; // Gunakan IP komputer Anda
// Atau jika menggunakan emulator Android
// const String baseUrl = "http://10.0.2.2:3000";

class ApiService {
// Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Connectivity _connectivity = Connectivity();

// Check network connectivity
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Handle HTTP requests with error handling and timeout
  Future<http.Response> _safeHttpRequest(
      Future<http.Response> httpRequest) async {
    if (!await _checkConnectivity()) {
      throw Exception('Tidak ada koneksi internet');
    }

    try {
      return await httpRequest.timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('Koneksi timeout'));
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server');
    } on HttpException {
      throw Exception('Permintaan HTTP gagal');
    } on FormatException {
      throw Exception('Format respons tidak valid');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Login API
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _safeHttpRequest(http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone': phone, 'password': password}),
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Simpan token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setBool('isAdmin', data['user']['is_admin'] == 1);
      await prefs.setString('userData', json.encode(data['user']));
      return data;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Login gagal');
    }
  }

  // Register API
  Future<User> register(
      String name, String address, String phone, String password) async {
    final response = await _safeHttpRequest(http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'address': address,
        'phone': phone,
        'password': password,
        'is_admin': 0,
      }),
    ));

    if (response.statusCode == 201) {
      return User.fromJson(json.decode(response.body)['user']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Registrasi gagal');
    }
  }

  // Get Ambulance Location
  Future<List<AmbulanceLocation>> getAmbulanceLocations() async {
    final response = await _safeHttpRequest(
        http.get(Uri.parse('$baseUrl/ambulance/locations')));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => AmbulanceLocation.fromJson(item)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengambil lokasi ambulan');
    }
  }

  // Update Ambulance Location with retry
  Future<void> updateAmbulanceLocation(
      double latitude, double longitude) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    // Implement retry logic
    int retries = 3;
    while (retries > 0) {
      try {
        final response = await _safeHttpRequest(http.post(
          Uri.parse('$baseUrl/ambulance/update-location'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'latitude': latitude,
            'longitude': longitude,
            'status': 'active',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ));

        if (response.statusCode == 200) {
          return; // Success
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal memperbarui lokasi');
        }
      } catch (e) {
        retries--;
        if (retries <= 0) rethrow;
        await Future.delayed(const Duration(seconds: 2)); // Wait before retry
      }
    }
  }

  // Get Comments
  Future<List<Comment>> getComments() async {
    final response =
        await _safeHttpRequest(http.get(Uri.parse('$baseUrl/comments')));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => Comment.fromJson(item)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengambil komentar');
    }
  }

  // Add Comment
  Future<Comment> addComment(String content) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await _safeHttpRequest(http.post(
      Uri.parse('$baseUrl/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ));

    if (response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menambah komentar');
    }
  }
}

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  // Check login status
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    final token = prefs.getString('token');

    if (userData != null && token != null) {
      try {
        _currentUser = User.fromJson(json.decode(userData));
        return true;
      } catch (e) {
        // Invalid user data in storage
        await logout();
        return false;
      }
    }
    return false;
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdmin') ?? false;
  }

  // Login
  Future<bool> login(String phone, String password) async {
    try {
      final result = await _apiService.login(phone, password);
      _currentUser = User.fromJson(result['user']);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Register
  Future<bool> register(
      String name, String address, String phone, String password) async {
    try {
      await _apiService.register(name, address, phone, password);
      // After registration, try to login
      return await login(phone, password);
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('isAdmin');
    await prefs.remove('userData');
    _currentUser = null;
  }
}

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  final ApiService _apiService = ApiService();
  StreamController<LocationData> locationController =
      StreamController<LocationData>.broadcast();
  bool _serviceEnabled = false;
  bool _isTracking = false;
  StreamSubscription<LocationData>? _locationSubscription;

  bool get isTracking => _isTracking;

  // Initialize location service
  Future<bool> initialize() async {
    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          return false;
        }
      }

      // Request permission
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return false;
        }
      }

      // Set up location settings
      _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 5000,
        distanceFilter: 10,
      );

      return true;
    } catch (e) {
      debugPrint('Error initializing location service: $e');
      return false;
    }
  }

  // Start tracking
  void startTracking() {
    if (!_isTracking) {
      _isTracking = true;

      // Cancel existing subscription if any
      _locationSubscription?.cancel();

      _locationSubscription =
          _location.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          locationController.add(currentLocation);

          _apiService
              .updateAmbulanceLocation(
            currentLocation.latitude!,
            currentLocation.longitude!,
          )
              .catchError((error) {
            debugPrint('Error updating location: $error');
          });
        }
      }, onError: (e) {
        debugPrint('Location subscription error: $e');
        // Try to recover
        stopTracking();
        Future.delayed(const Duration(seconds: 5), () {
          if (_isTracking) startTracking();
        });
      });
    }
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _location.enableBackgroundMode(enable: false);
  }

  // Get current location once
  Future<LocationData> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      throw Exception('Gagal mendapatkan lokasi: $e');
    }
  }

  // Enable background mode
  void enableBackgroundMode() {
    _location.enableBackgroundMode(enable: true);
  }

  void dispose() {
    stopTracking();
    locationController.close();
  }
}

// State provider untuk manajemen state aplikasi
class AppStateProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  bool _isTracking = false;
  List<AmbulanceLocation> _ambulanceLocations = [];
  List<Comment> _comments = [];
  Timer? _refreshTimer;

  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  List<AmbulanceLocation> get ambulanceLocations => _ambulanceLocations;
  List<Comment> get comments => _comments;
  User? get currentUser => _authService.currentUser;

  AppStateProvider() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final locationInitialized = await _locationService.initialize();
      if (!locationInitialized) {
        debugPrint('Warning: Location service could not be initialized');
      }

      await _authService.isLoggedIn();
      await fetchData();

      // Set up periodic data refresh
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        fetchData().catchError((e) {
          debugPrint('Background refresh error: $e');
        });
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchData() async {
    try {
      final locs = await _apiService.getAmbulanceLocations();
      final coms = await _apiService.getComments();

      _ambulanceLocations = locs;
      _comments = coms;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching data: $e');
      // Don't throw the error here to prevent UI disruption
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool result = await _authService.login(phone, password);
      return result;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
      String name, String address, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool result = await _authService.register(name, address, phone, password);
      return result;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> addComment(String content) async {
    try {
      await _apiService.addComment(content);
      await fetchData();
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow; // Propagate error to UI
    }
  }

  void toggleTracking() {
    if (_isTracking) {
      _locationService.stopTracking();
    } else {
      _locationService.startTracking();
      _locationService.enableBackgroundMode();
    }

    _isTracking = !_isTracking;
    notifyListeners();
  }

  Future<bool> isAdmin() async {
    return await _authService.isAdmin();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
