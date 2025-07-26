import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

class ScrapingService {
  Future<Map<String, String>> scrapeNovelData(String urlString) async {
    final Map<String, String> data = {};

    try {
      final url = Uri.parse(urlString);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final document = html.parse(response.body);

        // Try to get Open Graph meta tags first, as they are more reliable
        final ogTitle = _getMetaProperty(document, 'og:title');
        final ogImage = _getMetaProperty(document, 'og:image');
        final ogDescription = _getMetaProperty(document, 'og:description');
        final synopsisFromDiv = document.querySelector('#contents-tabpane-about .description')?.text.trim();

        data['title'] = ogTitle ?? document.querySelector('h1')?.text.trim() ?? '';
        data['imageUrl'] = ogImage ?? '';
        data['synopsis'] = synopsisFromDiv ?? ogDescription ?? '';
        
        // As a fallback for image, you could try finding a prominent img tag
        if (data['imageUrl']!.isEmpty) {
            final imgElement = document.querySelector('div.image-section img'); // Example selector
            if (imgElement != null && imgElement.attributes['src'] != null) {
                data['imageUrl'] = imgElement.attributes['src']!;
            }
        }

        // Scrape genres
        final genreElements = document.querySelectorAll('div.genres span.genre');
        if (genreElements.isNotEmpty) {
          data['genres'] = genreElements.map((e) => e.text.trim()).join(', ');
        } else {
          data['genres'] = '';
        }

      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scraping data: $e');
      // Return empty map or rethrow exception to be handled by the caller
      return {};
    }

    return data;
  }

  String? _getMetaProperty(dom.Document document, String property) {
    final element = document.querySelector('meta[property="$property"]');
    return element?.attributes['content'];
  }
} 