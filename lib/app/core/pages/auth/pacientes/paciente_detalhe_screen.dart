import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prontuario_social/app/core/pages/auth/pacientes/internacao_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteDetalhesScreen extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const PacienteDetalhesScreen({super.key, required this.paciente});

  @override
  State<PacienteDetalhesScreen> createState() => _PacienteDetalhesScreenState();
}

class _PacienteDetalhesScreenState extends State<PacienteDetalhesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para formatar data do banco no formato dd/MM/yyyy
  String formatarData(String data) {
    try {
      final DateTime parsedDate = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }

  // Função para formatar a entrada manual da data (ex: 09111995 → 09/11/1995)
  String formatarEntradaData(String input) {
    if (input.length == 8) {
      return '${input.substring(0, 2)}/${input.substring(2, 4)}/${input.substring(4, 8)}';
    }
    return input;
  }

  Future<void> _excluirPaciente() async {
    bool confirmado = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este paciente?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir')),
          ],
        );
      },
    );

    if (confirmado) {
      await supabase.from('pacientes').delete().eq('id', widget.paciente['id']);
      Navigator.pop(context, true);
    }
  }

  Future<void> _editarPaciente() async {
    final nomeController = TextEditingController(text: widget.paciente['nome']);
    final dataNascimentoController = TextEditingController(
        text: formatarData(widget.paciente['data_nascimento']));
    final sexoController = TextEditingController(text: widget.paciente['sexo']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Paciente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dataNascimentoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento (dd/MM/yyyy)',
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
                            dataNascimentoController.text = formattedDate;
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 8) {
                      setState(() {
                        dataNascimentoController.text =
                            formatarEntradaData(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sexoController,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () async {
                  // Convertendo a data formatada para o formato do banco (yyyy-MM-dd)
                  String formattedDate = DateFormat('yyyy-MM-dd').format(
                      DateFormat('dd/MM/yyyy')
                          .parse(dataNascimentoController.text));

                  await supabase.from('pacientes').update({
                    'nome': nomeController.text,
                    'data_nascimento': formattedDate,
                    'sexo': sexoController.text,
                  }).eq('id', widget.paciente['id']);

                  setState(() {
                    widget.paciente['nome'] = nomeController.text;
                    widget.paciente['data_nascimento'] = formattedDate;
                    widget.paciente['sexo'] = sexoController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salvar')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarPaciente,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPatientInfoCard(),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        InternacaoScreen(pacienteId: widget.paciente['id']),
                  ),
                );
              },
              child: const Text(
                '📋 Ver Internações',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildPatientDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoRow('Nome:', widget.paciente['nome']),
        const SizedBox(height: 10),
        _buildInfoRow('Data de Nascimento:',
            formatarData(widget.paciente['data_nascimento'])),
        const SizedBox(height: 10),
        _buildInfoRow('Sexo:', widget.paciente['sexo']),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          if (value != null && value.isNotEmpty)
            Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14))
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _excluirPaciente,
        child: const Text('Excluir Paciente'),
      ),
    );
  }
}
