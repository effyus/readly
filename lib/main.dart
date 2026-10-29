import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

const Color corCafe = Color(0xFF5D4037);
const Color corMarrom = Color(0xFF795548);
const Color corCaramelo = Color(0xFFA67C52);
const Color corPapel = Color(0xFFF5EFE3);
const Color corPapelClaro = Color(0xFFFFFCF7);
const Color corBorda = Color(0xFFD8C7AE);
const Color corTexto = Color(0xFF3E3028);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ReadlyApp());
}

class ReadlyApp extends StatelessWidget {
  const ReadlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(
      seedColor: corMarrom,
      brightness: Brightness.light,
    ).copyWith(
      primary: corMarrom,
      onPrimary: Colors.white,
      secondary: corCaramelo,
      onSecondary: Colors.white,
      surface: corPapelClaro,
      onSurface: corTexto,
      error: const Color(0xFF9B332B),
    );

    return MaterialApp(
      title: 'Readly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: esquema,
        scaffoldBackgroundColor: corPapel,

        appBarTheme: const AppBarTheme(
          backgroundColor: corPapel,
          foregroundColor: corCafe,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: corCafe,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: corPapelClaro,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          labelStyle: const TextStyle(color: corMarrom),
          floatingLabelStyle: const TextStyle(
            color: corCafe,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Color(0xFF9A8A78)),
          prefixIconColor: corMarrom,
          suffixIconColor: corMarrom,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: corBorda),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: corBorda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: corMarrom, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9B332B)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF9B332B),
              width: 1.8,
            ),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: corMarrom,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD7C8B7),
            disabledForegroundColor: const Color(0xFF75675A),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corMarrom,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: corMarrom,
            side: const BorderSide(color: corMarrom),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: corMarrom,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        cardTheme: CardThemeData(
          color: corPapelClaro,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8DCCB)),
          ),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: corPapelClaro,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: corCafe,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: corPapelClaro,
          indicatorColor: const Color(0xFFE7D7C2),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? corCafe
                  : const Color(0xFF857466),
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? corCafe
                  : const Color(0xFF857466),
            ),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: corMarrom,
          foregroundColor: Colors.white,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: corCafe,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: corMarrom,
        ),

        dividerColor: corBorda,
      ),
      home: const LoginPage(),
    );
  }
}
