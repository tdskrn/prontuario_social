import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evolucao_screen.dart';

class InternacaoScreen extends StatefulWidget {
  final int pacienteId;

  const InternacaoScreen({super.key, required this.pacienteId});

  @override
  State<InternacaoScreen> createState() => _InternacaoScreenState();
}

class _InternacaoScreenState extends State<InternacaoScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para formatar datas para exibição
  String formatarData(String data) {
    try {
      final DateTime parsedDate = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInternacoesComRn() async {
    final response = await supabase
        .from('internacao')
        .select('*, rn(*)')
        .eq('paciente_id', widget.pacienteId)
        .order('data_internacao', ascending: false);

    return response.map((internacao) {
      return {
        ...internacao,
        'rn': internacao['rn'].isNotEmpty ? internacao['rn'][0] : null,
      };
    }).toList();
  }

  Future<void> _cadastrarOuEditarInternacao(
      {Map<String, dynamic>? internacao}) async {
    bool isEdit = internacao != null;
    final tipoController =
        TextEditingController(text: isEdit ? internacao!['tipo'] : '');
    final numeroLeitoController = TextEditingController(
        text: isEdit ? internacao!['numero_leito'].toString() : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Editar Internação' : 'Cadastrar Internação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tipoController,
                decoration:
                    const InputDecoration(labelText: 'Tipo de internação'),
              ),
              TextField(
                controller: numeroLeitoController,
                decoration: const InputDecoration(labelText: 'Número do leito'),
                keyboardType: TextInputType.number,
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
                if (tipoController.text.isEmpty ||
                    numeroLeitoController.text.isEmpty) {
                  return;
                }

                if (isEdit) {
                  // Atualiza internação existente
                  await supabase.from('internacao').update({
                    'tipo': tipoController.text,
                    'numero_leito':
                        int.tryParse(numeroLeitoController.text) ?? 0,
                  }).eq('id', internacao!['id']);
                } else {
                  // Cria nova internação
                  await supabase.from('internacao').insert({
                    'paciente_id': widget.pacienteId,
                    'tipo': tipoController.text,
                    'numero_leito':
                        int.tryParse(numeroLeitoController.text) ?? 0,
                    'data_internacao': DateTime.now().toIso8601String(),
                  });
                }

                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _excluirInternacao(int internacaoId) async {
    bool confirmado = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content:
              const Text('Tem certeza que deseja excluir esta internação?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmado) {
      await supabase.from('internacao').delete().eq('id', internacaoId);
      await supabase.from('rn').delete().eq('internacao_id', internacaoId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _cadastrarOuEditarInternacao(),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _fetchInternacoesComRn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar internações.'));
          }

          final internacoes = snapshot.data as List;

          if (internacoes.isEmpty) {
            return const Center(child: Text('Nenhuma internação cadastrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: internacoes.length,
            itemBuilder: (context, index) {
              final internacao = internacoes[index];
              final bool isParto = internacao['rn'] != null;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('Leito: ${internacao['numero_leito']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🛏️ Tipo: ${internacao['tipo']}'),
                      Text(
                          '📅 Data: ${formatarData(internacao['data_internacao'])}'),
                      if (isParto) ...[
                        Text('👶 Nome do RN: ${internacao['rn']['nome_rn']}'),
                        Text(
                            '📅 Data do Parto: ${formatarData(internacao['rn']['data_parto'])}'),
                      ],
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 5,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _cadastrarOuEditarInternacao(
                            internacao: internacao),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _excluirInternacao(internacao['id']),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EvolucaoScreen(internacaoId: internacao['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
