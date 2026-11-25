import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CriarCompeticaoPage extends StatefulWidget {
  final String clubeId;

  const CriarCompeticaoPage({super.key, required this.clubeId});

  @override
  State<CriarCompeticaoPage> createState() => _CriarCompeticaoPageState();
}

class _CriarCompeticaoPageState extends State<CriarCompeticaoPage> {
  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const caramelo = Color(0xFFA67C52);
  static const fundo = Color(0xFFF5EFE3);
  static const papel = Color(0xFFFFFCF7);
  static const borda = Color(0xFFD8C7AE);

  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final metaController = TextEditingController();
  final regrasController = TextEditingController();

  String modalidade = 'quem_le_mais';
  DateTime? dataTermino;
  bool salvando = false;

  DateTime somenteData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  int get duracaoDias {
    if (dataTermino == null) return 0;

    final hoje = somenteData(DateTime.now());

    // Calcula dias de calendário sem interferência
    // de horário de verão ou fuso.
    final inicioUtc = DateTime.utc(hoje.year, hoje.month, hoje.day);

    final fimUtc = DateTime.utc(
      dataTermino!.year,
      dataTermino!.month,
      dataTermino!.day,
    );

    return fimUtc.difference(inicioUtc).inDays;
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  String get descricaoModalidade {
    switch (modalidade) {
      case 'quem_le_mais':
        return 'Vence quem acumular mais páginas '
            'durante o período da competição.';

      case 'mais_consistente':
        return 'Vence quem registrar leituras '
            'no maior número de dias diferentes.';

      case 'meta_coletiva':
        return 'Todos os participantes colaboram '
            'para alcançar uma meta de páginas.';

      default:
        return '';
    }
  }

  Future<void> selecionarDataTermino() async {
    final hoje = somenteData(DateTime.now());

    final primeiroDia = hoje.add(const Duration(days: 1));

    final ultimoDia = DateTime(hoje.year + 5, hoje.month, hoje.day);

    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataTermino != null && !dataTermino!.isBefore(primeiroDia)
          ? dataTermino!
          : hoje.add(const Duration(days: 30)),
      firstDate: primeiroDia,
      lastDate: ultimoDia,
      helpText: 'Selecione o término da competição',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: cafe,
              onPrimary: Colors.white,
              surface: papel,
              onSurface: cafe,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida == null || !mounted) return;

    setState(() {
      dataTermino = somenteData(dataEscolhida);
    });
  }

  void mostrarMensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> salvarCompeticao() async {
    if (salvando) return;

    if (!formKey.currentState!.validate()) return;

    if (dataTermino == null || duracaoDias <= 0) {
      mostrarMensagem('Selecione uma data de término válida.');
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      mostrarMensagem('Você precisa estar conectado.');
      return;
    }

    final bool coletiva = modalidade == 'meta_coletiva';

    final int? metaValor = coletiva
        ? int.tryParse(metaController.text.trim())
        : null;

    if (coletiva && (metaValor == null || metaValor <= 0)) {
      mostrarMensagem('Informe uma meta coletiva válida.');
      return;
    }

    setState(() => salvando = true);

    try {
      final dadosCompeticao = <String, dynamic>{
        'nome': nomeController.text.trim(),
        'descricao': descricaoController.text.trim(),
        'duracaoDias': duracaoDias,
        'regras': regrasController.text.trim(),
        'modalidade': modalidade,
        'tipoCompeticao': coletiva ? 'colaborativa' : 'individual',
        'criadoPor': usuario.uid,
        'criadoEm': FieldValue.serverTimestamp(),

        // Somente a modalidade coletiva utiliza meta.
        if (coletiva) 'metaValor': metaValor,
      };

      await FirebaseFirestore.instance
          .collection('clubes')
          .doc(widget.clubeId)
          .collection('competicoes')
          .add(dadosCompeticao);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        e.code == 'permission-denied'
            ? 'Você não tem permissão para criar '
                  'esta competição. Verifique as '
                  'regras do Firestore.'
            : 'Erro ao criar competição: '
                  '${e.message ?? e.code}',
      );
    } catch (e) {
      mostrarMensagem('Erro inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  Widget campoNumero(TextEditingController controller, String titulo) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: const Icon(Icons.flag_outlined, color: cafe),
      ),
      validator: (valor) {
        final numero = int.tryParse(valor?.trim() ?? '');

        if (numero == null || numero <= 0) {
          return 'Informe um número maior que zero.';
        }

        return null;
      },
    );
  }

  Widget opcaoModalidade({
    required String valor,
    required String titulo,
    required String descricao,
    required IconData icone,
  }) {
    final selecionada = modalidade == valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selecionada ? const Color(0xFFE7D7C2) : papel,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<String>(
          value: valor,
          groupValue: modalidade,
          onChanged: salvando
              ? null
              : (novaModalidade) {
                  if (novaModalidade == null) return;
                  setState(() {
                    modalidade = novaModalidade;
                  });
                },
          title: Text(
            titulo,
            style: const TextStyle(color: cafe, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(descricao),
          secondary: Icon(icone, color: cafe),
          activeColor: cafe,
        ),
      ),
    );
  }

  Widget secaoCalendario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: cafe),
            SizedBox(width: 9),
            Text(
              'Período da competição',
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
          'A competição começa quando for criada. '
          'Selecione no calendário quando ela '
          'deverá terminar.',
          style: TextStyle(color: marrom, height: 1.4),
        ),

        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: papel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borda),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.today_outlined, color: cafe),
                title: const Text('Data de início'),
                subtitle: Text(formatarData(DateTime.now())),
                trailing: const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: marrom,
                ),
              ),

              const Divider(height: 1),

              ListTile(
                onTap: salvando ? null : selecionarDataTermino,
                leading: const Icon(
                  Icons.event_available_outlined,
                  color: cafe,
                ),
                title: const Text('Data de término'),
                subtitle: Text(
                  dataTermino == null
                      ? 'Toque para escolher no calendário'
                      : formatarData(dataTermino!),
                ),
                trailing: const Icon(Icons.calendar_month, color: cafe),
              ),
            ],
          ),
        ),

        if (dataTermino != null && duracaoDias > 0) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE7D7C2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Duração calculada',
                  style: TextStyle(color: marrom, fontSize: 14),
                ),

                const SizedBox(height: 6),

                Text(
                  '$duracaoDias '
                  '${duracaoDias == 1 ? 'dia' : 'dias'}',
                  style: const TextStyle(
                    color: cafe,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'De ${formatarData(DateTime.now())} '
                  'até ${formatarData(dataTermino!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: marrom, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    metaController.dispose();
    regrasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool coletiva = modalidade == 'meta_coletiva';

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(title: const Text('Nova competição')),
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
                    'Escolha a modalidade, defina o '
                    'período e incentive seu clube '
                    'a ler cada vez mais.',
                    style: TextStyle(color: fundo, height: 1.5),
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
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe um nome.';
                }
                return null;
              },
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

            opcaoModalidade(
              valor: 'quem_le_mais',
              titulo: 'Quem lê mais',
              descricao: 'Vence quem acumular mais páginas.',
              icone: Icons.menu_book_rounded,
            ),

            opcaoModalidade(
              valor: 'mais_consistente',
              titulo: 'Mais consistente',
              descricao: 'Vence quem lê em mais dias diferentes.',
              icone: Icons.local_fire_department_rounded,
            ),

            opcaoModalidade(
              valor: 'meta_coletiva',
              titulo: 'Meta coletiva',
              descricao: 'Todos colaboram para alcançar a meta.',
              icone: Icons.groups_rounded,
            ),

            const SizedBox(height: 16),

            Text(
              descricaoModalidade,
              style: const TextStyle(
                color: marrom,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),

            if (coletiva) ...[
              const SizedBox(height: 24),

              campoNumero(metaController, 'Meta coletiva de páginas'),
            ],

            const SizedBox(height: 28),

            secaoCalendario(),

            const SizedBox(height: 24),

            TextFormField(
              controller: regrasController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Regras (opcional)',
                hintText: 'Defina as regras do desafio.',
                prefixIcon: Icon(Icons.rule_outlined),
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
                salvando ? 'Criando competição...' : 'Criar competição',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cafe,
                padding: const EdgeInsets.all(18),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
