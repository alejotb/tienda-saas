import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importación necesaria

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/isar_service.dart';
import 'package:baul_pandora/pages/administracion/admin_pagos_page.dart';
import 'package:baul_pandora/pages/administracion/admin_despachos_page.dart';
import 'package:baul_pandora/pages/administracion/admin_inventario_page.dart';
import 'package:baul_pandora/pages/administracion/admin_auditoria_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Inicializar DotEnv
  await dotenv.load(fileName: ".env");

  // 1. Inicializar Supabase
  await SupaFlow.initialize();

  // 2. Inicializar Isar (Nuestra nueva base de datos local)
  //await IsarService.instance.init();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = baulPandoraSupabaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BaulPandora',
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({
    super.key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  });

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'mainHomePage';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateNotifier.instance,
      builder: (context, _) {
        final isAdmin =
            (AppStateNotifier.instance.currentUserRow?.isAdmin ?? false) ||
                FFAppState().isAdmin;

        // Redirección automática si un admin cae en una ruta de cliente o viceversa
        if (isAdmin &&
            ![
              'mainHomePage',
              'adminPagos',
              'adminDespachos',
              'adminInventario',
              'adminAuditoria',
              'mainProfile'
            ].contains(_currentPageName)) {
          _currentPageName = 'mainHomePage';
        } else if (!isAdmin &&
            ![
              'mainHomePage',
              'mainFavorites',
              'mainOrderHistory',
              'mainProfile'
            ].contains(_currentPageName)) {
          _currentPageName = 'mainHomePage';
        }

        final adminTabs = {
          'mainHomePage': MainHomePageWidget(),
          'adminPagos': AdminPagosPage(),
          'adminDespachos': AdminDespachosPage(),
          'adminInventario': AdminInventarioPage(),
          'adminAuditoria': AdminAuditoriaPage(),
          'mainProfile': MainProfileWidget(),
        };

        final adminBottomKeys = [
          'mainHomePage',
          'adminPagos',
          'adminDespachos',
          'adminInventario',
          'mainProfile'
        ];

        final clientTabs = {
          'mainHomePage': MainHomePageWidget(),
          'mainFavorites': MainFavoritesWidget(),
          'mainOrderHistory': MainOrderHistoryWidget(),
          'mainProfile': MainProfileWidget(),
        };

        final activeTabs = isAdmin ? adminTabs : clientTabs;
        final bottomNavKeys = isAdmin
            ? adminBottomKeys
            : [
                'mainHomePage',
                'mainFavorites',
                'mainOrderHistory',
                'mainProfile'
              ];
        final currentBottomIndex = bottomNavKeys.indexOf(_currentPageName);

        return Scaffold(
          resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
          body: _currentPage ?? activeTabs[_currentPageName],
          bottomNavigationBar: Visibility(
            visible: responsiveVisibility(
              context: context,
              tabletLandscape: false,
              desktop: false,
            ),
            child: isAdmin
                ? BottomNavigationBar(
                    currentIndex:
                        currentBottomIndex == -1 ? 0 : currentBottomIndex,
                    onTap: (i) => safeSetState(() {
                      _currentPage = null;
                      _currentPageName = bottomNavKeys[i];
                    }),
                    backgroundColor:
                        FlutterFlowTheme.of(context).primaryBackground,
                    selectedItemColor: FlutterFlowTheme.of(context).primary,
                    unselectedItemColor:
                        FlutterFlowTheme.of(context).secondaryText,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.storefront_outlined, size: 24.0),
                          label: 'Tienda'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.payments_outlined, size: 24.0),
                          label: 'Pagos'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.local_shipping_outlined, size: 24.0),
                          label: 'Despachos'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.inventory_2_outlined, size: 24.0),
                          label: 'Inventario'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.account_circle_outlined, size: 24.0),
                          label: 'Perfil'),
                    ],
                  )
                : BottomNavigationBar(
                    currentIndex:
                        currentBottomIndex == -1 ? 0 : currentBottomIndex,
                    onTap: (i) => safeSetState(() {
                      _currentPage = null;
                      _currentPageName = bottomNavKeys[i];
                    }),
                    backgroundColor:
                        FlutterFlowTheme.of(context).primaryBackground,
                    selectedItemColor: FlutterFlowTheme.of(context).primary,
                    unselectedItemColor:
                        FlutterFlowTheme.of(context).secondaryText,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined, size: 24.0),
                          label: 'Home'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.favorite_border, size: 24.0),
                          label: 'Favoritos'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.history_rounded, size: 24.0),
                          label: 'Historial'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.account_circle_outlined, size: 24.0),
                          label: 'Perfil'),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
