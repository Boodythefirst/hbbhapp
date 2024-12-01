import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hbbh/firebase_options.dart';
import 'package:hbbh/services/onboarding_service.dart';
import 'package:hbbh/services/auth_service.dart';
import 'package:hbbh/screens/onboarding/onboarding_screen.dart';
import 'package:hbbh/screens/onboarding/welcome_screen.dart';
import 'package:hbbh/screens/home_screen.dart';
import 'package:hbbh/screens/bookmarks_screen.dart';
import 'package:hbbh/screens/profile_screen.dart';
import 'package:hbbh/screens/settings_screen.dart';
import 'package:hbbh/screens/auth/sign_in_screen.dart';
import 'package:hbbh/screens/auth/sign_up_screen.dart';
import 'package:hbbh/screens/auth/forgot_password_screen.dart';
import 'package:hbbh/screens/spot/spot_onboarding_screen.dart';
import 'package:hbbh/screens/spot/spot_management_screen.dart';
import 'package:hbbh/models/spot_model.dart';
import 'package:hbbh/screens/spot/spot_edit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  runApp(const ProviderScope(child: HbbhApp()));
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final onboardingServiceProvider =
    Provider<OnboardingService>((ref) => OnboardingService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final onboardingService = ref.watch(onboardingServiceProvider);

  try {
    // First check Firebase
    final isFirebaseOnboardingComplete =
        await authService.isOnboardingCompleted();
    if (isFirebaseOnboardingComplete) {
      return true;
    }

    // Fallback to local storage
    final data = await onboardingService.getOnboardingData();
    return data['isComplete'] ?? false;
  } catch (e) {
    // Final fallback to local storage
    final data = await onboardingService.getOnboardingData();
    return data['isComplete'] ?? false;
  }
});

Future<SpotModel?> _loadSpotData(Ref ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final spotData = await authService.getSpotData();
    if (spotData != null) {
      return SpotModel.fromMap(spotData, spotData['id']);
    }
    return null;
  } catch (e) {
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) async {
      final authState = ref.read(authStateChangesProvider);
      final isAuthenticated = authState.value != null;

      // Check if it's a spot account
      bool? isSpotAccount;
      if (isAuthenticated && authState.value != null) {
        final userData = await ref.read(authServiceProvider).getUserData();
        isSpotAccount = userData['isSpot'] ?? false;
      }

      // Check onboarding status
      final isOnboardingComplete =
          await ref.read(onboardingCompletedProvider.future);
      final location = state.uri.toString();

      // Auth pages handling
      if (location.startsWith('/signin') ||
          location.startsWith('/signup') ||
          location.startsWith('/forgot-password')) {
        if (isAuthenticated && isOnboardingComplete) {
          return isSpotAccount == true ? '/spot-management' : '/home';
        }
        return null;
      }

      // Not authenticated flow
      if (!isAuthenticated) {
        if (!isOnboardingComplete) {
          // Allow welcome and onboarding screens
          if (location == '/' || location.startsWith('/onboarding')) {
            return null;
          }
          return '/';
        } else {
          // Allow main screens for guest users
          if (location == '/home' ||
              location == '/bookmarks' ||
              location == '/profile' ||
              location == '/settings') {
            return null;
          }
          return '/home';
        }
      }

      // Authenticated flow
      if (isAuthenticated) {
        // Spot account flow
        if (isSpotAccount == true) {
          // Check if spot has completed registration
          final spotData = await ref.read(authServiceProvider).getSpotData();
          final isSpotRegistered =
              spotData != null && spotData.containsKey('name');

          if (!isSpotRegistered && !location.startsWith('/spot-onboarding')) {
            return '/spot-onboarding';
          }

          if (isSpotRegistered &&
              (location == '/' ||
                  location.startsWith('/onboarding') ||
                  location.startsWith('/spot-onboarding'))) {
            return '/spot-management';
          }

          // Prevent spot accounts from accessing user-only routes
          if (location.startsWith('/home') ||
              location.startsWith('/bookmarks')) {
            return '/spot-management';
          }
        }
        // Regular user flow
        else {
          if (!isOnboardingComplete && !location.startsWith('/onboarding')) {
            return '/onboarding';
          }
          if (isOnboardingComplete &&
              (location == '/' || location.startsWith('/onboarding'))) {
            return '/home';
          }
          // Prevent regular users from accessing spot-only routes
          if (location.startsWith('/spot-')) {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/spot-onboarding',
        builder: (context, state) => const SpotOnboardingScreen(),
      ),
      GoRoute(
        path: '/spot-management',
        builder: (context, state) => const SpotManagementScreen(),
      ),
      GoRoute(
        path: '/spot-edit',
        builder: (context, state) {
          return FutureBuilder(
            future: _loadSpotData(ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SpotManagementScreen();
              }

              return SpotEditScreen(spot: snapshot.data!);
            },
          );
        },
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: 'Explore'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks), label: 'Bookmarks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/bookmarks')) return 1;
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/bookmarks');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

class HbbhApp extends ConsumerWidget {
  const HbbhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      debugShowCheckedModeBanner: false,
      title: 'HBBH',
      theme: ThemeData(
        primaryColor: const Color(0xFF800000),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF800000),
          secondary: const Color(0xFFFFA500),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.ibmPlexSansTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
    );
  }
}
