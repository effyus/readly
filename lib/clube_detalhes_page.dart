
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'competicao_detalhes_page.dart';
import 'criar_competicao_page.dart';

class ClubeDetalhesPage extends StatelessWidget {
  final String clubeId;
  final Map<String, dynamic> clube;

  const ClubeDetalhesPage({
    super.key,
    required this.clubeId,
    required this.clube,
  });

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const papel = Color(0xFFF5EFE3);
  static const papelClaro = Color(0xFFFFFCF7);

  DocumentReference<Map<String, dynamic>> get clubeRef =>
      FirebaseFirestore.instance.collection('clubes').doc(clubeId);

  String nomeModalidade(String modalidade) {
    switch (modalidade) {
      case 'quem_le_mais':
        return 'Quem lê mais';
      case 'mais_consistente':
        return 'Mais consistente';
      case 'meta_coletiva':
        return 'Meta coletiva';
      default:
        return 'Competição';
    }
  }

  Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    required String acao,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: Text(acao),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> sairDoClube(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmado = await confirmar(
      context,
      titulo: 'Sair do clube?',
      mensagem:
          'Você deixará de participar deste clube e '
          'de suas competições. Seu histórico pessoal '
          'de leitura não será apagado.',
      acao: 'Sair do clube',
    );

    if (!confirmado || !context.mounted) return;

    try {
      await clubeRef.update({
        'participantes': FieldValue.arrayRemove([uid]),
      });

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível sair do clube: $e'),
        ),
      );
    }
  }

  Future<void> excluirClube(BuildContext context) async {
    final confirmado = await confirmar(
      context,
      titulo: 'Excluir clube?',
      mensagem:
          'O clube deixará de aparecer para todos os '
          'participantes. Esta ação não poderá ser '
          'desfeita pelo aplicativo.',
      acao: 'Excluir clube',
    );

    if (!confirmado || !context.mounted) return;

    try {
      await clubeRef.update({
        'participantes': <String>[],
        'excluido': true,
        'excluidoEm': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir: $e'),
        ),
      );
    }
  }

  Future<void> editarClube(
    BuildContext context,
    Map<String, dynamic> dados,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditarClubeDialog(
        clubeRef: clubeRef,
        nomeInicial: dados['nome'] as String? ?? '',
        descricaoInicial:
            dados['descricao'] as String? ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: clubeRef.snapshots(),
      builder: (context, clubeSnapshot) {
        if (clubeSnapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Erro ao carregar o clube.'),
            ),
          );
        }

        if (!clubeSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dados = clubeSnapshot.data!.data();

        if (dados == null ||
            dados['excluido'] == true ||
            !(dados['participantes'] as List? ?? [])
                .contains(uid)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Clube')),
            body: const Center(
              child: Text(
                'Este clube não está mais disponível '
                'para sua conta.',
              ),
            ),
          );
        }

        final proprietario = dados['criadorId'] == uid;

        final competicoesRef =
            clubeRef.collection('competicoes');

        return Scaffold(
          backgroundColor: papel,
          appBar: AppBar(
            backgroundColor: papel,
            foregroundColor: cafe,
            title: const Text('Detalhes do clube'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Opções do clube',
                icon: const Icon(Icons.more_vert),
                onSelected: (opcao) {
                  if (opcao == 'editar') {
                    editarClube(context, dados);
                  } else if (opcao == 'sair') {
                    sairDoClube(context);
                  } else if (opcao == 'excluir') {
                    excluirClube(context);
                  }
                },
                itemBuilder: (_) => [
                  if (proprietario) ...[
                    const PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar clube'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text('Excluir clube'),
                      ),
                    ),
                  ] else
                    const PopupMenuItem(
                      value: 'sair',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Sair do clube'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                dados['nome'] as String? ?? 'Clube',
                style: const TextStyle(
                  color: cafe,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dados['descricao'] as String? ?? '',
                style: const TextStyle(
                  color: marrom,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),

              Card(
                color: papelClaro,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do clube',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cafe,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Participantes: '
                        '${(dados['participantes'] as List? ?? []).length}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Código de entrada: '
                        '${dados['codigoEntrada'] ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        proprietario
                            ? 'Sua função: Proprietário'
                            : 'Sua função: Membro',
                        style: const TextStyle(color: marrom),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Competições do clube',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: cafe,
                      ),
                    ),
                  ),
                  if (proprietario)
                    IconButton(
                      tooltip: 'Criar competição',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CriarCompeticaoPage(
                              clubeId: clubeId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: cafe,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: competicoesRef
                    .orderBy('criadoEm', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar as competições.',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final competicoes = snapshot.data!.docs;

                  if (competicoes.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Este clube ainda não possui competições.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: competicoes.map((documento) {
                      final competicao = documento.data();
                      final modalidade = nomeModalidade(
                        competicao['modalidade'] as String? ?? '',
                      );

                      final unidade =
                          competicao['modalidade'] ==
                                  'mais_consistente'
                              ? 'dias'
                              : 'páginas';

                      return Card(
                        color: papelClaro,
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            backgroundColor:
                                Color(0xFFE7D7C2),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: cafe,
                            ),
                          ),
                          title: Text(
                            competicao['nome'] as String? ??
                                'Competição',
                            style: const TextStyle(
                              color: cafe,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '$modalidade\n'
                            'Meta: ${competicao['metaValor'] ?? 0} '
                            '$unidade',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CompeticaoDetalhesPage(
                                  clubeId: clubeId,
                                  competicaoId: documento.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              if (proprietario) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CriarCompeticaoPage(
                          clubeId: clubeId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Criar nova competição'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EditarClubeDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> clubeRef;
  final String nomeInicial;
  final String descricaoInicial;

  const _EditarClubeDialog({
    required this.clubeRef,
    required this.nomeInicial,
    required this.descricaoInicial,
  });

  @override
  State<_EditarClubeDialog> createState() =>
      _EditarClubeDialogState();
}

class _EditarClubeDialogState
    extends State<_EditarClubeDialog> {
  late final TextEditingController nome;
  late final TextEditingController descricao;

  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    nome = TextEditingController(
      text: widget.nomeInicial,
    );
    descricao = TextEditingController(
      text: widget.descricaoInicial,
    );
  }

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    final novoNome = nome.text.trim();
    final novaDescricao = descricao.text.trim();

    if (novoNome.isEmpty || novoNome.length > 60 ||
        novaDescricao.length > 300) {
      setState(() {
        erro = 'Nome deve ter até 60 caracteres e '
            'descrição até 300.';
      });
      return;
    }

    if (salvando) return;

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      await widget.clubeRef.update({
        'nome': novoNome,
        'descricao': novaDescricao,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          erro = 'Não foi possível salvar: $e';
        });
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar clube'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nome do clube',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricao,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
              ),
            ),
            if (erro != null)
              Text(
                erro!,
                style: const TextStyle(color: Colors.red),
              ),
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
          child: Text(
            salvando ? 'Salvando...' : 'Salvar alterações',
          ),
        ),
      ],
    );
  }
}
