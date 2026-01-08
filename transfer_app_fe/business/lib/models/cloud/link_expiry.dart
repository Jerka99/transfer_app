enum LinkExpiry {
  oneHour(300),
  oneDay(2),
  oneWeek(604800),
  oneMonth(2592000);
  // oneHour(3600),
  // oneDay(86400),
  // oneWeek(604800),
  // oneMonth(2592000);


  final int seconds;
  const LinkExpiry(this.seconds);

  String get label {
    switch (this) {
      case LinkExpiry.oneHour:
        return '1 hour';
      case LinkExpiry.oneDay:
        return '1 day';
      case LinkExpiry.oneWeek:
        return '1 week';
      case LinkExpiry.oneMonth:
        return '1 month';
    }
  }
}
