
import 'package:flutter/material.dart';

class ClubeDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> clube;

  const ClubeDetalhesPage({
    super.key,
    required this.clube,
  });

  @override
  Widget build(BuildContext context) {
    final nome = clube['nome'] ?? 'Clube sem nome';
    final descricao = clube['descricao'] ?? '';
    final modalidade = clube['modalidade'] ?? '';
    final objetivo = clube['objetivo'] ?? '';
    final duracao = clube['duracaoDias'] ?? 0;
    final participantes = clube['participantes'] as List? ?? [];
    final codigo = clube['codigoEntrada'] ?? '';

    String nomeModalidade;

    switch (modalidade) {
      case 'quem_le_mais':
        nomeModalidade = 'Quem lê mais';
        break;
      case 'mais_consistente':
        nomeModalidade = 'Quem é mais consistente';
        break;
      case 'meta_coletiva':
        nomeModalidade = 'Meta coletiva';
        break;
      default:
        nomeModalidade = modalidade;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        title: const Text('Detalhes do clube'),
        backgroundColor: const Color(0xFF795548),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),

            if (descricao.toString().isNotEmpty)
              Text(
                descricao,
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 24),

            _informacao('Modalidade', nomeModalidade),
            _informacao('Objetivo', objetivo.toString()),
            _informacao('Duração', '$duracao dias'),
            _informacao(
              'Participantes',
              '${participantes.length}',
            ),

            const SizedBox(height: 20),

            const Text(
              'Código de entrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                codigo.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informacao(String titulo, String valor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF795548),
            ),
          ),
          const SizedBox(height: 6),
          Text(valor),
        ],
      ),
    );
  }
}
