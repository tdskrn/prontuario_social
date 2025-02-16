import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvolucaoScreen extends StatefulWidget {
  final int internacaoId;

  const EvolucaoScreen({super.key, required this.internacaoId});

  @override
  State<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends State<EvolucaoScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String formatarData(String data) {
    try {
      final DateTime parsedDate = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<void> _cadastrarOuEditarEvolucao(
      {Map<String, dynamic>? evolucao}) async {
    bool isEdit = evolucao != null;
    final observacaoController =
        TextEditingController(text: isEdit ? evolucao!['observacao'] : '');
    DateTime selectedDate =
        isEdit ? DateTime.parse(evolucao!['data_visita']) : DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Evolução' : 'Adicionar Evolução'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                        "Data da Visita: ${formatarData(selectedDate.toIso8601String())}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setStateDialog(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: observacaoController,
                    decoration: const InputDecoration(labelText: 'Observação'),
                    maxLines: 4,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (observacaoController.text.isNotEmpty) {
                      if (isEdit) {
                        await supabase.from('evolucao').update({
                          'data_visita': selectedDate.toIso8601String(),
                          'observacao': observacaoController.text,
                        }).eq('id', evolucao!['id']);
                      } else {
                        final response = await supabase
                            .from('internacao')
                            .select('paciente_id')
                            .eq('id', widget.internacaoId)
                            .single();

                        final pacienteId = response['paciente_id'];

                        await supabase.from('evolucao').insert({
                          'internacao_id': widget.internacaoId,
                          'paciente_id': pacienteId,
                          'data_visita': selectedDate.toIso8601String(),
                          'observacao': observacaoController.text,
                        });
                      }
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evoluções')),
      body: FutureBuilder(
        future: supabase
            .from('evolucao')
            .select()
            .eq('internacao_id', widget.internacaoId)
            .order('data_visita', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar evoluções.'));
          }

          final evolucoes = snapshot.data as List;

          if (evolucoes.isEmpty) {
            return const Center(child: Text('Nenhuma evolução cadastrada.'));
          }

          return ListView.builder(
            itemCount: evolucoes.length,
            itemBuilder: (context, index) {
              final evolucao = evolucoes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                      '📅 Data da visita: ${formatarData(evolucao['data_visita'])}'),
                  subtitle: Text('📝 Observação: ${evolucao['observacao']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _cadastrarOuEditarEvolucao(evolucao: evolucao),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cadastrarOuEditarEvolucao(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
