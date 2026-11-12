
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
  static const marrom = Color(0xFF795548);
  static const fundo = Color(0xFFF5EFE3);

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
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

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
  }

  Future<void> criarClube() async {
    if (carregando) return;

    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    
    final meta = int.tryParse(metaController.text.trim());
    final duracao = int.tryParse(duracaoController.text.trim());

    final limiteTexto = competidoresController.text.trim();
    final limite = limiteTexto.isEmpty
        ? null
        : int.tryParse(limiteTexto);

    final regras = regrasController.text.trim();

    // Valida os campos obrigatórios.
    if (nome.isEmpty) {
      mostrarMensagem('Informe o nome do clube.');
      return;
    }

    if (meta == null || meta <= 0) {
      mostrarMensagem('Informe uma meta válida, maior que zero.');
      return;
    }

    if (duracao == null || duracao <= 0) {
      mostrarMensagem('Informe uma duração válida em dias.');
      return;
    }

    if (limiteTexto.isNotEmpty &&
        (limite == null || limite < 2)) {
      mostrarMensagem(
        'O limite deve ser de pelo menos 2 competidores.',
      );
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      mostrarMensagem('Entre na sua conta para criar um clube.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final codigo = gerarCodigo();

      final dadosClube = <String, dynamic>{
        'nome': nome,
        'descricao': descricao,
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
      };

      // Salva diretamente no Firestore.
      // Não fazemos uma consulta prévia pelo código, pois
      // essa consulta pode ser bloqueada pelas regras de leitura.
      await FirebaseFirestore.instance
          .collection('clubes')
          .add(dadosClube);

      if (!mounted) return;

      mostrarMensagem(
        'Clube criado com sucesso! Código: $codigo',
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      debugPrint('Erro Firebase ao criar clube: ${e.code}');
      debugPrint('Detalhes: ${e.message}');

      String mensagem;

      if (e.code == 'permission-denied') {
        mensagem =
            'O Firebase bloqueou a criação do clube. '
            'Verifique as regras do Firestore.';
      } else if (e.code == 'unavailable') {
        mensagem =
            'Não foi possível conectar ao Firebase. '
            'Verifique sua internet e tente novamente.';
      } else {
        mensagem =
            'Erro ao criar clube (${e.code}): '
            '${e.message ?? "Sem detalhes"}';
      }

      mostrarMensagem(mensagem);
    } catch (e, stackTrace) {
      debugPrint('Erro ao criar clube: $e');
      debugPrintStack(stackTrace: stackTrace);

      mostrarMensagem(
        'Não foi possível criar o clube. Tente novamente.',
      );
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
    IconData? icone,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: titulo,
        helperText: ajuda,
        prefixIcon: icone == null ? null : Icon(icone),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Criar clube'),
        backgroundColor: marrom,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: marrom,
            ),
            const SizedBox(height: 16),

            const Text(
              'Crie seu clube de leitura',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: marrom,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Defina como será a competição e convide outros leitores.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            TextField(
              controller: nomeController,
              textCapitalization: TextCapitalization.words,
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
                  setState(() {
                    modalidade = valor;
                  });
                }
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'quem_le_mais',
                    title: Text('Quem lê mais'),
                    subtitle: Text(
                      'Vence quem acumular mais páginas lidas.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'mais_consistente',
                    title: Text('Quem é mais consistente'),
                    subtitle: Text(
                      'Classificação baseada na frequência de leitura.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'meta_coletiva',
                    title: Text('Meta coletiva'),
                    subtitle: Text(
                      'Todos contribuem para alcançar uma meta comum.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            campoNumerico(
              controller: metaController,
              titulo: '$textoMeta *',
              ajuda: modalidade == 'mais_consistente'
                  ? 'Quantidade de dias de leitura pretendida'
                  : 'Informe a quantidade de páginas',
              icone: Icons.flag_outlined,
            ),
            const SizedBox(height: 16),

            campoNumerico(
              controller: duracaoController,
              titulo: 'Duração da competição (dias) *',
              icone: Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 16),

            campoNumerico(
              controller: competidoresController,
              titulo: 'Limite de competidores (opcional)',
              ajuda: 'Deixe vazio para não definir um limite',
              icone: Icons.people_outline,
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
              icon: carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                carregando ? 'Criando clube...' : 'Criar clube',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: marrom,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
