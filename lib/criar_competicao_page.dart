
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CriarCompeticaoPage extends StatefulWidget {
  final String clubeId;

  const CriarCompeticaoPage({
    super.key,
    required this.clubeId,
  });

  @override
  State<CriarCompeticaoPage> createState() =>
      _CriarCompeticaoPageState();
}

class _CriarCompeticaoPageState
    extends State<CriarCompeticaoPage> {
  static const cafe = Color(0xFF5D4037);
  static const fundo = Color(0xFFF5EFE3);

  final formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final metaController = TextEditingController();
  final duracaoController = TextEditingController();
  final regrasController = TextEditingController();

  String modalidade = 'quem_le_mais';
  bool salvando = false;

  String get rotuloMeta {
    switch (modalidade) {
      case 'mais_consistente':
        return 'Meta de dias de leitura';
      case 'meta_coletiva':
        return 'Meta coletiva de páginas';
      default:
        return 'Meta de páginas por participante';
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    metaController.dispose();
    duracaoController.dispose();
    regrasController.dispose();
    super.dispose();
  }

  Future<void> salvarCompeticao() async {
    if (!formKey.currentState!.validate() || salvando) return;

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    setState(() => salvando = true);

    try {
      await FirebaseFirestore.instance
          .collection('clubes')
          .doc(widget.clubeId)
          .collection('competicoes')
          .add({
        'nome': nomeController.text.trim(),
        'descricao': descricaoController.text.trim(),
        'metaValor': int.parse(metaController.text.trim()),
        'duracaoDias': int.parse(duracaoController.text.trim()),
        'regras': regrasController.text.trim(),
        'modalidade': modalidade,
        'tipoCompeticao': modalidade == 'meta_coletiva'
            ? 'colaborativa'
            : 'individual',
        'criadoPor': usuario.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Competição criada com sucesso!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Você não tem permissão para criar esta competição.'
                : 'Erro ao criar competição: ${e.message ?? e.code}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget campoNumero(
    TextEditingController controller,
    String titulo,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: titulo),
      validator: (valor) {
        final numero = int.tryParse(valor?.trim() ?? '');
        if (numero == null || numero <= 0) {
          return 'Informe um número maior que zero.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Nova competição'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cafe,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFEACDA7),
                    size: 44,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Um novo desafio começa aqui.',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Defina uma meta e incentive os membros '
                    'do clube a lerem mais.',
                    style: TextStyle(
                      color: Color(0xFFF5EFE3),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            TextFormField(
              controller: nomeController,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nome da competição',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (valor) =>
                  valor == null || valor.trim().isEmpty
                      ? 'Informe um nome.'
                      : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: descricaoController,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Modalidade',
              style: TextStyle(
                color: cafe,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),

            const SizedBox(height: 10),

            ...[
              (
                'quem_le_mais',
                'Quem lê mais',
                'Vence quem acumular mais páginas.',
                Icons.menu_book_rounded,
              ),
              (
                'mais_consistente',
                'Mais consistente',
                'Vence quem mantém maior frequência.',
                Icons.local_fire_department_rounded,
              ),
              (
                'meta_coletiva',
                'Meta coletiva',
                'Todos colaboram para alcançar uma meta.',
                Icons.groups_rounded,
              ),
            ].map((opcao) {
              final selecionada = modalidade == opcao.$1;

              return Card(
                color: selecionada
                    ? const Color(0xFFE7D7C2)
                    : const Color(0xFFFFFCF7),
                child: RadioListTile<String>(
                  value: opcao.$1,
                  groupValue: modalidade,
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() => modalidade = valor);
                    }
                  },
                  title: Text(opcao.$2),
                  subtitle: Text(opcao.$3),
                  secondary: Icon(opcao.$4, color: cafe),
                ),
              );
            }),

            const SizedBox(height: 22),

            campoNumero(metaController, rotuloMeta),

            const SizedBox(height: 16),

            campoNumero(
              duracaoController,
              'Duração da competição (dias)',
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: regrasController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Regras (opcional)',
                hintText: 'Defina as regras do desafio.',
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: salvando ? null : salvarCompeticao,
              icon: salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                salvando
                    ? 'Criando competição...'
                    : 'Criar competição',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cafe,
                padding: const EdgeInsets.all(18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
