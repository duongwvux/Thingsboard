class Device {
  final String id;
  final String name;
  final String type;
  final bool active;
  final DateTime? createdTime;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    this.createdTime,
  });

  // ThingsBoard trả về dạng:
  // { "id": { "id": "uuid" }, "name": "...", "type": "...", "active": true }
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id:          (json['id'] as Map<String, dynamic>)['id'] as String,
      name:        json['name'] as String? ?? 'Unnamed',
      type:        json['type'] as String? ?? 'default',
      active:      json['active'] as bool? ?? false,
      createdTime: json['createdTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdTime'] as int)
          : null,
    );
  }
}