import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/article_model.dart';
import '../providers/news_interaction_provider.dart';
import '../services/news_service.dart';
import '../widgets/news_tile.dart';

class NewsDetailScreen extends StatelessWidget {
  final Article article;

  const NewsDetailScreen({
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
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con imagen expandible (SliverAppBar)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image-${article.id}',
                child: article.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildImageFallback(theme),
                      )
                    : _buildImageFallback(theme),
              ),
            ),
          ),
          
          // Contenido del artículo
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Metadata: Fuente y fecha
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(153),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.sourceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRelativeTime(article.publishedAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  article.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const Divider(height: 32),
                
                Text(
                  article.url != null 
                      ? 'Esta es una simulación del contenido detallado de la noticia. Para leer el artículo original, puedes visitar la fuente oficial de ${article.sourceName}.\n\nAquí se presentaría el texto completo de la noticia consumido desde el servidor o el scraper correspondiente. El diseño es responsivo y respeta los lineamientos visuales del sistema.'
                      : 'El contenido para esta noticia no se encuentra disponible.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withAlpha(220),
                  ),
                ),
                
                // Sección de noticias relacionadas
                _RelatedNewsSection(currentArticleId: article.id),
                
                const SizedBox(height: 80), // Espacio para que el scroll libre la barra inferior
              ]),
            ),
          ),
        ],
      ),
      
      // Barra inferior de interacciones
      bottomNavigationBar: Consumer<NewsInteractionProvider>(
        builder: (context, provider, child) {
          final isFav = provider.isFavorite(article.id);
          final currentVote = provider.getVote(article.id);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(102),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Me Gusta
                  _InteractionButton(
                    isActive: currentVote == VoteType.like,
                    activeColor: theme.colorScheme.primary,
                    activeIcon: Icons.thumb_up_rounded,
                    inactiveIcon: Icons.thumb_up_outlined,
                    label: 'Me gusta',
                    onTap: () => provider.vote(article.id, VoteType.like),
                  ),
                  
                  // Botón No Me Gusta
                  _InteractionButton(
                    isActive: currentVote == VoteType.dislike,
                    activeColor: theme.colorScheme.error,
                    activeIcon: Icons.thumb_down_rounded,
                    inactiveIcon: Icons.thumb_down_outlined,
                    label: 'No me gusta',
                    onTap: () => provider.vote(article.id, VoteType.dislike),
                  ),
                  
                  // Divider vertical sutil
                  Container(
                    height: 24,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  
                  // Botón Favorito
                  _InteractionButton(
                    isActive: isFav,
                    activeColor: const Color(0xFFE91E63), // Color rosado/rojo premium para favoritos
                    activeIcon: Icons.favorite_rounded,
                    inactiveIcon: Icons.favorite_outline_rounded,
                    label: 'Favorito',
                    onTap: () => provider.toggleFavorite(article),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
            ),
            const SizedBox(height: 12),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.isActive,
    required this.activeColor,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? activeColor : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey<bool>(isActive),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedNewsSection extends StatefulWidget {
  final String currentArticleId;

  const _RelatedNewsSection({required this.currentArticleId});

  @override
  State<_RelatedNewsSection> createState() => _RelatedNewsSectionState();
}

class _RelatedNewsSectionState extends State<_RelatedNewsSection> {
  final NewsService _newsService = NewsService();
  late Future<List<Article>> _relatedNewsFuture;

  @override
  void initState() {
    super.initState();
    // Podríamos pasar una categoría si el Article la tuviera. Usamos top headlines generales por ahora.
    _relatedNewsFuture = _newsService.getTopHeadlines();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FutureBuilder<List<Article>>(
      future: _relatedNewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final relatedArticles = snapshot.data!
            .where((a) => a.id != widget.currentArticleId)
            .take(3)
            .toList();

        if (relatedArticles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              'Noticias relacionadas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...relatedArticles.map((article) => NewsTile(
                  article: article,
                  margin: const EdgeInsets.only(bottom: 16),
                )).toList(),
          ],
        );
      },
    );
  }
}
