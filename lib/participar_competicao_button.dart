import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParticiparCompeticaoButton extends StatefulWidget {
  final String clubeId;
  final String competicaoId;

  const ParticiparCompeticaoButton({
    super.key,
    required this.clubeId,
    required this.competicaoId,
  });

  @override
  State<ParticiparCompeticaoButton> createState() =>
      _ParticiparCompeticaoButtonState();
}

class _ParticiparCompeticaoButtonState
    extends State<ParticiparCompeticaoButton> {
  bool processando = false;

  final firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get competicaoRef => firestore
      .collection('clubes')
      .doc(widget.clubeId)
      .collection('competicoes')
      .doc(widget.competicaoId);

  DocumentReference<Map<String, dynamic>> get inscricaoRef =>
      competicaoRef.collection('participantes').doc(uid);

  void avisar(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> importarLivros() async {
    final usuarioId = uid;

    if (usuarioId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final livrosOficiais = await competicaoRef.collection('livros').get();

    final biblioteca = firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('livros');

    for (final documento in livrosOficiais.docs) {
      final dados = documento.data();

      // ID fixo: evita criar o mesmo livro duas
      // vezes nesta mesma competição.
      final idBiblioteca =
          '${widget.clubeId}_${widget.competicaoId}_${documento.id}';

      final livroRef = biblioteca.doc(idBiblioteca);
      final livroExistente = await livroRef.get();

      // Preserva progresso de livros já importados.

      if (livroExistente.exists) {
        final dadosAtuais = livroExistente.data() ?? {};
        final atualizacoes = <String, dynamic>{};

        final capa = dados['capaUrl'] as String?;
        final googleId = dados['googleBooksId'] as String?;

        if (capa != null && capa.isNotEmpty && dadosAtuais['capaUrl'] != capa) {
          atualizacoes['capaUrl'] = capa;
        }

        if (googleId != null &&
            googleId.isNotEmpty &&
            dadosAtuais['googleBooksId'] != googleId) {
          atualizacoes['googleBooksId'] = googleId;
        }

        if (atualizacoes.isNotEmpty) {
          await livroRef.update(atualizacoes);
        }

        continue;
      }

      final titulo = dados['titulo'] as String? ?? '';
      final autor = dados['autor'] as String? ?? '';
      final total = (dados['totalPaginas'] as num?)?.toInt() ?? 0;

      if (titulo.trim().isEmpty || total <= 0) continue;

      final capaUrl = dados['capaUrl'] as String?;
      final googleBooksId = dados['googleBooksId'] as String?;

      final livroImportado = <String, dynamic>{
        'titulo': titulo,
        'autor': autor,
        'totalPaginas': total,
        'paginaAtual': 0,
        'status': 'quero_ler',
        'criadoEm': FieldValue.serverTimestamp(),
      };

      if (capaUrl != null && capaUrl.isNotEmpty) {
        livroImportado['capaUrl'] = capaUrl;
      }

      if (googleBooksId != null && googleBooksId.isNotEmpty) {
        livroImportado['googleBooksId'] = googleBooksId;
      }

      await livroRef.set(livroImportado);
    }
  }

  Future<void> participar() async {
    if (processando || uid == null) return;

    setState(() => processando = true);

    try {
      final perfil = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final nome = (perfil.data()?['nome'] as String? ?? '').trim();
      final inscricao = await inscricaoRef.get();

      if (!inscricao.exists) {
        await inscricaoRef.set({
          'uid': uid,
          'inscritoEm': FieldValue.serverTimestamp(),
        });
        await inscricaoRef.set({
          'uid': uid,
          'inscritoEm': FieldValue.serverTimestamp(),
          if (nome.isNotEmpty)
            'nome': nome.length > 60 ? nome.substring(0, 60) : nome,
        });
      }

      // Importa os livros sem sobrescrever progresso.
      await importarLivros();

      avisar('Livros oficiais adicionados à sua biblioteca!');
    } on FirebaseException catch (e) {
      avisar(
        e.code == 'permission-denied'
            ? 'Permissão negada. Confira as novas regras do Firestore.'
            : 'Erro no Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      avisar('Não foi possível concluir: $e');
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Text('Faça login para participar.');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: inscricaoRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Não foi possível consultar sua inscrição.');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final inscrito = snapshot.data!.exists;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inscrito)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF795548)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Você participa desta competição!')),
                  ],
                ),
              ),

            FilledButton.icon(
              onPressed: processando ? null : participar,
              icon: Icon(
                inscrito ? Icons.sync_rounded : Icons.emoji_events_rounded,
              ),
              label: Text(
                processando
                    ? 'Processando...'
                    : inscrito
                    ? 'Sincronizar livros oficiais'
                    : 'Participar da competição',
              ),
            ),
          ],
        );
      },
    );
  }
}
