import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';

/// Login con email y contraseña. No hay registro: el usuario lo crea el
/// administrador en Supabase.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      ref.read(currentUserIdProvider.notifier).refresh();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '@sistente',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresá con tu usuario',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('login-email'),
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Ingresá un email válido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresá la contraseña'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          key: const Key('login-error'),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('login-submit'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
