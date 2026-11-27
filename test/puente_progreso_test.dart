import 'dart:convert';

import 'package:arcade_de_bolsillo/puente_progreso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Validación de claves y valores', () {
    test('acepta claves arc_ normales', () {
      expect(PuenteProgreso.claveValida('arc_best_snake'), isTrue);
    });

    test('rechaza claves sin prefijo, vacías, no texto o muy largas', () {
      expect(PuenteProgreso.claveValida('best_snake'), isFalse);
      expect(PuenteProgreso.claveValida('arc_'), isFalse);
      expect(PuenteProgreso.claveValida(null), isFalse);
      expect(PuenteProgreso.claveValida(42), isFalse);
      expect(PuenteProgreso.claveValida('arc_${'x' * 61}'), isFalse); // 65
      expect(PuenteProgreso.claveValida('arc_${'x' * 60}'), isTrue); // 64 justo
    });

    test('valores: solo texto de hasta 20000 caracteres', () {
      expect(PuenteProgreso.valorValido('123'), isTrue);
      expect(PuenteProgreso.valorValido('a' * 20000), isTrue);
      expect(PuenteProgreso.valorValido('a' * 20001), isFalse);
      expect(PuenteProgreso.valorValido(123), isFalse);
      expect(PuenteProgreso.valorValido(null), isFalse);
    });
  });

  group('Filtro de claves arc_', () {
    test('deja solo arc_* con valor String', () {
      final r = PuenteProgreso.filtrarClaves({
        'arc_a': '1',
        'arc_b': 2,
        'otra': 'x',
        'arc_c': '{"n":3}',
      });
      expect(r, {'arc_a': '1', 'arc_c': '{"n":3}'});
    });

    test('leerGuardados usa SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'arc_best': '120',
        'arc_num': 5,
        'tema': 'oscuro',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(PuenteProgreso.leerGuardados(prefs), {'arc_best': '120'});
    });
  });

  group('Generación del script', () {
    test('valores con comillas y saltos de línea no rompen el JS', () {
      const raro = 'a"b\'c\nd\\e</script> ';
      final js = PuenteProgreso.generarScript({'arc_x': raro});
      // El mapa aparece como literal JSON, que se puede decodificar igual.
      final inicio = js.indexOf('var guardados = ') + 'var guardados = '.length;
      final fin = js.indexOf(';\n', inicio);
      final literal = js.substring(inicio, fin);
      expect(jsonDecode(literal), {'arc_x': raro});
      // El salto de línea real no aparece crudo dentro del literal.
      expect(literal.contains('\n'), isFalse);
    });

    test('incluye los handlers y el evento de plataforma lista', () {
      final js = PuenteProgreso.generarScript({});
      expect(js, contains("'guardar'"));
      expect(js, contains("'vibrar'"));
      expect(js, contains('flutterInAppWebViewPlatformReady'));
      expect(js, contains('var guardados = {};'));
      expect(js, contains("var PRE = 'arc_';"));
    });
  });

  group('Guardado con debounce', () {
    late SharedPreferences prefs;
    late PuenteProgreso puente;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'arc_viejo': 'x'});
      prefs = await SharedPreferences.getInstance();
      puente = PuenteProgreso(prefs, espera: const Duration(minutes: 1));
    });

    tearDown(() => puente.cerrar());

    test('guarda al hacer flush y no antes', () async {
      expect(puente.recibirGuardar([{'k': 'arc_best', 'v': '99'}]), isTrue);
      expect(prefs.getString('arc_best'), isNull);
      expect(puente.hayPendientes, isTrue);
      await puente.guardarPendientes();
      expect(prefs.getString('arc_best'), '99');
      expect(puente.hayPendientes, isFalse);
    });

    test('el último valor gana', () async {
      puente.recibirGuardar([{'k': 'arc_best', 'v': '1'}]);
      puente.recibirGuardar([{'k': 'arc_best', 'v': '2'}]);
      await puente.guardarPendientes();
      expect(prefs.getString('arc_best'), '2');
    });

    test('borrar elimina la clave', () async {
      expect(puente.recibirGuardar([{'k': 'arc_viejo', 'borrar': true}]), isTrue);
      await puente.guardarPendientes();
      expect(prefs.containsKey('arc_viejo'), isFalse);
    });

    test('ignora mensajes inválidos', () async {
      expect(puente.recibirGuardar([]), isFalse);
      expect(puente.recibirGuardar(['texto']), isFalse);
      expect(puente.recibirGuardar([{'k': 'malo', 'v': '1'}]), isFalse);
      expect(puente.recibirGuardar([{'k': 'arc_a', 'v': 5}]), isFalse);
      expect(puente.recibirGuardar([{'k': 'arc_a', 'v': 'a' * 20001}]), isFalse);
      expect(puente.hayPendientes, isFalse);
    });

    test('el temporizador escribe solo tras la espera', () async {
      final rapido = PuenteProgreso(prefs, espera: const Duration(milliseconds: 10));
      rapido.recibirGuardar([{'k': 'arc_t', 'v': 'ok'}]);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(prefs.getString('arc_t'), 'ok');
      rapido.cerrar();
    });
  });
}
