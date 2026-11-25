
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
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);
  static const papel = Color(0xFFFFFCF7);
  static const borda = Color(0xFFD8C7AE);

  final nomeController = TextEditingController();
  final senhaAtualController = TextEditingController();
  final novaSenhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool carregando = true;
  bool salvandoNome = false;
  bool salvandoSenha = false;
  bool mostrarSenhas = false;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!mounted) return;

      nomeController.text =
          (documento.data()?['nome'] as String?) ??
          usuario.displayName ??
          '';

      setState(() => carregando = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => carregando = false);
      mensagem('Erro ao carregar o perfil: $e');
    }
  }

  void mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> salvarNome() async {
    final nome = nomeController.text.trim();

    if (nome.isEmpty || nome.length > 60) {
      mensagem('Informe um nome entre 1 e 60 caracteres.');
      return;
    }

    setState(() => salvandoNome = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser!;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.update(
        firestore.collection('usuarios').doc(usuario.uid),
        {'nome': nome},
      );

      batch.set(
        firestore.collection('perfis_publicos').doc(usuario.uid),
        {'nome': nome},
        SetOptions(merge: true),
      );

      await batch.commit();

      // O Firestore é a fonte principal do nome.
      // Sincroniza também com o Authentication.
      try {
        await usuario.updateDisplayName(nome);
      } on FirebaseAuthException {
        // Não desfaz a atualização já concluída
        // no Firestore.
      }

      mensagem('Nome atualizado com sucesso!');
    } on FirebaseException catch (e) {
      mensagem('Erro ao salvar nome: ${e.code}');
    } catch (e) {
      mensagem('Não foi possível salvar: $e');
    } finally {
      if (mounted) {
        setState(() => salvandoNome = false);
      }
    }
  }

  String erroSenha(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'A senha atual está incorreta.';

      case 'weak-password':
        return 'Escolha uma senha mais forte.';

      case 'requires-recent-login':
        return 'Sua sessão precisa ser atualizada. '
            'Saia da conta e entre novamente.';

      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';

      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';

      case 'user-disabled':
        return 'Esta conta está desativada.';

      default:
        return 'Não foi possível alterar a senha: ${e.code}';
    }
  }

  Future<void> alterarSenha() async {
    final atual = senhaAtualController.text;
    final nova = novaSenhaController.text;
    final confirmar = confirmarSenhaController.text;

    if (atual.isEmpty || nova.isEmpty || confirmar.isEmpty) {
      mensagem('Preencha todos os campos de senha.');
      return;
    }

    if (nova.length < 6) {
      mensagem('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }

    if (nova != confirmar) {
      mensagem('A confirmação não corresponde à nova senha.');
      return;
    }

    if (nova == atual) {
      mensagem('A nova senha deve ser diferente da atual.');
      return;
    }

    setState(() => salvandoSenha = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser;
      final email = usuario?.email;

      if (usuario == null || email == null) {
        throw Exception('Conta não encontrada.');
      }

      // Confirma a identidade usando a senha atual.
      final credencial = EmailAuthProvider.credential(
        email: email,
        password: atual,
      );

      await usuario.reauthenticateWithCredential(credencial);

      // Altera a senha no Firebase Authentication.
      await usuario.updatePassword(nova);

      senhaAtualController.clear();
      novaSenhaController.clear();
      confirmarSenhaController.clear();

      mensagem('Senha alterada com sucesso!');
    } on FirebaseAuthException catch (e) {
      mensagem(erroSenha(e));
    } catch (e) {
      mensagem('Erro ao alterar senha: $e');
    } finally {
      if (mounted) {
        setState(() => salvandoSenha = false);
      }
    }
  }

  Widget campoSenha(
    String titulo,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: !mostrarSenhas,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: mostrarSenhas
              ? 'Ocultar senhas'
              : 'Mostrar senhas',
          icon: Icon(
            mostrarSenhas
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () {
            setState(() => mostrarSenhas = !mostrarSenhas);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();
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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // INFORMAÇÕES DA CONTA
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: papel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: cafe),
                          SizedBox(width: 10),
                          Text(
                            'Informações da conta',
                            style: TextStyle(
                              color: cafe,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Este nome será exibido na Home, '
                        'no perfil e nos rankings.',
                        style: TextStyle(color: marrom),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: nomeController,
                        maxLength: 60,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome de exibição',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              salvandoNome ? null : salvarNome,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            salvandoNome
                                ? 'Salvando...'
                                : 'Salvar nome',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SEGURANÇA DA CONTA
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: papel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security_outlined, color: cafe),
                          SizedBox(width: 10),
                          Text(
                            'Segurança da conta',
                            style: TextStyle(
                              color: cafe,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Atualize sua senha para manter '
                        'sua conta protegida.',
                        style: TextStyle(color: marrom),
                      ),
                      const SizedBox(height: 22),
                      campoSenha(
                        'Senha atual',
                        senhaAtualController,
                      ),
                      const SizedBox(height: 15),
                      campoSenha(
                        'Nova senha',
                        novaSenhaController,
                      ),
                      const SizedBox(height: 15),
                      campoSenha(
                        'Confirmar nova senha',
                        confirmarSenhaController,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Utilize uma senha forte e exclusiva, '
                        'com pelo menos 6 caracteres.',
                        style: TextStyle(
                          color: marrom,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              salvandoSenha ? null : alterarSenha,
                          icon: const Icon(Icons.lock_reset_rounded),
                          label: Text(
                            salvandoSenha
                                ? 'Alterando...'
                                : 'Alterar senha',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Sua próxima história começa aqui.',
                    style: TextStyle(
                      color: marrom,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
