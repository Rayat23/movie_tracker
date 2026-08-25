class UserProfile {
  final String id;
  final String name;
  final int avatarIndex;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Profile',
      avatarIndex: (json['avatar_index'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_index': avatarIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? name,
    int? avatarIndex,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      createdAt: createdAt,
    );
  }

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'P';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
