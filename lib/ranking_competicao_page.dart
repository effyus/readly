import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'modalidades_service.dart';

/// Tela que calcula as três modalidades usando registros já vinculados
/// à competição em clubes/{clubeId}/competicoes/{competicaoId}/registros.
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

Future<void> _editarMeuNome(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final firestore = FirebaseFirestore.instance;
  final perfilRef = firestore.collection('usuarios').doc(uid);

  final inscricaoRef = firestore
      .collection('clubes')
      .doc(clubeId)
      .collection('competicoes')
      .doc(competicaoId)
      .collection('participantes')
      .doc(uid);

  try {
    final resultados = await Future.wait([
      perfilRef.get(),
      inscricaoRef.get(),
    ]);

    if (!resultados[1].exists) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Participe da competição antes de alterar seu nome.',
          ),
        ),
      );
      return;
    }

    final nomeAtual = (resultados[1].data()?['nome'] ??
            resultados[0].data()?['nome'] ??
            '') as String;

    if (!context.mounted) return;

    final controller = TextEditingController(text: nomeAtual);

    final novoNome = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar meu nome'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome exibido no ranking',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nome = controller.text.trim();
              if (nome.isNotEmpty) {
                Navigator.pop(dialogContext, nome);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (novoNome == null) return;

    // Atualiza o perfil e o nome da inscrição juntos.
    final batch = firestore.batch();
    batch.update(perfilRef, {'nome': novoNome});
    batch.update(inscricaoRef, {'nome': novoNome});
    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nome atualizado com sucesso!'),
      ),
    );
  } on FirebaseException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: ${e.code}')),
    );
  }
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
          if (!info.hasData)
            return const Center(child: CircularProgressIndicator());
          if (!info.data!.exists)
            return const Center(child: Text('Competição não encontrada.'));

          final dados = info.data!.data()!;
          final modalidade = (dados['modalidade'] as String?) ?? 'quem_le_mais';
          final inicioCampo = dados['criadoEm'];
          final dias = (dados['duracaoDias'] as num?)?.toInt() ?? 0;
          if (inicioCampo is! Timestamp || dias <= 0) {
            return const Center(
              child: Text('Competição sem data ou duração válida.'),
            );
          }
          final inicio = inicioCampo.toDate();
          final fim = inicio.add(Duration(days: dias));
          final meta = (dados['metaValor'] as num?)?.toInt() ?? 0;
          final agora = DateTime.now();
          final encerrada =
              !agora.isBefore(fim) || dados['status'] == 'concluida';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: competicao.collection('registros').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Sem permissão para ler os registros. Verifique as regras de registros no Firestore.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final registros = snapshot.data!.docs.map((doc) {
                final r = doc.data();
                final criado = r['criadoEm'];
                if (criado is! Timestamp) return null;
                return RegistroPontuacao(
                  usuarioId: (r['usuarioId'] as String?) ?? '',
                  leituraId: (r['leituraId'] as String?) ?? doc.id,
                  paginasLidas: (r['paginasLidas'] as num?)?.toInt() ?? 0,
                  diaLocal: (r['diaLocal'] as String?) ?? '',
                  criadoEm: criado.toDate(),
                );
              }).whereType<RegistroPontuacao>();

              final registrosValidos = registros.toList();

              final resultado = ModalidadesService.calcular(
                modalidade: modalidade,
                registros: registrosValidos,
                inicio: inicio,
                fim: fim,
                meta: meta,
              );

              final progresso = meta > 0
                  ? (resultado.paginasColetivas / meta)
                        .clamp(0.0, 1.0)
                        .toDouble()
                  : 0.0;

              final percentual = (progresso * 100).round();

              debugPrint('===== DIAGNÓSTICO READLY =====');
              debugPrint('Competição: $competicaoId');
              debugPrint('Modalidade: $modalidade');
              debugPrint('Início: $inicio');
              debugPrint('Fim: $fim');

              debugPrint(
                'Documentos no Firestore: ${snapshot.data!.docs.length}',
              );

              debugPrint(
                'Registros com data válida: ${registrosValidos.length}',
              );

              debugPrint(
                'Participantes no ranking: ${resultado.ranking.length}',
              );

              for (final registro in registrosValidos) {
                debugPrint(
                  'Leitura: ${registro.usuarioId} | '
                  '${registro.paginasLidas} páginas | '
                  '${registro.criadoEm} | '
                  'Dentro do prazo: '
                  '${!registro.criadoEm.isBefore(inicio) && registro.criadoEm.isBefore(fim)}',
                );
              }

              debugPrint('=============================');

              final unidade = modalidade == 'mais_consistente'
                  ? 'dias'
                  : 'páginas';
              final titulo = switch (modalidade) {
                'mais_consistente' => 'Mais consistente',
                'meta_coletiva' => 'Meta coletiva',
                _ => 'Quem lê mais',
              };
              final eu = FirebaseAuth.instance.currentUser?.uid;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: competicao.collection('participantes').snapshots(),
                builder: (context, participantesSnapshot) {
                  final nomes = <String, String>{};

                  if (participantesSnapshot.hasData) {
                    for (final participante
                        in participantesSnapshot.data!.docs) {
                      final nome =
                          (participante.data()['nome'] as String? ?? '').trim();

                      if (nome.isNotEmpty) {
                        nomes[participante.id] = nome;
                      }
                    }
                  }

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
                        '$titulo • ${encerrada ? 'Encerrada' : 'Em andamento'}',
                        style: const TextStyle(color: _marrom),
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
                                    fontWeight: FontWeight.bold,
                                    color: _cafe,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${resultado.paginasColetivas} / $meta páginas',
                                ),
                                const SizedBox(height: 9),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progresso,
                                      minHeight: 11,
                                      color: _marrom,
                                      backgroundColor: const Color(0xFFE7D7C2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      '$percentual% da meta concluída',
                                      style: const TextStyle(
                                        color: _cafe,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  resultado.paginasColetivas >= meta && meta > 0
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
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE7D7C2),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: _cafe),
                              ),
                            ),
                            title: Text(
                              nomes[resultado.ranking[i].usuarioId] ??
                                  (resultado.ranking[i].usuarioId == eu
                                      ? 'Você'
                                      : 'Leitor ${resultado.ranking[i].usuarioId.length > 6 ? resultado.ranking[i].usuarioId.substring(0, 6) : resultado.ranking[i].usuarioId}'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _cafe,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'O ranking considera apenas registros feitos durante o período da competição.',
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
