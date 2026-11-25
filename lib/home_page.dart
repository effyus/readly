import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'personalizar_avatar_page.dart';

import 'editar_perfil_page.dart';

import 'entrar_clube_page.dart';

import 'competicao_detalhes_page.dart';

import 'meus_livros_page.dart';

import 'clube_detalhes_page.dart';

import 'criar_clube_page.dart';

import 'login_page.dart';

import 'livros_competicao_page.dart';

import 'leitura_service.dart';
import 'registro_rapido_competicao_sheet.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:fluttermoji/fluttermoji.dart';

class ReadlyHomePage extends StatefulWidget {

  const ReadlyHomePage({super.key});

  @override

  State<ReadlyHomePage> createState() => _ReadlyHomePageState();

}

class _ReadlyHomePageState extends State<ReadlyHomePage> {

  int paginaAtual = 0;

  int secaoDesafios = 0;

  final Color marrom = Color(0xFF795548);

  Future<int> contarCompeticoesAtivas(

    List<QueryDocumentSnapshot<Map<String, dynamic>>> clubes,

  ) async {

    int total = 0;

    final agora = DateTime.now();

    for (final clube in clubes) {

      final consulta = await FirebaseFirestore.instance

          .collection('clubes')

          .doc(clube.id)

          .collection('competicoes')

          .get();

      for (final competicao in consulta.docs) {

        final dados = competicao.data();

        // Não contabilizar competições excluídas.

        if (dados['excluido'] == true) {

          continue;

        }

        final status = dados['status'] as String?;

        if (status == 'em_andamento') {

          total++;

          continue;

        }

        if (status != null) continue;

        // Compatibilidade com competições antigas

        // que ainda não possuem campo "status".

        final criadoEm = dados['criadoEm'];

        final duracao = dados['duracaoDias'];

        if (criadoEm is Timestamp && duracao is int) {

          final inicio = criadoEm.toDate();

          final fim = inicio.add(Duration(days: duracao));

          if (!agora.isBefore(inicio) && agora.isBefore(fim)) {

            total++;

          }

        }

      }

    }

    return total;

  }

  @override

  Widget build(BuildContext context) {

    final paginas = [

      inicioPage(),

      const MeusLivrosPage(),

      desafiosPage(),

      perfilPage(),

    ];

    return Scaffold(

      backgroundColor: const Color(0xFFF5EFE3),

      appBar: paginaAtual == 1

          ? null

          : AppBar(

              backgroundColor: const Color(0xFFF5EFE3),

              title: Row(

                children: [

                  Icon(Icons.menu_book_rounded, color: marrom, size: 30),

                  const SizedBox(width: 8),

                  Text(

                    'Readly',

                    style: TextStyle(

                      color: marrom,

                      fontWeight: FontWeight.bold,

                      fontSize: 24,

                    ),

                  ),

                ],

              ),

              actions: [

                IconButton(

                  onPressed: () => setState(() => paginaAtual = 3),
                  icon: const Icon(Icons.account_circle_outlined),

                  tooltip: 'Meu perfil',

                ),

                const SizedBox(width: 8),

              ],

            ),

      body: paginas[paginaAtual],

      bottomNavigationBar: NavigationBar(

        selectedIndex: paginaAtual,

        onDestinationSelected: (indice) {

          setState(() => paginaAtual = indice);

        },

        destinations: const [

          NavigationDestination(

            icon: Icon(Icons.home_outlined),

            selectedIcon: Icon(Icons.home_rounded),

            label: 'Início',

          ),

          NavigationDestination(

            icon: Icon(Icons.menu_book_outlined),

            selectedIcon: Icon(Icons.menu_book_rounded),

            label: 'Biblioteca',

          ),

          NavigationDestination(

            icon: Icon(Icons.emoji_events_outlined),

            selectedIcon: Icon(Icons.emoji_events_rounded),

            label: 'Desafios',

          ),

          NavigationDestination(

            icon: Icon(Icons.person_outline),

            selectedIcon: Icon(Icons.person_rounded),

            label: 'Perfil',

          ),

        ],

      ),

    );

  }

  // Painel de leitura: uma ação principal, progresso e estatísticas compactas.
  Widget inicioPage() {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    const caramelo = Color(0xFFA67C52);
    const papel = Color(0xFFFFFCF7);
    const borda = Color(0xFFD8C7AE);
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return const Center(child: Text('Faça login novamente.'));

    Widget caixa({required Widget child, EdgeInsets? padding}) => Container(
      padding: padding ?? const EdgeInsets.all(17),
      decoration: BoxDecoration(color: papel, borderRadius: BorderRadius.circular(20), border: Border.all(color: borda)),
      child: child,
    );

    Widget numero({required String valor, required String rotulo, required IconData icone}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, color: caramelo, size: 22),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(color: cafe, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(rotulo, style: const TextStyle(color: marrom, fontSize: 11)),
        ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('usuarios').doc(usuario.uid).snapshots(),
          builder: (context, snapshot) {
            final nomeFirestore = (snapshot.data?.data()?['nome'] as String? ?? '').trim();
            final nome = nomeFirestore.isNotEmpty ? nomeFirestore : (usuario.displayName ?? '');
            final primeiro = nome.trim().isNotEmpty ? nome.trim().split(RegExp(r'\s+')).first : 'leitor';
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SUA JORNADA LITERÁRIA', style: TextStyle(color: caramelo, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Olá, $primeiro! 👋', style: const TextStyle(color: cafe, fontSize: 29, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Que história vamos continuar hoje?', style: TextStyle(color: marrom, fontSize: 14)),
            ]);
          },
        ),
        const SizedBox(height: 23),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: LeituraService.observarLivros(),
          builder: (context, livrosSnapshot) {
            if (livrosSnapshot.hasError) return caixa(child: const Text('Não foi possível carregar seus livros.'));
            if (!livrosSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final livros = livrosSnapshot.data!.docs.where((doc) => doc.data()['removido'] != true).toList();
            final emAndamento = livros.where((doc) => doc.data()['status'] == 'lendo').toList();
            emAndamento.sort((a,b) {
              final at = a.data()['atualizadoEm']; final bt = b.data()['atualizadoEm'];
              if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
              return 0;
            });
            final concluidos = livros.where((doc) => doc.data()['status'] == 'concluido').length;
            final livro = emAndamento.isEmpty ? null : emAndamento.first;

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Continue sua leitura', style: TextStyle(color: cafe, fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => setState(() => paginaAtual = 1), child: const Text('Biblioteca')),
              ]),
              const SizedBox(height: 7),
              if (livro == null)
                caixa(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.auto_stories_rounded, color: caramelo, size: 34),
                  const SizedBox(height: 10),
                  const Text('Sua próxima história começa aqui', style: TextStyle(color: cafe, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Entre em uma competição e escolha um livro para começar.', style: TextStyle(color: marrom)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => setState(() { paginaAtual = 2; secaoDesafios = 0; }), icon: const Icon(Icons.emoji_events_outlined), label: const Text('Explorar desafios'), style: FilledButton.styleFrom(backgroundColor: cafe)),
                ]))
              else Builder(builder: (context) {
                final dados = livro.data();
                final titulo = (dados['titulo'] as String?) ?? 'Meu livro';
                final autor = (dados['autor'] as String?) ?? '';
                final capa = (dados['capaUrl'] as String?)?.trim() ?? '';
                final total = (dados['totalPaginas'] as num?)?.toInt() ?? 0;
                final atual = (dados['paginaAtual'] as num?)?.toInt() ?? 0;
                final porcentagem = total > 0 ? (atual/total).clamp(0.0,1.0).toDouble() : 0.0;
                // Os documentos pessoais usam IDs no formato clube_competicao_livroOficial.
                // Aqui, só abrimos registro rápido quando os IDs são explícitos e confiáveis.
                final clubeId = dados['clubeId'] as String?;
                final competicaoId = dados['competicaoId'] as String?;
                final podeRegistrar = clubeId != null && clubeId.isNotEmpty && competicaoId != null && competicaoId.isNotEmpty;
                return caixa(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 83, height: 116,
                      child: capa.startsWith('http') ? Image.network(capa.replaceFirst('http://', 'https://'), fit: BoxFit.cover, errorBuilder: (_,__,___) => const ColoredBox(color: Color(0xFFE7D7C2), child: Icon(Icons.book, color: cafe, size: 35))) : const ColoredBox(color: Color(0xFFE7D7C2), child: Icon(Icons.book, color: cafe, size: 35)))),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('LENDO AGORA', style: TextStyle(color: caramelo, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cafe, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(autor, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: marrom, fontSize: 12)),
                      const SizedBox(height: 16),
                      Text('$atual de $total páginas', style: const TextStyle(color: marrom, fontSize: 12)),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(value: porcentagem, borderRadius: BorderRadius.circular(8), minHeight: 8, color: cafe, backgroundColor: const Color(0xFFE7D7C2)),
                    ])),
                  ]),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    onPressed: () {
                      if (podeRegistrar) {
                        abrirRegistroRapido(context, clubeId: clubeId, competicaoId: competicaoId);
                      } else {
                        setState(() => paginaAtual = 1);
                      }
                    },
                    icon: Icon(podeRegistrar ? Icons.edit_note_rounded : Icons.menu_book_rounded),
                    label: Text(podeRegistrar ? 'Registrar leitura' : 'Continuar na biblioteca'),
                    style: FilledButton.styleFrom(backgroundColor: cafe, padding: const EdgeInsets.symmetric(vertical: 15)),
                  )),
                ]));
              }),
              const SizedBox(height: 22),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: LeituraService.observarLeituras(),
                builder: (context, leiturasSnapshot) {
                  if (leiturasSnapshot.hasError) return caixa(child: const Text('Não foi possível carregar suas estatísticas.'));
                  if (!leiturasSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final leituras = leiturasSnapshot.data!.docs;
                  final paginas = leituras.fold<int>(0, (s, doc) => s + ((doc.data()['paginasLidas'] as num?)?.toInt() ?? 0));
                  final ofensiva = LeituraService.calcularOfensiva(leituras.map((doc) => doc.data()));
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Seu progresso', style: TextStyle(color: cafe, fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    caixa(child: Row(children: [
                      Expanded(child: numero(valor: '$ofensiva dias', rotulo: 'Ofensiva', icone: Icons.local_fire_department_rounded)),
                      Container(height: 58, width: 1, color: borda),
                      const SizedBox(width: 15),
                      Expanded(child: numero(valor: '$paginas', rotulo: 'Páginas lidas', icone: Icons.auto_stories_rounded)),
                      Container(height: 58, width: 1, color: borda),
                      const SizedBox(width: 15),
                      Expanded(child: numero(valor: '$concluidos', rotulo: 'Concluídos', icone: Icons.check_circle_outline)),
                    ])),
                  ]);
                },
              ),
              const SizedBox(height: 22),
              const Text('Sua comunidade', style: TextStyle(color: cafe, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('clubes').where('participantes', arrayContains: usuario.uid).snapshots(),
                builder: (context, clubeSnapshot) {
                  if (clubeSnapshot.hasError) return caixa(child: const Text('Não foi possível carregar seus clubes.'));
                  if (!clubeSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final clubes = clubeSnapshot.data!.docs.where((doc) => doc.data()['excluido'] != true).toList();
                  return caixa(child: Row(children: [
                    const Icon(Icons.groups_rounded, color: caramelo, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${clubes.length} ${clubes.length == 1 ? 'clube' : 'clubes'}', style: const TextStyle(color: cafe, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Veja suas competições e sua comunidade.', style: TextStyle(color: marrom, fontSize: 12)),
                    ])),
                    IconButton(tooltip: 'Abrir desafios', onPressed: () => setState(() {paginaAtual = 2; secaoDesafios = 0;}), icon: const Icon(Icons.arrow_forward_rounded, color: cafe)),
                  ]));
                },
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget estatisticaCard(IconData icone, String valor, String descricao) {

    const cafe = Color(0xFF5D4037);

    const marrom = Color(0xFF795548);

    const texto = Color(0xFF3E3028);

    return Container(

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(

        color: const Color(0xFFFFFCF7),

        borderRadius: BorderRadius.circular(19),

        border: Border.all(color: const Color(0xFFD8C7AE), width: 1),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(

              color: const Color(0xFFF0E5D5),

              borderRadius: BorderRadius.circular(12),

            ),

            child: Icon(icone, color: cafe, size: 24),

          ),

          const SizedBox(height: 18),

          Text(

            valor,

            style: const TextStyle(

              fontSize: 25,

              fontWeight: FontWeight.bold,

              color: texto,

            ),

          ),

          const SizedBox(height: 5),

          Text(

            descricao,

            style: const TextStyle(

              fontSize: 12,

              color: marrom,

              fontWeight: FontWeight.w500,

            ),

          ),

        ],

      ),

    );

  }

  Widget desafiosPage() {

    const cafe = Color(0xFF5D4037);

    const marrom = Color(0xFF795548);

    const papel = Color(0xFFFFFCF7);

    return Column(

      children: [

        // Cabeçalho dos desafios

        Padding(

          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(

                'Sua jornada em grupo',

                style: TextStyle(

                  color: cafe,

                  fontSize: 25,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(height: 6),

              const Text(

                'Participe de desafios e acompanhe seus clubes.',

                style: TextStyle(color: marrom, fontSize: 14),

              ),

              const SizedBox(height: 22),

              // Alternância entre competições e clubes

              Container(

                padding: const EdgeInsets.all(5),

                decoration: BoxDecoration(

                  color: const Color(0xFFE7D7C2),

                  borderRadius: BorderRadius.circular(16),

                ),

                child: Row(

                  children: [

                    Expanded(

                      child: _botaoSecaoDesafios(

                        titulo: 'Competições',

                        icone: Icons.emoji_events_outlined,

                        selecionado: secaoDesafios == 0,

                        onTap: () {

                          setState(() => secaoDesafios = 0);

                        },

                      ),

                    ),

                    const SizedBox(width: 5),

                    Expanded(

                      child: _botaoSecaoDesafios(

                        titulo: 'Meus clubes',

                        icone: Icons.groups_outlined,

                        selecionado: secaoDesafios == 1,

                        onTap: () {

                          setState(() => secaoDesafios = 1);

                        },

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

        // Conteúdo reaproveitado das páginas atuais

        Expanded(child: secaoDesafios == 0 ? competicoesPage() : clubesPage()),

      ],

    );

  }

  Widget _botaoSecaoDesafios({

    required String titulo,

    required IconData icone,

    required bool selecionado,

    required VoidCallback onTap,

  }) {

    return Material(

      color: selecionado ? const Color(0xFFFFFCF7) : Colors.transparent,

      borderRadius: BorderRadius.circular(12),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(12),

        child: Padding(

          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(icone, size: 19, color: const Color(0xFF5D4037)),

              const SizedBox(width: 7),

              Flexible(

                child: Text(

                  titulo,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(

                    color: const Color(0xFF5D4037),

                    fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,

                    fontSize: 13,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  // Identidade visual compartilhada com os cartões de Detalhes do clube.
  ({String titulo, IconData icone, Color destaque, Color suave})
      _identidadeModalidade(String modalidade) {
    switch (modalidade) {
      case 'quem_le_mais':
        return (
          titulo: 'QUEM LÊ MAIS',
          icone: Icons.menu_book_rounded,
          destaque: const Color(0xFF5D4037),
          suave: const Color(0xFFE7D7C2),
        );
      case 'mais_consistente':
        return (
          titulo: 'MAIS CONSISTENTE',
          icone: Icons.local_fire_department_rounded,
          destaque: const Color(0xFFB47C42),
          suave: const Color(0xFFF1E4D0),
        );
      case 'meta_coletiva':
        return (
          titulo: 'META COLETIVA',
          icone: Icons.groups_rounded,
          destaque: const Color(0xFF4C6C60),
          suave: const Color(0xFFDFEAE5),
        );
      default:
        return (
          titulo: 'COMPETIÇÃO',
          icone: Icons.emoji_events_outlined,
          destaque: const Color(0xFF795548),
          suave: const Color(0xFFE7D7C2),
        );
    }
  }

  // Calcula a situação usando o prazo real, inclusive nos documentos antigos
  // que ainda não têm campo 'status'.
  String _situacaoCompeticao(Map<String, dynamic> dados, DateTime agora) {
    final status = dados['status'] as String?;
    if (status == 'cancelada' || status == 'concluida') return 'Encerrada';
    final criadoEm = dados['criadoEm'];
    final duracao = (dados['duracaoDias'] as num?)?.toInt() ?? 0;
    if (criadoEm is Timestamp && duracao > 0) {
      final inicio = criadoEm.toDate();
      final fim = inicio.add(Duration(days: duracao));
      if (!agora.isBefore(fim)) return 'Encerrada';
      if (agora.isBefore(inicio)) return 'Agendada';
    }
    if (status == 'agendada') return 'Agendada';
    return 'Em andamento';
  }

  Widget _cartaoCompeticaoCompacto({
    required BuildContext context,
    required String clubeId,
    required String competicaoId,
    required String clubeNome,
    required Map<String, dynamic> dados,
  }) {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    final visual = _identidadeModalidade(
      (dados['modalidade'] as String?) ?? '',
    );
    final nome = (dados['nome'] as String?)?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompeticaoDetalhesPage(
                clubeId: clubeId,
                competicaoId: competicaoId,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD8C7AE)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(width: 5, height: 94, color: visual.destaque),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 47,
                          height: 47,
                          decoration: BoxDecoration(
                            color: visual.suave,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            visual.icone,
                            size: 25,
                            color: visual.destaque,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                visual.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: visual.destaque,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                nome == null || nome.isEmpty
                                    ? 'Competição'
                                    : nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: cafe,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.groups_outlined,
                                    size: 13,
                                    color: marrom,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      clubeNome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: marrom,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: marrom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget competicoesPage() {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(
        child: Text('Faça login para ver suas competições.'),
      );
    }

    final clubes = FirebaseFirestore.instance
        .collection('clubes')
        .where('participantes', arrayContains: usuario.uid);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 22),
      children: [
        const Text(
          'Competições',
          style: TextStyle(
            color: cafe,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Identifique cada desafio pela cor e pelo clube.',
          style: TextStyle(color: marrom, fontSize: 13),
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: clubes.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Não foi possível carregar seus clubes.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final documentos = snapshot.data!.docs
                .where((doc) => doc.data()['excluido'] != true)
                .toList();
            if (documentos.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Text('Entre em um clube para encontrar desafios.'),
                ),
              );
            }

            // A consulta continua em tempo real para cada clube, como antes.
            // Cada cartão exibe o nome do clube, evitando confusão entre eles.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: documentos.map((clubeDoc) {
                final nomeClube =
                    (clubeDoc.data()['nome'] as String?) ?? 'Meu clube';
                final competicoes = clubeDoc.reference
                    .collection('competicoes')
                    .orderBy('criadoEm', descending: true);

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: competicoes.snapshots(),
                  builder: (context, competicaoSnapshot) {
                    if (competicaoSnapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('Erro ao carregar competições.'),
                      );
                    }
                    if (!competicaoSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final agora = DateTime.now();
                    final ativos = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    final agendados = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    final encerrados = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                    for (final doc in competicaoSnapshot.data!.docs) {
                      final dados = doc.data();
                      if (dados['excluido'] == true) continue;
                      final situacao = _situacaoCompeticao(dados, agora);
                      if (situacao == 'Encerrada') {
                        encerrados.add(doc);
                      } else if (situacao == 'Agendada') {
                        agendados.add(doc);
                      } else {
                        ativos.add(doc);
                      }
                    }

                    if (ativos.isEmpty && agendados.isEmpty && encerrados.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    Widget cartao(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                      return _cartaoCompeticaoCompacto(
                        context: context,
                        clubeId: clubeDoc.id,
                        competicaoId: doc.id,
                        clubeNome: nomeClube,
                        dados: doc.data(),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ativos.isNotEmpty) ...[
                          ...ativos.map((doc) => cartao(doc)),
                        ],
                        if (agendados.isNotEmpty) ...[
                          ...agendados.map((doc) => cartao(doc)),
                        ],
                        if (encerrados.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                              childrenPadding: EdgeInsets.zero,
                              title: Text(
                                'Encerradas • $nomeClube',
                                style: const TextStyle(
                                  color: cafe,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${encerrados.length} desafio(s)',
                                style: const TextStyle(color: marrom, fontSize: 12),
                              ),
                              children: [
                                ...encerrados.map((doc) => cartao(doc)),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Área de clubes com ações de criação/entrada e cartões compactos.
  Widget clubesPage() {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        const Text('Meus clubes', style: TextStyle(color: cafe, fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 5),
        const Text('Suas comunidades de leitura em um só lugar.', style: TextStyle(color: marrom, fontSize: 13)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: abrirCriacaoClube,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Criar clube'),
            style: FilledButton.styleFrom(backgroundColor: cafe, padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntrarClubePage())),
            icon: const Icon(Icons.login_rounded, size: 19),
            label: const Text('Entrar'),
            style: OutlinedButton.styleFrom(foregroundColor: cafe, side: const BorderSide(color: Color(0xFFD8C7AE)), padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
        ]),
        const SizedBox(height: 23),
        clubesDoUsuario(),
      ],
    );
  }

  Widget clubesDoUsuario({bool compacto = false}) {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    const caramelo = Color(0xFFA67C52);
    const borda = Color(0xFFD8C7AE);
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return const Center(child: Text('Entre na sua conta para ver seus clubes.'));
    final consulta = FirebaseFirestore.instance.collection('clubes').where('participantes', arrayContains: usuario.uid);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: consulta.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Não foi possível carregar os clubes. Verifique a conexão.');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final clubes = snapshot.data!.docs.where((doc) => doc.data()['excluido'] != true).toList();
        if (clubes.isEmpty) return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFFFFFCF7), borderRadius: BorderRadius.circular(20), border: Border.all(color: borda)),
          child: Column(children: [
            const Icon(Icons.groups_outlined, color: caramelo, size: 45),
            const SizedBox(height: 10),
            const Text('Encontre sua comunidade de leitores', textAlign: TextAlign.center, style: TextStyle(color: cafe, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Crie um clube ou participe usando um código de convite.', textAlign: TextAlign.center, style: TextStyle(color: marrom)),
          ]),
        );
        final exibidos = compacto ? clubes.take(2).toList() : clubes;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${clubes.length} ${clubes.length == 1 ? 'comunidade' : 'comunidades'}', style: const TextStyle(color: cafe, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          for (final documento in exibidos) Builder(builder: (context) {
            final dados = documento.data();
            final nome = (dados['nome'] as String?) ?? 'Clube sem nome';
            final descricao = (dados['descricao'] as String?)?.trim() ?? '';
            final participantes = (dados['participantes'] as List?)?.length ?? 0;
            final codigo = (dados['codigoEntrada'] as String?)?.trim() ?? '';
            final dono = dados['criadorId'] == usuario.uid;
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Material(color: const Color(0xFFFFFCF7), borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubeDetalhesPage(clubeId: documento.id, clube: dados))),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(border: Border.all(color: borda), borderRadius: BorderRadius.circular(18)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 51, height: 51, decoration: BoxDecoration(color: const Color(0xFFE7D7C2), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_stories_rounded, color: cafe, size: 27)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cafe, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$participantes ${participantes == 1 ? 'membro' : 'membros'}  •  ${dono ? 'Seu clube' : 'Membro'}', style: const TextStyle(color: marrom, fontSize: 12)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: marrom),
                      ]),
                      if (descricao.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: marrom, fontSize: 13)),
                      ],
                      if (codigo.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: borda),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.key_rounded, size: 16, color: caramelo),
                          const SizedBox(width: 6),
                          const Text('Código de convite', style: TextStyle(color: marrom, fontSize: 12)),
                          const Spacer(),
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: codigo));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
                            },
                            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(codigo, style: const TextStyle(color: cafe, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 5),
                              const Icon(Icons.copy_rounded, color: cafe, size: 16),
                            ])),
                          ),
                        ]),
                      ],
                    ]),
                  ),
                ),
              ),
            );
          }),
        ]);
      },
    );
  }

  Future<void> abrirCriacaoClube() async {

    await Navigator.push(

      context,

      MaterialPageRoute(builder: (_) => const CriarClubePage()),

    );

    // O StreamBuilder atualiza a lista automaticamente.

    if (mounted) {

      setState(() {});

    }

  }

  Widget perfilPage() {

    const cafe = Color(0xFF5D4037);

    const marrom = Color(0xFF795548);

    const papel = Color(0xFFFFFCF7);

    const borda = Color(0xFFD8C7AE);

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {

      return const Center(child: Text('Faça login para acessar seu perfil.'));

    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(

      stream: FirebaseFirestore.instance

          .collection('usuarios')

          .doc(usuario.uid)

          .snapshots(),

      builder: (context, snapshot) {

        final dados = snapshot.data?.data() ?? {};

        final avatarConfig = dados['avatarConfig'] as String?;

        final nome = (dados['nome'] as String? ?? '').trim();

        final fotoUrl = dados['fotoUrl'] as String?;

        final nomeExibido = nome.isNotEmpty

            ? nome

            : usuario.displayName ?? 'Leitor do Readly';

        final email = usuario.email ?? '';

        final foto = fotoUrl != null && fotoUrl.startsWith('https\://')

            ? NetworkImage(fotoUrl)

            : null;

        return ListView(

          padding: const EdgeInsets.all(20),

          children: [

            const Text(

              'Meu perfil',

              style: TextStyle(

                color: cafe,

                fontSize: 28,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 6),

            const Text(

              'Seu espaço na comunidade Readly.',

              style: TextStyle(color: marrom, fontSize: 14),

            ),

            const SizedBox(height: 24),

            Container(

              padding: const EdgeInsets.all(23),

              decoration: BoxDecoration(

                color: papel,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(color: borda),

              ),

              child: Column(

                children: [

                  Container(

                    width: 110,

                    height: 110,

                    padding: const EdgeInsets.all(5),

                    decoration: const BoxDecoration(

                      color: Color(0xFFE7D7C2),

                      shape: BoxShape.circle,

                    ),

                    child: ClipOval(

                      child: avatarConfig != null && avatarConfig.isNotEmpty

                          ? SvgPicture.string(

                              FluttermojiFunctions()

                                  .decodeFluttermojifromString(avatarConfig),

                              fit: BoxFit.contain,

                            )

                          : const Icon(

                              Icons.person_rounded,

                              size: 65,

                              color: Color(0xFF795548),

                            ),

                    ),

                  ),

                  const SizedBox(height: 17),

                  const Divider(height: 1, indent: 18, endIndent: 18),

                  ListTile(

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 18,

                      vertical: 7,

                    ),

                    leading: const Icon(

                      Icons.face_retouching_natural,

                      color: Color(0xFF5D4037),

                      size: 27,

                    ),

                    title: const Text(

                      'Personalizar meu avatar',

                      style: TextStyle(

                        color: Color(0xFF5D4037),

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    subtitle: const Text('Cabelo, rosto, roupas e acessórios'),

                    trailing: const Icon(

                      Icons.chevron_right,

                      color: Color(0xFF795548),

                    ),

                    onTap: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) => const PersonalizarAvatarPage(),

                        ),

                      );

                    },

                  ),

                  Text(

                    nomeExibido,

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      color: cafe,

                      fontWeight: FontWeight.bold,

                      fontSize: 23,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    email,

                    textAlign: TextAlign.center,

                    style: const TextStyle(color: marrom, fontSize: 13),

                  ),

                  const SizedBox(height: 16),

                  Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 14,

                      vertical: 8,

                    ),

                    decoration: BoxDecoration(

                      color: const Color(0xFFF0E5D5),

                      borderRadius: BorderRadius.circular(30),

                    ),

                    child: const Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Icon(Icons.auto_stories_rounded, color: cafe, size: 17),

                        SizedBox(width: 7),

                        Text(

                          'Leitor do Readly',

                          style: TextStyle(

                            color: cafe,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            Container(

              decoration: BoxDecoration(

                color: papel,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: borda),

              ),

              child: Column(

                children: [

                  ListTile(

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 18,

                      vertical: 7,

                    ),

                    leading: const Icon(

                      Icons.manage_accounts_outlined,

                      color: cafe,

                      size: 27,

                    ),

                    title: const Text(

                      'Editar perfil',

                      style: TextStyle(

                        color: cafe,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    subtitle: const Text('Alterar nome e senha'),

                    trailing: const Icon(Icons.chevron_right, color: marrom),

                    onTap: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) => const EditarPerfilPage(),

                        ),

                      );

                    },

                  ),

                  const Divider(height: 1, indent: 18, endIndent: 18),

                  ListTile(

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 18,

                      vertical: 7,

                    ),

                    leading: const Icon(

                      Icons.logout_rounded,

                      color: Colors.redAccent,

                    ),

                    title: const Text(

                      'Sair da conta',

                      style: TextStyle(

                        color: Colors.redAccent,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    trailing: const Icon(Icons.chevron_right, color: marrom),

                    onTap: sairDaConta,

                  ),

                ],

              ),

            ),

            const SizedBox(height: 22),

            const Center(

              child: Text(

                'Cada página faz parte da sua história.',

                style: TextStyle(color: marrom, fontStyle: FontStyle.italic),

              ),

            ),

          ],

        );

      },

    );

  }

  Future<void> sairDaConta() async {

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(

      MaterialPageRoute(builder: (_) => const LoginPage()),

      (route) => false,

    );

  }

}
