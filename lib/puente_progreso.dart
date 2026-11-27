import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Puente entre el localStorage del juego (dentro del WebView) y
/// SharedPreferences (almacenamiento nativo de la app).
///
/// ¿Por qué? El localStorage de un WebView puede borrarse (limpieza de caché,
/// cambios de versión del WebView). Guardando una copia en SharedPreferences
/// los récords sobreviven, y al abrir la app se restauran en el juego.
///
/// Solo se respaldan claves que empiezan con [prefijo] ("arc_"), que son las
/// que usa el objeto `S` del juego.
class PuenteProgreso {
  PuenteProgreso(this._prefs, {this.espera = const Duration(milliseconds: 1500)});

  static const String prefijo = 'arc_';
  static const int maxLargoClave = 64;
  static const int maxLargoValor = 20000;

  /// Máximo de claves distintas que se respaldan (el juego usa ~15).
  /// Evita que una página llene el archivo de preferencias.
  static const int maxClaves = 200;

  /// Nombres de los handlers JS ↔ Dart.
  static const String handlerGuardar = 'guardar';
  static const String handlerVibrar = 'vibrar';

  final SharedPreferences _prefs;

  /// Tiempo de espera (debounce) antes de escribir en disco. Algunos juegos
  /// guardan muchas veces por segundo; así no se escribe en cada cambio.
  final Duration espera;

  // Cambios pendientes por clave: String = guardar, null = borrar.
  final Map<String, String?> _pendientes = {};
  final Map<String, Timer> _timers = {};

  // ---------------------------------------------------------------------
  // Lógica pura (sin estado): fácil de probar
  // ---------------------------------------------------------------------

  /// La clave debe ser texto, empezar con "arc_" y medir 64 caracteres o menos.
  static bool claveValida(Object? clave) =>
      clave is String &&
      clave.startsWith(prefijo) &&
      clave.length > prefijo.length &&
      clave.length <= maxLargoClave;

  /// El valor debe ser texto de 20000 caracteres o menos.
  static bool valorValido(Object? valor) =>
      valor is String && valor.length <= maxLargoValor;

  /// Toma todas las claves de SharedPreferences y deja solo las "arc_*"
  /// válidas cuyo valor sea String.
  static Map<String, String> filtrarClaves(Map<String, Object?> todo) {
    final resultado = <String, String>{};
    todo.forEach((clave, valor) {
      if (claveValida(clave) && valorValido(valor)) {
        resultado[clave] = valor as String;
      }
    });
    return resultado;
  }

  /// Lee de SharedPreferences el progreso guardado.
  static Map<String, String> leerGuardados(SharedPreferences prefs) {
    final todo = <String, Object?>{};
    for (final clave in prefs.getKeys()) {
      if (clave.startsWith(prefijo)) todo[clave] = prefs.get(clave);
    }
    return filtrarClaves(todo);
  }

  /// Genera el JavaScript que se inyecta al inicio del documento.
  ///
  /// El mapa se inserta con `jsonEncode`, que escapa comillas, barras y saltos
  /// de línea; un literal JSON siempre es un literal JS válido, así que ningún
  /// valor guardado puede "romper" el script ni inyectar código.
  static String generarScript(Map<String, String> guardados) {
    final json = jsonEncode(guardados);
    return '''
(function () {
  'use strict';
  if (window.__arcPuente) return; // evita instalarlo dos veces
  window.__arcPuente = true;

  var PRE = '$prefijo';
  var guardados = $json;

  // --- Cola de mensajes hacia Flutter ---
  // En document_start el puente window.flutter_inappwebview puede no estar
  // listo todavía; los mensajes se guardan y se envían al evento
  // 'flutterInAppWebViewPlatformReady'.
  var cola = [];
  var listo = false;
  function enviar(nombre, dato) {
    var p = window.flutter_inappwebview;
    if (listo && p && typeof p.callHandler === 'function') {
      try { p.callHandler(nombre, dato); } catch (e) {}
    } else if (cola.length < 1000) {
      cola.push([nombre, dato]);
    }
  }
  function vaciarCola() {
    if (listo) return;
    listo = true;
    var c = cola; cola = [];
    for (var i = 0; i < c.length; i++) enviar(c[i][0], c[i][1]);
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', vaciarCola);
  if (window.flutter_inappwebview && window.flutter_inappwebview._platformReady) vaciarCola();

  var ls = null;
  try { ls = window.localStorage; } catch (e) {}
  var proto = window.Storage && Storage.prototype;
  if (ls && proto) {
    var setOriginal = proto.setItem;
    var removeOriginal = proto.removeItem;
    var clearOriginal = proto.clear;
    function esArc(k) { return typeof k === 'string' && k.indexOf(PRE) === 0; }

    // 1) Restaurar: el valor guardado en Flutter gana sobre el de localStorage.
    var claves = Object.keys(guardados);
    for (var i = 0; i < claves.length; i++) {
      try { setOriginal.call(ls, claves[i], guardados[claves[i]]); } catch (e) {}
    }

    // 2) Migración: si Flutter no tenía nada, mandar una sola vez lo que ya
    //    hubiera en localStorage (por ejemplo, de una versión anterior).
    if (claves.length === 0) {
      try {
        for (var j = 0; j < ls.length; j++) {
          var k = ls.key(j);
          if (esArc(k)) enviar('$handlerGuardar', { k: k, v: ls.getItem(k) });
        }
      } catch (e) {}
    }

    // 3) Interceptar escrituras de localStorage (no de sessionStorage).
    proto.setItem = function (k, v) {
      var r = setOriginal.apply(this, arguments); // si falla (cuota), lanza y no se avisa
      if (this === ls) {
        var ks = String(k);
        if (esArc(ks)) enviar('$handlerGuardar', { k: ks, v: String(v) });
      }
      return r;
    };
    proto.removeItem = function (k) {
      var r = removeOriginal.apply(this, arguments);
      if (this === ls) {
        var ks = String(k);
        if (esArc(ks)) enviar('$handlerGuardar', { k: ks, borrar: true });
      }
      return r;
    };
    proto.clear = function () {
      var borradas = [];
      if (this === ls) {
        try {
          for (var n = 0; n < ls.length; n++) { var kc = ls.key(n); if (esArc(kc)) borradas.push(kc); }
        } catch (e) {}
      }
      var r = clearOriginal.apply(this, arguments);
      for (var m = 0; m < borradas.length; m++) enviar('$handlerGuardar', { k: borradas[m], borrar: true });
      return r;
    };
  }

  // 4) Vibración: navigator.vibrate(ms | [ms, pausa, ms, ...]) -> Flutter.
  //    Para un arreglo se suman los tramos que vibran (posiciones pares).
  function vibrar(patron) {
    var ms = 0;
    if (typeof patron === 'number') {
      ms = patron;
    } else if (patron && typeof patron.length === 'number') {
      for (var i = 0; i < patron.length; i += 2) ms += Number(patron[i]) || 0;
    }
    ms = Math.round(Number(ms) || 0);
    if (ms > 0) enviar('$handlerVibrar', ms);
    return true;
  }
  try {
    Object.defineProperty(navigator, 'vibrate', { value: vibrar, configurable: true, writable: true });
  } catch (e) {
    try { navigator.vibrate = vibrar; } catch (e2) {}
  }
})();
''';
  }

  // ---------------------------------------------------------------------
  // Parte con estado: recibe mensajes del juego y escribe con debounce
  // ---------------------------------------------------------------------

  /// Callback del handler JS 'guardar'. Recibe `[{k, v}]` o `[{k, borrar: true}]`.
  /// Devuelve true si el mensaje fue aceptado.
  bool recibirGuardar(List<dynamic> argumentos) {
    if (argumentos.isEmpty) return false;
    final dato = argumentos.first;
    if (dato is! Map) return false;
    final clave = dato['k'];
    if (!claveValida(clave)) return false;
    final k = clave as String;

    if (dato['borrar'] == true) {
      _programar(k, null);
      return true;
    }
    final valor = dato['v'];
    if (!valorValido(valor)) return false;
    // Clave nueva: no pasar del límite de claves guardadas.
    if (!_prefs.containsKey(k) && !_pendientes.containsKey(k)) {
      final usadas = _prefs.getKeys().where((c) => c.startsWith(prefijo)).length +
          _pendientes.length;
      if (usadas >= maxClaves) return false;
    }
    _programar(k, valor as String);
    return true;
  }

  /// Hay escrituras pendientes (útil para pruebas).
  bool get hayPendientes => _pendientes.isNotEmpty;

  void _programar(String clave, String? valor) {
    _pendientes[clave] = valor;
    _timers[clave]?.cancel();
    _timers[clave] = Timer(espera, () => _escribir(clave));
  }

  Future<void> _escribir(String clave) async {
    _timers.remove(clave)?.cancel();
    if (!_pendientes.containsKey(clave)) return;
    final valor = _pendientes.remove(clave);
    try {
      if (valor == null) {
        await _prefs.remove(clave);
      } else {
        await _prefs.setString(clave, valor);
      }
    } catch (_) {
      // Si falla el disco no hay mucho que hacer; el juego sigue
      // teniendo su copia en localStorage.
    }
  }

  /// Escribe ya todo lo pendiente (al pasar a segundo plano o cerrar).
  Future<void> guardarPendientes() async {
    final claves = _pendientes.keys.toList();
    await Future.wait(claves.map(_escribir));
  }

  /// Cancela temporizadores. Llamar a [guardarPendientes] antes si importa.
  void cerrar() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
