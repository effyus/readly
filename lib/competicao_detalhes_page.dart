import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'registro_rapido_competicao_sheet.dart';
import 'livros_competicao_page.dart';
import 'modalidades_service.dart';
import 'participar_competicao_button.dart';
import 'ranking_competicao_page.dart';


/// Painel único da competição. Não altera regras ou registros do Firestore.
class CompeticaoDetalhesPage extends StatelessWidget {
  final String clubeId;
  final String competicaoId;

  const CompeticaoDetalhesPage({
    super.key,
    required this.clubeId,
    required this.competicaoId,
  });

  static const _cafe = Color(0xFF5D4037);
  static const _marrom = Color(0xFF795548);
  static const _caramelo = Color(0xFFA67C52);
  static const _fundo = Color(0xFFF5EFE3);
  static const _papel = Color(0xFFFFFCF7);
  static const _borda = Color(0xFFD8C7AE);

  DocumentReference<Map<String, dynamic>> get _competicao => FirebaseFirestore
      .instance
      .collection('clubes')
      .doc(clubeId)
      .collection('competicoes')
      .doc(competicaoId);

  String _modalidadeNome(String modalidade) => switch (modalidade) {
    'quem_le_mais' => 'Quem lê mais',
    'mais_consistente' => 'Mais consistente',
    'meta_coletiva' => 'Meta coletiva',
    _ => 'Competição de leitura',
  };

  String _data(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  Future<void> _editar(
    BuildContext context,
    String nomeAtual,
    String descricaoAtual,
  ) async {
    final nomeController = TextEditingController(text: nomeAtual);
    final descricaoController = TextEditingController(text: descricaoAtual);
    try {
      final valores = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Editar competição'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Informe um nome válido.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'nome': nome,
                  'descricao': descricaoController.text.trim(),
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
      if (valores == null || !context.mounted) return;
      await _competicao.update(valores);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Competição atualizada!')));
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao editar: ${e.code}')));
      }
    } finally {
      // Aguarda o fechamento do diálogo antes de descartar os controladores.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nomeController.dispose();
        descricaoController.dispose();
      });
    }
  }

  Future<void> _excluir(BuildContext context, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir competição?'),
        content: Text(
          'Deseja excluir "$nome"? A competição sairá das listas ativas, '
          'mas o histórico de leituras será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      await _competicao.update({
        'excluido': true,
        'excluidoEm': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: ${e.code}')));
      }
    }
  }

  

  Widget _tituloSecao(String titulo, VoidCallback aoVerTodos) => Row(
    children: [
      Expanded(
        child: Text(
          titulo,
          style: const TextStyle(
            color: _cafe,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      TextButton(onPressed: aoVerTodos, child: const Text('Ver todos')),
    ],
  );

  Widget _cartao({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _papel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _borda),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _competicao.snapshots(),
      builder: (context, info) {
        if (info.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Não foi possível carregar esta competição.'),
            ),
          );
        }
        if (!info.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!info.data!.exists || info.data!.data()?['excluido'] == true) {
          return const Scaffold(
            body: Center(child: Text('Competição não encontrada.')),
          );
        }

        final dados = info.data!.data()!;
        final nome = (dados['nome'] as String?) ?? 'Competição';
        final descricao = (dados['descricao'] as String?) ?? '';
        final modalidade = (dados['modalidade'] as String?) ?? 'quem_le_mais';
        final meta = (dados['metaValor'] as num?)?.toInt() ?? 0;
        final duracao = (dados['duracaoDias'] as num?)?.toInt() ?? 0;
        final criadoEm = dados['criadoEm'];
        final inicio = criadoEm is Timestamp ? criadoEm.toDate() : null;
        final fim = inicio != null && duracao > 0
            ? inicio.add(Duration(days: duracao))
            : null;
        final agora = DateTime.now();
        final encerrada =
            dados['status'] == 'concluida' ||
            dados['status'] == 'cancelada' ||
            (fim != null && !agora.isBefore(fim));
        final agendada =
            dados['status'] == 'agendada' ||
            (inicio != null && agora.isBefore(inicio));
        final proprietario = uid != null && dados['criadoPor'] == uid;

        return Scaffold(
          backgroundColor: _fundo,
          appBar: AppBar(
            backgroundColor: _fundo,
            foregroundColor: _cafe,
            title: const Text('Competição'),
            actions: [
              if (proprietario)
                PopupMenuButton<String>(
                  tooltip: 'Gerenciar competição',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (opcao) {
                    if (opcao == 'editar') _editar(context, nome, descricao);
                    if (opcao == 'excluir') _excluir(context, nome);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: _cafe),
                          SizedBox(width: 10),
                          Text('Editar competição'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir competição'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Apenas participantes inscritos podem registrar leituras.
          bottomNavigationBar: uid == null || encerrada || agendada
              ? null
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _competicao
                      .collection('participantes')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, inscricao) {
                    if (!inscricao.hasData || !inscricao.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    return SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                        child: FilledButton.icon(
                          onPressed: () {
                            abrirRegistroRapido(
                              context,
                              clubeId: clubeId,
                              competicaoId: competicaoId,
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Registrar leitura'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _cafe,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: _cafe,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (descricao.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _marrom),
                ),
              ],
              const SizedBox(height: 14),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          color: _caramelo,
                        ),
                        Text(
                          _modalidadeNome(modalidade),
                          style: const TextStyle(
                            color: _cafe,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            encerrada
                                ? 'Encerrada'
                                : agendada
                                ? 'Agendada'
                                : 'Em andamento',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (fim != null)
                      Text(
                        'Até ${_data(fim)} • $duracao dias',
                        style: const TextStyle(color: _marrom),
                      ),
                    if (modalidade == 'meta_coletiva' && meta > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Meta do grupo: $meta páginas',
                        style: const TextStyle(color: _marrom),
                      ),
                    ],
                    if ((dados['regras'] as String? ?? '').trim().isNotEmpty)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: const Text('Regras do desafio'),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text((dados['regras'] as String).trim()),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // O próprio botão existente administra inscrição e permissões.
              ParticiparCompeticaoButton(
                clubeId: clubeId,
                competicaoId: competicaoId,
              ),
              const SizedBox(height: 20),
              _tituloSecao(
                'Classificação',
                () => _abrir(
                  context,
                  RankingCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _competicao.collection('registros').snapshots(),
                builder: (context, registrosSnapshot) {
                  if (registrosSnapshot.hasError) {
                    return _cartao(
                      child: const Text('Não foi possível carregar o ranking.'),
                    );
                  }
                  if (!registrosSnapshot.hasData ||
                      inicio == null ||
                      fim == null) {
                    return _cartao(
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final registros = registrosSnapshot.data!.docs
                      .map((doc) {
                        final item = doc.data();
                        final criado = item['criadoEm'];
                        if (criado is! Timestamp) return null;
                        return RegistroPontuacao(
                          usuarioId: (item['usuarioId'] as String?) ?? '',
                          leituraId: (item['leituraId'] as String?) ?? doc.id,
                          paginasLidas:
                              (item['paginasLidas'] as num?)?.toInt() ?? 0,
                          diaLocal: (item['diaLocal'] as String?) ?? '',
                          criadoEm: criado.toDate(),
                        );
                      })
                      .whereType<RegistroPontuacao>()
                      .toList();
                  final resultado = ModalidadesService.calcular(
                    modalidade: modalidade,
                    registros: registros,
                    inicio: inicio,
                    fim: fim,
                    meta: meta,
                  );
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _competicao.collection('participantes').snapshots(),
                    builder: (context, participantesSnapshot) {
                      final nomes = <String, String>{};
                      if (participantesSnapshot.hasData) {
                        for (final doc in participantesSnapshot.data!.docs) {
                          final nomePessoa =
                              (doc.data()['nome'] as String? ?? '').trim();
                          if (nomePessoa.isNotEmpty) nomes[doc.id] = nomePessoa;
                        }
                      }
                      final lideres = resultado.ranking.take(3).toList();
                      return _cartao(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (modalidade == 'meta_coletiva' && meta > 0) ...[
                              Text(
                                '${resultado.paginasColetivas} / $meta páginas do grupo',
                                style: const TextStyle(
                                  color: _cafe,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: resultado.progressoColetivo,
                                minHeight: 9,
                                color: _marrom,
                                backgroundColor: const Color(0xFFE7D7C2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (lideres.isEmpty)
                              const Text(
                                'As primeiras leituras aparecerão aqui.',
                                style: TextStyle(color: _marrom),
                              ),
                            for (var i = 0; i < lideres.length; i++) ...[
                              if (i > 0)
                                const Divider(color: _borda, height: 22),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: const Color(0xFFE7D7C2),
                                    child: Text(
                                      '${i + 1}º',
                                      style: const TextStyle(
                                        color: _cafe,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nomes[lideres[i].usuarioId] ??
                                          (lideres[i].usuarioId == uid
                                              ? 'Você'
                                              : 'Leitor'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _cafe,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        modalidade == 'mais_consistente'
                                            ? '${lideres[i].diasAtivos} dias'
                                            : '${lideres[i].paginas} pág.',
                                        style: const TextStyle(
                                          color: _cafe,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        modalidade == 'mais_consistente'
                                            ? '${lideres[i].paginas} páginas'
                                            : '${lideres[i].diasAtivos} dias lendo',
                                        style: const TextStyle(
                                          color: _marrom,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              _tituloSecao(
                'Livros do desafio',
                () => _abrir(
                  context,
                  LivrosCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                    nomeCompeticao: nome,
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _competicao.collection('livros').snapshots(),
                builder: (context, livrosSnapshot) {
                  if (livrosSnapshot.hasError) {
                    return _cartao(
                      child: const Text('Não foi possível carregar os livros.'),
                    );
                  }
                  if (!livrosSnapshot.hasData) {
                    return _cartao(
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final livros = livrosSnapshot.data!.docs;
                  if (livros.isEmpty) {
                    return _cartao(
                      child: const Text(
                        'Ainda não há livros oficiais nesta competição.',
                        style: TextStyle(color: _marrom),
                      ),
                    );
                  }
                  return _cartao(
                    child: Column(
                      children: [
                        for (var i = 0; i < livros.length && i < 3; i++) ...[
                          if (i > 0) const Divider(color: _borda),
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: _marrom,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (livros[i].data()['titulo'] as String?) ??
                                          'Livro',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _cafe,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (livros[i].data()['autor'] as String?) ??
                                          '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _marrom,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _abrir(
                            context,
                            LivrosCompeticaoPage(
                              clubeId: clubeId,
                              competicaoId: competicaoId,
                              nomeCompeticao: nome,
                            ),
                          ),
                          icon: const Icon(Icons.library_books_outlined),
                          label: const Text('Abrir biblioteca do desafio'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
