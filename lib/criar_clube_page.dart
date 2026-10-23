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
  static const marrom = Color.fromARGB(255, 132, 81, 11);

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final objetivoController = TextEditingController();
  final metaController = TextEditingController();
  final duracaoController = TextEditingController();
  final competidoresController = TextEditingController();
  final regrasController = TextEditingController();

  String modalidade = 'quem_le_mais';
  bool carregando = false;

  String get textoMeta {
    switch (modalidade) {
      case 'mais_consistente':
        return 'Meta de dias de leitura';
      case 'meta_coletiva':
        return 'Meta coletiva de páginas';
      default:
        return 'Meta de páginas por participante';
    }
  }

  String gerarCodigo() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final aleatorio = Random.secure();

    return List.generate(
      8,
      (_) => caracteres[aleatorio.nextInt(caracteres.length)],
    ).join();
  }

  Future<void> criarClube() async {
    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    final objetivo = objetivoController.text.trim();
    final meta = int.tryParse(metaController.text.trim());
    final duracao = int.tryParse(duracaoController.text.trim());
    final limiteTexto = competidoresController.text.trim();
    final limite = limiteTexto.isEmpty ? null : int.tryParse(limiteTexto);
    final regras = regrasController.text.trim();

    if (nome.isEmpty ||
        objetivo.isEmpty ||
        meta == null ||
        meta <= 0 ||
        duracao == null ||
        duracao <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha o nome, informe uma meta '
            'e sua duração.',
          ),
        ),
      );
      return;
    }

    if (limiteTexto.isNotEmpty && (limite == null || limite < 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O limite deve ser de pelo menos 2 competidores.'),
        ),
      );
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre na sua conta para criar um clube.'),
        ),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final codigo = gerarCodigo();

      final clubes = FirebaseFirestore.instance.collection('clubes');

      // Confere se o código já existe antes de utilizá-lo.
      final codigoExistente = await clubes
          .where('codigoEntrada', isEqualTo: codigo)
          .limit(1)
          .get();

      if (codigoExistente.docs.isNotEmpty) {
        throw Exception('Não foi possível gerar um código. Tente novamente.');
      }

      await clubes.add({
        'nome': nome,
        'descricao': descricao,
        'objetivo': objetivo,
        'metaValor': meta,
        'duracaoDias': duracao,
        'limiteCompetidores': limite,
        'regras': regras,
        'modalidade': modalidade,
        'tipoCompeticao': modalidade == 'meta_coletiva'
            ? 'colaborativa'
            : 'individual',
        'criadorId': usuario.uid,
        'participantes': [usuario.uid],
        'codigoEntrada': codigo,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clube criado! Código de entrada: $codigo'),
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('ERRO AO CRIAR CLUBE: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao criar clube: $e')));
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    objetivoController.dispose();
    metaController.dispose();
    duracaoController.dispose();
    competidoresController.dispose();
    regrasController.dispose();
    super.dispose();
  }

  Widget campoNumerico({
    required TextEditingController controller,
    required String titulo,
    String? ajuda,
    bool obrigatorio = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: titulo,
        helperText: ajuda,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Defina como será a competição e convide outros leitores.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do clube *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Modalidade da competição',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            RadioGroup<String>(
              groupValue: modalidade,
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => modalidade = valor);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'quem_le_mais',
                    title: Text('Quem lê mais'),
                    subtitle: Text(
                      'Competição individual: vence quem acumular '
                      'mais páginas lidas.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'mais_consistente',
                    title: Text('Quem é mais consistente'),
                    subtitle: Text(
                      'Competição individual: classificação baseada '
                      'na frequência de leitura.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'meta_coletiva',
                    title: Text('Meta coletiva'),
                    subtitle: Text(
                      'Competição colaborativa: todos contribuem '
                      'para alcançar uma meta comum.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: metaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '$textoMeta *',
                helperText: modalidade == 'mais_consistente'
                    ? 'Quantidade de dias de leitura pretendida'
                    : 'Informe a quantidade de páginas',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: duracaoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração da competição (dias) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: competidoresController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite de competidores (opcional)',
                helperText: 'Deixe vazio para não definir um limite',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: regrasController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Regras (opcional)',
                hintText: 'Defina as regras para os participantes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
