import 'dart:convert';
void main() {
  var reviews = jsonDecode('[{"id": 1}]');
  var userReviews = reviews.cast<Map<String, dynamic>>();
  userReviews.insert(0, {"id": 2});
  print(userReviews);
}