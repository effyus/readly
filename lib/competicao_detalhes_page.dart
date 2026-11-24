import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'competicoes_acoes.dart';
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
          final nome = dados['nome'] as String? ?? 'Competição';
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

                    if (dados['excluido'] != true) ...[
                      const SizedBox(height: 20),

                      CompeticaoAcoes(
                        clubeId: clubeId,
                        competicaoId: competicaoId,
                        criadorId: (dados['criadoPor'] as String?) ?? '',
                        nome: (dados['nome'] as String?) ?? '',
                        descricao: (dados['descricao'] as String?) ?? '',
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
