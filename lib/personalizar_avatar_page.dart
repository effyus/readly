import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';

class PersonalizarAvatarPage extends StatefulWidget {
  const PersonalizarAvatarPage({super.key});

  @override
  State<PersonalizarAvatarPage> createState() => _PersonalizarAvatarPageState();
}

class _PersonalizarAvatarPageState extends State<PersonalizarAvatarPage> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);

  bool salvando = false;

  Future<void> salvarNoFirebase() async {
    if (salvando) return;

    setState(() => salvando = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Converte a configuração do avatar em texto.
      final avatarConfig = await FluttermojiFunctions().encodeMySVGtoString();

      if (avatarConfig.isEmpty) {
        throw Exception('Personalize e salve o avatar primeiro.');
      }

      final firestore = FirebaseFirestore.instance;
      final perfil = await firestore
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final nome = (perfil.data()?['nome'] as String? ?? '').trim();

      if (nome.isEmpty) {
        throw Exception('Cadastre seu nome antes de salvar o avatar.');
      }
      final batch = firestore.batch();

      // Salva o avatar na conta privada.
      batch.update(firestore.collection('usuarios').doc(usuario.uid), {
        'avatarConfig': avatarConfig,
      });

      // Salva também no perfil público, para o ranking.
      batch.set(firestore.collection('perfis_publicos').doc(usuario.uid), {
        'nome': nome,
        'avatarConfig': avatarConfig,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar salvo no Readly!')));

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar avatar: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        title: const Text('Personalizar avatar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),

            FluttermojiCircleAvatar(
              radius: 65,
              backgroundColor: const Color(0xFFE7D7C2),
            ),

            const SizedBox(height: 14),

            const Text(
              'Seu personagem no Readly',
              style: TextStyle(
                color: cafe,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Escolha seu estilo, cabelo, roupas '
                'e acessórios.',
                textAlign: TextAlign.center,
                style: TextStyle(color: marrom),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(child: FluttermojiCustomizer(autosave: false)),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: salvando
                  ? const CircularProgressIndicator()
                  : FluttermojiSaveWidget(
                      onTap: salvarNoFirebase,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cafe,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Salvar meu avatar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
