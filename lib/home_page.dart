import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'editar_perfil_page.dart';
import 'entrar_clube_page.dart';
import 'competicao_detalhes_page.dart';
import 'meus_livros_page.dart';
import 'clube_detalhes_page.dart';
import 'criar_clube_page.dart';
import 'login_page.dart';

import 'livros_competicao_page.dart';
import 'leitura_service.dart';

class ReadlyHomePage extends StatefulWidget {
  const ReadlyHomePage({super.key});

  @override
  State<ReadlyHomePage> createState() => _ReadlyHomePageState();
}

class _ReadlyHomePageState extends State<ReadlyHomePage> {
  int paginaAtual = 0;

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
      clubesPage(),
      competicoesPage(),
      perfilPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE3),
      appBar: AppBar(
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
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Clubes',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Competições',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget inicioPage() {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);
    const caramelo = Color(0xFFA67C52);
    const papel = Color(0xFFFFFCF7);
    const borda = Color(0xFFD8C7AE);

    final usuario = FirebaseAuth.instance.currentUser;
    final nomeCompleto = usuario?.displayName?.trim() ?? '';
    final primeiroNome = nomeCompleto.isEmpty
        ? 'leitor'
        : nomeCompleto.split(' ').first;

    Widget indicador(IconData icone, String valor, String titulo) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: papel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: caramelo, size: 25),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cafe,
              ),
            ),
            const SizedBox(height: 4),
            Text(titulo, style: const TextStyle(fontSize: 12, color: marrom)),
          ],
        ),
      );
    }

    Widget abrirBiblioteca() {
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeusLivrosPage()),
          );
        },
        child: const Text('Ver todos'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'SUA JORNADA LITERÁRIA',
          style: TextStyle(
            color: marrom,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Olá, $primeiroNome!',
          style: const TextStyle(
            fontSize: 28,
            color: cafe,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada página faz parte da sua história.',
          style: TextStyle(color: marrom, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Indicadores reais do Firestore
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: LeituraService.observarLivros(),
          builder: (context, livrosSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: LeituraService.observarLeituras(),
              builder: (context, leiturasSnapshot) {
                if (livrosSnapshot.hasError || leiturasSnapshot.hasError) {
                  return const Text(
                    'Não foi possível carregar as estatísticas.',
                  );
                }

                if (!livrosSnapshot.hasData || !leiturasSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final livros = livrosSnapshot.data!.docs;
                final leituras = leiturasSnapshot.data!.docs;

                final paginasLidas = leituras.fold<int>(
                  0,
                  (soma, doc) =>
                      soma +
                      ((doc.data()['paginasLidas'] as num?)?.toInt() ?? 0),
                );

                final concluidos = livros.where((doc) {
                  return doc.data()['status'] == 'concluido';
                }).length;

                final ofensiva = LeituraService.calcularOfensiva(
                  leituras.map((doc) => doc.data()),
                );

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('clubes')
                      .where('participantes', arrayContains: usuario!.uid)
                      .snapshots(),
                  builder: (context, clubesSnapshot) {
                    if (clubesSnapshot.hasError) {
                      return const Text(
                        'Erro ao carregar informações dos clubes.',
                      );
                    }

                    if (!clubesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final clubes = clubesSnapshot.data!.docs;

                    return FutureBuilder<int>(
                      future: contarCompeticoesAtivas(clubes),
                      builder: (context, competicoesSnapshot) {
                        final quantidadeCompeticoes =
                            competicoesSnapshot.data ?? 0;

                        if (competicoesSnapshot.hasError) {
                          return const Text('Erro ao carregar as competições.');
                        }

                        final dados = [
                          (
                            Icons.local_fire_department_rounded,
                            '$ofensiva dias',
                            'Ofensiva',
                          ),
                          (
                            Icons.menu_book_rounded,
                            '$paginasLidas',
                            'Páginas lidas',
                          ),
                          (
                            Icons.check_circle_outline,
                            '$concluidos',
                            'Livros concluídos',
                          ),
                          (
                            Icons.emoji_events_outlined,
                            competicoesSnapshot.hasData
                                ? '$quantidadeCompeticoes'
                                : '...',
                            'Competições ativas',
                          ),
                          (
                            Icons.groups_rounded,
                            '${clubes.length}',
                            'Clubes participantes',
                          ),
                        ];

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final largura = (constraints.maxWidth - 12) / 2;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (int i = 0; i < dados.length; i++)
                                  SizedBox(
                                    width: i == 4
                                        ? constraints.maxWidth
                                        : largura,
                                    child: indicador(
                                      dados[i].$1,
                                      dados[i].$2,
                                      dados[i].$3,
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas leituras',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: cafe,
              ),
            ),
            abrirBiblioteca(),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Continue de onde você parou.',
          style: TextStyle(color: marrom, fontSize: 13),
        ),

        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: LeituraService.observarLivros(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Erro ao carregar livros.');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final livros = snapshot.data!.docs
                .where((doc) => doc.data()['status'] == 'lendo')
                .take(3)
                .toList();

            if (livros.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: papel,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: borda),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: caramelo, size: 43),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma leitura em andamento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cafe,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Escolha um livro na biblioteca para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: marrom),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: livros.map((documento) {
                final dados = documento.data();
                final capaUrl = dados['capaUrl'] as String?;

                final total = (dados['totalPaginas'] as num?)?.toInt() ?? 1;
                final atual = (dados['paginaAtual'] as num?)?.toInt() ?? 0;
                final progresso = total > 0
                    ? (atual / total).clamp(0.0, 1.0)
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 65,
                              height: 88,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child:
                                    capaUrl != null &&
                                        capaUrl.startsWith('https://')
                                    ? Image.network(
                                        capaUrl,
                                        width: 65,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const ColoredBox(
                                                color: Color(0xFFE7D7C2),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.book_rounded,
                                                    color: cafe,
                                                    size: 34,
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : const ColoredBox(
                                        color: Color(0xFFE7D7C2),
                                        child: Center(
                                          child: Icon(
                                            Icons.book_rounded,
                                            color: cafe,
                                            size: 34,
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dados['titulo'] ?? '',
                                    style: const TextStyle(
                                      color: cafe,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    dados['autor'] ?? '',
                                    style: const TextStyle(
                                      color: marrom,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: progresso,
                                    minHeight: 7,
                                    borderRadius: BorderRadius.circular(7),
                                    backgroundColor: const Color(0xFFE7D7C2),
                                    color: marrom,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '$atual/$total páginas • '
                                    '${(progresso * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: marrom,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MeusLivrosPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Continuar leitura'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
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

  Widget competicoesPage() {
    const cafe = Color(0xFF5D4037);
    const marrom = Color(0xFF795548);

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(child: Text('Faça login para ver suas competições.'));
    }

    String modalidadeTexto(String valor) {
      switch (valor) {
        case 'quem_le_mais':
          return 'Quem lê mais';
        case 'mais_consistente':
          return 'Mais consistente';
        case 'meta_coletiva':
          return 'Meta coletiva';
        default:
          return 'Competição';
      }
    }

    final clubes = FirebaseFirestore.instance
        .collection('clubes')
        .where('participantes', arrayContains: usuario.uid);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Competições',
          style: TextStyle(
            color: cafe,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Os desafios dos seus clubes de leitura.',
          style: TextStyle(color: marrom),
        ),
        const SizedBox(height: 24),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: clubes.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Não foi possível carregar seus clubes.');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final documentos = snapshot.data!.docs;

            if (documentos.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Você ainda não participa de nenhum clube.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: documentos.map((clubeDoc) {
                final dadosClube = clubeDoc.data();

                final competicoes = FirebaseFirestore.instance
                    .collection('clubes')
                    .doc(clubeDoc.id)
                    .collection('competicoes')
                    .orderBy('criadoEm', descending: true);
                    

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: competicoes.snapshots(),
                  builder: (context, competicaoSnapshot) {
                    if (competicaoSnapshot.hasError) {
                      return const Card(
                        child: ListTile(
                          title: Text('Erro ao carregar competições.'),
                        ),
                      );
                    }

                    if (!competicaoSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final lista = competicaoSnapshot.data!.docs;

                    if (lista.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            dadosClube['nome'] ?? 'Meu clube',
                            style: const TextStyle(
                              color: cafe,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        ...lista.map((competicaoDoc) {
                          final dados = competicaoDoc.data();
                          final modalidade =
                              dados['modalidade'] as String? ?? '';

                          final unidade = modalidade == 'mais_consistente'
                              ? 'dias'
                              : 'páginas';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE7D7C2),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: cafe,
                                ),
                              ),
                              title: Text(
                                dados['nome'] ?? 'Competição',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${modalidadeTexto(modalidade)}\n'
                                  'Meta: ${dados['metaValor'] ?? 0} $unidade',
                                ),
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CompeticaoDetalhesPage(
                                      clubeId: clubeDoc.id,
                                      competicaoId: competicaoDoc.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 12),
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

  Widget clubesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seus clubes de leitura',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe suas competições e participe '
            'da jornada de leitura.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: abrirCriacaoClube,
            icon: const Icon(Icons.add),
            label: const Text('Criar clube'),
            style: FilledButton.styleFrom(
              backgroundColor: marrom,
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EntrarClubePage()),
              );
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text('Entrar em um clube'),
            style: OutlinedButton.styleFrom(
              foregroundColor: marrom,
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: marrom),
            ),
          ),

          const SizedBox(height: 24),

          clubesDoUsuario(),
        ],
      ),
    );
  }

  Widget clubesDoUsuario({bool compacto = false}) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(
        child: Text('Entre na sua conta para ver seus clubes.'),
      );
    }

    final consulta = FirebaseFirestore.instance
        .collection('clubes')
        .where('participantes', arrayContains: usuario.uid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: consulta.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Não foi possível carregar os clubes. '
              'Verifique sua conexão e as regras do Firebase.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final clubes = snapshot.data?.docs ?? [];

        if (clubes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8DCCB)),
            ),
            child: Column(
              children: [
                Icon(Icons.groups_rounded, size: 48, color: marrom),
                const SizedBox(height: 12),
                const Text(
                  'Sua jornada começa em um clube!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie um clube para começar a ler em grupo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (compacto) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: abrirCriacaoClube,
                    child: const Text('Criar meu primeiro clube'),
                  ),
                ],
              ],
            ),
          );
        }

        final lista = compacto ? clubes.take(2).toList() : clubes;

        return Column(
          children: lista.map((documento) {
            final dados = documento.data();
            final nome = dados['nome'] as String? ?? 'Clube sem nome';
            final descricao = dados['descricao'] as String? ?? '';
            final participantes = dados['participantes'] as List? ?? [];
            final codigo = dados['codigoEntrada'] as String? ?? '';

            return Card(
              color: const Color(0xFFFFFCF7),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubeDetalhesPage(
                        clubeId: documento.id,
                        clube: documento.data(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: marrom.withValues(alpha: 0.12),
                            child: Icon(Icons.menu_book, color: marrom),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (descricao.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(descricao),
                      ],
                      const SizedBox(height: 12),

                      const SizedBox(height: 6),
                      Text('Participantes: ${participantes.length}'),

                      if (codigo.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Código de entrada: $codigo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar código',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: codigo),
                                );

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código de entrada copiado!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.vpn_key_outlined),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
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
    final usuario = FirebaseAuth.instance.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: marrom.withValues(alpha: 0.12),
              child: Icon(Icons.person, size: 52, color: marrom),
            ),
            const SizedBox(height: 16),
            const Text(
              'Meu perfil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF5D4037),
              ),
              title: const Text('Editar meu nome'),
              subtitle: const Text('Alterar nome exibido no Readly'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditarPerfilPage()),
                );
              },
            ),

            Text(
              usuario?.displayName ?? usuario?.email ?? 'Leitor do Readly',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas informações e estatísticas de leitura '
              'aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: sairDaConta,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
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
