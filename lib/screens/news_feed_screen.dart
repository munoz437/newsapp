import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article_model.dart';
import '../providers/news_interaction_provider.dart';
import '../services/news_service.dart';
import '../widgets/category_selector.dart';
import '../widgets/news_tile.dart';
import 'favorites_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final NewsService _newsService = NewsService();
  String _selectedCategory = 'general';
  
  // Guardamos el Future en el estado para evitar que se vuelva a disparar 
  // con cada reconstrucciÃ³n del widget, y poder actualizarlo selectivamente.
  late Future<List<Article>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    _newsFuture = _newsService.getTopHeadlines(category: _selectedCategory);
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _loadNews();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadNews();
    });
    // Esperamos a que el future se complete para ocultar el indicador de refresh
    try {
      await _newsFuture;
    } catch (_) {
      // Ignoramos errores aquÃ­ ya que el FutureBuilder los manejarÃ¡ en la UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'InfoPulse',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [

          Consumer<NewsInteractionProvider>(
            builder: (context, provider, child) {
              final count = provider.favoriteIds.length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  backgroundColor: const Color(0xFFE91E63),
                  textColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_rounded),
                    color: count > 0 ? const Color(0xFFE91E63) : null,
                    tooltip: 'Mis Favoritos',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÃ­tulo de secciÃ³n de categorÃ­as
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Text(
              'Categorías',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          
          // Selector de categorÃ­as
          CategorySelector(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategoryChanged,
          ),
          
          const SizedBox(height: 8),
          
          // Feed de noticias principal
          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                // Estado: Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando últimas noticias...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Estado: Error
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ocurrió un problema',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _loadNews();
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Intentar de nuevo'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Estado: Datos listos
                if (snapshot.hasData) {
                  final articles = snapshot.data!;
                  
                  // Estado: Lista vacÃ­a
                  if (articles.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay noticias disponibles',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No pudimos encontrar noticias en este momento. Desliza hacia abajo para refrescar.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Estado: Con noticias disponibles
                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        return NewsTile(article: articles[index]);
                      },
                    ),
                  );
                }

                // Fallback por defecto si nada coincide
                return const Center(child: Text('Algo salió mal.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
