import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RelatorioEvolucoesScreen extends StatefulWidget {
  const RelatorioEvolucoesScreen({super.key});

  @override
  State<RelatorioEvolucoesScreen> createState() =>
      _RelatorioEvolucoesScreenState();
}

class _RelatorioEvolucoesScreenState extends State<RelatorioEvolucoesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  DateTime? dataInicial;
  DateTime? dataFinal;
  List<Map<String, dynamic>> evolucoes = [];

  Future<void> _selecionarDataInicial() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dataInicial = picked;
      });
    }
  }

  Future<void> _selecionarDataFinal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dataFinal = picked;
      });
    }
  }

  Future<void> _filtrarEvolucoes() async {
    if (dataInicial == null || dataFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ambas as datas para filtrar.')),
      );
      return;
    }

    final response = await supabase
        .from('evolucao')
        .select()
        .gte('data_visita', DateFormat('yyyy-MM-dd').format(dataInicial!))
        .lte('data_visita', DateFormat('yyyy-MM-dd').format(dataFinal!))
        .order('data_visita', ascending: false);

    setState(() {
      evolucoes = response;
    });
  }

  Future<void> _gerarRelatorioPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Relatório de Evoluções",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              for (var evolucao in evolucoes)
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("📅 Data da Visita: ${evolucao['data_visita']}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("📝 Observação: ${evolucao['observacao']}"),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Evoluções'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: evolucoes.isNotEmpty ? _gerarRelatorioPdf : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                  "Data Inicial: ${dataInicial != null ? DateFormat('dd/MM/yyyy').format(dataInicial!) : 'Selecione'}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarDataInicial,
            ),
            ListTile(
              title: Text(
                  "Data Final: ${dataFinal != null ? DateFormat('dd/MM/yyyy').format(dataFinal!) : 'Selecione'}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarDataFinal,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _filtrarEvolucoes,
              child: const Text('Filtrar Evoluções'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: evolucoes.isEmpty
                  ? const Center(
                      child:
                          Text('Nenhuma evolução encontrada para o período.'))
                  : ListView.builder(
                      itemCount: evolucoes.length,
                      itemBuilder: (context, index) {
                        final evolucao = evolucoes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text('📅 Data: ${evolucao['data_visita']}'),
                            subtitle: Text('📝 ${evolucao['observacao']}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
