
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EntrarClubePage extends StatefulWidget {
  const EntrarClubePage({super.key});

  @override
  State<EntrarClubePage> createState() =>
      _EntrarClubePageState();
}

class _EntrarClubePageState extends State<EntrarClubePage> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const papel = Color(0xFFF5EFE3);

  final codigoController = TextEditingController();

  bool carregando = false;
  String? erro;

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  Future<void> entrarNoClube() async {
    final codigo = codigoController.text.trim().toUpperCase();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => erro = 'Faça login novamente.');
      return;
    }

    if (codigo.length != 8) {
      setState(() {
        erro = 'O código deve ter 8 caracteres.';
      });
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final resultado = await firestore
          .collection('clubes')
          .where('codigoEntrada', isEqualTo: codigo)
          .limit(2)
          .get();

      if (resultado.docs.isEmpty) {
        throw StateError('Nenhum clube encontrado com esse código.');
      }

      final clubesValidos = resultado.docs.where((doc) {
        return doc.data()['excluido'] != true;
      }).toList();

      if (clubesValidos.isEmpty) {
        throw StateError('Esse clube não está mais disponível.');
      }

      if (clubesValidos.length > 1) {
        throw StateError(
          'Código duplicado. Solicite outro convite ao responsável.',
        );
      }

      final documento = clubesValidos.first;
      final dados = documento.data();

      final participantes =
          List<String>.from(dados['participantes'] ?? []);

      if (participantes.contains(uid)) {
        throw StateError('Você já participa desse clube.');
      }

      // Confirma novamente os dados antes de entrar.
      await firestore.runTransaction((transaction) async {
        final atualizado =
            await transaction.get(documento.reference);

        if (!atualizado.exists) {
          throw StateError('Clube não encontrado.');
        }

        final clube = atualizado.data()!;

        if (clube['excluido'] == true ||
            clube['codigoEntrada'] != codigo) {
          throw StateError('Este convite não está disponível.');
        }

        final membros =
            List<String>.from(clube['participantes'] ?? []);

        if (membros.contains(uid)) {
          throw StateError('Você já participa desse clube.');
        }

        transaction.update(documento.reference, {
          'participantes': FieldValue.arrayUnion([uid]),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Você entrou no clube ${dados['nome'] ?? ''}!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          erro = e.code == 'permission-denied'
              ? 'O Firestore bloqueou a entrada. '
                  'Confira as regras de participantes.'
              : 'Erro no Firebase: ${e.message ?? e.code}';
        });
      }
    } on StateError catch (e) {
      if (mounted) {
        setState(() => erro = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = 'Não foi possível entrar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: papel,
      appBar: AppBar(
        title: const Text('Entrar em um clube'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.groups_rounded,
            size: 75,
            color: cafe,
          ),
          const SizedBox(height: 20),
          const Text(
            'Você recebeu um convite?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cafe,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Digite o código compartilhado pelo '
            'proprietário do clube.',
            textAlign: TextAlign.center,
            style: TextStyle(color: marrom),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: codigoController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Código de entrada',
              hintText: 'Ex.: ABCD1234',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            onSubmitted: (_) {
              if (!carregando) entrarNoClube();
            },
          ),
          if (erro != null) ...[
            const SizedBox(height: 10),
            Text(
              erro!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: carregando ? null : entrarNoClube,
            icon: const Icon(Icons.login_rounded),
            label: Text(
              carregando ? 'Entrando...' : 'Entrar no clube',
            ),
          ),
        ],
      ),
    );
  }
}
