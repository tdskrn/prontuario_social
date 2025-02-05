import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvolucaoScreen extends StatefulWidget {
  final int internacaoId;

  const EvolucaoScreen({super.key, required this.internacaoId});

  @override
  State<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends State<EvolucaoScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _adicionarEvolucao() async {
    final evolucaoController = TextEditingController();
    final statusController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Evolução'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: evolucaoController,
                decoration:
                    const InputDecoration(labelText: 'Descrição da evolução'),
              ),
              TextField(
                controller: statusController,
                decoration:
                    const InputDecoration(labelText: 'Status do paciente'),
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
                if (evolucaoController.text.isNotEmpty &&
                    statusController.text.isNotEmpty) {
                  // Recupera o paciente_id baseado na internação
                  final response = await supabase
                      .from('internacao')
                      .select('paciente_id')
                      .eq('id', widget.internacaoId)
                      .single();

                  final pacienteId = response['paciente_id'];

                  await supabase.from('evolucao').insert({
                    'internacao_id': widget.internacaoId,
                    'paciente_id': pacienteId,
                    'data_visita': DateTime.now().toIso8601String(),
                    'evolucao': evolucaoController.text,
                    'status': statusController.text,
                    'data_status': DateTime.now().toIso8601String(),
                  });

                  Navigator.pop(context);
                  setState(() {}); // Atualiza a lista
                }
              },
              child: const Text('Salvar'),
            ),
          ],
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
            .order('data_visita', ascending: false), // Ordena pela data
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
                  title: Text(evolucao['evolucao']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Data da visita: ${evolucao['data_visita']}'),
                      Text('📌 Status: ${evolucao['status']}'),
                      Text('📅 Data do status: ${evolucao['data_status']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarEvolucao,
        child: const Icon(Icons.add),
      ),
    );
  }
}
