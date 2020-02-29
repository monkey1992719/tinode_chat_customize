class User {
  static final User _singleton = User._internal();
  factory User() => _singleton;
  User._internal();
  static User get userData => _singleton;
  String firstName;
  String id;
  String photo;
}