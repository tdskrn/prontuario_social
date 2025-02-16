import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prontuario_social/app/core/pages/auth/pacientes/paciente_detalhe_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> stream;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    stream = supabase
        .from('pacientes')
        .stream(primaryKey: ['id'])
        .order('nome', ascending: true)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  // Formatar data no formato dd/MM/yyyy
  String formatarData(String data) {
    try {
      final DateTime parsedDate = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }

  // Função para formatar a entrada manual da data
  String formatarEntradaData(String input) {
    if (input.length == 8) {
      return '${input.substring(0, 2)}/${input.substring(2, 4)}/${input.substring(4, 8)}';
    }
    return input;
  }

  // Função para criar um novo paciente
  Future<void> _criarPaciente() async {
    final nomeController = TextEditingController();
    final dataNascimentoController = TextEditingController();

    String? sexoSelecionado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Paciente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person),
                  ),
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
                DropdownButtonFormField<String>(
                  value: sexoSelecionado,
                  items: ['Masculino', 'Feminino', 'Outro']
                      .map((sexo) => DropdownMenuItem(
                            value: sexo,
                            child: Text(sexo),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      sexoSelecionado = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    prefixIcon: Icon(Icons.wc),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty ||
                    dataNascimentoController.text.isEmpty ||
                    sexoSelecionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, preencha todos os campos!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Convertendo a data formatada para o formato do banco (yyyy-MM-dd)
                String formattedDate = DateFormat('yyyy-MM-dd').format(
                    DateFormat('dd/MM/yyyy')
                        .parse(dataNascimentoController.text));

                await supabase.from('pacientes').insert({
                  'nome': nomeController.text,
                  'data_nascimento': formattedDate,
                  'sexo': sexoSelecionado,
                });

                Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Lista de Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _criarPaciente,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum dado encontrado.'));
                }

                final pacientes = snapshot.data!;
                final searchQuery = _searchController.text.toLowerCase();

                final filteredPacientes = pacientes.where((paciente) {
                  final nome = paciente['nome'].toString().toLowerCase();
                  return nome.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filteredPacientes.length,
                  itemBuilder: (context, index) {
                    final paciente = filteredPacientes[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            paciente['nome'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PacienteDetalhesScreen(paciente: paciente),
                            ),
                          );
                        },
                        title: Text(
                          paciente['nome'] ?? 'Nome não encontrado',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Nascimento: ${formatarData(paciente['data_nascimento'])}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
