import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  runApp(const CofreApp());
}

class CofreApp extends StatelessWidget {
  const CofreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cofrinho de Recados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  String? _message;
  bool _success = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _message = null;
      _success = false;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Preencha todos os campos!';
        _success = false;
      });
      return;
    }

    if (email == 'bianca@gmail.com' && password == '123456') {
      await _secureStorage.write(key: 'auth_token', value: 'fake_token_123');
      setState(() {
        _message = 'Login realizado com sucesso!';
        _success = true;
      });

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CofrePage()),
      );
    } else {
      setState(() {
        _message = 'Credenciais inválidas!';
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _blob(200, Colors.deepPurpleAccent.withOpacity(0.3), top: -60, left: -60),
          _blob(250, Colors.purple.withOpacity(0.2), bottom: -80, right: -60),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Email', Icons.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Senha', Icons.lock),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _login,
                        child: const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_message != null)
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _success ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
      ),
    );
  }

  Widget _blob(double size, Color color, {double? top, double? left, double? bottom, double? right}) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class CofrePage extends StatefulWidget {
  const CofrePage({super.key});

  @override
  State<CofrePage> createState() => _CofrePageState();
}

class _CofrePageState extends State<CofrePage> {
  final _controller = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  late encrypt.Key _key;
  late encrypt.IV _iv;
  late encrypt.Encrypter _encrypter;

  String? _recadoCriptografado;
  String? _recadoDescriptografado;

  @override
  void initState() {
    super.initState();
    _inicializarCriptografia();
  }

  Future<void> _inicializarCriptografia() async {
    _key = encrypt.Key.fromSecureRandom(32);
    _iv = encrypt.IV.fromSecureRandom(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String _criptografar(String texto) {
    final encrypted = _encrypter.encrypt(texto, iv: _iv);
    return encrypted.base64;
  }

  String _descriptografar(String texto) {
    return _encrypter.decrypt64(texto, iv: _iv);
  }

  Future<void> _salvarRecado() async {
    final texto = _controller.text;
    if (texto.isEmpty) return;

    final criptografado = _criptografar(texto);

    await _secureStorage.write(key: 'recado', value: criptografado);
    await _secureStorage.write(key: 'iv', value: _iv.base64);

    setState(() {
      _recadoCriptografado = criptografado;
      _recadoDescriptografado = null;
    });

    _controller.clear();
  }

  Future<void> _lerRecado() async {
    final criptografado = await _secureStorage.read(key: 'recado');
    final ivBase64 = await _secureStorage.read(key: 'iv');

    if (criptografado == null || ivBase64 == null) return;

    _iv = encrypt.IV.fromBase64(ivBase64);
    final textoOriginal = _descriptografar(criptografado);

    setState(() => _recadoDescriptografado = textoOriginal);
  }

  Future<void> _recriptografar() async {
    if (_recadoDescriptografado != null) {
      final recriptografado = _criptografar(_recadoDescriptografado!);
      await _secureStorage.write(key: 'recado', value: recriptografado);
      await _secureStorage.write(key: 'iv', value: _iv.base64);

      setState(() {
        _recadoCriptografado = recriptografado;
        _recadoDescriptografado = null;
      });
    }
  }

  Future<void> _voltarAoLogin() async {
    await _secureStorage.delete(key: 'auth_token');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _blob(200, Colors.deepPurpleAccent.withOpacity(0.3), top: -80, left: -60),
          _blob(250, Colors.purple.withOpacity(0.2), bottom: -80, right: -60),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cofrinho', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _voltarAoLogin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _cardContainer(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _controller,
                                decoration: const InputDecoration(labelText: 'Digite seu recado'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _salvarRecado,
                                child: const Text('Salvar'),
                              ),
                              ElevatedButton(
                                onPressed: _lerRecado,
                                child: const Text('Mostrar'),
                              ),
                              ElevatedButton(
                                onPressed: _recriptografar,
                                child: const Text('Re-criptografar'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_recadoCriptografado != null)
                          _cardContainer(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🔒 Recado criptografado:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(_recadoCriptografado!),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_recadoDescriptografado != null)
                          _cardContainer(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🔓 Recado original:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(_recadoDescriptografado!),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, {double? top, double? left, double? bottom, double? right}) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _cardContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
