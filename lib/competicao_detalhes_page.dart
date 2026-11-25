import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'registrar_leitura_competicao_page.dart';
import 'participar_competicao_button.dart';
import 'livros_competicao_page.dart';
import 'ranking_competicao_page.dart';
import 'meus_livros_page.dart';

/// Página principal da competição.
/// Esta etapa organiza a navegação; ainda não envia leituras aos rankings.
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

  String _nomeModalidade(String? modalidade) {
    switch (modalidade) {
      case 'quem_le_mais':
        return 'Quem lê mais';
      case 'mais_consistente':
        return 'Mais consistente';
      case 'meta_coletiva':
        return 'Meta coletiva';
      default:
        return 'Modalidade não definida';
    }
  }

  Future<void> excluirCompeticao(BuildContext context, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir competição?'),
        content: Text(
          'Deseja excluir a competição "$nome"?\n\n'
          'Ela deixará de aparecer nas listas ativas, '
          'mas os registros de leitura serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('clubes')
          .doc(clubeId)
          .collection('competicoes')
          .doc(competicaoId)
          .update({
            'excluido': true,
            'excluidoEm': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao excluir: ${e.code}')));
    }
  }

  Future<void> abrirEdicaoCompeticao(
    BuildContext context,
    String nomeAtual,
    String descricaoAtual,
  ) async {
    final nomeController = TextEditingController(text: nomeAtual);
    final descricaoController = TextEditingController(text: descricaoAtual);

    try {
      final confirmar = await showDialog<bool>(
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
                  decoration: const InputDecoration(
                    labelText: 'Nome da competição',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nomeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Informe um nome válido.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );

      if (confirmar != true || !context.mounted) return;

      await FirebaseFirestore.instance
          .collection('clubes')
          .doc(clubeId)
          .collection('competicoes')
          .doc(competicaoId)
          .update({
            'nome': nomeController.text.trim(),
            'descricao': descricaoController.text.trim(),
          });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competição atualizada com sucesso!')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao editar: ${e.code}')));
    } finally {
      nomeController.dispose();
      descricaoController.dispose();
    }
  }

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  Widget _atalho({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback aoTocar,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _papel,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        leading: Icon(icone, size: 28, color: _marrom),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _cafe),
        ),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.chevron_right_rounded, color: _marrom),
        onTap: aoTocar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final referencia = FirebaseFirestore.instance
        .collection('clubes')
        .doc(clubeId)
        .collection('competicoes')
        .doc(competicaoId);

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        title: const Text('Detalhes da competição'),
        backgroundColor: _fundo,
        foregroundColor: _cafe,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: referencia.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final dados = snapshot.data!.data() ?? {};
              final uid = FirebaseAuth.instance.currentUser?.uid;

              final souProprietario = uid != null && dados['criadoPor'] == uid;

              if (!souProprietario || dados['excluido'] == true) {
                return const SizedBox.shrink();
              }

              final nome = (dados['nome'] as String?) ?? 'Competição';

              final descricao = (dados['descricao'] as String?) ?? '';

              return PopupMenuButton<String>(
                tooltip: 'Gerenciar competição',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (opcao) {
                  if (opcao == 'editar') {
                    abrirEdicaoCompeticao(context, nome, descricao);
                  } else if (opcao == 'excluir') {
                    excluirCompeticao(context, nome);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Color(0xFF5D4037)),
                        SizedBox(width: 10),
                        Text('Editar competição'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Excluir competição',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: referencia.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar a competição.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Competição não encontrada.'));
          }

          final dados = snapshot.data!.data()!;
          final nome = (dados['nome'] as String?) ?? 'Competição';

          final uid = FirebaseAuth.instance.currentUser?.uid;

          final souProprietario = uid != null && dados['criadoPor'] == uid;
          final descricao = dados['descricao'] as String? ?? '';
          final modalidade = dados['modalidade'] as String?;
          final meta = (dados['metaValor'] as num?)?.toInt();
          final duracao = (dados['duracaoDias'] as num?)?.toInt();
          final criadoEm = dados['criadoEm'];
          final inicio = criadoEm is Timestamp ? criadoEm.toDate() : null;
          final fim = inicio != null && duracao != null && duracao > 0
              ? inicio.add(Duration(days: duracao))
              : null;
          final agora = DateTime.now();
          final status = dados['status'] as String?;
          final encerrada =
              status == 'concluida' ||
              status == 'cancelada' ||
              (fim != null && !agora.isBefore(fim));
          final agendada =
              status == 'agendada' ||
              (inicio != null && agora.isBefore(inicio));
          final situacao = encerrada
              ? 'Encerrada'
              : agendada
              ? 'Agendada'
              : fim == null
              ? 'Período não definido'
              : 'Em andamento';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: _cafe,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 6),
              if (descricao.trim().isNotEmpty)
                Text(descricao, style: const TextStyle(color: _marrom)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _papel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8C7AE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          color: _caramelo,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _nomeModalidade(modalidade),
                            style: const TextStyle(
                              color: _cafe,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Situação: $situacao',
                      style: const TextStyle(color: _marrom),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Meta: $meta ${modalidade == 'mais_consistente' ? 'dias' : 'páginas'}',
                        style: const TextStyle(color: _marrom),
                      ),
                    ],
                    if (duracao != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Duração: $duracao dias',
                        style: const TextStyle(color: _marrom),
                      ),
                    ],
                    if (fim != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Término previsto: ${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year}',
                        style: const TextStyle(color: _marrom),
                      ),
                    ],

                    
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ParticiparCompeticaoButton(
                clubeId: clubeId,
                competicaoId: competicaoId,
              ),
              const Text(
                'Acessar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _cafe,
                ),
              ),
              const SizedBox(height: 12),
              _atalho(
                context: context,
                icone: Icons.menu_book_rounded,
                titulo: 'Livros da competição',
                descricao: 'Ver livros compartilhados e adicionar à biblioteca',
                aoTocar: () => _abrir(
                  context,
                  LivrosCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                    nomeCompeticao: nome,
                  ),
                ),
              ),
              _atalho(
                context: context,
                icone: Icons.emoji_events_rounded,
                titulo: 'Ranking',
                descricao: 'Classificação da modalidade selecionada',
                aoTocar: () => _abrir(
                  context,
                  RankingCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                  ),
                ),
              ),

              _atalho(
                context: context,
                icone: Icons.edit_note_rounded,
                titulo: 'Registrar leitura',
                descricao: 'Ler livros oficiais e pontuar no desafio',
                aoTocar: () => _abrir(
                  context,
                  RegistrarLeituraCompeticaoPage(
                    clubeId: clubeId,
                    competicaoId: competicaoId,
                  ),
                ),
              ),

              const SizedBox(height: 9),
              const Text(
                'Por enquanto, as páginas registradas na biblioteca não pontuam '
                'automaticamente nesta competição. A vinculação segura dos registros '
                'será implementada na próxima etapa.',
                style: TextStyle(color: _marrom, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
