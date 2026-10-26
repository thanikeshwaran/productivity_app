class ChecklistItem {
  final String id;
  final String checklistId;
  final String text;
  final bool completed;
  final int order;

  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.text,
    this.completed = false,
    required this.order,
  });

  ChecklistItem copyWith({String? text, bool? completed, int? order}) =>
      ChecklistItem(
        id: id,
        checklistId: checklistId,
        text: text ?? this.text,
        completed: completed ?? this.completed,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'checklistId': checklistId,
    'text': text,
    'completed': completed,
    'order': order,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as String,
    checklistId: json['checklistId'] as String,
    text: json['text'] as String,
    completed: json['completed'] as bool? ?? false,
    order: json['order'] as int? ?? 0,
  );
}
