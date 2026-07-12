class Article {
  final String title;
  final String? imageUrl;
  final String sourceName;
  final DateTime publishedAt;
  final String? url;

  Article({
    required this.title,
    this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
    this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    // Extract source name
    String source = 'Desconocido';
    if (json['source'] != null) {
      if (json['source'] is Map) {
        source = json['source']['name'] ?? 'Desconocido';
      } else if (json['source'] is String) {
        source = json['source'];
      }
    }

    // Try parsing date
    DateTime date = DateTime.now();
    if (json['publishedAt'] != null) {
      final parsedDate = DateTime.tryParse(json['publishedAt'].toString());
      if (parsedDate != null) {
        date = parsedDate.toLocal();
      }
    }

    // Support both NewsAPI (urlToImage) and GNews (image)
    final imgUrl = json['urlToImage'] ?? json['image'];

    return Article(
      title: json['title'] ?? 'Sin título',
      imageUrl: imgUrl != null && imgUrl.toString().isNotEmpty ? imgUrl.toString() : null,
      sourceName: source,
      publishedAt: date,
      url: json['url']?.toString(),
    );
  }
}
