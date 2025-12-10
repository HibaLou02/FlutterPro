// Importation des packages nécessaires
import 'package:flutter/material.dart'; // Pour les widgets Material Design
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'login_page.dart'; // Page de connexion pour la redirection

/// Écran d'inscription qui permet aux utilisateurs de créer un nouveau compte
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Contrôleurs pour les champs de formulaire
  // Ils permettent de récupérer les valeurs entrées par l'utilisateur
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // État pour gérer l'affichage d'un indicateur de chargement
  bool _isLoading = false;

  // État pour gérer la visibilité du mot de passe
  bool _obscurePassword = true;

  /// Fonction asynchrone pour gérer l'inscription d'un nouvel utilisateur
  /// Crée un compte utilisateur dans Firebase Auth avec l'email et le mot de passe fournis
  Future<void> registerUser() async {
    // Active l'indicateur de chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // Tente de créer un nouvel utilisateur avec Firebase Auth
      // trim() est utilisé pour supprimer les espaces superflus
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Affiche un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte créé avec succès ! Connectez-vous."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Redirige vers la page de connexion après une inscription réussie
      // pushReplacement empêche le retour à l'écran d'inscription
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs spécifiques à Firebase Auth
      String message = "Une erreur est survenue lors de l'inscription.";

      if (e.code == 'weak-password') {
        message =
            "Le mot de passe est trop faible. Utilisez au moins 6 caractères.";
      } else if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé par un autre compte.";
      } else if (e.code == 'invalid-email') {
        message = "L'adresse email n'est pas valide.";
      } else if (e.code == 'operation-not-allowed') {
        message = "L'inscription par email/mot de passe n'est pas activée.";
      }

      // Affiche le message d'erreur à l'utilisateur
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
      // Désactive l'indicateur de chargement dans tous les cas
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              const SizedBox(height: 20),
              Text(
                'Créer un compte',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les champs ci-dessous pour créer votre compte',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Champ Email
              Text(
                'Adresse email',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'exemple@email.com',
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
              Text(
                'Mot de passe',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),

              // Conditions d'utilisation
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (value) {},
                    activeColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Expanded(
                    child: Text(
                      'En vous inscrivant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton d'inscription
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: registerUser,
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
                        'S\'INSCRIRE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Lien vers la connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ? '),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
