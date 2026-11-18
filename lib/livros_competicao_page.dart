import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ranking_competicao_page.dart';
import 'leitura_service.dart';
import 'meus_livros_page.dart';

/// Livros recomendados ou definidos pelo organizador de uma competição.
/// Funciona também para competições sem livro obrigatório.
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

  static const Color cafe = Color(0xFF5D4037);
  static const Color marrom = Color(0xFF795548);
  static const Color papel = Color(0xFFF5EFE3);

  DocumentReference<Map<String, dynamic>> get _clube =>
      FirebaseFirestore.instance.collection('clubes').doc(clubeId);

  CollectionReference<Map<String, dynamic>> get _livros =>
      _clube.collection('competicoes').doc(competicaoId).collection('livros');

  Future<void> _cadastrar(BuildContext context) async {
    final sucesso = await showDialog<bool>(
      context: context,
      builder: (_) => _NovoLivroCompeticaoDialog(livros: _livros),
    );
    if (context.mounted && sucesso == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro adicionado à competição.')),
      );
    }
  }

  Future<void> _adicionarBiblioteca(
    BuildContext context,
    Map<String, dynamic> livro,
  ) async {
    try {
      final titulo = (livro['titulo'] as String? ?? '').trim();
      final autor = (livro['autor'] as String? ?? '').trim();
      final total = livro['totalPaginas'] as int? ?? 0;
      if (titulo.isEmpty || total <= 0) {
        throw StateError('Livro compartilhado inválido.');
      }

      // Consulta evita duplicação na maior parte dos casos. Para garantia
      // absoluta sob concorrência, migrar para ID canônico no catálogo.
      final existentes = await LeituraService.livros
          .where('titulo', isEqualTo: titulo)
          .get();
      final jaExiste = existentes.docs.any((doc) {
        final dado = doc.data();
        return (dado['autor'] as String? ?? '').trim().toLowerCase() ==
            autor.toLowerCase();
      });
      if (jaExiste) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este livro já está na sua biblioteca.'),
            ),
          );
        }
        return;
      }
      await LeituraService.cadastrarLivro(
        titulo: titulo,
        autor: autor,
        totalPaginas: total,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro adicionado à sua biblioteca!')),
      );
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível adicionar o livro: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: papel,

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
        stream: _clube.snapshots(),
        builder: (context, clubeSnapshot) {
          if (clubeSnapshot.hasError) {
            return const Center(child: Text('Erro ao carregar o clube.'));
          }
          if (!clubeSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clube = clubeSnapshot.data!.data();
          if (clube == null) {
            return const Center(child: Text('Clube não encontrado.'));
          }
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final podeCadastrar = uid != null && clube['criadorId'] == uid;
          // Quando o sistema tiver administradores, ampliar este teste
          // nas regras e na interface para admins autorizados.

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _livros.orderBy('criadoEm', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar livros.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final documentos = snapshot.data!.docs;
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Livros da competição',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cafe,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicione à sua biblioteca para acompanhar o progresso. '
                    'Cada participante mantém sua própria página atual.',
                    style: TextStyle(color: marrom),
                  ),
                  if (podeCadastrar) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _cadastrar(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar livro da competição'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (documentos.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Text('Nenhum livro compartilhado ainda.'),
                      ),
                    ),
                  for (final documento in documentos)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: cafe,
                                  size: 34,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        documento.data()['titulo'] ?? 'Livro',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: cafe,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${documento.data()['autor'] ?? ''} • '
                                        '${documento.data()['totalPaginas'] ?? 0} páginas',
                                        style: const TextStyle(color: marrom),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _adicionarBiblioteca(
                                  context,
                                  documento.data(),
                                ),
                                icon: const Icon(Icons.library_add_outlined),
                                label: const Text(
                                  'Adicionar à minha biblioteca',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MeusLivrosPage()),
                    ),
                    icon: const Icon(Icons.library_books_outlined),
                    label: const Text('Abrir minha biblioteca'),
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

class _NovoLivroCompeticaoDialog extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> livros;
  const _NovoLivroCompeticaoDialog({required this.livros});

  @override
  State<_NovoLivroCompeticaoDialog> createState() =>
      _NovoLivroCompeticaoDialogState();
}

class _NovoLivroCompeticaoDialogState
    extends State<_NovoLivroCompeticaoDialog> {
  final formKey = GlobalKey<FormState>();
  final titulo = TextEditingController();
  final autor = TextEditingController();
  final paginas = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void dispose() {
    titulo.dispose();
    autor.dispose();
    paginas.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (salvando || !formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await widget.livros.add({
        'titulo': titulo.text.trim(),
        'autor': autor.text.trim(),
        'totalPaginas': int.parse(paginas.text.trim()),
        'criadoPor': uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => erro = '$e');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo livro da competição'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titulo,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: autor,
                decoration: const InputDecoration(labelText: 'Autor'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o autor' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: paginas,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total de páginas',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return n == null || n <= 0 ? 'Informe um total válido' : null;
                },
              ),
              if (erro != null) ...[
                const SizedBox(height: 12),
                Text(erro!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvar,
          child: Text(salvando ? 'Salvando...' : 'Cadastrar'),
        ),
      ],
    );
  }
}
