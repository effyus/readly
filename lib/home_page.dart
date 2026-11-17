import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meus_livros_page.dart';
import 'clube_detalhes_page.dart';
import 'criar_clube_page.dart';
import 'login_page.dart';

class ReadlyHomePage extends StatefulWidget {
  const ReadlyHomePage({super.key});

  @override
  State<ReadlyHomePage> createState() => _ReadlyHomePageState();
}

class _ReadlyHomePageState extends State<ReadlyHomePage> {
  int paginaAtual = 0;

  final Color marrom = Color(0xFF795548);

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

  final usuario = FirebaseAuth.instance.currentUser;
  final nome = usuario?.displayName?.trim() ?? '';
  final primeiroNome =
      nome.isEmpty ? 'leitor' : nome.split(' ').first;

  Widget atalho({
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback acao,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: acao,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: papel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD8C7AE),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7D7C2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icone, color: cafe),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: cafe,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    descricao,
                    style: const TextStyle(
                      color: marrom,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: marrom,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'SUA JORNADA LITERÁRIA',
        style: TextStyle(
          color: marrom,
          letterSpacing: 2,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      Text(
        'Olá, $primeiroNome!',
        style: const TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.bold,
          color: cafe,
        ),
      ),

      const SizedBox(height: 7),

      const Text(
        'Que tal descobrir uma nova história hoje?',
        style: TextStyle(
          fontSize: 15,
          color: marrom,
        ),
      ),

      const SizedBox(height: 26),

      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cafe,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 43,
              color: Color(0xFFEACDA7),
            ),
            SizedBox(height: 18),
            Text(
              'Toda grande história\ncomeça com uma página.',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'O Readly acompanha sua jornada e transforma '
              'a leitura em uma experiência compartilhada.',
              style: TextStyle(
                color: Color(0xFFF5EFE3),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),

      const Text(
        'Explore o Readly',
        style: TextStyle(
          color: cafe,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      const Text(
        'Escolha por onde começar sua jornada.',
        style: TextStyle(
          color: marrom,
          fontSize: 14,
        ),
      ),

      const SizedBox(height: 20),

      atalho(
        icone: Icons.menu_book_rounded,
        titulo: 'Minha biblioteca',
        descricao: 'Organize seus livros e suas leituras.',
        acao: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MeusLivrosPage(),
            ),
          );
        },
      ),

      const SizedBox(height: 12),

      atalho(
        icone: Icons.groups_rounded,
        titulo: 'Clubes de leitura',
        descricao: 'Encontre seus grupos e outros leitores.',
        acao: () {
          setState(() => paginaAtual = 1);
        },
      ),

      const SizedBox(height: 12),

      atalho(
        icone: Icons.emoji_events_rounded,
        titulo: 'Competições',
        descricao: 'Acompanhe desafios e metas de leitura.',
        acao: () {
          setState(() => paginaAtual = 2);
        },
      ),

      const SizedBox(height: 30),

      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE7D7C2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: caramelo,
              size: 30,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'O segredo do hábito de leitura é a constância. '
                'Algumas páginas por dia já fazem diferença!',
                style: TextStyle(
                  color: cafe,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
    return const Center(
      child: Text('Faça login para ver suas competições.'),
    );
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
            return const Text(
              'Não foi possível carregar seus clubes.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: competicoes.snapshots(),
                builder: (context, competicaoSnapshot) {
                  if (competicaoSnapshot.hasError) {
                    return const Card(
                      child: ListTile(
                        title: Text(
                          'Erro ao carregar competições.',
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
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

                        final unidade =
                            modalidade == 'mais_consistente'
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
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClubeDetalhesPage(
                                    clubeId: clubeDoc.id,
                                    clube: dadosClube,
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
                      builder: (context) => ClubeDetalhesPage(
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
