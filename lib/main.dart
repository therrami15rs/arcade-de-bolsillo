import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'puente_progreso.dart';

const Color colorFondo = Color(0xFF140C2A);

/// JS que simula pulsar "‹ Menú" si hay un juego abierto.
/// Devuelve true si regresó al menú, false si ya estaba en el menú.
const String jsVolverAlMenu =
    "(()=>{const p=document.getElementById('play');if(p&&!p.hidden){document.getElementById('back').click();return true}return false})()";

bool get esAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (esAndroid) {
    // Pantalla completa: las barras del sistema aparecen al deslizar y se
    // vuelven a ocultar solas.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  try {
    await WakelockPlus.enable();
  } catch (_) {
    // Si el sistema no lo permite, el juego funciona igual.
  }

  final prefs = await SharedPreferences.getInstance();
  final guardados = PuenteProgreso.leerGuardados(prefs);
  final puente = PuenteProgreso(prefs);

  runApp(ArcadeApp(
    puente: puente,
    script: PuenteProgreso.generarScript(guardados),
  ));
}

class ArcadeApp extends StatelessWidget {
  const ArcadeApp({super.key, required this.puente, required this.script});

  final PuenteProgreso puente;
  final String script;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcade de bolsillo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFCF4A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: colorFondo,
      ),
      home: PantallaJuego(puente: puente, script: script),
    );
  }
}

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key, required this.puente, required this.script});

  final PuenteProgreso puente;
  final String script;

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  DateTime _ultimaVibracion = DateTime.fromMillisecondsSinceEpoch(0);
  InAppWebViewController? _controlador;
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Al minimizar, cambiar de app o cerrar: guardar ya lo pendiente
    // en lugar de esperar el debounce.
    _ciclo = AppLifecycleListener(
      onInactive: _guardarYa,
      onHide: _guardarYa,
      onPause: _guardarYa,
      onDetach: _guardarYa,
      onExitRequested: () async {
        await widget.puente.guardarPendientes();
        return AppExitResponse.exit;
      },
    );
  }

  void _guardarYa() {
    widget.puente.guardarPendientes();
  }

  @override
  void dispose() {
    _ciclo.dispose();
    widget.puente.guardarPendientes().whenComplete(widget.puente.cerrar);
    super.dispose();
  }

  Future<void> _vibrar(List<dynamic> argumentos) async {
    if (!esAndroid || argumentos.isEmpty) return;
    final valor = argumentos.first;
    if (valor is! num) return;
    final ms = valor.round().clamp(1, 1000);
    // Pausa mínima entre vibraciones para que no vibre sin parar.
    final ahora = DateTime.now();
    if (ahora.difference(_ultimaVibracion) < const Duration(milliseconds: 80)) return;
    _ultimaVibracion = ahora;
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: ms);
      }
    } catch (_) {
      // Sin vibrador o sin permiso: se ignora.
    }
  }

  /// Botón "atrás" de Android: si hay un juego abierto, vuelve al menú;
  /// si ya está en el menú, cierra la app.
  Future<void> _alPulsarAtras(bool yaSalio, Object? _) async {
    if (yaSalio) return;
    var regreso = false;
    try {
      final r = await _controlador?.evaluateJavascript(source: jsVolverAlMenu);
      regreso = r == true;
    } catch (_) {
      regreso = false;
    }
    if (!regreso) {
      await widget.puente.guardarPendientes();
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _alPulsarAtras,
      child: Scaffold(
        backgroundColor: colorFondo,
        body: SafeArea(
          child: InAppWebView(
            initialFile: 'assets/web/index.html',
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                source: widget.script,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
              ),
            ]),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: false,
              supportZoom: false,
              disableContextMenu: true,
              useHybridComposition: true,
              allowFileAccessFromFileURLs: false,
              allowUniversalAccessFromFileURLs: false,
              isInspectable: kDebugMode,
              // Necesario para que se llame shouldOverrideUrlLoading.
              useShouldOverrideUrlLoading: true,
            ),
            onWebViewCreated: (controlador) {
              _controlador = controlador;
              controlador.addJavaScriptHandler(
                handlerName: PuenteProgreso.handlerGuardar,
                callback: (argumentos) => widget.puente.recibirGuardar(argumentos),
              );
              controlador.addJavaScriptHandler(
                handlerName: PuenteProgreso.handlerVibrar,
                callback: (argumentos) {
                  _vibrar(argumentos);
                  return true;
                },
              );
            },
            // Lista blanca: solo se permite navegar a los archivos locales
            // del juego. Todo lo demás (http, https, intent:, mailto:...) se bloquea.
            shouldOverrideUrlLoading: (controlador, accion) async {
              final esquema = accion.request.url?.scheme.toLowerCase() ?? '';
              if (esquema == 'file' || esquema == 'about') {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            // No se da acceso a cámara, micrófono, etc.
            onPermissionRequest: (controlador, solicitud) async {
              return PermissionResponse(
                resources: solicitud.resources,
                action: PermissionResponseAction.DENY,
              );
            },
          ),
        ),
      ),
    );
  }
}
