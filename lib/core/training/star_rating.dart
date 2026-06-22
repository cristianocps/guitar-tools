/// Converts an accuracy percentage into a 1-3 star rating.
///
/// - 60-74% -> 1 star
/// - 75-89% -> 2 stars
/// - >= 90%  -> 3 stars
/// - < 60%   -> 0 stars
class StarRating {
  const StarRating._();

  static const double oneStarMin = 0.60;
  static const double twoStarMin = 0.75;
  static const double threeStarMin = 0.90;
  static const int maxStars = 3;

  static int fromAccuracy(double accuracy) {
    if (accuracy >= threeStarMin) {
      return 3;
    }
    if (accuracy >= twoStarMin) {
      return 2;
    }
    if (accuracy >= oneStarMin) {
      return 1;
    }
    return 0;
  }
}
