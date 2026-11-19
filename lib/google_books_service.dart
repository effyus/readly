
import 'dart:convert';

import 'package:http/http.dart' as http;

class LivroGoogle {
  final String id;
  final String titulo;
  final String autor;
  final int paginas;
  final String? capa;

  const LivroGoogle({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.paginas,
    this.capa,
  });

  factory LivroGoogle.fromJson(Map<String, dynamic> json) {
    final info = Map<String, dynamic>.from(
      json['volumeInfo'] as Map? ?? {},
    );

    final autores = (info['authors'] as List? ?? [])
        .map((autor) => autor.toString())
        .join(', ');

    final imagens = Map<String, dynamic>.from(
      info['imageLinks'] as Map? ?? {},
    );

    final capa = imagens['thumbnail']?.toString();

    return LivroGoogle(
      id: json['id']?.toString() ?? '',
      titulo: info['title']?.toString() ?? 'Sem título',
      autor: autores.isEmpty ? 'Autor não informado' : autores,
      paginas: (info['pageCount'] as num?)?.toInt() ?? 0,
      capa: capa?.replaceFirst('http://', 'https://'),
    );
  }
}

class GoogleBooksService {
  // Configure uma chave de API do Google Books.
  // Passe pelo comando --dart-define, sem gravá-la no código.
  static const _apiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
  );

  static Future<List<LivroGoogle>> pesquisar(String termo) async {
    final texto = termo.trim();

    if (texto.isEmpty) return [];

    final parametros = <String, String>{
      'q': texto,
      'maxResults': '15',
      'printType': 'books',
    };

    if (_apiKey.isNotEmpty) {
      parametros['key'] = _apiKey;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/books/v1/volumes',
      parametros,
    );

    final resposta = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Google Books retornou HTTP ${resposta.statusCode}.',
      );
    }

    final dados = jsonDecode(resposta.body)
        as Map<String, dynamic>;

    final itens = dados['items'] as List? ?? [];

    return itens.map((item) {
      return LivroGoogle.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).where((livro) {
      return livro.id.isNotEmpty &&
          livro.titulo.trim().isNotEmpty;
    }).toList();
  }
}
