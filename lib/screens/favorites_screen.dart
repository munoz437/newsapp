import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/news_interaction_provider.dart';
import 'news_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<NewsInteractionProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoriteArticles;
          
          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 72,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes favoritos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las noticias que marques como favoritas aparecerán aquí para leerlas más tarde.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final article = favorites[index];
              final dateAdded = provider.getFavoriteAddedDate(article.id);
              
              return Dismissible(
                key: Key('fav-${article.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: theme.colorScheme.error,
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (direction) {
                  // Guardamos una copia local para la opciÃ³n Deshacer
                  final deletedArticle = article;
                  provider.removeFavorite(article.id);
                  
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${deletedArticle.title}" eliminada de favoritos'),
                      action: SnackBarAction(
                        label: 'DESHACER',
                        onPressed: () {
                          provider.toggleFavorite(deletedArticle);
                        },
                      ),
                    ),
                  );
                },
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(article: article),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(102),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Miniatura de imagen
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: article.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: article.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => _buildThumbnailFallback(theme),
                                )
                              : _buildThumbnailFallback(theme),
                        ),
                        
                        // InformaciÃ³n
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TÃ­tulo
                                Text(
                                  article.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Fecha de guardado
                                if (dateAdded != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bookmark_added_outlined,
                                        size: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Guardado: ${_formatDateTime(dateAdded)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // BotÃ³n de eliminar
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error.withAlpha(200),
                          ),
                          tooltip: 'Eliminar de favoritos',
                          onPressed: () {
                            final deletedArticle = article;
                            provider.removeFavorite(article.id);
                            
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Eliminado de favoritos'),
                                action: SnackBarAction(
                                  label: 'DESHACER',
                                  onPressed: () {
                                    provider.toggleFavorite(deletedArticle);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildThumbnailFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
      child: Center(
        child: Icon(
          Icons.newspaper_outlined,
          size: 28,
          color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
        ),
      ),
    );
  }
}

