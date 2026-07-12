import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/article_model.dart';
import '../providers/news_interaction_provider.dart';
import '../screens/news_detail_screen.dart';

class NewsTile extends StatelessWidget {
  final Article article;

  const NewsTile({
    super.key,
    required this.article,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'Reciente';
    }

    if (difference.inSeconds < 60) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Hace $days ${days == 1 ? 'día' : 'días'}';
    } else {
      return '${article.publishedAt.day.toString().padLeft(2, '0')}/${article.publishedAt.month.toString().padLeft(2, '0')}/${article.publishedAt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(102),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la noticia con botón de Favoritos superpuesto
            Stack(
              children: [
                if (article.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                      child: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildImageFallback(theme),
                  )
                else
                  _buildImageFallback(theme),
                  
                // Botón de favoritos premium superpuesto en la imagen
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<NewsInteractionProvider>(
                    builder: (context, provider, child) {
                      final isFav = provider.isFavorite(article.id);
                      
                      return ClipOval(
                        child: Material(
                          color: Colors.black.withAlpha(80), // Fondo semitransparente oscuro
                          child: InkWell(
                            onTap: () {
                              provider.toggleFavorite(article);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? const Color(0xFFE91E63) : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
              
            // Contenido de la noticia
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila de metadatos (Fuente y Fecha)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge de la fuente
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(153),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      
                      // Fecha de publicación
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRelativeTime(article.publishedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Título
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback(ThemeData theme) {
    return Container(
      height: 160,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
          ),
          const SizedBox(height: 8),
          Text(
            'Imagen no disponible',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }
}
