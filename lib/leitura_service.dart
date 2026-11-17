
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeituraService {
  static String get uid {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw StateError('Usuário não autenticado');
    }
    return usuario.uid;
  }

  static CollectionReference<Map<String, dynamic>> get livros =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('livros');

  static CollectionReference<Map<String, dynamic>> get leituras =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('leituras');

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      observarLivros() => livros.orderBy('titulo').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      observarLeituras() => leituras.snapshots();

  static Future<void> cadastrarLivro({
    required String titulo,
    required String autor,
    required int totalPaginas,
  }) async {
    await livros.add({
      'titulo': titulo.trim(),
      'autor': autor.trim(),
      'totalPaginas': totalPaginas,
      'paginaAtual': 0,
      'status': 'quero_ler',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> iniciarLivro(String livroId) async {
  await livros.doc(livroId).update({
    'status': 'lendo',
    'paginaAtual': 0,
  });
}

  static String diaLocal(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  static Future<int> registrarLeitura({
    required String livroId,
    required int novaPagina,
  }) async {
    final usuarioId = uid;
    final livroRef = livros.doc(livroId);
    final leituraRef = leituras.doc();
    final hoje = diaLocal(DateTime.now());

    return FirebaseFirestore.instance.runTransaction<int>(
      (transaction) async {
        final snapshot = await transaction.get(livroRef);

        if (!snapshot.exists) {
          throw StateError('Livro não encontrado.');
        }

        final dados = snapshot.data()!;
        final paginaAnterior =
            (dados['paginaAtual'] as num?)?.toInt() ?? 0;
        final total =
            (dados['totalPaginas'] as num).toInt();

        if (novaPagina <= paginaAnterior) {
          throw StateError(
            'A nova página deve ser maior que a atual.',
          );
        }

        if (novaPagina > total) {
          throw StateError(
            'A página não pode ultrapassar o total do livro.',
          );
        }

        final quantidade = novaPagina - paginaAnterior;

        transaction.update(livroRef, {
          'paginaAtual': novaPagina,
          'status': novaPagina == total
              ? 'concluido'
              : 'lendo',
        });

        transaction.set(leituraRef, {
          'livroId': livroId,
          'paginaAnterior': paginaAnterior,
          'paginaAtual': novaPagina,
          'paginasLidas': quantidade,
          'diaLocal': hoje,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        return quantidade;
      },
    );
  }

  static int calcularOfensiva(
    Iterable<Map<String, dynamic>> registros,
  ) {
    final dias = registros
        .map((registro) => registro['diaLocal'])
        .whereType<String>()
        .toSet();

    final agora = DateTime.now();
    var dia = DateTime.utc(
      agora.year,
      agora.month,
      agora.day,
    );

    String chave(DateTime data) => diaLocal(data);

    // Mantém a ofensiva durante o dia atual,
    // mesmo se a pessoa ainda não leu hoje.
    if (!dias.contains(chave(dia))) {
      dia = dia.subtract(const Duration(days: 1));
    }

    int sequencia = 0;

    while (dias.contains(chave(dia))) {
      sequencia++;
      dia = dia.subtract(const Duration(days: 1));
    }

    return sequencia;
  }
}
