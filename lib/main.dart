import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'data/models/user_role.dart';
import 'ui/viewmodels/auth_viewmodel.dart';
import 'ui/viewmodels/client_viewmodel.dart';
import 'ui/viewmodels/provider_viewmodel.dart';
import 'ui/viewmodels/manager_viewmodel.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/client/client_home_screen.dart';
import 'ui/screens/client/business_detail_screen.dart';
import 'ui/screens/provider/provider_home_screen.dart';
import 'ui/screens/manager/manager_home_screen.dart';
import 'ui/screens/manager/business_setup_screen.dart';
import 'ui/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EasyBookApp());
}

class EasyBookApp extends StatelessWidget {
  const EasyBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
        ChangeNotifierProvider(create: (_) => ProviderViewModel()),
        ChangeNotifierProvider(create: (_) => ManagerViewModel()),
      ],
      child: MaterialApp(
        title: 'EasyBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6650a4),
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF6650a4),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigator(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      ),
    );
  }
}

/// Root navigator handling auth state and role-based routing.
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

enum _AppScreen {
  login,
  register,
  clientHome,
  providerHome,
  managerHome,
  businessSetup,
  profile,
  businessDetail,
}

class _MainNavigatorState extends State<MainNavigator> {
  _AppScreen _currentScreen = _AppScreen.login;
  String? _businessDetailId;
  bool _initialCheckDone = false;

  void _navigateTo(_AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  void _onLoginSuccess(UserRole role) {
    final authVM = context.read<AuthViewModel>();
    switch (role) {
      case UserRole.client:
        _navigateTo(_AppScreen.clientHome);
        break;
      case UserRole.provider:
        _navigateTo(_AppScreen.providerHome);
        break;
      case UserRole.manager:
        if (authVM.userBusiness == null) {
          _navigateTo(_AppScreen.businessSetup);
        } else {
          _navigateTo(_AppScreen.managerHome);
        }
        break;
    }
  }

  void _goToLogin() {
    _navigateTo(_AppScreen.login);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // Auto-navigate when user is already logged in
        if (!_initialCheckDone &&
            authVM.status == AuthStatus.success &&
            authVM.currentUser != null) {
          _initialCheckDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onLoginSuccess(authVM.currentUser!.role);
          });
        }

        switch (_currentScreen) {
          case _AppScreen.login:
            return LoginScreen(
              onLoginSuccess: _onLoginSuccess,
              onRegisterClick: () => _navigateTo(_AppScreen.register),
            );
          case _AppScreen.register:
            return RegisterScreen(
              onRegisterSuccess: _onLoginSuccess,
              onLoginClick: () => _navigateTo(_AppScreen.login),
            );
          case _AppScreen.clientHome:
            return ClientHomeScreen(
              onLogout: _goToLogin,
              onProfileClick: () => _navigateTo(_AppScreen.profile),
              onBusinessClick: (id) {
                _businessDetailId = id;
                _navigateTo(_AppScreen.businessDetail);
              },
            );
          case _AppScreen.businessDetail:
            return BusinessDetailScreen(
              businessId: _businessDetailId!,
              onBack: () => _navigateTo(_AppScreen.clientHome),
            );
          case _AppScreen.providerHome:
            return ProviderHomeScreen(
              onLogout: _goToLogin,
              onProfileClick: () => _navigateTo(_AppScreen.profile),
            );
          case _AppScreen.managerHome:
            return ManagerHomeScreen(
              onLogout: _goToLogin,
              onProfileClick: () => _navigateTo(_AppScreen.profile),
            );
          case _AppScreen.businessSetup:
            return BusinessSetupScreen(
              onSetupComplete: () => _navigateTo(_AppScreen.managerHome),
            );
          case _AppScreen.profile:
            return ProfileScreen(
              onBack: () {
                final user = authVM.currentUser;
                if (user != null) {
                  _onLoginSuccess(user.role);
                } else {
                  _goToLogin();
                }
              },
              onAccountDeleted: _goToLogin,
            );
        }
      },
    );
  }
}
