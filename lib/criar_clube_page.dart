
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CriarClubePage extends StatefulWidget {
  const CriarClubePage({super.key});

  @override
  State<CriarClubePage> createState() => _CriarClubePageState();
}

class _CriarClubePageState extends State<CriarClubePage> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);
  static const papel = Color(0xFFFFFCF7);

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();

  bool carregando = false;

  String gerarCodigo() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final aleatorio = Random.secure();

    return List.generate(
      8,
      (_) => caracteres[aleatorio.nextInt(caracteres.length)],
    ).join();
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> criarClube() async {
    if (carregando) return;

    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem('Informe o nome do clube.');
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      mostrarMensagem('Entre na sua conta para criar um clube.');
      return;
    }

    setState(() => carregando = true);

    try {
      final codigo = gerarCodigo();

      await FirebaseFirestore.instance
          .collection('clubes')
          .add({
        'nome': nome,
        'descricao': descricao,
        'criadorId': usuario.uid,
        'participantes': [usuario.uid],
        'codigoEntrada': codigo,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      mostrarMensagem('Clube criado com sucesso!');
      Navigator.of(context).pop();

    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (e.code == 'permission-denied') {
        mostrarMensagem(
          'Permissão negada. Confira as regras do Firestore.',
        );
      } else {
        mostrarMensagem(
          'Não foi possível criar o clube: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      mostrarMensagem('Erro ao criar clube: $e');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Criar clube'),
        backgroundColor: fundo,
        foregroundColor: cafe,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cafe,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: Color(0xFFEACDA7),
                    size: 45,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Crie seu espaço de leitura.',
                    style: TextStyle(
                      color: papel,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Reúna seus amigos, compartilhe histórias '
                    'e organize desafios quando quiser.',
                    style: TextStyle(
                      color: Color(0xFFF5EFE3),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Informações do clube',
              style: TextStyle(
                fontSize: 21,
                color: cafe,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: nomeController,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do clube *',
                hintText: 'Ex.: Clube dos Leitores',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descricaoController,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText:
                    'Conte um pouco sobre o propósito do clube...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: papel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD8C7AE),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: marrom,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Após criar o clube, você poderá '
                      'organizar competições e convidar leitores.',
                      style: TextStyle(
                        color: marrom,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: carregando ? null : criarClube,
              icon: carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                carregando ? 'Criando clube...' : 'Criar clube',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cafe,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
