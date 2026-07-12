import 'package:flutter/material.dart';
import '../models/article_model.dart';

enum VoteType { like, dislike, none }

class NewsInteractionProvider extends ChangeNotifier {
  // Set de IDs de noticias favoritas
  final Set<String> _favoriteIds = {};
  
  // Mapa de noticias favoritas completas para poder mostrarlas en FavoritesScreen
  final Map<String, Article> _favoriteArticles = {};
  
  // Mapa de fechas de adición a favoritos
  final Map<String, DateTime> _favoriteAddedDates = {};
  
  // Mapa de votos por ID de noticia
  final Map<String, VoteType> _votes = {};

  // Getters públicos
  Set<String> get favoriteIds => _favoriteIds;
  Map<String, VoteType> get votes => _votes;

  // Retorna los artículos favoritos ordenados por fecha de adición (más recientes primero)
  List<Article> get favoriteArticles {
    final articles = _favoriteArticles.values.toList();
    articles.sort((a, b) {
      final dateA = _favoriteAddedDates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = _favoriteAddedDates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Descendente
    });
    return articles;
  }

  // Métodos de consulta de estado
  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  DateTime? getFavoriteAddedDate(String id) {
    return _favoriteAddedDates[id];
  }

  VoteType getVote(String id) {
    return _votes[id] ?? VoteType.none;
  }

  // Métodos de modificación de estado
  
  // Alternar favorito (toggle)
  void toggleFavorite(Article article) {
    final id = article.id;
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favoriteArticles.remove(id);
      _favoriteAddedDates.remove(id);
    } else {
      _favoriteIds.add(id);
      _favoriteArticles[id] = article;
      _favoriteAddedDates[id] = DateTime.now();
    }
    notifyListeners();
  }

  // Eliminar favorito directamente (para swipe-to-dismiss o botón)
  void removeFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favoriteArticles.remove(id);
      _favoriteAddedDates.remove(id);
      notifyListeners();
    }
  }

  // Lógica de votación
  void vote(String id, VoteType type) {
    final currentVote = _votes[id] ?? VoteType.none;

    if (currentVote == type) {
      // Si toca el mismo botón, se quita el voto (toggle a none)
      _votes[id] = VoteType.none;
    } else {
      // Si toca el otro botón, se reemplaza por el nuevo tipo
      _votes[id] = type;
    }
    notifyListeners();
  }
}
