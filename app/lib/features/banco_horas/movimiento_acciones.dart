import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/banco/banco_repository.dart';
import '../../data/banco/movimiento.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';

void _avisar(ScaffoldMessengerState messenger, String texto) =>
    messenger.showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );

/// Marca [m] como perdido (no computa) o lo vuelve a vigente. Devuelve
/// `true` si se guardó.
Future<bool> cambiarPerdido(
  BuildContext context,
  WidgetRef ref,
  LocalMovimiento m, {
  required bool perdido,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return false;
  try {
    await ref
        .read(bancoRepositoryProvider)
        .marcarPerdido(userId: userId, id: m.id, perdido: perdido);
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    _avisar(
      messenger,
      perdido
          ? '${describirMovimiento(m)} marcado como perdido: ya no computa.'
          : '${describirMovimiento(m)} vuelve a estar vigente.',
    );
    return true;
  } on BancoInvalidoException catch (e) {
    _avisar(messenger, e.message);
  } catch (e) {
    _avisar(messenger, 'No se pudo guardar: $e');
  }
  return false;
}

/// Pide confirmación y borra [m] (borrado lógico). Devuelve `true` si se
/// borró.
Future<bool> borrarMovimiento(
  BuildContext context,
  WidgetRef ref,
  LocalMovimiento m,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Borrar movimiento'),
      content: Text(
        '¿Querés borrar ${describirMovimiento(m).toLowerCase()}? '
        'Deja de computar en el saldo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-borrar'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return false;
  try {
    await ref
        .read(bancoRepositoryProvider)
        .borrarMovimiento(userId: userId, id: m.id);
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    _avisar(messenger, '${describirMovimiento(m)} borrado.');
    return true;
  } on BancoInvalidoException catch (e) {
    _avisar(messenger, e.message);
  } catch (e) {
    _avisar(messenger, 'No se pudo borrar: $e');
  }
  return false;
}

/// Texto del estado: "Vigente" o "Perdido (no computa)".
String estadoLabel(LocalMovimiento m) =>
    m.perdido ? 'Perdido (no computa)' : 'Vigente';
