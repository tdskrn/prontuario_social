import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:prontuario_social/app/core/config/utils.dart';
import 'package:prontuario_social/app/core/pages/auth/controllers/login_controller.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  static const String name = 'login-page';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final SupabaseClient supabase;
  late final LoginController _loginController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
        centerTitle: true,
        title: Text('Prontuario Social'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                children: [
                  Text(
                    "Email",
                    style: TextStyle(color: Color(0xFF707070), fontSize: 18),
                  ),
                  TextFormField(
                    controller: _emailController,
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: [AutofillHints.email],
                    decoration: InputDecoration(
                      hintText: "exemplo@email.com",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF707070)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF707070)),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Senha",
                    style: TextStyle(color: Color(0xFF707070), fontSize: 18),
                  ),
                  TextFormField(
                    controller: _passwordController,
                    autofillHints: [AutofillHints.password],
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Insira algum texto';
                      }
                      if (value.length < 6) {
                        return "Senha muito curta";
                      }
                      return null;
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "********",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF707070)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF707070)),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            EasyLoading.show(status: 'Fazendo Login...');
                            print('antes do login');
                            _loginController
                                .signIn(_emailController.text,
                                    _passwordController.text)
                                .whenComplete(
                              () {
                                context.go('/home-page');
                              },
                            );

                            EasyLoading.dismiss();
                          } catch (error) {
                            EasyLoading.dismiss();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(error.toString()),
                            ));
                          }
                        }
                      },
                      child: Text('ENTRAR'))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
