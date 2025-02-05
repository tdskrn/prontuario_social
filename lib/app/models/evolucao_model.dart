class EvolucaoModel {
  int pacienteId;
  int intenacaoId;
  DateTime dataVisita;
  String evolucao;
  String status;
  DateTime dataStatus;
  EvolucaoModel({
    required this.pacienteId,
    required this.intenacaoId,
    required this.dataVisita,
    required this.evolucao,
    required this.status,
    required this.dataStatus,
  });
}
