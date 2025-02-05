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

  // Função para formatar entrada manual de data (ex: 09111995 → 09/11/1995)
  String formatarEntradaData(String input) {
    if (input.length == 8) {
      return '${input.substring(0, 2)}/${input.substring(2, 4)}/${input.substring(4, 8)}';
    }
    return input;
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

  Future<void> _editarInternacao(Map<String, dynamic> internacao) async {
    final tipoController = TextEditingController(text: internacao['tipo']);
    final numeroLeitoController =
        TextEditingController(text: internacao['numero_leito'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Internação'),
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
                await supabase.from('internacao').update({
                  'tipo': tipoController.text,
                  'numero_leito': int.tryParse(numeroLeitoController.text) ?? 0,
                }).eq('id', internacao['id']);

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

  Future<void> _editarRn(Map<String, dynamic> rn) async {
    final nomeRnController = TextEditingController(text: rn['nome_rn']);
    final dataPartoController =
        TextEditingController(text: formatarData(rn['data_parto']));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Recém-Nascido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeRnController,
                decoration: const InputDecoration(labelText: 'Nome do RN'),
              ),
              TextField(
                controller: dataPartoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Data do Parto (dd/MM/yyyy)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null) {
                        String formattedDate =
                            DateFormat('dd/MM/yyyy').format(pickedDate);
                        setState(() {
                          dataPartoController.text = formattedDate;
                        });
                      }
                    },
                  ),
                ),
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
                await supabase.from('rn').update({
                  'nome_rn': nomeRnController.text,
                  'data_parto': DateFormat('yyyy-MM-dd').format(
                      DateFormat('dd/MM/yyyy').parse(dataPartoController.text)),
                }).eq('id', rn['id']);

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

  Future<void> _excluirRn(int rnId) async {
    await supabase.from('rn').delete().eq('id', rnId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internações'),
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
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarRn(internacao['rn']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _excluirRn(internacao['rn']['id']),
                        ),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _excluirInternacao(internacao['id']),
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
