import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'services.dart';
// Re-export models to ensure they're available where needed
export 'models.dart';

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulasi loading 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/logo.png', width: 200),
            const SizedBox(height: 20),
            const Text(
              'Madiun Siaga 112',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _commentController = TextEditingController();
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    // Refresh data saat tampilan dibuat
    Future.microtask(() {
      if (mounted) {
        final provider = Provider.of<AppStateProvider>(context, listen: false);
        provider.fetchData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final ambulanceLocations = provider.ambulanceLocations;
        final comments = provider.comments;
        final isLoggedIn = provider.currentUser != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Madiun Siaga 112'),
            backgroundColor: Colors.red,
            actions: [
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  setState(() {
                    _showComments = !_showComments;
                  });
                },
              ),
              if (!isLoggedIn)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                PopupMenuButton(
                  onSelected: (value) async {
                    if (value == 'admin') {
                      bool isAdmin = await provider.isAdmin();
                      if (isAdmin && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminScreen()),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anda bukan admin')),
                        );
                      }
                    } else if (value == 'logout') {
                      provider.logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Login Sebagai Admin'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                ),
            ],
          ),
          body: Stack(
            children: [
              // Peta OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: ambulanceLocations.isNotEmpty
                      ? LatLng(ambulanceLocations.first.latitude,
                          ambulanceLocations.first.longitude)
                      : LatLng(-7.6310, 111.5289), // Koordinat default Madiun
                  zoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.madiun_siaga_112',
                  ),
                  // Marker ambulan
                  MarkerLayer(
                    markers: ambulanceLocations
                        .map((loc) => Marker(
                              point: LatLng(loc.latitude, loc.longitude),
                              width: 80,
                              height: 80,
                              builder: (context) => const Icon(
                                Icons.local_hospital,
                                color: Colors.red,
                                size: 40,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),

              // Panel komentar (jika ditampilkan)
              if (_showComments)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Komentar & Keluhan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(comment.userName),
                                subtitle: Text(comment.content),
                                trailing: Text(
                                  '${comment.timestamp.day}/${comment.timestamp.month}/${comment.timestamp.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tambahkan komentar...',
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: isLoggedIn,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: isLoggedIn
                                    ? () async {
                                        if (_commentController
                                            .text.isNotEmpty) {
                                          await provider.addComment(
                                              _commentController.text);
                                          _commentController.clear();
                                        }
                                      }
                                    : () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Silakan login untuk menambahkan komentar'),
                                          ),
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(Icons.refresh),
            onPressed: () {
              provider.fetchData();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  // Register Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: Colors.red,
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('images/logo.png', height: 100),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Masuk ke Akun Anda' : 'Buat Akun Baru',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Additional fields for Register form
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Common fields
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon/WA',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              bool success;
                              if (_isLogin) {
                                success = await provider.login(
                                  _phoneController.text,
                                  _passwordController.text,
                                );
                              } else {
                                success = await provider.register(
                                  _nameController.text,
                                  _addressController.text,
                                  _phoneController.text,
                                  _passwordController.text,
                                );
                              }

                              if (success && context.mounted) {
                                Navigator.pop(context);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isLogin
                                        ? 'Login gagal. Periksa nomor dan password'
                                        : 'Registrasi gagal. Coba lagi'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            _isLogin ? 'LOGIN' : 'REGISTER',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Toggle Login/Register
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Belum punya akun? Register di sini'
                          : 'Sudah punya akun? Login di sini',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// Admin Screen
class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final isTracking = provider.isTracking;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Control Panel'),
            backgroundColor: Colors.red,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Card(
                child: ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Dashboard Admin'),
                  subtitle: Text('Panel kontrol ambulan'),
                ),
              ),
              const SizedBox(height: 16),

              // Status Tracking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status GPS Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTracking ? 'Aktif' : 'Tidak Aktif',
                            style: TextStyle(
                              fontSize: 16,
                              color: isTracking ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: isTracking,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              provider.toggleTracking();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTracking
                            ? 'GPS tracking ambulan aktif. Lokasi ambulan akan terus diperbarui.'
                            : 'GPS tracking ambulan tidak aktif. Aktifkan untuk memulai tracking.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informasi Tambahan
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Petunjuk'),
                        subtitle:
                            Text('Aktifkan GPS tracking saat ambulan bertugas'),
                        dense: true,
                      ),
                      ListTile(
                        leading: Icon(Icons.battery_alert),
                        title: Text('Peringatan'),
                        subtitle: Text(
                            'Tracking GPS aktif dapat menghabiskan baterai'),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Tombol Kembali
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        );
      },
    );
  }
}
