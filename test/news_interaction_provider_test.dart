import 'package:flutter_test/flutter_test.dart';
import 'package:newsapp/models/article_model.dart';
import 'package:newsapp/providers/news_interaction_provider.dart';

void main() {
  group('NewsInteractionProvider Tests', () {
    late NewsInteractionProvider provider;
    late Article testArticle1;
    late Article testArticle2;

    setUp(() {
      provider = NewsInteractionProvider();
      
      testArticle1 = Article(
        id: 'https://example.com/article1',
        title: 'Article 1',
        sourceName: 'Source 1',
        publishedAt: DateTime.now(),
        url: 'https://example.com/article1',
      );

      testArticle2 = Article(
        id: 'https://example.com/article2',
        title: 'Article 2',
        sourceName: 'Source 2',
        publishedAt: DateTime.now(),
        url: 'https://example.com/article2',
      );
    });

    test('should toggle favorite status correctly', () {
      expect(provider.isFavorite(testArticle1.id), isFalse);

      // Add to favorites
      provider.toggleFavorite(testArticle1);
      expect(provider.isFavorite(testArticle1.id), isTrue);
      expect(provider.favoriteArticles.length, 1);
      expect(provider.favoriteArticles.first.id, testArticle1.id);
      expect(provider.getFavoriteAddedDate(testArticle1.id), isNotNull);

      // Remove from favorites
      provider.toggleFavorite(testArticle1);
      expect(provider.isFavorite(testArticle1.id), isFalse);
      expect(provider.favoriteArticles.isEmpty, isTrue);
      expect(provider.getFavoriteAddedDate(testArticle1.id), isNull);
    });

    test('should remove favorite directly using removeFavorite', () {
      provider.toggleFavorite(testArticle1);
      expect(provider.isFavorite(testArticle1.id), isTrue);

      provider.removeFavorite(testArticle1.id);
      expect(provider.isFavorite(testArticle1.id), isFalse);
      expect(provider.favoriteArticles.isEmpty, isTrue);
    });

    test('should sort favorite articles descending by added date', () async {
      provider.toggleFavorite(testArticle1);
      
      // Esperar una mínima fracción de tiempo para asegurar una fecha posterior
      await Future.delayed(const Duration(milliseconds: 10));
      provider.toggleFavorite(testArticle2);

      final favorites = provider.favoriteArticles;
      expect(favorites.length, 2);
      
      // testArticle2 debe estar primero en la lista por ser el más reciente agregado
      expect(favorites[0].id, testArticle2.id);
      expect(favorites[1].id, testArticle1.id);
    });

    test('should handle voting toggle and swap logic correctly', () {
      final articleId = testArticle1.id;
      
      // Voto inicial es none
      expect(provider.getVote(articleId), VoteType.none);

      // Dar like
      provider.vote(articleId, VoteType.like);
      expect(provider.getVote(articleId), VoteType.like);

      // Quitar like (al presionar me gusta de nuevo) -> toggle
      provider.vote(articleId, VoteType.like);
      expect(provider.getVote(articleId), VoteType.none);

      // Dar like y cambiar a dislike -> swap
      provider.vote(articleId, VoteType.like);
      expect(provider.getVote(articleId), VoteType.like);

      provider.vote(articleId, VoteType.dislike);
      expect(provider.getVote(articleId), VoteType.dislike);

      // Quitar dislike (al presionar no me gusta de nuevo) -> toggle
      provider.vote(articleId, VoteType.dislike);
      expect(provider.getVote(articleId), VoteType.none);
    });
  });
}
