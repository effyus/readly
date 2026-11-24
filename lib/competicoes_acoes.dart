
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompeticaoAcoes extends StatelessWidget {
  final String clubeId;
  final String competicaoId;
  final String criadorId;
  final String nome;
  final String descricao;

  const CompeticaoAcoes({
    super.key,
    required this.clubeId,
    required this.competicaoId,
    required this.criadorId,
    required this.nome,
    required this.descricao,
  });

  static const cafe = Color(0xFF5D4037);

  DocumentReference<Map<String, dynamic>> get referencia =>
      FirebaseFirestore.instance
          .collection('clubes')
          .doc(clubeId)
          .collection('competicoes')
          .doc(competicaoId);

  Future<void> _editar(BuildContext context) async {
    final nomeController = TextEditingController(text: nome);
    final descricaoController =
        TextEditingController(text: descricao);

    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar competição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nome da competição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final novoNome = nomeController.text.trim();

              if (novoNome.isEmpty) return;

              Navigator.pop(dialogContext, {
                'nome': novoNome,
                'descricao': descricaoController.text.trim(),
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    nomeController.dispose();
    descricaoController.dispose();

    if (dados == null) return;

    try {
      await referencia.update(dados);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Competição atualizada!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao editar: ${e.code}'),
        ),
      );
    }
  }

  Future<void> _excluir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir competição?'),
        content: Text(
          'A competição "$nome" deixará de aparecer '
          'nas listas ativas do Readly.\n\n'
          'Os livros, participantes e registros de leitura '
          'serão preservados no Firestore.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await referencia.update({
        'excluido': true,
        'excluidoEm': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      // Retorna à tela anterior após a exclusão.
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: ${e.code}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Somente o criador pode administrar.
    if (uid == null || uid != criadorId) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administração da competição',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cafe,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: cafe,
              ),
              title: const Text('Editar competição'),
              subtitle: const Text(
                'Alterar nome e descrição',
              ),
              onTap: () => _editar(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Excluir competição',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                'Ocultar preservando o histórico',
              ),
              onTap: () => _excluir(context),
            ),
          ],
        ),
      ),
    );
  }
}
