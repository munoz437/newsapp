import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  
  // Obtiene la API key desde las variables de entorno de Dart a través de --dart-define
  final String _apiKey = const String.fromEnvironment('NEWS_API_KEY');

  Future<List<Article>> getTopHeadlines({String category = 'general'}) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'API Key de NewsAPI no configurada.\n\n'
        'Por favor, inicia la aplicación pasando tu API Key de la siguiente manera:\n'
        'flutter run --dart-define=NEWS_API_KEY=tu_api_key_aqui'
      );
    }

    // Para NewsAPI.org, 'top-headlines' requiere country, category, sources o q.
    // Usaremos 'us' por defecto para asegurar resultados estables en todas las categorías.
    final Uri url = Uri.parse('$_baseUrl/top-headlines?country=us&category=$category&apiKey=$_apiKey');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'ok') {
          final List<dynamic> articlesJson = data['articles'] ?? [];
          
          // Mapeamos los artículos válidos (ignorando los que no tienen título o están eliminados)
          final List<Article> articles = articlesJson
              .map((json) => Article.fromJson(json))
              .where((article) => article.title != '[Removed]' && article.title.isNotEmpty)
              .toList();
              
          return articles;
        } else {
          throw Exception(data['message'] ?? 'Error desconocido de la API.');
        }
      } else {
        // NewsAPI devuelve un cuerpo con el mensaje de error detallado
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error de servidor con código: ${response.statusCode}');
        } catch (_) {
          throw Exception('Error al obtener noticias. Código HTTP: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('No se pudo conectar al servidor. Revisa tu conexión a internet.');
      }
      rethrow;
    }
  }
}
