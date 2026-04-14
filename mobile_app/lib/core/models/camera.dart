class Camera {
  final int id;
  final String name;
  final String location;
  final String streamUrl;
  final String protocol;
  final String status;
  final bool isActive;
  final int frameRate;
  final DateTime? lastSeen;
  final String? errorMessage;

  const Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.streamUrl,
    required this.protocol,
    required this.status,
    required this.isActive,
    required this.frameRate,
    this.lastSeen,
    this.errorMessage,
  });

  factory Camera.fromJson(Map<String, dynamic> j) => Camera(
        id: j['id'],
        name: j['name'],
        location: j['location'],
        streamUrl: j['stream_url'],
        protocol: j['protocol'],
        status: j['status'] ?? 'offline',
        isActive: j['is_active'] ?? false,
        frameRate: j['frame_rate'] ?? 5,
        lastSeen: j['last_seen'] != null ? DateTime.parse(j['last_seen']) : null,
        errorMessage: j['error_message'],
      );
}
