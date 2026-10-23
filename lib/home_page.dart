import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'criar_clube_page.dart';
import 'login_page.dart';

class ReadlyHomePage extends StatefulWidget {
  const ReadlyHomePage({super.key});

  @override
  State<ReadlyHomePage> createState() => _ReadlyHomePageState();
}

class _ReadlyHomePageState extends State<ReadlyHomePage> {
  int paginaAtual = 0;

  final Color marrom = Color.fromARGB(255, 132, 81, 11);

  @override
  Widget build(BuildContext context) {
    final paginas = [inicioPage(), clubesPage(), perfilPage()];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FC),
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
            onPressed: () {
              setState(() => paginaAtual = 2);
            },
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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget inicioPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olá, leitor! 👋',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pronto para sua próxima leitura?',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),

          // Cartão de boas-vindas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [marrom, const Color.fromARGB(255, 166, 131, 75)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories_rounded, color: Colors.white, size: 42),
                SizedBox(height: 16),
                Text(
                  'Cada página conta!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Leia, participe de clubes e evolua '
                  'junto com outros leitores.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'Sua atividade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: estatisticaCard(Icons.menu_book, '0', 'Páginas lidas'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: estatisticaCard(
                  Icons.local_fire_department,
                  '0 dias',
                  'Sequência',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meus clubes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() => paginaAtual = 1);
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepPurple.shade50),
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
                  'Crie um clube ou participe de um '
                  'para ler em grupo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => paginaAtual = 1);
                  },
                  child: const Text('Conhecer clubes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget estatisticaCard(IconData icone, String valor, String descricao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: marrom, size: 28),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget clubesPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded, size: 76, color: marrom),
            const SizedBox(height: 20),
            const Text(
              'Seus clubes de leitura',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Aqui você poderá criar clubes, '
              'participar de competições e acompanhar '
              'o progresso dos participantes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CriarClubePage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar clube'),
            ),
          ],
        ),
      ),
    );
  }

  Widget perfilPage() {
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
              'Suas informações, estatísticas de leitura '
              'e clubes aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
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
