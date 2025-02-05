import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prontuario_social/app/core/pages/auth/controllers/login_controller.dart';

import 'package:prontuario_social/app/core/pages/auth/pacientes/get_pacientes_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  static const String name = 'home-page';
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SupabaseClient supabase;
  late final LoginController _loginController;
  int currentIndex = 0;
  List<Widget> pages = [
    PacientesScreen(),
    PacientesScreen(),
    Placeholder(),
  ];

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _loginController = LoginController(supabase: supabase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        actions: [
          Text('SAIR'),
          IconButton(
            onPressed: () async {
              _loginController.signOut();
              context.go('/');
            },
            icon: Icon(
              Icons.logout,
            ),
          ),
        ],
        title: Text('Usuário: ${supabase.auth.currentUser!.email}'),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Color.fromARGB(255, 3, 9, 97),
          textTheme: TextTheme(
            displayLarge: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        child: BottomNavigationBar(
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          fixedColor: Colors.yellow,
          onTap: (value) {
            currentIndex = value;
            setState(() {});
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              label: 'Servidores',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.propane_tank_rounded,
              ),
              label: 'Gráficos',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.format_quote,
              ),
              label: 'Vagas',
            ),
          ],
        ),
      ),
    );
  }
}
