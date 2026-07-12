import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/news_service.dart';
import '../widgets/category_selector.dart';
import '../widgets/news_tile.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final NewsService _newsService = NewsService();
  String _selectedCategory = 'general';
  
  // Guardamos el Future en el estado para evitar que se vuelva a disparar 
  // con cada reconstrucción del widget, y poder actualizarlo selectivamente.
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
      // Ignoramos errores aquí ya que el FutureBuilder los manejará en la UI
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Búsqueda disponible en próximas actualizaciones'),
                  duration: Duration(seconds: 2),
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
          // Título de sección de categorías
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
          
          // Selector de categorías
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
                  
                  // Estado: Lista vacía
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

                // Fallback por defecto si nada coincide (no debería ocurrir)
                return const Center(child: Text('Algo salió mal.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
