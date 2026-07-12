import 'package:flutter_test/flutter_test.dart';
import 'package:newsapp/models/article_model.dart';

void main() {
  group('Article Model Tests', () {
    test('should parse NewsAPI format correctly', () {
      final json = {
        'source': {'id': 'google-news', 'name': 'Google News'},
        'author': 'Jane Doe',
        'title': 'Test Article Title',
        'description': 'Test article description here.',
        'url': 'https://example.com/test',
        'urlToImage': 'https://example.com/image.jpg',
        'publishedAt': '2026-07-12T15:00:00Z',
        'content': 'Some content...'
      };

      final article = Article.fromJson(json);

      expect(article.title, 'Test Article Title');
      expect(article.sourceName, 'Google News');
      expect(article.imageUrl, 'https://example.com/image.jpg');
      expect(article.url, 'https://example.com/test');
      expect(article.publishedAt.year, 2026);
      expect(article.publishedAt.month, 7);
      expect(article.publishedAt.day, 12);
    });

    test('should parse GNews format correctly', () {
      final json = {
        'title': 'GNews Article Title',
        'description': 'GNews description.',
        'content': 'GNews content...',
        'url': 'https://gnews.io/article',
        'image': 'https://gnews.io/image.png',
        'publishedAt': '2026-07-12T10:30:00Z',
        'source': {
          'name': 'GNews Source',
          'url': 'https://gnews.io'
        }
      };

      final article = Article.fromJson(json);

      expect(article.title, 'GNews Article Title');
      expect(article.sourceName, 'GNews Source');
      expect(article.imageUrl, 'https://gnews.io/image.png');
      expect(article.url, 'https://gnews.io/article');
    });

    test('should handle missing and null fields safely', () {
      final json = <String, dynamic>{
        'title': null,
        'source': null,
        'urlToImage': null,
        'publishedAt': null,
      };

      final article = Article.fromJson(json);

      expect(article.title, 'Sin título');
      expect(article.sourceName, 'Desconocido');
      expect(article.imageUrl, isNull);
      expect(article.publishedAt, isNotNull);
    });
  });
}
