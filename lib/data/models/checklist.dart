class Checklist {
  final String id;
  final String name;
  final String? sourceTemplateId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Checklist({
    required this.id,
    required this.name,
    this.sourceTemplateId,
    required this.createdAt,
    required this.updatedAt,
  });

  Checklist copyWith({String? name, DateTime? updatedAt}) => Checklist(
    id: id,
    name: name ?? this.name,
    sourceTemplateId: sourceTemplateId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceTemplateId': sourceTemplateId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
    id: json['id'] as String,
    name: json['name'] as String,
    sourceTemplateId: json['sourceTemplateId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
