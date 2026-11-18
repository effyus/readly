/// Motor de pontuação do Readly. Não depende de Flutter nem Firebase,
/// o que permite testar as modalidades isoladamente.
///
/// Regras do MVP:
/// - quem_le_mais: soma de páginas válidas por participante;
/// - mais_consistente: número de dias distintos com leitura;
///   desempates: maior sequência consecutiva, depois páginas;
/// - meta_coletiva: soma das páginas dos participantes contra a meta.
///
/// Não conte novamente o mesmo (usuarioId, leituraId), mesmo que a
/// coleção contenha registros repetidos.

class RegistroPontuacao {
  final String usuarioId;
  final String leituraId;
  final int paginasLidas;
  final String diaLocal; // yyyy-MM-dd
  final DateTime criadoEm;

  const RegistroPontuacao({
    required this.usuarioId,
    required this.leituraId,
    required this.paginasLidas,
    required this.diaLocal,
    required this.criadoEm,
  });
}

class ParticipantePontuacao {
  final String usuarioId;
  final int paginas;
  final int diasAtivos;
  final int maiorSequencia;
  const ParticipantePontuacao({
    required this.usuarioId,
    required this.paginas,
    required this.diasAtivos,
    required this.maiorSequencia,
  });
}

class ResultadoModalidade {
  final String modalidade;
  final List<ParticipantePontuacao> ranking;
  final int paginasColetivas;
  final int meta;

  const ResultadoModalidade({
    required this.modalidade,
    required this.ranking,
    required this.paginasColetivas,
    required this.meta,
  });

  double get progressoColetivo => meta <= 0
      ? 0
      : (paginasColetivas / meta).clamp(0.0, 1.0).toDouble();

  bool get metaAlcancada => meta > 0 && paginasColetivas >= meta;
}

class ModalidadesService {
  static DateTime? _dia(String data) {
    final partes = data.split('-');
    if (partes.length != 3) return null;
    final ano = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final dia = int.tryParse(partes[2]);
    if (ano == null || mes == null || dia == null) return null;
    final resultado = DateTime.utc(ano, mes, dia);
    if (resultado.year != ano || resultado.month != mes || resultado.day != dia) {
      return null;
    }
    return resultado;
  }

  static int _maiorSequencia(Set<String> dias) {
    final ordenados = dias.map(_dia).whereType<DateTime>().toList()..sort();
    var maior = 0;
    var atual = 0;
    DateTime? anterior;
    for (final dia in ordenados) {
      if (anterior != null && dia.difference(anterior).inDays == 1) {
        atual++;
      } else {
        atual = 1;
      }
      if (atual > maior) maior = atual;
      anterior = dia;
    }
    return maior;
  }

  static ResultadoModalidade calcular({
    required String modalidade,
    required Iterable<RegistroPontuacao> registros,
    required DateTime inicio,
    required DateTime fim,
    int meta = 0,
    Iterable<String> participantes = const [],
  }) {
    if (!['quem_le_mais', 'mais_consistente', 'meta_coletiva'].contains(modalidade)) {
      throw ArgumentError.value(modalidade, 'modalidade', 'Modalidade desconhecida');
    }
    final totalPorPessoa = <String, int>{};
    final diasPorPessoa = <String, Set<String>>{};
    final vistos = <String>{};
    final permitidos = participantes.toSet();

    for (final id in permitidos) {
      totalPorPessoa[id] = 0;
      diasPorPessoa[id] = <String>{};
    }

    for (final registro in registros) {
      if (registro.usuarioId.isEmpty || registro.leituraId.isEmpty ||
          registro.paginasLidas <= 0 || _dia(registro.diaLocal) == null) continue;
      if (registro.criadoEm.isBefore(inicio) || !registro.criadoEm.isBefore(fim)) continue;
      if (permitidos.isNotEmpty && !permitidos.contains(registro.usuarioId)) continue;
      final chave = '${registro.usuarioId}/${registro.leituraId}';
      if (!vistos.add(chave)) continue;

      totalPorPessoa.update(
        registro.usuarioId,
        (atual) => atual + registro.paginasLidas,
        ifAbsent: () => registro.paginasLidas,
      );
      diasPorPessoa.putIfAbsent(registro.usuarioId, () => <String>{})
          .add(registro.diaLocal);
    }

    final ranking = totalPorPessoa.entries.map((entrada) {
      final dias = diasPorPessoa[entrada.key] ?? <String>{};
      return ParticipantePontuacao(
        usuarioId: entrada.key,
        paginas: entrada.value,
        diasAtivos: dias.length,
        maiorSequencia: _maiorSequencia(dias),
      );
    }).toList();

    ranking.sort((a, b) {
      int primeiro;
      if (modalidade == 'mais_consistente') {
        primeiro = b.diasAtivos.compareTo(a.diasAtivos);
        if (primeiro != 0) return primeiro;
        primeiro = b.maiorSequencia.compareTo(a.maiorSequencia);
        if (primeiro != 0) return primeiro;
      }
      primeiro = b.paginas.compareTo(a.paginas);
      if (primeiro != 0) return primeiro;
      if (modalidade != 'mais_consistente') {
        primeiro = b.diasAtivos.compareTo(a.diasAtivos);
        if (primeiro != 0) return primeiro;
      }
      return a.usuarioId.compareTo(b.usuarioId);
    });

    return ResultadoModalidade(
      modalidade: modalidade,
      ranking: List.unmodifiable(ranking),
      paginasColetivas: totalPorPessoa.values.fold(0, (a, b) => a + b),
      meta: meta,
    );
  }
}
