class TemplateItem {
  final String text;
  final int order;

  const TemplateItem({required this.text, required this.order});

  Map<String, dynamic> toJson() => {'text': text, 'order': order};

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
    text: json['text'] as String,
    order: json['order'] as int? ?? 0,
  );
}

class ChecklistTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<TemplateItem> items;
  final bool builtIn;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.items,
    this.builtIn = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'items': items.map((e) => e.toJson()).toList(),
    'builtIn': builtIn,
  };

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) =>
      ChecklistTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => TemplateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        builtIn: json['builtIn'] as bool? ?? false,
      );
}
