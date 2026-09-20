class Memo {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  Memo({
    required this.id,
    this.title = '',
    this.content = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Memo.fromMap(Map<dynamic, dynamic> map) => Memo(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
}
