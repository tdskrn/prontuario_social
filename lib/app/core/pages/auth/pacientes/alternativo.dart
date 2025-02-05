// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class InternacaoScreen extends StatefulWidget {
//   final int pacienteId;
//   const InternacaoScreen({super.key, required this.pacienteId});
  
//   @override
//   State<InternacaoScreen> createState() => _InternacaoScreenState();
// }

// class _InternacaoScreenState extends State<InternacaoScreen> {
//   final SupabaseClient supabase = Supabase.instance.client;
  
//   Future<void> _cadastrarInternacao() async {
//     bool isParto = false;
//     String? nomeBebe;
//     int? peso, altura, dataNascimento;
    
//     // Primeiro perguntar se é parto
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Cadastrar Internação'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextButton(
//               onPressed: () {
//                 isParto = true;
//                 Navigator.pop(context);
//               },
//               child: const Text('Sim, é um parto')),
//             TextButton(
//               onPressed: () {
//                 isParto = false;
//                 Navigator.pop(context);
//               },
//               child: const Text('Não, não é um parto'))
//           ],
//         ),
//       ),
//     );
    
//     if (isParto) {
//       // Se for parto, mostrar campos extras para o bebê
//       final tipoController = TextEditingController();
//       final numeroLeitoController = TextEditingController();
      
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Cadastrar Internação'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: tipoController,
//                 decoration: const InputDecoration(labelText: 'Tipo de internação'),
//               ),
//               TextField(
//                 controller: numeroLeitoController,
//                 decoration: const InputDecoration(labelText: 'Número do leito'),
//                 keyboardType: TextInputType.number,
//               ),
//               const Text('Dados do Bebê:'),
//               TextField(
//                 controller: TextEditingController()..addListener((_) => nomeBebe = _controller.text),
//                 decoration: const InputDecoration(labelText: 'Nome do bebê'),
//               ),
//               TextField(
//                 controller: TextEditingController()..addListener((_) => peso = int.tryParse(_controller.text)),
//                 decoration: const InputDecoration(labelText: 'Peso (em gramas)'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: TextEditingController()..addListener((_) => altura = int.tryParse(_controller.text)),
//                 decoration: const InputDecoration(labelText: 'Altura (cm)'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: TextEditingController()..addListener((_) => dataNascimento = DateTime.parse(_controller.text).millisecondsSinceEpoch),
//                 decoration: const InputDecoration(labelText: 'Data de nascimento'),
//                 keyboardType: TextInputType.datetime,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancelar'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 if (tipoController.text.isNotEmpty &&
//                     numeroLeitoController.text.isNotEmpty) {
//                   // Salvar internação
//                   final internacaoId = await supabase
//                       .from('internacao')
//                       .insert([
//                         'paciente_id': widget.pacienteId,
//                         'tipo_internacao': tipoController.text,
//                         'leito': int.parse(numeroLeitoController.text),
//                         'dataHoraInternacao': DateTime.now().millisecondsSinceEpoch,
//                       ]).single();
                  
//                   // Se for parto, salvar dados do bebê
//                   if (isParto) {
//                     await supabase
//                         .from('bebe')
//                         .insert([
//                           'internacao_id': internacaoId,
//                           'nome': nomeBebe,
//                           'peso': peso,
//                           'altura': altura,
//                           'data_nascimento': dataNascimento,
//                         ]).single();
//                   }
                  
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('Salvar'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // Caso não seja parto, manter o fluxo original
//       final tipoController = TextEditingController();
//       final numeroLeitoController = TextEditingController();
      
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Cadastrar Internação'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: tipoController,
//                 decoration: const InputDecoration(labelText: 'Tipo de internação'),
//               ),
//               TextField(
//                 controller: numeroLeitoController,
//                 decoration: const InputDecoration(labelText: 'Número do leito'),
//                 keyboardType: TextInputType.number,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancelar'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 if (tipoController.text.isNotEmpty &&
//                     numeroLeitoController.text.isNotEmpty) {
//                   await supabase
//                       .from('internacao')
//                       .insert([
//                         'paciente_id': widget.pacienteId,
//                         'tipo_internacao': tipoController.text,
//                         'leito': int.parse(numeroLeitoController.text),
//                         'dataHoraInternacao': DateTime.now().millisecondsSinceEpoch,
//                       ]).single();
                  
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('Salvar'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Cadastro de Internações')),
//       body: Center(child: ElevatedButton(
//         onPressed: _cadastrarInternacao,
//         child: const Text('Cadastrar Internação'),
//       )),
//     );
//   }
// }