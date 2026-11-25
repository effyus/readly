
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);
  static const papel = Color(0xFFFFFCF7);

  final nomeController = TextEditingController();
  final imagePicker = ImagePicker();

  Uint8List? fotoSelecionada;
  String? fotoAtual;
  String? erro;

  bool carregando = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) {
        throw StateError('Usuário não autenticado.');
      }

      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!mounted) return;

      setState(() {
        nomeController.text =
            (documento.data()?['nome'] as String?) ?? '';
        fotoAtual = documento.data()?['fotoUrl'] as String?;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível carregar seu perfil: $e';
        carregando = false;
      });
    }
  }

  Future<void> escolherFoto() async {
    try {
      final imagem = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (bytes.length > 2 * 1024 * 1024) {
        setState(() {
          erro = 'Escolha uma foto com menos de 2 MB.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        fotoSelecionada = bytes;
        erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível selecionar a foto: $e';
      });
    }
  }

  Future<void> salvar() async {
    final nome = nomeController.text.trim();

    if (nome.isEmpty || nome.length > 60) {
      setState(() {
        erro = 'Informe um nome de 1 a 60 caracteres.';
      });
      return;
    }

    setState(() {
      salvando = true;
      erro = null;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) {
        throw StateError('Usuário não autenticado.');
      }

      String? novaFotoUrl = fotoAtual;

      // Envia a nova imagem somente se houver uma selecionada.
      if (fotoSelecionada != null) {
        final referencia = FirebaseStorage.instance
            .ref()
            .child('avatares')
            .child(usuario.uid)
            .child('perfil.jpg');

        await referencia.putData(
          fotoSelecionada!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        novaFotoUrl = await referencia.getDownloadURL();
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Dados privados da conta.
      batch.update(
        firestore.collection('usuarios').doc(usuario.uid),
        {
          'nome': nome,
          if (novaFotoUrl != null) 'fotoUrl': novaFotoUrl,
        },
      );

      // Dados públicos exibidos nos rankings.
      batch.set(
        firestore.collection('perfis_publicos').doc(usuario.uid),
        {
          'nome': nome,
          if (novaFotoUrl != null) 'fotoUrl': novaFotoUrl,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Mantém o nome também no Firebase Authentication.
      await usuario.updateDisplayName(nome);

      if (novaFotoUrl != null) {
        await usuario.updatePhotoURL(novaFotoUrl);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Erro do Firebase: ${e.code}\n'
            '${e.message ?? ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível salvar o perfil: $e';
      });
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget fotoPerfil() {
    ImageProvider? imagem;

    if (fotoSelecionada != null) {
      imagem = MemoryImage(fotoSelecionada!);
    } else if (fotoAtual != null &&
        fotoAtual!.startsWith('https://')) {
      imagem = NetworkImage(fotoAtual!);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 57,
          backgroundColor: const Color(0xFFE7D7C2),
          backgroundImage: imagem,
          child: imagem == null
              ? const Icon(
                  Icons.person_rounded,
                  color: marrom,
                  size: 65,
                )
              : null,
        ),
        Positioned(
          bottom: 1,
          right: 0,
          child: Material(
            color: cafe,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Escolher foto',
              onPressed: salvando ? null : escolherFoto,
              icon: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: papel,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFD8C7AE),
                      ),
                    ),
                    child: Column(
                      children: [
                        fotoPerfil(),
                        const SizedBox(height: 16),
                        const Text(
                          'Sua identidade no Readly',
                          style: TextStyle(
                            color: cafe,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Toque na câmera para escolher '
                          'uma foto da galeria.',
                          style: TextStyle(color: marrom),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: nomeController,
                          maxLength: 60,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nome de exibição',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      erro!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: salvando ? null : salvar,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        salvando
                            ? 'Salvando alterações...'
                            : 'Salvar alterações',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: cafe,
                        padding: const EdgeInsets.all(17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
