class User {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String? password;
  final bool isAdmin;

  User({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.password,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      password: json['password'],
      isAdmin: json['is_admin'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'password': password,
      'is_admin': isAdmin ? 1 : 0,
    };
  }
}

class AmbulanceLocation {
  final int? id;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime timestamp;

  AmbulanceLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
  });

  factory AmbulanceLocation.fromJson(Map<String, dynamic> json) {
    return AmbulanceLocation(
      id: json['id'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Comment {
  final int? id;
  final int userId;
  final String content;
  final DateTime timestamp;
  final String userName;

  Comment({
    this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    required this.userName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      userName: json['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'user_name': userName,
    };
  }
}