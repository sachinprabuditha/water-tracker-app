/// The containers a drink can be logged with.
enum CupShape { smallGlass, mediumGlass, largeGlass, bottle }

class Cup {
  const Cup(this.shape, this.name, this.ml);

  final CupShape shape;
  final String name;
  final int ml;

  static const all = [
    Cup(CupShape.smallGlass, 'Small glass', 200),
    Cup(CupShape.mediumGlass, 'Medium glass', 240),
    Cup(CupShape.largeGlass, 'Large glass', 350),
    Cup(CupShape.bottle, 'Water bottle', 500),
  ];

  static const fallback = Cup(CupShape.mediumGlass, 'Medium glass', 240);

  /// The preset closest to [ml], used for amounts saved by older versions.
  static Cup nearest(int ml) =>
      all.reduce((a, b) => (a.ml - ml).abs() <= (b.ml - ml).abs() ? a : b);

  static Cup forMl(int ml) =>
      all.firstWhere((c) => c.ml == ml, orElse: () => nearest(ml));
}
