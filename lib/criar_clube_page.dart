import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CriarClubePage extends StatefulWidget {
  const CriarClubePage({super.key});

  @override
  State<CriarClubePage> createState() => _CriarClubePageState();
}

class _CriarClubePageState extends State<CriarClubePage> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final livroController = TextEditingController();
  final paginasController = TextEditingController();

  bool carregando = false;

  Future<void> criarClube() async {
    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    final livro = livroController.text.trim();
    final paginas = int.tryParse(paginasController.text.trim());

    if (nome.isEmpty || livro.isEmpty || paginas == null || paginas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o nome do clube, o livro e uma meta válida de páginas.',
          ),
        ),
      );
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa entrar na sua conta novamente.'),
        ),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      await FirebaseFirestore.instance.collection('clubes').add({
        'nome': nome,
        'descricao': descricao,
        'livro': livro,
        'metaPaginas': paginas,
        'criadorId': usuario.uid,
        'participantes': [usuario.uid],
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clube criado com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar o clube: $erro')),
      );
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
    livroController.dispose();
    paginasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const marrom = Color.fromARGB(255, 132, 81, 11);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar clube')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.menu_book_rounded, size: 64, color: marrom),
            const SizedBox(height: 16),
            const Text(
              'Crie seu clube de leitura',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reúna pessoas e acompanhe o progresso '
              'da leitura em grupo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do clube',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: livroController,
              decoration: const InputDecoration(
                labelText: 'Nome do livro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: paginasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta de páginas',
                helperText: 'Quantidade de páginas para a meta do clube',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: carregando ? null : criarClube,
              icon: const Icon(Icons.add),
              label: Text(carregando ? 'Criando clube...' : 'Criar clube'),
              style: FilledButton.styleFrom(
                backgroundColor: marrom,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
