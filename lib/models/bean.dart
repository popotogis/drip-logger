class Bean {
  final String id;
  final String name;
  final String roaster;
  final String roastLevel; // e.g. Light, Medium, Dark
  final String origin; // e.g. Ethiopia
  // final String process; // e.g. Washed, Natural (Keep it simple for now)

  final DateTime lastUsed;

  Bean({
    required this.id,
    required this.name,
    this.roaster = '',
    this.roastLevel = '',
    this.origin = '',
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roaster': roaster,
        'roastLevel': roastLevel,
        'origin': origin,
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory Bean.fromJson(Map<String, dynamic> json) {
    return Bean(
      id: json['id'] as String,
      name: json['name'] as String,
      roaster: json['roaster'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
