import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../settings/app_settings.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> register(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    }
  }

  /// Inicialización de Google Sign-In (se hace una sola vez).
  static Future<void>? _googleInit;

  /// Inicia sesión con la cuenta de Google. Devuelve null si salió bien o el
  /// mensaje de error.
  ///
  /// En Android usa el selector de cuentas nativo del celular (sin abrir el
  /// navegador). En otras plataformas usa la ventana de Google de Firebase.
  ///
  /// Requiere que en la consola de Firebase esté activado el proveedor
  /// "Google", registrada la huella SHA-1 y el google-services.json
  /// descargado después de activar Google.
  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      _googleInit ??= googleSignIn.initialize();
      await _googleInit;

      if (googleSignIn.supportsAuthenticate()) {
        final account = await googleSignIn.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          return tr('No se pudo iniciar sesión con Google.',
              'Could not sign in with Google.');
        }
        await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
        // Si la cuenta aún no tiene nombre, se guarda el de Google.
        final current = _auth.currentUser?.displayName?.trim() ?? '';
        final googleName = account.displayName?.trim() ?? '';
        if (current.isEmpty && googleName.isNotEmpty) {
          await _auth.currentUser?.updateDisplayName(googleName);
        }
      } else {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithProvider(provider);
      }

      // Trae el nombre y la foto de la cuenta de Google antes de entrar.
      await _auth.currentUser?.reload();
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return _traducirError('canceled');
      }
      debugPrint('Error de Google Sign-In: ${e.code} ${e.description}');
      return tr('No se pudo iniciar sesión con Google.',
          'Could not sign in with Google.');
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    } catch (e) {
      debugPrint('Error iniciando sesión con Google: $e');
      _googleInit = null; // permite reintentar la inicialización
      return tr('No se pudo iniciar sesión con Google.',
          'Could not sign in with Google.');
    }
  }

  /// Envía el correo para restablecer la contraseña.
  /// Devuelve null si se envió o el mensaje de error.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    }
  }

  /// Cambia el nombre visible del usuario con sesión iniciada y recarga sus
  /// datos para que el nuevo nombre se vea en toda la app.
  /// Devuelve null si salió bien o el mensaje de error.
  Future<String?> updateDisplayName(String name) async {
    if (_auth.currentUser == null) {
      return tr('Debes iniciar sesión.', 'You must sign in.');
    }
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    } catch (_) {
      return tr('Ocurrió un error. Intenta de nuevo.',
          'Something went wrong. Please try again.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Si entró con Google, también se cierra allí para que la próxima vez
    // pueda elegir otra cuenta.
    try {
      if (_googleInit != null) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  String _traducirError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return tr('Este correo ya está registrado.',
            'This email is already registered.');
      case 'invalid-email':
        return tr('El correo no es válido.', 'The email is not valid.');
      case 'missing-email':
        return tr('Escribe tu correo electrónico.', 'Enter your email.');
      case 'weak-password':
        return tr('La contraseña debe tener al menos 6 caracteres.',
            'The password must have at least 6 characters.');
      case 'user-not-found':
        return tr('No existe una cuenta con ese correo.',
            'There is no account with that email.');
      case 'wrong-password':
        return tr('Contraseña incorrecta.', 'Wrong password.');
      case 'invalid-credential':
        return tr('Correo o contraseña incorrectos.',
            'Wrong email or password.');
      case 'too-many-requests':
        return tr('Demasiados intentos. Espera un momento.',
            'Too many attempts. Please wait a moment.');
      case 'network-request-failed':
        return tr('Sin conexión a internet. Revisa tu red.',
            'No internet connection. Check your network.');
      case 'operation-not-allowed':
        return tr('Este método de inicio de sesión no está activado en Firebase.',
            'This sign-in method is not enabled in Firebase.');
      case 'account-exists-with-different-credential':
        return tr('Ese correo ya tiene una cuenta con contraseña. Entra con tu correo y contraseña.',
            'That email already has a password account. Sign in with your email and password.');
      case 'web-context-canceled':
      case 'canceled':
        return tr('Cancelaste el inicio de sesión con Google.',
            'You canceled the Google sign-in.');
      default:
        return tr('Ocurrió un error. Intenta de nuevo.',
            'Something went wrong. Please try again.');
    }
  }
}
