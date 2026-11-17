
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  static const papel = Color(0xFFFFFCF7);
  static const fundo = Color(0xFFF5EFE3);

  String nomeModalidade(String modalidade) {
    switch (modalidade) {
      case 'quem_le_mais':
        return 'Quem lê mais';
      case 'mais_consistente':
        return 'Mais consistente';
      case 'meta_coletiva':
        return 'Meta coletiva';
      default:
        return modalidade;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = clube['nome'] ?? 'Clube sem nome';
    final descricao = clube['descricao'] ?? '';
    final participantes = clube['participantes'] as List? ?? [];
    final codigo = clube['codigoEntrada'] ?? '';
    final usuario = FirebaseAuth.instance.currentUser;

    final criador =
        usuario?.uid == clube['criadorId'];

    final competicoes = FirebaseFirestore.instance
        .collection('clubes')
        .doc(clubeId)
        .collection('competicoes');

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(title: const Text('Meu clube')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cafe,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFFEACDA7),
                  size: 42,
                ),
                const SizedBox(height: 16),
                Text(
                  nome.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (descricao.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    descricao.toString(),
                    style: const TextStyle(
                      color: Color(0xFFF5EFE3),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.groups_rounded,
                color: cafe,
              ),
              title: const Text('Participantes'),
              subtitle: Text(
                '${participantes.length} leitores',
              ),
            ),
          ),

          const SizedBox(height: 14),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.key_rounded,
                color: marrom,
              ),
              title: const Text('Código do clube'),
              subtitle: SelectableText(
                codigo.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              trailing: IconButton(
                tooltip: 'Copiar código',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: codigo.toString()),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado!'),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

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
              if (criador)
                IconButton.filled(
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
                  icon: const Icon(Icons.add),
                ),
            ],
          ),

          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: competicoes
                .orderBy('criadoEm', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Não foi possível carregar as competições.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final documentos = snapshot.data!.docs;

              if (documentos.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: papel,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: marrom,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nenhuma competição ainda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cafe,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        criador
                            ? 'Crie o primeiro desafio deste clube.'
                            : 'Aguarde o criador organizar um desafio.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: marrom),
                      ),
                      if (criador) ...[
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
                          label: const Text('Criar competição'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                children: documentos.map((documento) {
                  final dados = documento.data();
                  final modalidade =
                      dados['modalidade'] as String? ?? '';

                  final meta = dados['metaValor'] ?? 0;
                  final dias = dados['duracaoDias'] ?? 0;

                  final unidade =
                      modalidade == 'mais_consistente'
                          ? 'dias'
                          : 'páginas';

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE7D7C2),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: cafe,
                        ),
                      ),
                      title: Text(
                        dados['nome'] ?? 'Competição',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${nomeModalidade(modalidade)}\n'
                          'Meta: $meta $unidade • $dias dias',
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
