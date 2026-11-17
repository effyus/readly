import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeusLivrosPage extends StatelessWidget {
  const MeusLivrosPage({super.key});

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);

  Future<void> abrirCadastro(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => const CadastroLivroDialog(),
    );

    if (!context.mounted) return;

    if (resultado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro cadastrado com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para ver seus livros.')),
      );
    }

    final livros = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('livros');

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Minha biblioteca'),
        backgroundColor: fundo,
        foregroundColor: cafe,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirCadastro(context),
        backgroundColor: cafe,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: livros.orderBy('titulo').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar os livros.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documentos = snapshot.data!.docs;

          if (documentos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 70, color: marrom),
                    SizedBox(height: 18),
                    Text(
                      'Sua biblioteca está vazia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: cafe,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Cadastre seu primeiro livro e comece '
                      'a organizar suas leituras.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: marrom, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final livro = documentos[index].data();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFE7D7C2),
                    child: Icon(Icons.menu_book_rounded, color: cafe),
                  ),
                  title: Text(
                    livro['titulo'] ?? 'Livro sem título',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cafe,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${livro['autor'] ?? 'Autor não informado'}\n'
                      '${livro['totalPaginas'] ?? 0} páginas',
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Formulário independente para gerenciar
// corretamente o ciclo de vida dos controladores.

class CadastroLivroDialog extends StatefulWidget {
  const CadastroLivroDialog({super.key});

  @override
  State<CadastroLivroDialog> createState() => _CadastroLivroDialogState();
}

class _CadastroLivroDialogState extends State<CadastroLivroDialog> {
  static const cafe = Color(0xFF5D4037);

  final formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final autorController = TextEditingController();
  final paginasController = TextEditingController();

  bool salvando = false;
  String? mensagemErro;

  @override
  void dispose() {
    tituloController.dispose();
    autorController.dispose();
    paginasController.dispose();
    super.dispose();
  }

  Future<void> salvarLivro() async {
    if (salvando) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      setState(() {
        mensagemErro = 'Você precisa estar conectado.';
      });
      return;
    }

    setState(() {
      salvando = true;
      mensagemErro = null;
    });

    try {
      final livros = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .collection('livros');

      await livros.add({
        'titulo': tituloController.text.trim(),
        'autor': autorController.text.trim(),
        'totalPaginas': int.parse(paginasController.text.trim()),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on FirebaseException catch (erro) {
      if (!mounted) return;

      setState(() {
        mensagemErro = erro.code == 'permission-denied'
            ? 'Permissão negada. Verifique as regras do Firestore.'
            : 'Erro ao salvar: ${erro.message ?? erro.code}';
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        mensagemErro = 'Não foi possível salvar o livro.';
      });

      debugPrint('Erro ao cadastrar livro: $erro');
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: cafe),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cadastrar livro',
              style: TextStyle(fontSize: 20, color: cafe),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: tituloController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título do livro',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o título do livro.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: autorController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: paginasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total de páginas',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (valor) {
                  final numero = int.tryParse(valor?.trim() ?? '');

                  if (numero == null || numero <= 0) {
                    return 'Informe um número válido.';
                  }

                  return null;
                },
              ),

              if (mensagemErro != null) ...[
                const SizedBox(height: 15),
                Text(
                  mensagemErro!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvarLivro,
          child: salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
