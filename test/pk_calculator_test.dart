import 'package:flutter_test/flutter_test.dart';

import 'package:doselab/features/pk_engine/domain/usecases/pk_calculator.dart';

void main() {
  group('PkCalculator', () {
    const calc = PkCalculator();

    test('single dose decay', () {
      final c = calc.concentrationAt(
        tHours: 10,
        halfLifeHours: 10,
        schedule: const [DoseEvent(hoursFromOrigin: 0, amountMg: 100)],
      );
      // After one half-life, concentration should be 50
      expect(c, closeTo(50, 0.1));
    });

    test('two-dose superposition', () {
      final c = calc.concentrationAt(
        tHours: 20,
        halfLifeHours: 10,
        schedule: const [
          DoseEvent(hoursFromOrigin: 0, amountMg: 100),
          DoseEvent(hoursFromOrigin: 10, amountMg: 100),
        ],
      );
      // At t=20: first dose 100*0.5^(2)=25, second dose 100*0.5^(1)=50 → 75
      expect(c, closeTo(75, 0.1));
    });

    test('simulate produces decreasing tail', () {
      final curve = calc.simulate(
        const PkInput(
          halfLifeHours: 10,
          schedule: [DoseEvent(hoursFromOrigin: 0, amountMg: 100)],
          simHours: 30,
        ),
      );
      expect(curve.concentrations.first, closeTo(100, 0.1));
      expect(curve.concentrations.last, closeTo(12.5, 0.5));
    });

    test('timeToThreshold basic', () {
      final t = PkCalculator.timeToThreshold(
        cStart: 100,
        halfLifeHours: 10,
        threshold: 25,
      );
      expect(t, closeTo(20, 0.1));
    });

    test('timeToThreshold already below returns 0', () {
      final t = PkCalculator.timeToThreshold(
        cStart: 10,
        halfLifeHours: 10,
        threshold: 25,
      );
      expect(t, 0);
    });

    test('BSA DuBois formula', () {
      final bsa = PkCalculator.estimateBsa(170, 70);
      // ≈ 1.81 m²
      expect(bsa, closeTo(1.81, 0.05));
    });

    test('buildRegularSchedule generates correct events', () {
      final sched = calc.buildRegularSchedule(
        simHours: 48,
        doseMg: 100,
        intervalHours: 24,
      );
      expect(sched.length, 2);
      expect(sched[0].hoursFromOrigin, 0);
      expect(sched[1].hoursFromOrigin, 24);
    });

    test('zero half-life returns 0', () {
      final c = calc.concentrationAt(
        tHours: 5,
        halfLifeHours: 0,
        schedule: const [DoseEvent(hoursFromOrigin: 0, amountMg: 100)],
      );
      expect(c, 0);
    });
  });
}
