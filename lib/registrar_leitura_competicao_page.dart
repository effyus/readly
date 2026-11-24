import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'leitura_service.dart';

class RegistrarLeituraCompeticaoPage extends StatelessWidget {
  final String clubeId;
  final String competicaoId;

  const RegistrarLeituraCompeticaoPage({
    super.key,
    required this.clubeId,
    required this.competicaoId,
  });

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Faça login novamente.')));
    }

    final competicaoRef = FirebaseFirestore.instance
        .collection('clubes')
        .doc(clubeId)
        .collection('competicoes')
        .doc(competicaoId);

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(title: const Text('Registrar leitura')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: competicaoRef.collection('participantes').doc(uid).snapshots(),
        builder: (context, inscricaoSnapshot) {
          if (inscricaoSnapshot.hasError) {
            return const Center(
              child: Text('Erro ao consultar sua inscrição.'),
            );
          }

          if (!inscricaoSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!inscricaoSnapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você precisa participar da competição '
                  'antes de registrar leituras.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: competicaoRef
                .collection('livros')
                .orderBy('criadoEm', descending: true)
                .snapshots(),
            builder: (context, oficiaisSnapshot) {
              if (oficiaisSnapshot.hasError) {
                return const Center(
                  child: Text('Erro ao carregar livros oficiais.'),
                );
              }

              if (!oficiaisSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final oficiais = oficiaisSnapshot.data!.docs;

              if (oficiais.isEmpty) {
                return const Center(
                  child: Text('A competição ainda não possui livros oficiais.'),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: LeituraService.observarLivros(),
                builder: (context, bibliotecaSnapshot) {
                  if (bibliotecaSnapshot.hasError) {
                    return const Center(
                      child: Text('Erro ao carregar sua biblioteca.'),
                    );
                  }

                  if (!bibliotecaSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final biblioteca = {
                    for (final doc in bibliotecaSnapshot.data!.docs)
                      doc.id: doc.data(),
                  };

                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      const Text(
                        'Livros da competição',
                        style: TextStyle(
                          color: cafe,
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registre seu progresso para pontuar '
                        'na modalidade deste desafio.',
                        style: TextStyle(color: marrom),
                      ),
                      const SizedBox(height: 18),

                      for (final oficial in oficiais)
                        Builder(
                          builder: (context) {
                            final livroId =
                                '${clubeId}_${competicaoId}_${oficial.id}';

                            final pessoal = biblioteca[livroId];
                            final dados = oficial.data();
                            final atual =
                                (pessoal?['paginaAtual'] as num?)?.toInt() ?? 0;
                            final total =
                                (pessoal?['totalPaginas'] as num?)?.toInt() ??
                                0;

                            final concluido =
                                pessoal != null && total > 0 && atual >= total;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                leading: _Capa(
                                  url: dados['capaUrl'] as String?,
                                ),
                                title: Text(
                                  dados['titulo'] as String? ?? 'Livro',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cafe,
                                  ),
                                ),
                                subtitle: Text(
                                  pessoal == null
                                      ? 'Sincronize os livros oficiais'
                                      : concluido
                                      ? 'Leitura concluída'
                                      : '$atual de $total páginas',
                                ),
                                trailing: Icon(
                                  pessoal == null
                                      ? Icons.sync
                                      : concluido
                                      ? Icons.check_circle
                                      : Icons.chevron_right,
                                  color: marrom,
                                ),
                                onTap: pessoal == null || concluido
                                    ? null
                                    : () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => _RegistroDialog(
                                            clubeId: clubeId,
                                            competicaoId: competicaoId,
                                            livroOficialId: oficial.id,
                                            livroId: livroId,
                                            titulo:
                                                dados['titulo'] as String? ??
                                                'Livro',
                                            paginaAtual: atual,
                                            totalPaginas: total,
                                          ),
                                        );
                                      },
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Capa extends StatelessWidget {
  final String? url;

  const _Capa({this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 65,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: url != null && url!.startsWith('https://')
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.book, color: Color(0xFF795548)),
              )
            : const Icon(Icons.book, color: Color(0xFF795548)),
      ),
    );
  }
}

class _RegistroDialog extends StatefulWidget {
  final String clubeId;
  final String competicaoId;
  final String livroOficialId;
  final String livroId;
  final String titulo;
  final int paginaAtual;
  final int totalPaginas;

  const _RegistroDialog({
    required this.clubeId,
    required this.competicaoId,
    required this.livroOficialId,
    required this.livroId,
    required this.titulo,
    required this.paginaAtual,
    required this.totalPaginas,
  });

  @override
  State<_RegistroDialog> createState() => _RegistroDialogState();
}

class _RegistroDialogState extends State<_RegistroDialog> {
  late final TextEditingController pagina;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    pagina = TextEditingController(text: widget.paginaAtual.toString());
  }

  @override
  void dispose() {
    pagina.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    final novaPagina = int.tryParse(pagina.text.trim());

    if (salvando ||
        novaPagina == null ||
        novaPagina <= widget.paginaAtual ||
        novaPagina > widget.totalPaginas) {
      setState(() {
        erro =
            'Informe uma página entre '
            '${widget.paginaAtual + 1} e '
            '${widget.totalPaginas}.';
      });
      return;
    }

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;

      final competicaoRef = firestore
          .collection('clubes')
          .doc(widget.clubeId)
          .collection('competicoes')
          .doc(widget.competicaoId);

      final inscricaoRef = competicaoRef.collection('participantes').doc(uid);

      final oficialRef = competicaoRef
          .collection('livros')
          .doc(widget.livroOficialId);

      final pessoalRef = LeituraService.livros.doc(widget.livroId);

      final leituraRef = LeituraService.leituras.doc();

      final registroRef = competicaoRef
          .collection('registros')
          .doc('${uid}_${leituraRef.id}');

      final hoje = LeituraService.diaLocal(DateTime.now());

      final paginas = await firestore.runTransaction<int>((tx) async {
        // Todas as leituras vêm antes das escritas.
        final inscricao = await tx.get(inscricaoRef);
        final competicao = await tx.get(competicaoRef);
        final oficial = await tx.get(oficialRef);
        final pessoal = await tx.get(pessoalRef);

        if (!inscricao.exists) {
          throw StateError('Você não está inscrito.');
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

        if (agora.isBefore(inicio) ||
            !agora.isBefore(fim) ||
            ['concluida', 'cancelada', 'agendada'].contains(status)) {
          throw StateError('A competição não está ativa.');
        }

        final dadosLivro = pessoal.data()!;
        final anterior = (dadosLivro['paginaAtual'] as num?)?.toInt() ?? 0;
        final total = (dadosLivro['totalPaginas'] as num?)?.toInt() ?? 0;

        if (novaPagina <= anterior || novaPagina > total) {
          throw StateError('O progresso mudou. Feche e abra novamente.');
        }

        final quantidade = novaPagina - anterior;

        tx.update(pessoalRef, {
          'paginaAtual': novaPagina,
          'status': novaPagina == total ? 'concluido' : 'lendo',
        });

        tx.set(leituraRef, {
          'livroId': widget.livroId,
          'paginaAnterior': anterior,
          'paginaAtual': novaPagina,
          'paginasLidas': quantidade,
          'diaLocal': hoje,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        tx.set(registroRef, {
          'usuarioId': uid,
          'livroId': widget.livroId,
          'livroOficialId': widget.livroOficialId,
          'leituraId': leituraRef.id,
          'paginasLidas': quantidade,
          'diaLocal': hoje,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        return quantidade;
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$paginas páginas registradas na competição!')),
      );
    } on FirebaseException catch (e) {
      debugPrint('===== ERRO FIRESTORE READLY =====');
      debugPrint('Código: ${e.code}');
      debugPrint('Mensagem: ${e.message}');
      debugPrint('Clube: ${widget.clubeId}');
      debugPrint('Competição: ${widget.competicaoId}');
      debugPrint('Usuário: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('===============================');

      if (mounted) {
        setState(() {
          erro = 'Erro do Firestore: ${e.code}\n${e.message ?? ""}';
        });
      }
    } catch (e) {
      debugPrint('Erro ao registrar leitura: $e');

      if (mounted) {
        setState(() {
          erro = 'Não foi possível registrar: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Página atual: ${widget.paginaAtual} '
            'de ${widget.totalPaginas}',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pagina,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Página em que parou',
              border: OutlineInputBorder(),
            ),
          ),
          if (erro != null) ...[
            const SizedBox(height: 12),
            Text(erro!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : registrar,
          child: Text(salvando ? 'Registrando...' : 'Registrar leitura'),
        ),
      ],
    );
  }
}
