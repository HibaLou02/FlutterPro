// Importation des packages nécessaires
import 'package:flutter/material.dart'; // Pour les widgets Material Design
import 'package:firebase_core/firebase_core.dart'; // Pour l'initialisation de Firebase
import 'firebase_options.dart'; // Configuration générée par FlutterFire

// Importation des écrans de l'application
import 'screens/fruitsclassifier_page.dart'; // Écran de classification des fruits
import 'screens/home_page.dart'; // Page d'accueil après connexion
import 'screens/login_page.dart'; // Page de connexion
import 'screens/register_page.dart'; // Page d'inscription

/// Point d'entrée principal de l'application Flutter
/// Cette fonction est exécutée au démarrage de l'application
void main() async {
  // Assure que les widgets Flutter sont correctement initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase avec la configuration spécifique à la plateforme
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lance l'application avec le widget racine MyApp
  runApp(const MyApp());
}

/// Widget racine de l'application
/// Configure le thème, les routes et la navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Désactive la bannière de débogage en haut à droite
      debugShowCheckedModeBanner: false,

      // Titre de l'application
      title: 'Flutter Bousmah_App',

      // Configuration du thème de l'application
      theme: ThemeData(
        // Définit une palette de couleurs basée sur la couleur verte
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // Active Material 3 (Design System le plus récent)
        useMaterial3: true,
      ),

      // Route initiale au démarrage de l'application
      initialRoute: '/login',

      // Définition des routes nommées de l'application
      routes: {
        '/login': (context) => const LoginPage(), // Écran de connexion
        '/register': (context) => const RegisterPage(), // Écran d'inscription
        '/home': (context) => const HomePage(), // Page d'accueil
        '/fruitsclassifier': (context) =>
            const FruitsClassifierPage(), // Classificateur de fruits
      },

      // Gestionnaire de route personnalisé pour la navigation
      // Utile pour le débogage et la gestion des routes non définies
      onGenerateRoute: (settings) {
        // Affiche la route demandée dans la console pour le débogage
        print('Navigating to: ${settings.name}');

        // Retourne une route en fonction du nom de la route demandée
        return MaterialPageRoute(
          builder: (context) {
            switch (settings.name) {
              case '/fruitsclassifier':
                return const FruitsClassifierPage();
              // Par défaut, redirige vers la page d'accueil
              // Cela peut être modifié pour afficher une page 404 personnalisée
              default:
                return const HomePage();
            }
          },
        );
      },
    );
  }
}
