// Désactive les avertissements pour les imports non utilisés
// ignore_for_file: unused_import

// Importations des packages et fichiers nécessaires
import 'package:flutter/material.dart'; // Pour les widgets Material Design
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'register_page.dart'; // Page d'inscription
import 'home_page.dart'; // Page d'accueil après connexion

/// Écran de connexion qui permet aux utilisateurs de se connecter avec email/mot de passe
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Contrôleurs pour les champs de saisie
  // Ils permettent de récupérer les valeurs entrées par l'utilisateur
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // État pour gérer l'affichage du chargement pendant les opérations asynchrones
  bool _isLoading = false;

  /// Fonction asynchrone pour gérer la connexion de l'utilisateur
  /// Vérifie les identifiants via Firebase Auth et gère les états de l'interface
  Future<void> loginUser() async {
    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
    });

    try {
      // Tentative de connexion avec Firebase Auth
      // Utilise les valeurs des contrôleurs en supprimant les espaces superflus
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Si la connexion réussit, on redirige vers la page d'accueil
      // pushReplacement remplace l'écran actuel pour empêcher le retour à l'écran de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs spécifiques à Firebase Auth
      String message = "Erreur de connexion.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = "Email ou mot de passe incorrect.";
      } else if (e.code == 'invalid-credential') {
        // Erreur générique pour des identifiants invalides
        message = "Identifiants invalides.";
      } else if (e.code == 'too-many-requests') {
        message = "Trop de tentatives. Réessayez plus tard.";
      }

      // Affichage d'un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // S'exécute dans tous les cas (succès ou échec)
      if (mounted) {
        setState(() {
          _isLoading = false; // Désactive l'indicateur de chargement
        });
      }
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un email de réinitialisation a été envoyé'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de l\'envoi de l\'email';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé avec cet email';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec logo et titre
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.fastfood_rounded,
                  size: 100,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bienvenue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez-vous pour continuer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Champ Email
              Text(
                'Email',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'entrez@votre.email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Champ Mot de passe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mot de passe',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Veuillez d\'abord entrer votre email'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _resetPassword(email);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        color: Colors.grey),
                    onPressed: () {
                      // Implémentez la logique pour afficher/masquer le mot de passe
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                obscureText: true,
                onSubmitted: (_) => loginUser(),
              ),
              const SizedBox(height: 32),

              // Bouton de connexion
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SE CONNECTER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Ligne de séparation
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton pour s'inscrire
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green),
                  ),
                ),
                child: const Text(
                  'CRÉER UN COMPTE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
