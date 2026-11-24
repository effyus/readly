import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  static const cafe = Color(0xFF5D4037);
  static const fundo = Color(0xFFF5EFE3);

  final nomeController = TextEditingController();

  bool carregando = true;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!mounted) return;

      nomeController.text = (documento.data()?['nome'] as String?) ?? '';

      setState(() => carregando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar o perfil: $e';
      });
    }
  }

  Future<void> salvar() async {
    final nome = nomeController.text.trim();

    if (nome.isEmpty || nome.length > 60) {
      setState(() {
        erro = 'Informe um nome com até 60 caracteres.';
      });
      return;
    }

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser!;

      final firestore = FirebaseFirestore.instance;

      final batch = firestore.batch();

      batch.update(firestore.collection('usuarios').doc(usuario.uid), {
        'nome': nome,
      });

      batch.set(firestore.collection('perfis_publicos').doc(usuario.uid), {
        'nome': nome,
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome atualizado com sucesso!')),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Erro ao salvar: ${e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível salvar: $e';
      });
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: fundo,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meu nome',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: cafe,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esse nome será exibido na sua conta '
                    'e nas competições do Readly.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nomeController,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome de exibição',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: salvando ? null : salvar,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        salvando ? 'Salvando...' : 'Salvar alterações',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
