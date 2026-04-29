class CurrencyBalance {
  final int coins;
  final int diamonds;

  static const int coinsPerDiamond = 100;

  const CurrencyBalance({
    this.coins = 0,
    this.diamonds = 0,
  });

  int get totalCoinValue => coins + (diamonds * coinsPerDiamond);

  double get diamondValueInCoins => diamonds * coinsPerDiamond.toDouble();
}

class StreakProgress {
  final int daysPlayed;

  static const int daysPerDiamondTrade = 5;
  static const int diamondsPerTrade = 50;

  const StreakProgress({
    this.daysPlayed = 0,
  });

  int get tradeableIntervals => daysPlayed ~/ daysPerDiamondTrade;

  int get tradeableDiamonds => tradeableIntervals * diamondsPerTrade;

  int get remainingDaysToNextTrade {
    final remainder = daysPlayed % daysPerDiamondTrade;
    if (remainder == 0) {
      return 0;
    }

    return daysPerDiamondTrade - remainder;
  }

  bool get canTradeForDiamonds => daysPlayed >= daysPerDiamondTrade;
}
