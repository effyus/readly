
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClubeDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> clube;

  const ClubeDetalhesPage({
    super.key,
    required this.clube,
  });

  @override
  Widget build(BuildContext context) {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    const fundo = Color(0xFFF5EFE3);
    const papel = Color(0xFFFFFCF7);

    final nome = clube['nome'] ?? 'Clube sem nome';
    final descricao = clube['descricao'] ?? '';
    final participantes = clube['participantes'] as List? ?? [];
    final codigo = clube['codigoEntrada'] ?? '';

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu clube'),
        backgroundColor: fundo,
        foregroundColor: cafe,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(23),
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
                  const SizedBox(height: 18),
                  Text(
                    nome.toString(),
                    style: const TextStyle(
                      color: papel,
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

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: papel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: cafe,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Participantes',
                        style: TextStyle(color: marrom),
                      ),
                      Text(
                        '${participantes.length} leitores',
                        style: const TextStyle(
                          color: cafe,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Convide novos leitores',
              style: TextStyle(
                color: cafe,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: papel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código do clube',
                          style: TextStyle(color: marrom),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          codigo.toString(),
                          style: const TextStyle(
                            color: cafe,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
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
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: cafe,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: cafe,
                  size: 27,
                ),
                SizedBox(width: 10),
                Text(
                  'Competições do clube',
                  style: TextStyle(
                    color: cafe,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: papel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD8C7AE),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 44,
                    color: marrom,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Nenhuma competição cadastrada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: cafe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Em breve você poderá criar desafios '
                    'para os participantes deste clube.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: marrom,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
