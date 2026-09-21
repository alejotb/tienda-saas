import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:baul_pandora/auth/auth_manager.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'email_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:baul_pandora/services/favorites_service.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'supabase_user_provider.dart';

export 'package:baul_pandora/auth/base_auth_user_provider.dart';

class SupabaseAuthManager extends AuthManager
    with EmailSignInManager, AnonymousSignInManager, GoogleSignInManager {
  @override
  Future signOut() async {
    // 1. Clear the cart first to ensure it's wiped both locally and remotely
    try {
      await CartService.instance.clearCart();
    } catch (e) {
      debugPrint('Error clearing cart on signOut: $e');
    }

    // 2. Clear all local user data (favorites, addresses, invitado mode, etc.)
    FFAppState().clearUserData();

    // 3. Reset guest mode whenever the app signs out and signOut Supabase
    try {
      await SupaFlow.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out Supabase: $e');
    }
  }

  @override
  Future<BaseAuthUser?> signInAnonymously(BuildContext context) async {
    // Guest mode does not create an authenticated Supabase user at this time.
    return null;
  }

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) async {
    return _signInOrCreateAccount(
      context,
      () async {
        try {
          // Initialize GoogleSignIn
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId: kIsWeb ? '396689225591-msso5bm3reoquf18m4quo8f1sjeeb7du.apps.googleusercontent.com' : null,
            serverClientId: '396689225591-msso5bm3reoquf18m4quo8f1sjeeb7du.apps.googleusercontent.com',
            scopes: [
              'email',
              'profile',
            ],
          );

          // Trigger the Google Sign-In flow
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            // User cancelled the sign-in flow
            return null;
          }

          // Obtain the authentication details from the request
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

          if (googleAuth.idToken == null) {
            throw Exception('ID Token not found.');
          }

          // Sign in to Supabase with the Google ID Token
          final AuthResponse response = await SupaFlow.client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );

          return response.user;
        } catch (e) {
          debugPrint('Error signing in with Google: $e');
          rethrow;
        }
      },
    );
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        print('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email change confirmation email sent')),
    );
  }

  @override
  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(newPassword);
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully')),
    );
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
    String? redirectTo,
  }) async {
    try {
      await SupaFlow.client.auth
          .resetPasswordForEmail(email, redirectTo: redirectTo);
    } on AuthException catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return null;
    }
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailSignInFunc(email, password),
      );

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => emailCreateAccountFunc(email, password),
      );

  /// Tries to sign in or create an account using Supabase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<User?> Function() signInFunc,
  ) async {
    try {
      final user = await signInFunc();
      final authUser = user == null ? null : BaulPandoraSupabaseUser(user);

      // Update currentUser here in case user info needs to be used immediately
      // after a user is signed in. This should be handled by the user stream,
      // but adding here too in case of a race condition where the user stream
      // doesn't assign the currentUser in time.
      if (authUser != null) {
        currentUser = authUser;
        await AppStateNotifier.instance.update(authUser);

        // Sincronizar / crear información del usuario en tabla 'usuarios'
        try {
          final metadata = user?.userMetadata;
          final fullName = metadata?['display_name']?.toString() ??
              metadata?['full_name']?.toString() ??
              metadata?['name']?.toString() ??
              metadata?['nombre']?.toString();
          final avatarUrl = metadata?['avatar_url']?.toString() ??
              metadata?['picture']?.toString() ??
              metadata?['photo_path']?.toString();

          final existingUser = await UsuariosTable().querySingleRow(
            queryFn: (q) => q.eq('id', authUser.uid!),
          );

          if (existingUser.isEmpty) {
            await SupaFlow.client.from('usuarios').insert({
              'id': authUser.uid!,
              'email': user?.email,
              if (fullName != null && fullName.isNotEmpty) 'nombre_completo': fullName,
              if (avatarUrl != null && avatarUrl.isNotEmpty) 'photo_path': avatarUrl,
              'rol': 'cliente',
              'is_admin': false,
            });
          } else {
            final userRow = existingUser.first;
            bool needsUpdate = false;
            final updateData = <String, dynamic>{};

            if (fullName != null &&
                fullName.isNotEmpty &&
                (userRow.nombreCompleto == null || userRow.nombreCompleto!.isEmpty)) {
              updateData['nombre_completo'] = fullName;
              needsUpdate = true;
            }
            if (avatarUrl != null &&
                avatarUrl.isNotEmpty &&
                (userRow.photoPath == null || userRow.photoPath!.isEmpty)) {
              updateData['photo_path'] = avatarUrl;
              needsUpdate = true;
            }

            if (needsUpdate) {
              await UsuariosTable().update(
                data: updateData,
                matchingRows: (rows) => rows.eq('id', authUser.uid!),
              );
            }
          }
        } catch (e) {
          debugPrint('Error sincronizando usuario en tabla usuarios: $e');
        }

        // Synchronize favorites upon successful login
        try {
          await FavoritesService.instance.syncFavorites();
        } catch (e) {
          debugPrint('Error syncing favorites: $e');
        }

        // Synchronize guest cart to remote upon successful login
        try {
          await CartService.instance.syncGuestCartToRemote();
        } catch (e) {
          debugPrint('Error syncing guest cart: $e');
        }
      }
      return authUser;
    } on AuthException catch (e) {
      final errorMsg = e.message.contains('User already registered')
          ? 'Error: The email is already in use by a different account'
          : 'Error: ${e.message}';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return null;
    } catch (e) {
      String errorMsg =
          'Error: An unexpected error occurred. Please try again.';
      if (e.toString().contains('ClientException') ||
          e.toString().contains('Failed to fetch')) {
        errorMsg =
            'Network error: Please check your internet connection or verify the Supabase Site URL in the dashboard.';
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return null;
    }
  }
}
