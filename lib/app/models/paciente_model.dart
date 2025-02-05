enum Sexo {
  masculino,
  feminino,
  outro,
}

class PacienteModel {
  int? id;
  String nome;
  DateTime dataNascimento;
  Sexo sexo;
  bool isParto; // Apenas para sexo feminino
  CriancaModel? dadosCrianca;

  PacienteModel({
    this.id,
    required this.nome,
    required this.dataNascimento,
    required this.sexo,
    this.isParto = false,
    this.dadosCrianca,
  });
}

class CriancaModel {
  String nomeCrianca;
  DateTime dataNascimento;

  CriancaModel({
    required this.nomeCrianca,
    required this.dataNascimento,
  });
}
