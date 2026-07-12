class Article {
  final String id;
  final String title;
  final String? imageUrl;
  final String sourceName;
  final DateTime publishedAt;
  final String? url;

  Article({
    required this.id,
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
    final urlStr = json['url']?.toString() ?? '';
    
    // Generar un ID único basado en la URL del artículo, o el título como fallback
    final id = urlStr.isNotEmpty 
        ? urlStr 
        : (json['title']?.toString() ?? 'sin-id-${date.millisecondsSinceEpoch}');

    return Article(
      id: id,
      title: json['title'] ?? 'Sin título',
      imageUrl: imgUrl != null && imgUrl.toString().isNotEmpty ? imgUrl.toString() : null,
      sourceName: source,
      publishedAt: date,
      url: urlStr.isNotEmpty ? urlStr : null,
    );
  }
}
