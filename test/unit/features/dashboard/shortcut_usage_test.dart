import 'package:cloud_lms/core/storage/local_prefs_service.dart';
import 'package:cloud_lms/features/dashboard/presentation/providers/shortcut_usage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _all = ['students', 'teachers', 'classes', 'attendance', 'exams', 'fees', 'notices', 'assignments', 'reports', 'payroll', 'departments', 'more'];

Future<ShortcutUsage> _usage([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return ShortcutUsage(LocalPrefsService(await SharedPreferences.getInstance()));
}

List<String> _pick(ShortcutUsage u, [List<String> all = _all]) =>
    u.pick(role: 'admin', all: all, idOf: (t) => t, isMore: (t) => t == 'more');

void main() {
  test('with no history keeps the default order, trimmed to 8 with More last', () async {
    final picked = _pick(await _usage());
    expect(picked, ['students', 'teachers', 'classes', 'attendance', 'exams', 'fees', 'notices', 'more']);
  });

  test('most-used shortcuts come first', () async {
    final picked = _pick(await _usage({'prefs.shortcut_usage.admin': '{"payroll": 5, "reports": 2, "fees": 9}'}));
    expect(picked.take(3), ['fees', 'payroll', 'reports']);
    expect(picked.last, 'more');
    expect(picked.length, 8);
  });

  test('roles with few shortcuts keep them all', () async {
    final picked = _pick(await _usage(), ['a', 'b', 'c', 'more']);
    expect(picked, ['a', 'b', 'c', 'more']);
  });

  test('taps are saved but the order only changes on the next launch', () async {
    final usage = await _usage();
    final before = _pick(usage);
    await usage.record('admin', 'departments');
    await usage.record('admin', 'departments');
    expect(_pick(usage), before); // same session: tiles don't jump

    final nextLaunch = ShortcutUsage(LocalPrefsService(await SharedPreferences.getInstance()));
    expect(_pick(nextLaunch).first, 'departments');
  });
}
