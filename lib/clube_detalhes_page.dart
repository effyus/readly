import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'competicao_detalhes_page.dart';
import 'criar_competicao_page.dart';

class ClubeDetalhesPage extends StatelessWidget {
  final String clubeId;
  final Map<String, dynamic> clube;

  const ClubeDetalhesPage({
    super.key,
    required this.clubeId,
    required this.clube,
  });

  static const cafe = Color(0xFF5D4037);
  static const marrom = Color(0xFF795548);
  static const papel = Color(0xFFF5EFE3);
  static const papelClaro = Color(0xFFFFFCF7);
  static const borda = Color(0xFFD8C7AE);

  DocumentReference<Map<String, dynamic>> get clubeRef =>
      FirebaseFirestore.instance.collection('clubes').doc(clubeId);

  Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    required String acao,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(acao),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> sairDoClube(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmado = await confirmar(
      context,
      titulo: 'Sair do clube?',
      mensagem: 'Você deixará de participar deste clube e de suas '
          'competições. Seu histórico pessoal de leitura não será apagado.',
      acao: 'Sair do clube',
    );
    if (!confirmado || !context.mounted) return;

    try {
      await clubeRef.update({
        'participantes': FieldValue.arrayRemove([uid]),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair do clube: $e')),
      );
    }
  }

  Future<void> excluirClube(BuildContext context) async {
    final confirmado = await confirmar(
      context,
      titulo: 'Excluir clube?',
      mensagem: 'O clube deixará de aparecer para todos os participantes. '
          'Esta ação não poderá ser desfeita pelo aplicativo.',
      acao: 'Excluir clube',
    );
    if (!confirmado || !context.mounted) return;

    try {
      await clubeRef.update({
        'participantes': <String>[],
        'excluido': true,
        'excluidoEm': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $e')),
      );
    }
  }

  Future<void> editarClube(BuildContext context, Map<String, dynamic> dados) {
    return showDialog<void>(
      context: context,
      builder: (_) => _EditarClubeDialog(
        clubeRef: clubeRef,
        nomeInicial: dados['nome'] as String? ?? '',
        descricaoInicial: dados['descricao'] as String? ?? '',
      ),
    );
  }

  void _abrirCriacao(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriarCompeticaoPage(clubeId: clubeId),
      ),
    );
  }

  void _abrirCompeticao(BuildContext context, String competicaoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompeticaoDetalhesPage(
          clubeId: clubeId,
          competicaoId: competicaoId,
        ),
      ),
    );
  }

  _VisualModalidade _visual(String modalidade) => switch (modalidade) {
        'quem_le_mais' => const _VisualModalidade(
            titulo: 'QUEM LÊ MAIS',
            descricao: 'Mais páginas vence',
            cor: cafe,
            fundoIcone: Color(0xFFE7D7C2),
            icone: Icons.menu_book_rounded,
          ),
        'mais_consistente' => const _VisualModalidade(
            titulo: 'MAIS CONSISTENTE',
            descricao: 'Mais dias de leitura vence',
            cor: Color(0xFFB47C42),
            fundoIcone: Color(0xFFF1E4D0),
            icone: Icons.local_fire_department_rounded,
          ),
        'meta_coletiva' => const _VisualModalidade(
            titulo: 'META COLETIVA',
            descricao: 'Todos leem juntos',
            cor: Color(0xFF4C6C60),
            fundoIcone: Color(0xFFDFEAE5),
            icone: Icons.groups_rounded,
          ),
        _ => const _VisualModalidade(
            titulo: 'COMPETIÇÃO',
            descricao: 'Desafio de leitura',
            cor: marrom,
            fundoIcone: Color(0xFFE7D7C2),
            icone: Icons.emoji_events_outlined,
          ),
      };

  DateTime? _inicio(Map<String, dynamic> dados) {
    final valor = dados['criadoEm'];
    return valor is Timestamp ? valor.toDate() : null;
  }

  DateTime? _fim(Map<String, dynamic> dados) {
    final inicio = _inicio(dados);
    final duracao = (dados['duracaoDias'] as num?)?.toInt() ?? 0;
    if (inicio == null || duracao <= 0) return null;
    return inicio.add(Duration(days: duracao));
  }

  String _situacao(Map<String, dynamic> dados, DateTime agora) {
    final status = dados['status'] as String?;
    final inicio = _inicio(dados);
    final fim = _fim(dados);
    if (status == 'concluida' || status == 'cancelada' ||
        (fim != null && !agora.isBefore(fim))) {
      return 'Encerrada';
    }
    if (status == 'agendada' ||
        (inicio != null && agora.isBefore(inicio))) {
      return 'Agendada';
    }
    return 'Em andamento';
  }

  Widget _cartaoCompeticao(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
    String situacao,
  ) {
    final dados = documento.data();
    final tipo = dados['modalidade'] as String? ?? '';
    final visual = _visual(tipo);
    final duracao = (dados['duracaoDias'] as num?)?.toInt() ?? 0;
    final meta = (dados['metaValor'] as num?)?.toInt() ?? 0;
    final fim = _fim(dados);
    final nome = (dados['nome'] as String?)?.trim();

    return Card(
      color: papelClaro,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _abrirCompeticao(context, documento.id),
        child: Column(
          children: [
            Container(height: 6, color: visual.cor),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: visual.fundoIcone,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(visual.icone, color: visual.cor, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visual.titulo,
                              style: TextStyle(
                                color: visual.cor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nome == null || nome.isEmpty ? 'Competição' : nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: cafe,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              visual.descricao,
                              style: const TextStyle(color: marrom, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: marrom),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _chip(
                        Icons.circle,
                        situacao,
                        situacao == 'Em andamento'
                            ? const Color(0xFF4C6C60)
                            : marrom,
                      ),
                      if (duracao > 0)
                        _chip(Icons.calendar_today_outlined, '$duracao dias', marrom),
                      if (tipo == 'meta_coletiva' && meta > 0)
                        _chip(Icons.flag_outlined, 'Meta: $meta páginas', visual.cor),
                    ],
                  ),
                  if (fim != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      'Término previsto: ${_formatarData(fim)}',
                      style: const TextStyle(fontSize: 12, color: marrom),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  Widget _chip(IconData icone, String texto, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 12),
            const SizedBox(width: 5),
            Text(texto, style: TextStyle(color: cor, fontSize: 11,
                fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _grupoCompeticions(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
    DateTime agora,
  ) {
    if (documentos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Este clube ainda não possui competições.'),
        ),
      );
    }

    final ativas = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final agendadas = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final encerradas = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in documentos) {
      final situacao = _situacao(doc.data(), agora);
      if (situacao == 'Encerrada') {
        encerradas.add(doc);
      } else if (situacao == 'Agendada') {
        agendadas.add(doc);
      } else {
        ativas.add(doc);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ativas.isNotEmpty) ...[
          _cabecalhoGrupo('Em andamento', ativas.length),
          const SizedBox(height: 10),
          for (final doc in ativas) _cartaoCompeticao(context, doc, 'Em andamento'),
        ],
        if (agendadas.isNotEmpty) ...[
          const SizedBox(height: 12),
          _cabecalhoGrupo('Agendadas', agendadas.length),
          const SizedBox(height: 10),
          for (final doc in agendadas) _cartaoCompeticao(context, doc, 'Agendada'),
        ],
        if (encerradas.isNotEmpty) ...[
          const SizedBox(height: 9),
          Card(
            color: papelClaro,
            child: ExpansionTile(
              leading: const Icon(Icons.history_rounded, color: marrom),
              title: Text('Encerradas (${encerradas.length})',
                  style: const TextStyle(color: cafe, fontWeight: FontWeight.bold)),
              subtitle: const Text('Toque para consultar os desafios anteriores'),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              children: [
                for (final doc in encerradas)
                  _cartaoCompeticao(context, doc, 'Encerrada'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cabecalhoGrupo(String texto, int quantidade) => Row(
        children: [
          Text(texto,
              style: const TextStyle(color: cafe, fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 9),
          Text('$quantidade', style: const TextStyle(color: marrom)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: clubeRef.snapshots(),
      builder: (context, clubeSnapshot) {
        if (clubeSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Erro ao carregar o clube.')),
          );
        }
        if (!clubeSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final dados = clubeSnapshot.data!.data();
        if (dados == null || dados['excluido'] == true ||
            !(dados['participantes'] as List? ?? []).contains(uid)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Clube')),
            body: const Center(
              child: Text('Este clube não está mais disponível para sua conta.'),
            ),
          );
        }

        final proprietario = dados['criadorId'] == uid;
        final competicoesRef = clubeRef.collection('competicoes');
        final participantes = (dados['participantes'] as List? ?? []).length;
        final codigo = (dados['codigoEntrada'] as String?) ?? '-';
        final descricao = (dados['descricao'] as String? ?? '').trim();

        return Scaffold(
          backgroundColor: papel,
          appBar: AppBar(
            backgroundColor: papel,
            foregroundColor: cafe,
            title: const Text('Detalhes do clube'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Opções do clube',
                icon: const Icon(Icons.more_vert),
                onSelected: (opcao) {
                  if (opcao == 'editar') {
                    editarClube(context, dados);
                  } else if (opcao == 'sair') {
                    sairDoClube(context);
                  } else if (opcao == 'excluir') {
                    excluirClube(context);
                  }
                },
                itemBuilder: (_) => [
                  if (proprietario) ...[
                    const PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, color: cafe),
                        SizedBox(width: 10),
                        Text('Editar clube'),
                      ]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'excluir',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Excluir clube'),
                      ]),
                    ),
                  ] else
                    const PopupMenuItem<String>(
                      value: 'sair',
                      child: Row(children: [
                        Icon(Icons.logout, color: marrom),
                        SizedBox(width: 10),
                        Text('Sair do clube'),
                      ]),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                dados['nome'] as String? ?? 'Clube',
                style: const TextStyle(
                  color: cafe,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),
              if (descricao.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(descricao,
                    style: const TextStyle(color: marrom, fontSize: 14)),
              ],
              const SizedBox(height: 15),
              Card(
                color: papelClaro,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informações do clube',
                          style: TextStyle(color: cafe, fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 8, children: [
                        _chip(Icons.people_outline, '$participantes participantes', marrom),
                        _chip(Icons.badge_outlined,
                            proprietario ? 'Proprietário' : 'Membro', marrom),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.key_outlined, color: marrom, size: 18),
                          const SizedBox(width: 8),
                          const Text('Código:', style: TextStyle(color: marrom)),
                          const SizedBox(width: 7),
                          SelectableText(codigo,
                              style: const TextStyle(color: cafe,
                                  fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Competições do clube',
                        style: TextStyle(color: cafe, fontSize: 21,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (proprietario)
                    IconButton(
                      tooltip: 'Criar competição',
                      onPressed: () => _abrirCriacao(context),
                      icon: const Icon(Icons.add_circle_outline, color: cafe),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: competicoesRef.orderBy('criadoEm', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Erro ao carregar as competições.');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final competicoes = snapshot.data!.docs
                      .where((doc) => doc.data()['excluido'] != true)
                      .toList();
                  return _grupoCompeticions(context, competicoes, DateTime.now());
                },
              ),
              if (proprietario) ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _abrirCriacao(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar nova competição'),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _VisualModalidade {
  final String titulo;
  final String descricao;
  final Color cor;
  final Color fundoIcone;
  final IconData icone;

  const _VisualModalidade({
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.fundoIcone,
    required this.icone,
  });
}

class _EditarClubeDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> clubeRef;
  final String nomeInicial;
  final String descricaoInicial;

  const _EditarClubeDialog({
    required this.clubeRef,
    required this.nomeInicial,
    required this.descricaoInicial,
  });

  @override
  State<_EditarClubeDialog> createState() => _EditarClubeDialogState();
}

class _EditarClubeDialogState extends State<_EditarClubeDialog> {
  late final TextEditingController nome;
  late final TextEditingController descricao;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    nome = TextEditingController(text: widget.nomeInicial);
    descricao = TextEditingController(text: widget.descricaoInicial);
  }

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    final novoNome = nome.text.trim();
    final novaDescricao = descricao.text.trim();
    if (novoNome.isEmpty || novoNome.length > 60 || novaDescricao.length > 300) {
      setState(() => erro = 'Nome deve ter até 60 caracteres e descrição até 300.');
      return;
    }
    if (salvando) return;
    setState(() { salvando = true; erro = null; });
    try {
      await widget.clubeRef.update({
        'nome': novoNome,
        'descricao': novaDescricao,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => erro = 'Não foi possível salvar: $e');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar clube'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nome do clube'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricao,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            if (erro != null)
              Text(erro!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvar,
          child: Text(salvando ? 'Salvando...' : 'Salvar alterações'),
        ),
      ],
    );
  }
}
