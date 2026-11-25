import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'leitura_service.dart';

/// Abre o registro rápido sem trocar de página.
Future<void> abrirRegistroRapido(
  BuildContext context, {
  required String clubeId,
  required String competicaoId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFF5EFE3),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _RegistroRapidoSheet(
      clubeId: clubeId,
      competicaoId: competicaoId,
    ),
  );
}

class _RegistroRapidoSheet extends StatefulWidget {
  final String clubeId;
  final String competicaoId;
  const _RegistroRapidoSheet({
    required this.clubeId,
    required this.competicaoId,
  });

  @override
  State<_RegistroRapidoSheet> createState() => _RegistroRapidoSheetState();
}

class _RegistroRapidoSheetState extends State<_RegistroRapidoSheet> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const borda = Color(0xFFD8C7AE);
  static const papel = Color(0xFFFFFCF7);

  final paginaController = TextEditingController();
  String? oficialSelecionado;
  bool salvando = false;
  String? erro;

  @override
  void dispose() {
    paginaController.dispose();
    super.dispose();
  }

  void escolherLivro(String id, int paginaAtual) {
    setState(() {
      oficialSelecionado = id;
      paginaController.text = paginaAtual.toString();
      erro = null;
    });
  }

  Future<void> registrar({
    required String livroOficialId,
    required String livroId,
    required int paginaAtual,
    required int totalPaginas,
  }) async {
    if (salvando) return;
    final novaPagina = int.tryParse(paginaController.text.trim());
    if (novaPagina == null ||
        novaPagina <= paginaAtual ||
        novaPagina > totalPaginas) {
      setState(() {
        erro = 'Informe uma página entre ${paginaAtual + 1} e $totalPaginas.';
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
      final firestore = FirebaseFirestore.instance;
      final competicaoRef = firestore
          .collection('clubes')
          .doc(widget.clubeId)
          .collection('competicoes')
          .doc(widget.competicaoId);
      final inscricaoRef = competicaoRef.collection('participantes').doc(uid);
      final oficialRef = competicaoRef.collection('livros').doc(livroOficialId);
      final pessoalRef = LeituraService.livros.doc(livroId);
      final leituraRef = LeituraService.leituras.doc();
      final registroRef = competicaoRef
          .collection('registros')
          .doc('${uid}_${leituraRef.id}');
      final hoje = LeituraService.diaLocal(DateTime.now());

      final quantidade = await firestore.runTransaction<int>((tx) async {
        // Firestore exige todas as leituras antes de qualquer escrita.
        final inscricao = await tx.get(inscricaoRef);
        final competicao = await tx.get(competicaoRef);
        final oficial = await tx.get(oficialRef);
        final pessoal = await tx.get(pessoalRef);

        if (!inscricao.exists) {
          throw StateError('Participe da competição antes de registrar.');
        }
        if (!competicao.exists || !oficial.exists || !pessoal.exists) {
          throw StateError('Livro ou competição não encontrado.');
        }

        final dadosComp = competicao.data()!;
        final inicioCampo = dadosComp['criadoEm'];
        final duracao = (dadosComp['duracaoDias'] as num?)?.toInt() ?? 0;
        if (inicioCampo is! Timestamp || duracao <= 0) {
          throw StateError('Período da competição inválido.');
        }
        final inicio = inicioCampo.toDate();
        final fim = inicio.add(Duration(days: duracao));
        final agora = DateTime.now();
        final status = dadosComp['status'] as String?;
        if (dadosComp['excluido'] == true ||
            agora.isBefore(inicio) ||
            !agora.isBefore(fim) ||
            ['concluida', 'cancelada', 'agendada'].contains(status)) {
          throw StateError('A competição não está ativa.');
        }

        final dadosLivro = pessoal.data()!;
        if (dadosLivro['removido'] == true) {
          throw StateError('Este livro foi removido da biblioteca.');
        }
        final anterior = (dadosLivro['paginaAtual'] as num?)?.toInt() ?? 0;
        final total = (dadosLivro['totalPaginas'] as num?)?.toInt() ?? 0;
        if (novaPagina <= anterior || novaPagina > total) {
          throw StateError('O progresso mudou. Escolha a página novamente.');
        }
        final paginas = novaPagina - anterior;

        tx.update(pessoalRef, {
          'paginaAtual': novaPagina,
          'status': novaPagina == total ? 'concluido' : 'lendo',
        });
        tx.set(leituraRef, {
          'livroId': livroId,
          'paginaAnterior': anterior,
          'paginaAtual': novaPagina,
          'paginasLidas': paginas,
          'diaLocal': hoje,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        tx.set(registroRef, {
          'usuarioId': uid,
          'livroId': livroId,
          'livroOficialId': livroOficialId,
          'leituraId': leituraRef.id,
          'paginasLidas': paginas,
          'diaLocal': hoje,
          'criadoEm': FieldValue.serverTimestamp(),
        });
        return paginas;
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$quantidade páginas registradas!')),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => erro = e.code == 'permission-denied'
            ? 'O Firestore não permitiu o registro. Confira sua inscrição e o período.'
            : 'Erro do Firestore: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget _espera() => const Center(child: CircularProgressIndicator());

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Text('Faça login novamente.'),
      );
    }

    final compRef = FirebaseFirestore.instance
        .collection('clubes')
        .doc(widget.clubeId)
        .collection('competicoes')
        .doc(widget.competicaoId);

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borda,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Registrar leitura',
                    style: TextStyle(
                      color: cafe,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: cafe),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: compRef.collection('participantes').doc(uid).snapshots(),
              builder: (context, inscricao) {
                if (inscricao.hasError) {
                  return const Center(child: Text('Erro ao consultar sua inscrição.'));
                }
                if (!inscricao.hasData) return _espera();
                if (!inscricao.data!.exists) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Participe da competição para registrar leituras.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: compRef.collection('livros').snapshots(),
                  builder: (context, oficiaisSnap) {
                    if (oficiaisSnap.hasError) {
                      return const Center(child: Text('Erro ao carregar livros oficiais.'));
                    }
                    if (!oficiaisSnap.hasData) return _espera();
                    final oficiais = oficiaisSnap.data!.docs;
                    if (oficiais.isEmpty) {
                      return const Center(child: Text('A competição ainda não possui livros.'));
                    }
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: LeituraService.observarLivros(),
                      builder: (context, bibliotecaSnap) {
                        if (bibliotecaSnap.hasError) {
                          return const Center(child: Text('Erro ao carregar biblioteca.'));
                        }
                        if (!bibliotecaSnap.hasData) return _espera();
                        final biblioteca = {
                          for (final doc in bibliotecaSnap.data!.docs)
                            doc.id: doc.data(),
                        };
                        final disponiveis = <({
                          String oficialId,
                          String livroId,
                          String titulo,
                          String autor,
                          String? capaUrl,
                          int atual,
                          int total,
                          bool removido,
                        })>[];
                        for (final oficial in oficiais) {
                          final id = '${widget.clubeId}_${widget.competicaoId}_${oficial.id}';
                          final pessoal = biblioteca[id];
                          if (pessoal == null) continue;
                          final atual = (pessoal['paginaAtual'] as num?)?.toInt() ?? 0;
                          final total = (pessoal['totalPaginas'] as num?)?.toInt() ?? 0;
                          disponiveis.add((
                            oficialId: oficial.id,
                            livroId: id,
                            titulo: (oficial.data()['titulo'] as String?) ?? 'Livro',
                            autor: (oficial.data()['autor'] as String?) ?? '',
                            capaUrl: (oficial.data()['capaUrl'] as String?) ??
                                (pessoal['capaUrl'] as String?),
                            atual: atual,
                            total: total,
                            removido: pessoal['removido'] == true,
                          ));
                        }
                        final ativos = disponiveis.where(
                          (livro) => !livro.removido && livro.total > livro.atual,
                        ).toList();
                        if (ativos.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Nenhum livro disponível para registrar. '
                                'Confira se os livros oficiais foram adicionados à sua biblioteca.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final selecionado = ativos.where(
                          (livro) => livro.oficialId == oficialSelecionado,
                        );
                        final atual = selecionado.isEmpty ? null : selecionado.first;
                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                            20, 8, 20,
                            MediaQuery.viewInsetsOf(context).bottom + 24,
                          ),
                          children: [
                            const Text(
                              'Qual livro você leu?',
                              style: TextStyle(
                                color: cafe,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...ativos.map((livro) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: livro.oficialId == oficialSelecionado
                                    ? const Color(0xFFE7D7C2)
                                    : papel,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onTap: salvando ? null : () => escolherLivro(
                                    livro.oficialId, livro.atual,
                                  ),
                                  leading: _CapaLivroRapida(url: livro.capaUrl),
                                  title: Text(
                                    livro.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('${livro.atual} de ${livro.total} páginas'),
                                  trailing: Icon(
                                    livro.oficialId == oficialSelecionado
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: marrom,
                                  ),
                                ),
                              ),
                            )),
                            if (atual != null) ...[
                              const SizedBox(height: 18),
                              const Text(
                                'Em qual página você parou?',
                                style: TextStyle(
                                  color: cafe,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: paginaController,
                                enabled: !salvando,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Nova página',
                                  helperText: 'Última registrada: ${atual.atual} de ${atual.total}',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() => erro = null),
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: paginaController,
                                builder: (context, valor, _) {
                                  final novaPagina = int.tryParse(valor.text);
                                  final paginas = novaPagina == null
                                      ? 0
                                      : (novaPagina - atual.atual).clamp(0, atual.total);
                                  return Text(
                                    '+$paginas páginas nesta leitura',
                                    style: const TextStyle(
                                      color: marrom,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                              if (erro != null) ...[
                                const SizedBox(height: 12),
                                Text(erro!, style: const TextStyle(color: Colors.red)),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cafe,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  onPressed: salvando
                                      ? null
                                      : () => registrar(
                                          livroOficialId: atual.oficialId,
                                          livroId: atual.livroId,
                                          paginaAtual: atual.atual,
                                          totalPaginas: atual.total,
                                        ),
                                  icon: salvando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(salvando ? 'Salvando...' : 'Confirmar leitura'),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostra a capa cadastrada na API Google Books; usa ícone quando indisponível.
class _CapaLivroRapida extends StatelessWidget {
  final String? url;
  const _CapaLivroRapida({required this.url});

  @override
  Widget build(BuildContext context) {
    final original = url?.trim();
    final uri = original == null ? null : Uri.tryParse(original);
    final segura = uri != null &&
            uri.hasAuthority &&
            (uri.scheme == 'https' || uri.scheme == 'http')
        ? uri.replace(scheme: 'https').toString()
        : null;

    Widget substituta() => Container(
      width: 48,
      height: 65,
      color: const Color(0xFFE7D7C2),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF5D4037)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 48,
        height: 65,
        child: segura == null
            ? substituta()
            : Image.network(
                segura,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => substituta(),
              ),
      ),
    );
  }
}
