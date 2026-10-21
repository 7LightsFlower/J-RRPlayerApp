class Article {
  final String id;
  final String title;
  final String date;
  final String imageUrl;
  final String description;
  final String url;
  final String? category;

  const Article({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.description,
    required this.url,
    this.category,
  });

  Article copyWith({
    String? id,
    String? title,
    String? date,
    String? imageUrl,
    String? description,
    String? url,
    String? category,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      url: url ?? this.url,
      category: category ?? this.category,
    );
  }
}