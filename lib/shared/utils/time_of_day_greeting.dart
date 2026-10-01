/// "Good Morning,"/"Good Afternoon,"/"Good Evening," for a Home screen's
/// hero banner, based on the device's local wall-clock hour.
String timeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}
