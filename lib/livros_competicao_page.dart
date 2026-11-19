
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'google_books_service.dart';
import 'ranking_competicao_page.dart';

class LivrosCompeticaoPage extends StatelessWidget {
  final String clubeId;
  final String competicaoId;
  final String nomeCompeticao;

  const LivrosCompeticaoPage({
    super.key,
    required this.clubeId,
    required this.competicaoId,
    required this.nomeCompeticao,
  });

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final clubeRef = firestore.collection('clubes').doc(clubeId);
    final livrosRef = clubeRef
        .collection('competicoes')
        .doc(competicaoId)
        .collection('livros');

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: Text(nomeCompeticao),
        actions: [
          IconButton(
            tooltip: 'Ver ranking',
            icon: const Icon(Icons.emoji_events_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RankingCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: clubeRef.snapshots(),
        builder: (context, clubeSnapshot) {
          if (clubeSnapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar clube.'),
            );
          }
          if (!clubeSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final clube = clubeSnapshot.data!.data();
          if (clube == null) {
            return const Center(
              child: Text('Clube não encontrado.'),
            );
          }

          final usuarioId =
              FirebaseAuth.instance.currentUser?.uid;

          final administrador =
              usuarioId != null &&
              clube['criadorId'] == usuarioId;

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: livrosRef
                .orderBy('criadoEm', descending: true)
                .snapshots(),
            builder: (context, livrosSnapshot) {
              if (livrosSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Não foi possível carregar os livros.',
                  ),
                );
              }
              if (!livrosSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final livros = livrosSnapshot.data!.docs;

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Livros oficiais',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cafe,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estes são os livros definidos para os '
                    'participantes desta competição.',
                    style: TextStyle(color: marrom),
                  ),
                  const SizedBox(height: 18),

                  if (administrador)
                    FilledButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => _CadastrarLivroDialog(
                            livrosRef: livrosRef,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Definir livro oficial'),
                    ),

                  const SizedBox(height: 16),

                  if (livros.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Text(
                          'O administrador ainda não '
                          'definiu os livros.',
                        ),
                      ),
                    ),

                  for (final documento in livros)
                    _CartaoLivro(dados: documento.data()),

                  const SizedBox(height: 14),
                  const Text(
                    'Os livros oficiais serão vinculados '
                    'à biblioteca quando o usuário entrar '
                    'na competição.',
                    style: TextStyle(
                      color: marrom,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CartaoLivro extends StatelessWidget {
  final Map<String, dynamic> dados;

  const _CartaoLivro({required this.dados});

  @override
  Widget build(BuildContext context) {
    final capa = dados['capaUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 86,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: capa != null && capa.startsWith('https://')
                    ? Image.network(
                        capa,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.menu_book, size: 35),
                      )
                    : const ColoredBox(
                        color: Color(0xFFE7D7C2),
                        child: Icon(
                          Icons.menu_book,
                          color: Color(0xFF5D4037),
                          size: 35,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dados['titulo'] as String? ?? 'Livro',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(dados['autor'] as String? ?? ''),
                  const SizedBox(height: 5),
                  Text(
                    '${dados['totalPaginas'] ?? 0} páginas',
                    style: const TextStyle(
                      color: Color(0xFF795548),
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
}

class _CadastrarLivroDialog extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> livrosRef;

  const _CadastrarLivroDialog({
    required this.livrosRef,
  });

  @override
  State<_CadastrarLivroDialog> createState() =>
      _CadastrarLivroDialogState();
}

class _CadastrarLivroDialogState
    extends State<_CadastrarLivroDialog> {
  final titulo = TextEditingController();
  final autor = TextEditingController();
  final paginas = TextEditingController();
  final pesquisa = TextEditingController();

  bool modoGoogle = true;
  bool buscando = false;
  bool salvando = false;

  String? erro;
  String? googleId;
  String? capaUrl;

  List<LivroGoogle> resultados = [];

  @override
  void dispose() {
    titulo.dispose();
    autor.dispose();
    paginas.dispose();
    pesquisa.dispose();
    super.dispose();
  }

  Future<void> buscar() async {
    if (pesquisa.text.trim().isEmpty || buscando) return;

    setState(() {
      buscando = true;
      erro = null;
      resultados = [];
    });

    try {
      final livros = await GoogleBooksService.pesquisar(
        pesquisa.text,
      );

      if (!mounted) return;

      setState(() {
        resultados = livros;
        if (livros.isEmpty) {
          erro = 'Nenhum livro encontrado.';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => erro = 'Erro na pesquisa: $e');
      }
    } finally {
      if (mounted) setState(() => buscando = false);
    }
  }

  void selecionarLivro(LivroGoogle livro) {
    setState(() {
      titulo.text = livro.titulo;
      autor.text = livro.autor;
      paginas.text =
          livro.paginas > 0 ? livro.paginas.toString() : '';
      googleId = livro.id;
      capaUrl = livro.capa;
      resultados = [];
    });
  }

  void alterarModo(bool novoModo) {
    setState(() {
      modoGoogle = novoModo;
      googleId = null;
      capaUrl = null;
      titulo.clear();
      autor.clear();
      paginas.clear();
      erro = null;
      resultados = [];
    });
  }

  Future<void> salvar() async {
    if (salvando) return;

    final nome = titulo.text.trim();
    final nomeAutor = autor.text.trim();
    final total = int.tryParse(paginas.text.trim());

    if (nome.isEmpty || nomeAutor.isEmpty ||
        total == null || total <= 0 || total > 10000) {
      setState(() {
        erro = 'Informe título, autor e um total '
            'de páginas entre 1 e 10000.';
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => erro = 'Faça login novamente.');
      return;
    }

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      final dados = <String, dynamic>{
        'titulo': nome,
        'autor': nomeAutor,
        'totalPaginas': total,
        'criadoPor': uid,
        'criadoEm': FieldValue.serverTimestamp(),
      };

      if (googleId != null) {
        dados['googleBooksId'] = googleId;
      }

      if (capaUrl != null) {
        dados['capaUrl'] = capaUrl;
      }

      await widget.livrosRef.add(dados);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => erro = 'Erro ao salvar: $e');
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget campo(
    TextEditingController controller,
    String nome, {
    bool numero = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          numero ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: nome,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Definir livro oficial'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.search),
                    label: Text('Google Books'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.edit),
                    label: Text('Manual'),
                  ),
                ],
                selected: {modoGoogle},
                onSelectionChanged: (selecionado) {
                  alterarModo(selecionado.first);
                },
              ),
              const SizedBox(height: 16),

              if (modoGoogle) ...[
                campo(pesquisa, 'Título, autor ou ISBN'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: buscando ? null : buscar,
                  icon: const Icon(Icons.search),
                  label: Text(
                    buscando ? 'Pesquisando...' : 'Pesquisar',
                  ),
                ),
                if (buscando)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                for (final livro in resultados)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: livro.capa == null
                        ? const Icon(Icons.book)
                        : Image.network(
                            livro.capa!,
                            width: 42,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.book),
                          ),
                    title: Text(livro.titulo),
                    subtitle: Text(
                      '${livro.autor} • '
                      '${livro.paginas > 0 ? livro.paginas : "Páginas não informadas"}',
                    ),
                    onTap: () => selecionarLivro(livro),
                  ),
                if (googleId != null)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Livro selecionado. Confira os dados:',
                    ),
                  ),
              ],

              // Campos editáveis mesmo após buscar na API.
              if (!modoGoogle || googleId != null) ...[
                const SizedBox(height: 12),
                campo(titulo, 'Título'),
                const SizedBox(height: 10),
                campo(autor, 'Autor'),
                const SizedBox(height: 10),
                campo(
                  paginas,
                  'Total de páginas da edição oficial',
                  numero: true,
                ),
              ],

              if (erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  erro!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ||
                  (modoGoogle && googleId == null)
              ? null
              : salvar,
          child: Text(salvando ? 'Salvando...' : 'Confirmar livro'),
        ),
      ],
    );
  }
}
