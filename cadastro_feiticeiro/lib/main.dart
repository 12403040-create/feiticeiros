import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Se rodar `flutterfire configure`, descomente a linha abaixo e o parâmetro
// "options" no Firebase.initializeApp.
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JujutsuApp());
}

class JujutsuApp extends StatelessWidget {
  const JujutsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escola Jujutsu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Usuário logado? NÃO -> LoginPage | SIM -> CentralJujutsuPage
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const CentralJujutsuPage();
        }
        return const LoginPage();
      },
    );
  }
}



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _carregando = false;

  Future<void> _entrarComGoogle() async {
    setState(() => _carregando = true);
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // usuário cancelou
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon,
                    size: 96, color: tema.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'ESCOLA JUJUTSU',
                  style: tema.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text('Acesso restrito para feiticeiros',
                    style: tema.textTheme.bodyLarge),
                const SizedBox(height: 40),
                _carregando
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _entrarComGoogle,
                        icon: const Icon(Icons.login),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('ENTRAR COM GOOGLE'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CENTRAL JUJUTSU
// ---------------------------------------------------------------------------

class CentralJujutsuPage extends StatefulWidget {
  const CentralJujutsuPage({super.key});

  @override
  State<CentralJujutsuPage> createState() => _CentralJujutsuPageState();
}

class _CentralJujutsuPageState extends State<CentralJujutsuPage> {
  final _missoes = FirebaseFirestore.instance.collection('missoes');

  Future<void> _sair() async {
    if (!kIsWeb) await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _cadastrarMissao() async {
    final tituloCtrl = TextEditingController();
    int grau = 4;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nova missão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: grau,
                decoration: const InputDecoration(labelText: 'Grau'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Grau especial (0)')),
                  DropdownMenuItem(value: 1, child: Text('Grau 1')),
                  DropdownMenuItem(value: 2, child: Text('Grau 2')),
                  DropdownMenuItem(value: 3, child: Text('Grau 3')),
                  DropdownMenuItem(value: 4, child: Text('Grau 4')),
                ],
                onChanged: (v) => setStateDialog(() => grau = v ?? grau),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    final titulo = tituloCtrl.text.trim();
    if (salvar != true || titulo.isEmpty) return;

    await _missoes.add({
      'titulo': titulo,
      'grau': grau,
      'concluida': false,
      'usuarioId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Jujutsu'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cadastrarMissao,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar missão'),
      ),
      body: Column(
        children: [
          _CabecalhoUsuario(user: user),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Regra principal: somente as missões do usuário logado
              stream: _missoes
                  .where('usuarioId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma missão cadastrada.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    final concluida = d['concluida'] == true;
                    return ListTile(
                      leading: Checkbox(
                        value: concluida,
                        onChanged: (v) =>
                            doc.reference.update({'concluida': v ?? false}),
                      ),
                      title: Text(
                        d['titulo'] ?? '',
                        style: TextStyle(
                          decoration:
                              concluida ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                          'Grau ${d['grau']} • ${concluida ? 'Concluída' : 'Pendente'}'),
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => doc.reference.delete(),
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

class _CabecalhoUsuario extends StatelessWidget {
  const _CabecalhoUsuario({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bem-vindo,'),
                Text(
                  user.displayName ?? 'Feiticeiro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(user.email ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
