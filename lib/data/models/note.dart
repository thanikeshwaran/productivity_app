class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Personal',
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.reminderAt,
  });

  Note copyWith({
    String? title,
    String? content,
    String? category,
    bool? pinned,
    DateTime? updatedAt,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'pinned': pinned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    category: json['category'] as String? ?? 'Personal',
    pinned: json['pinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    reminderAt: json['reminderAt'] == null
        ? null
        : DateTime.parse(json['reminderAt'] as String),
  );
}

const kNoteCategories = [
  'Personal',
  'Work',
  'Health',
  'Finance',
  'Ideas',
  'Other',
];
