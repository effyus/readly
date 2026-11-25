import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'modalidades_service.dart';

/// Ranking da competição: mantém a pontuação do ModalidadesService e
/// acrescenta a frequência de leitura ao longo da duração do desafio.
class RankingCompeticaoPage extends StatelessWidget {
  final String clubeId;
  final String competicaoId;

  const RankingCompeticaoPage({
    super.key,
    required this.clubeId,
    required this.competicaoId,
  });

  static const _cafe = Color(0xFF5D4037);
  static const _marrom = Color(0xFF795548);
  static const _papel = Color(0xFFF5EFE3);
  static const _carameloClaro = Color(0xFFE7D7C2);

  String _modalidadeTitulo(String modalidade) {
    switch (modalidade) {
      case 'mais_consistente':
        return 'Mais consistente';
      case 'meta_coletiva':
        return 'Meta coletiva';
      default:
        return 'Quem lê mais';
    }
  }

  String _nomeExibido(String id, String? nome, String? uidAtual) {
    final limpo = nome?.trim() ?? '';
    if (limpo.isNotEmpty) return limpo;
    if (id == uidAtual) return 'Você';
    return 'Leitor ${id.length > 6 ? id.substring(0, 6) : id}';
  }

  // Mostra o total de dias do desafio, não apenas o número de dias já passados.
  // O dia de início é o primeiro dia disponível para leitura.
  int _diasDecorridos(DateTime inicio, int duracao, DateTime agora) {
    if (agora.isBefore(inicio)) return 0;
    final inicioDia = DateTime.utc(inicio.year, inicio.month, inicio.day);
    final hojeDia = DateTime.utc(agora.year, agora.month, agora.day);
    final dias = hojeDia.difference(inicioDia).inDays + 1;
    return dias.clamp(0, duracao).toInt();
  }

  Widget _frequencia({
    required int diasAtivos,
    required int duracaoDias,
    required int diasDecorridos,
    required bool encerrada,
  }) {
    final progresso = duracaoDias <= 0
        ? 0.0
        : (diasAtivos / duracaoDias).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: _marrom),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Leu em $diasAtivos de $duracaoDias dias',
                style: const TextStyle(
                  color: _cafe,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progresso,
          minHeight: 8,
          color: _marrom,
          backgroundColor: _carameloClaro,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 5),
        Text(
          encerrada
              ? 'Competição encerrada'
              : '$diasDecorridos de $duracaoDias dias do desafio transcorridos',
          style: const TextStyle(color: _marrom, fontSize: 11),
        ),
      ],
    );
  }

  Widget _cartaoParticipante({
    required ParticipantePontuacao participante,
    required int colocacao,
    required String modalidade,
    required String nome,
    required int duracaoDias,
    required int diasDecorridos,
    required bool encerrada,
  }) {
    final principal = modalidade == 'mais_consistente'
        ? '${participante.diasAtivos} ${participante.diasAtivos == 1 ? 'dia ativo' : 'dias ativos'}'
        : '${participante.paginas} ${participante.paginas == 1 ? 'página' : 'páginas'}';

    final complementar = modalidade == 'mais_consistente'
        ? '${participante.paginas} páginas • Maior sequência: ${participante.maiorSequencia} dias'
        : 'Maior sequência: ${participante.maiorSequencia} dias';

    return Card(
      color: const Color(0xFFFFFCF7),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _carameloClaro,
                  child: Text('$colocacaoº',
                      style: const TextStyle(
                          color: _cafe, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          style: const TextStyle(
                              color: _cafe,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(principal,
                          style: const TextStyle(
                              color: _marrom,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(
                  modalidade == 'mais_consistente'
                      ? Icons.local_fire_department_outlined
                      : Icons.menu_book_outlined,
                  color: _marrom,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(complementar,
                style: const TextStyle(color: _marrom, fontSize: 12)),
            const SizedBox(height: 13),
            _frequencia(
              diasAtivos: participante.diasAtivos,
              duracaoDias: duracaoDias,
              diasDecorridos: diasDecorridos,
              encerrada: encerrada,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competicao = FirebaseFirestore.instance
        .collection('clubes')
        .doc(clubeId)
        .collection('competicoes')
        .doc(competicaoId);

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(title: const Text('Ranking da competição')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: competicao.snapshots(),
        builder: (context, info) {
          if (info.hasError) {
            return const Center(
              child: Text('Sem permissão para consultar a competição.'),
            );
          }
          if (!info.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!info.data!.exists) {
            return const Center(child: Text('Competição não encontrada.'));
          }

          final dados = info.data!.data()!;
          final modalidade =
              (dados['modalidade'] as String?) ?? 'quem_le_mais';
          final inicioCampo = dados['criadoEm'];
          final duracaoDias = (dados['duracaoDias'] as num?)?.toInt() ?? 0;

          if (inicioCampo is! Timestamp || duracaoDias <= 0) {
            return const Center(
              child: Text('Competição sem data ou duração válida.'),
            );
          }

          final inicio = inicioCampo.toDate();
          final fim = inicio.add(Duration(days: duracaoDias));
          final meta = (dados['metaValor'] as num?)?.toInt() ?? 0;
          final agora = DateTime.now();
          final encerrada = !agora.isBefore(fim) ||
              dados['status'] == 'concluida' ||
              dados['status'] == 'cancelada';
          final diasDecorridos =
              _diasDecorridos(inicio, duracaoDias, agora);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: competicao.collection('registros').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Sem permissão para ler os registros.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final registros = snapshot.data!.docs
                  .map<RegistroPontuacao?>((doc) {
                    final r = doc.data();
                    final criado = r['criadoEm'];
                    if (criado is! Timestamp) return null;
                    return RegistroPontuacao(
                      usuarioId: (r['usuarioId'] as String?) ?? '',
                      leituraId: (r['leituraId'] as String?) ?? doc.id,
                      paginasLidas:
                          (r['paginasLidas'] as num?)?.toInt() ?? 0,
                      diaLocal: (r['diaLocal'] as String?) ?? '',
                      criadoEm: criado.toDate(),
                    );
                  })
                  .whereType<RegistroPontuacao>()
                  .toList();

              // Este é o único cálculo de pontuação: preserva os
              // desempates e a prevenção de registros duplicados.
              final resultado = ModalidadesService.calcular(
                modalidade: modalidade,
                registros: registros,
                inicio: inicio,
                fim: fim,
                meta: meta,
              );

              final uidAtual = FirebaseAuth.instance.currentUser?.uid;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: competicao.collection('participantes').snapshots(),
                builder: (context, participantesSnapshot) {
                  final nomes = <String, String>{};
                  if (participantesSnapshot.hasData) {
                    for (final participante
                        in participantesSnapshot.data!.docs) {
                      final nome =
                          (participante.data()['nome'] as String? ?? '').trim();
                      if (nome.isNotEmpty) nomes[participante.id] = nome;
                    }
                  }

                  final progresso = resultado.progressoColetivo;
                  final percentual = (progresso * 100).round();

                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        (dados['nome'] as String?) ?? 'Competição',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: _cafe,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${_modalidadeTitulo(modalidade)} • '
                        '${encerrada ? 'Encerrada' : 'Em andamento'}',
                        style: const TextStyle(color: _marrom),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duração: $duracaoDias dias',
                        style: const TextStyle(color: _marrom, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      if (modalidade == 'meta_coletiva') ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progresso do grupo',
                                  style: TextStyle(
                                    color: _cafe,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${resultado.paginasColetivas} / $meta páginas',
                                  style: const TextStyle(color: _marrom),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: progresso,
                                  minHeight: 11,
                                  color: _marrom,
                                  backgroundColor: _carameloClaro,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$percentual% da meta concluída',
                                  style: const TextStyle(
                                    color: _cafe,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  resultado.metaAlcancada
                                      ? 'Meta alcançada! 🎉'
                                      : 'Meta ainda não alcançada',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contribuição dos participantes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _cafe,
                          ),
                        ),
                      ] else
                        const Text(
                          'Classificação',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _cafe,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (resultado.ranking.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(22),
                            child: Text(
                              'Ainda não há leituras vinculadas a esta competição.',
                            ),
                          ),
                        ),
                      for (var i = 0; i < resultado.ranking.length; i++)
                        _cartaoParticipante(
                          participante: resultado.ranking[i],
                          colocacao: i + 1,
                          modalidade: modalidade,
                          nome: _nomeExibido(
                            resultado.ranking[i].usuarioId,
                            nomes[resultado.ranking[i].usuarioId],
                            uidAtual,
                          ),
                          duracaoDias: duracaoDias,
                          diasDecorridos: diasDecorridos,
                          encerrada: encerrada,
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'São consideradas apenas leituras registradas '
                        'durante o período da competição. Leituras no mesmo '
                        'dia contam como um único dia ativo.',
                        style: TextStyle(fontSize: 12, color: _marrom),
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
