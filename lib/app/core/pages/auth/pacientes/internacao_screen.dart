import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prontuario_social/app/core/pages/auth/pacientes/evolucao_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum Ala {
  EnfermariaMasculina,
  EnfermariaFeminina,
  PediatriaAlojamentoConjunto,
  Pediatria,
  LeitosSaudeMental,
}

extension AlaExtension on Ala {
  String get displayName {
    switch (this) {
      case Ala.EnfermariaMasculina:
        return 'Enfermaria Masculina';
      case Ala.EnfermariaFeminina:
        return 'Enfermaria Feminina';
      case Ala.PediatriaAlojamentoConjunto:
        return 'Pediatria Alojamento Conjunto';
      case Ala.Pediatria:
        return 'Pediatria';
      case Ala.LeitosSaudeMental:
        return 'Leitos Saúde Mental';
      default:
        return toString().split('.').last;
    }
  }
}

class InternacaoScreen extends StatefulWidget {
  final int pacienteId;

  const InternacaoScreen({super.key, required this.pacienteId});

  @override
  State<InternacaoScreen> createState() => _InternacaoScreenState();
}

class _InternacaoScreenState extends State<InternacaoScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

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
    final TextEditingController leitoController = TextEditingController();
    final TextEditingController diagnosticoController = TextEditingController();
    final TextEditingController dataInternacaoController =
        TextEditingController();
    Ala? alaSelecionada;

    if (internacao != null) {
      leitoController.text = internacao['numero_leito']?.toString() ?? '';
      diagnosticoController.text = internacao['diagnostico']?.toString() ?? '';
      dataInternacaoController.text =
          formatarData(internacao['data_internacao']?.toString() ?? '');
      alaSelecionada = Ala.values.firstWhere(
        (ala) => ala.toString() == 'Ala.${internacao['ala']}',
        orElse: () => Ala.EnfermariaMasculina,
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(internacao == null
                  ? 'Adicionar Internação'
                  : 'Editar Internação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: leitoController,
                      decoration: const InputDecoration(
                        labelText: 'Número do Leito',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: diagnosticoController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dataInternacaoController,
                      decoration: InputDecoration(
                        labelText: 'Data de Internação',
                        hintText: 'DD/MM/AAAA',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          dataInternacaoController.text =
                              DateFormat('dd/MM/yyyy').format(pickedDate);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Ala>(
                      value: alaSelecionada,
                      onChanged: (Ala? value) {
                        setStateDialog(() {
                          alaSelecionada = value;
                        });
                      },
                      items: Ala.values.map((Ala ala) {
                        return DropdownMenuItem<Ala>(
                          value: ala,
                          child: Text(ala.displayName), // Texto formatado
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Ala',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (leitoController.text.isNotEmpty &&
                        diagnosticoController.text.isNotEmpty &&
                        dataInternacaoController.text.isNotEmpty &&
                        alaSelecionada != null) {
                      final Map<String, dynamic> novaInternacao = {
                        'numero_leito': leitoController.text,
                        'diagnostico': diagnosticoController.text,
                        'data_internacao': DateFormat('yyyy-MM-dd').format(
                            DateFormat('dd/MM/yyyy')
                                .parse(dataInternacaoController.text)),
                        'ala': alaSelecionada
                            .toString()
                            .split('.')
                            .last, // Valor original
                        'paciente_id': widget.pacienteId,
                      };

                      if (internacao == null) {
                        await supabase
                            .from('internacao')
                            .insert([novaInternacao]);
                      } else {
                        final int internacaoId = internacao['id'] as int;
                        await supabase
                            .from('internacao')
                            .update(novaInternacao)
                            .eq('id', internacaoId);
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

  Future<void> _fecharInternacao(int internacaoId) async {
    String? desfechoSelecionado;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Fechar Internação'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Escolha o motivo do fechamento:'),
                  RadioListTile<String>(
                    title: const Text('Alta'),
                    value: 'Alta',
                    groupValue: desfechoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        desfechoSelecionado = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Transferência'),
                    value: 'Transferencia',
                    groupValue: desfechoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        desfechoSelecionado = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Óbito'),
                    value: 'Obito',
                    groupValue: desfechoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        desfechoSelecionado = value;
                      });
                    },
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
                    if (desfechoSelecionado != null) {
                      await supabase.from('internacao').update({
                        'desfecho': desfechoSelecionado,
                      }).eq('id', internacaoId);

                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: const Text('Fechar'),
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
      appBar: AppBar(title: const Text('Internações')),
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
              final bool isFechada = internacao['desfecho'] != null;
              final Color cardColor = isFechada
                  ? const Color.fromARGB(255, 104, 9, 2)
                  : const Color.fromARGB(255, 239, 243, 14);
              final Color textColor = isFechada ? Colors.white : Colors.black;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    'Leito: ${internacao['numero_leito']}',
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏥 Ala: ${Ala.values.firstWhere((ala) => ala.toString() == 'Ala.${internacao['ala']}').displayName}',
                        style: TextStyle(
                          color: textColor,
                        ),
                      ),
                      Text(
                        '📄 Diagnóstico: ${internacao['diagnostico']}',
                        style: TextStyle(
                          color: textColor,
                        ),
                      ),
                      Text(
                        '📅 Data: ${formatarData(internacao['data_internacao'])}',
                        style: TextStyle(
                          color: textColor,
                        ),
                      ),
                      if (isFechada)
                        Text(
                          '⚠ Desfecho: ${internacao['desfecho']}',
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 5,
                    children: [
                      if (!isFechada)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _fecharInternacao(internacao['id']),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _cadastrarOuEditarInternacao(
                            internacao: internacao),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cadastrarOuEditarInternacao(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
