import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    const texto = Color(0xFF3E3028);
    const papelClaro = Color(0xFFFFFCF7);
    const borda = Color(0xFFD8C7AE);

    final usuario = FirebaseAuth.instance.currentUser;
    final nomeCompleto = usuario?.displayName?.trim() ?? '';
    final primeiroNome = nomeCompleto.isNotEmpty
        ? nomeCompleto.split(' ').first
        : 'leitor';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          const Text(
            'SUA JORNADA LITERÁRIA',
            style: TextStyle(
              fontSize: 11,
              color: marrom,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Olá, $primeiroNome!',
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: texto,
            ),
          ),

          const SizedBox(height: 6),

          // Banner principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cafe,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cafe.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFFEACDA7),
                      size: 38,
                    ),
                    Spacer(),
                    Icon(
                      Icons.auto_awesome_outlined,
                      color: Color(0xFFEACDA7),
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Text(
                  'Cada página é\numa conquista.',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: papelClaro,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Compartilhe suas leituras, participe de '
                  'desafios e evolua junto com outros leitores.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF5EFE3),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() => paginaAtual = 1);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('Explorar meus clubes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: caramelo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Estatísticas
          const Text(
            'Sua atividade',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: texto,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Acompanhe sua evolução na leitura.',
            style: TextStyle(fontSize: 13, color: marrom),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: estatisticaCard(
                  Icons.menu_book_rounded,
                  '0',
                  'Páginas lidas',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: estatisticaCard(
                  Icons.local_fire_department_rounded,
                  '0 dias',
                  'Sua sequência',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Clubes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meus clubes',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: texto,
                ),
              ),

              TextButton.icon(
                onPressed: () {
                  setState(() => paginaAtual = 1);
                },
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                label: const Text('Ver todos'),
                style: TextButton.styleFrom(foregroundColor: marrom),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Suas histórias ficam melhores em companhia.',
            style: TextStyle(fontSize: 13, color: marrom),
          ),

          const SizedBox(height: 16),

          // Mantém a integração original com o Firestore
          clubesDoUsuario(compacto: true),

          const SizedBox(height: 22),

          // Convite para criar clube
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: papelClaro,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borda),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7D7C2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: cafe,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crie seu clube',
                        style: TextStyle(
                          color: texto,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Convide amigos para um desafio de leitura.',
                        style: TextStyle(
                          color: marrom,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: abrirCriacaoClube,
                  icon: const Icon(Icons.arrow_forward_rounded, color: cafe),
                  tooltip: 'Criar clube',
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Competições',
            style: TextStyle(
              fontSize: 28,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe os desafios dos seus clubes.',
            style: TextStyle(color: Color(0xFF795548)),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 65,
                    color: Color(0xFFA67C52),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Suas competições aparecerão aqui!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'As competições serão organizadas '
                    'dentro dos seus clubes de leitura.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF795548)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                      builder: (context) =>
                          ClubeDetalhesPage(clube: documento.data()),
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
