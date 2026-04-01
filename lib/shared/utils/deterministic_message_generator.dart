import 'dart:math';

class DeterministicMessageGenerator {
  static const Map<String, List<String>> _messages = {
    'OVERLOAD': [
      'Seguís progresando 🔥',
      'Récord en camino',
      'El trabajo da frutos',
      'Progresión constante',
      'Superando tus límites',
    ],
    'STAGNANT': [
      'Momento de cambiar algo',
      'Plateau detectado',
      'Prueba un nuevo estímulo',
      'Varía el esquema de series',
      'Considera aumentar la carga',
    ],
    'REGRESSION': [
      'Descansá más esta semana',
      'Revisa tu técnica',
      'Puede ser fatiga acumulada',
      'Prioriza la recuperación',
      'Menos es más por ahora',
    ],
    'NEW': [
      'Nuevo ejercicio, gran potencial',
      'Primeros datos en registro',
      'Construyendo tu base',
      'Ejercicio recién añadido',
      'Sigue entrenando para ver tendencias',
    ],
  };

  static String generate(String seed, String status) {
    final list = _messages[status] ?? _messages['NEW']!;
    final rng = Random(seed.hashCode);
    return list[rng.nextInt(list.length)];
  }
}
