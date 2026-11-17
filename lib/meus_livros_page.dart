
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'leitura_service.dart';

class MeusLivrosPage extends StatelessWidget {
  const MeusLivrosPage({super.key});

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);
  static const papel = Color(0xFFFFFCF7);

  Future<void> cadastrar(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => const _CadastroLivroDialog(),
    );

    if (resultado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro cadastrado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Minha biblioteca'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => cadastrar(context),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: LeituraService.observarLivros(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar a biblioteca.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final livros = snapshot.data!.docs;

          if (livros.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 65,
                      color: marrom,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Sua biblioteca está esperando!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: cafe,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cadastre seu primeiro livro.',
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: livros.length,
            itemBuilder: (context, index) {
              final documento = livros[index];
              final dados = documento.data();

              final titulo = dados['titulo'] as String? ?? '';
              final autor = dados['autor'] as String? ?? '';
              final total =
                  (dados['totalPaginas'] as num?)?.toInt() ?? 1;
              final atual =
                  (dados['paginaAtual'] as num?)?.toInt() ?? 0;
              final status =
                  dados['status'] as String? ?? 'quero_ler';

              final progresso =
                  total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.0;

              final statusTexto = switch (status) {
                'lendo' => 'Lendo',
                'concluido' => 'Concluído',
                _ => 'Quero ler',
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 62,
                            height: 86,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7D7C2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.book_rounded,
                              size: 34,
                              color: cafe,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: cafe,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  autor.isEmpty
                                      ? 'Autor não informado'
                                      : autor,
                                  style: const TextStyle(
                                    color: marrom,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  statusTexto,
                                  style: const TextStyle(
                                    color: marrom,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progresso,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: const Color(0xFFE7D7C2),
                        color: marrom,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$atual de $total páginas • '
                        '${(progresso * 100).round()}%',
                        style: const TextStyle(
                          color: marrom,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (status != 'concluido')
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (status == 'quero_ler') {
                                try {
                                  await LeituraService.iniciarLivro(
                                    documento.id,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Erro: $e'),
                                    ),
                                  );
                                }
                              } else {
                                await showDialog<bool>(
                                  context: context,
                                  builder: (_) => _RegistrarLeituraDialog(
                                    livroId: documento.id,
                                    paginaAtual: atual,
                                    totalPaginas: total,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              status == 'quero_ler'
                                  ? Icons.play_arrow_rounded
                                  : Icons.edit_note_rounded,
                            ),
                            label: Text(
                              status == 'quero_ler'
                                  ? 'Começar leitura'
                                  : 'Registrar páginas',
                            ),
                          ),
                        )
                      else
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: marrom,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Leitura concluída!',
                              style: TextStyle(
                                color: cafe,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CadastroLivroDialog extends StatefulWidget {
  const _CadastroLivroDialog();

  @override
  State<_CadastroLivroDialog> createState() =>
      _CadastroLivroDialogState();
}

class _CadastroLivroDialogState
    extends State<_CadastroLivroDialog> {
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

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      await LeituraService.cadastrarLivro(
        titulo: titulo.text,
        autor: autor.text,
        totalPaginas: int.parse(paginas.text.trim()),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => erro = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cadastrar livro'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titulo,
                decoration: const InputDecoration(
                  labelText: 'Título',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe o título'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: autor,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                ),
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
                  return n == null || n <= 0
                      ? 'Informe um número válido'
                      : null;
                },
              ),
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
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvar,
          child: Text(salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}

class _RegistrarLeituraDialog extends StatefulWidget {
  final String livroId;
  final int paginaAtual;
  final int totalPaginas;

  const _RegistrarLeituraDialog({
    required this.livroId,
    required this.paginaAtual,
    required this.totalPaginas,
  });

  @override
  State<_RegistrarLeituraDialog> createState() =>
      _RegistrarLeituraDialogState();
}

class _RegistrarLeituraDialogState
    extends State<_RegistrarLeituraDialog> {
  final formKey = GlobalKey<FormState>();
  final paginaController = TextEditingController();

  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    paginaController.text =
        widget.paginaAtual.toString();
  }

  @override
  void dispose() {
    paginaController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (salvando || !formKey.currentState!.validate()) return;

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      final quantidade = await LeituraService.registrarLeitura(
        livroId: widget.livroId,
        novaPagina: int.parse(paginaController.text.trim()),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+$quantidade páginas registradas!',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          erro = e is StateError
              ? e.message
              : 'Não foi possível registrar: $e';
        });
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar leitura'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Você está na página ${widget.paginaAtual} '
              'de ${widget.totalPaginas}.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: paginaController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Página em que parou',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
              validator: (v) {
                final numero = int.tryParse(v?.trim() ?? '');

                if (numero == null ||
                    numero <= widget.paginaAtual ||
                    numero > widget.totalPaginas) {
                  return 'Informe uma página entre '
                      '${widget.paginaAtual + 1} e '
                      '${widget.totalPaginas}.';
                }
                return null;
              },
            ),
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
      actions: [
        TextButton(
          onPressed: salvando
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvar,
          child: Text(salvando ? 'Salvando...' : 'Registrar'),
        ),
      ],
    );
  }
}
