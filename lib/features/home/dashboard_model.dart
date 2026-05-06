class Dashboard {
  final String id;
  final String title;
  final DateTime? createdTime;
  final bool assignedToCurrentUser;
 
  const Dashboard({
    required this.id,
    required this.title,
    this.createdTime,
    this.assignedToCurrentUser = false,
  });
 
  // ThingsBoard response:
  // { "id": { "id": "uuid" }, "title": "My Dashboard", "createdTime": 1234567890 }
  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id:    (json['id'] as Map<String, dynamic>)['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      createdTime: json['createdTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdTime'] as int)
          : null,
    );
  }
}