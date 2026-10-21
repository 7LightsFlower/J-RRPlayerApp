class News {
  final String id;
  final String title;
  final String date;
  final String imageUrl;
  final String description;
  final String url;

  /// Дата в машинно-читаемом виде — используется для сортировки.
  /// По умолчанию, если не передана, берётся текущий момент.
  final DateTime parsedDate;

  News({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.description,
    required this.url,
    DateTime? parsedDate,
  }) : parsedDate = parsedDate ?? DateTime.now();

  News copyWith({
    String? id,
    String? title,
    String? date,
    String? imageUrl,
    String? description,
    String? url,
    DateTime? parsedDate,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      url: url ?? this.url,
      parsedDate: parsedDate ?? this.parsedDate,
    );
  }
}