import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartbagx/firebase_options.dart';
import 'auth/auth_services.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _checkIfSignedIn();
    });
  }

  Future<void> _checkIfSignedIn() async {
    final user = AuthServices.firebaseAuth.currentUser;

    if (user != null && mounted) {
      // User is already signed in, navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() {
        isAuthenticating = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    final user = await AuthServices.signInWithGoogle();
    if (user != null && mounted) {
      //create user in firestore
      AuthServices.createUser(user);

      // Navigate to HomePage after successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isAuthenticating
        ? Scaffold(
            body: Center(
              child: const CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Please sign in to continue'),
              centerTitle: true,
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: _handleSignIn,
                child: Container(
                    width: 170,
                    padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/icons/google.png',
                            width: 24,
                          ),
                        ),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    )),
              ),
            ),
          );
  }
}
