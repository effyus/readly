
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeusLivrosPage extends StatelessWidget {
  const MeusLivrosPage({super.key});

  CollectionReference<Map<String, dynamic>> get livros {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('livros');
  }

  Future<void> cadastrarLivro(
    BuildContext context,
  ) async {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final autorController = TextEditingController();
    final paginasController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool salvando = false;

          return StatefulBuilder(
            builder: (contextDialog, atualizarDialog) {
              return AlertDialog(
                title: const Text('Cadastrar livro'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: tituloController,
                          decoration: const InputDecoration(
                            labelText: 'Título do livro',
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Informe o título';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: autorController,
                          decoration: const InputDecoration(
                            labelText: 'Autor',
                          ),
                        ),
                        TextFormField(
                          controller: paginasController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total de páginas',
                          ),
                          validator: (valor) {
                            final paginas =
                                int.tryParse(valor ?? '');

                            if (paginas == null || paginas <= 0) {
                              return 'Informe um total válido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: salvando
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            atualizarDialog(
                              () => salvando = true,
                            );

                            try {
                              await livros.add({
                                'titulo':
                                    tituloController.text.trim(),
                                'autor':
                                    autorController.text.trim(),
                                'totalPaginas': int.parse(
                                  paginasController.text.trim(),
                                ),
                                'criadoEm':
                                    FieldValue.serverTimestamp(),
                              });

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (erro) {
                              atualizarDialog(
                                () => salvando = false,
                              );

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao salvar livro: $erro',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(
                      salvando ? 'Salvando...' : 'Salvar',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      tituloController.dispose();
      autorController.dispose();
      paginasController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Faça login para ver seus livros.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE3),
      appBar: AppBar(
        title: const Text('Meus livros'),
        backgroundColor: const Color(0xFFF5EFE3),
        foregroundColor: const Color(0xFF5D4037),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => cadastrarLivro(context),
        backgroundColor: const Color(0xFF795548),
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

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não cadastrou livros.\n'
                  'Toque em "Cadastrar livro" para começar!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documentos.length,
            itemBuilder: (context, indice) {
              final livro = documentos[indice].data();

              return Card(
                color: const Color(0xFFFFFCF7),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7D7C2),
                    child: Icon(
                      Icons.menu_book,
                      color: Color(0xFF795548),
                    ),
                  ),
                  title: Text(
                    livro['titulo'] ?? 'Livro sem título',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${livro['autor'] ?? 'Autor não informado'}\n'
                    '${livro['totalPaginas']} páginas',
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
