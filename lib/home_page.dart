import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'criar_clube_page.dart';
import 'login_page.dart';

class ReadlyHomePage extends StatefulWidget {
  const ReadlyHomePage({super.key});

  @override
  State<ReadlyHomePage> createState() => _ReadlyHomePageState();
}

class _ReadlyHomePageState extends State<ReadlyHomePage> {
  int paginaAtual = 0;

  final Color marrom = const Color.fromARGB(255, 132, 81, 11);

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
            onPressed: () => setState(() => paginaAtual = 2),
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
                onPressed: () => setState(() => paginaAtual = 1),
                child: const Text('Ver todos'),
              ),
            ],
          ),

          clubesDoUsuario(compacto: true),
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
            final modalidade = dados['modalidade'] as String? ?? 'quem_le_mais';
            final duracao = dados['duracaoDias'];
            final objetivo = dados['objetivo'] as String? ?? '';
            final participantes = dados['participantes'] as List? ?? [];
            final codigo = dados['codigoEntrada'] as String? ?? '';

            String nomeModalidade;

            switch (modalidade) {
              case 'mais_consistente':
                nomeModalidade = 'Quem é mais consistente';
                break;
              case 'meta_coletiva':
                nomeModalidade = 'Meta coletiva';
                break;
              default:
                nomeModalidade = 'Quem lê mais';
            }

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
                    Text(
                      nomeModalidade,
                      style: TextStyle(
                        color: marrom,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (objetivo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Objetivo: $objetivo'),
                    ],
                    const SizedBox(height: 6),
                    Text('Participantes: ${participantes.length}'),
                    if (duracao is int) ...[
                      const SizedBox(height: 6),
                      Text('Duração: $duracao dias'),
                    ],
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
