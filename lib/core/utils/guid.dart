import 'package:uuid/uuid.dart';

extension Extension on String {
  bool isNullOrEmpty() => this == null || this == '';
}

class Guid {
  static const String _defaultGuid = "00000000-0000-0000-0000-000000000000";
  String _value = "";

  Guid(String value) {
    if (value.isNullOrEmpty()) {
      value = _defaultGuid;
    } else if (!Uuid.isValidUUID(fromString: value)) {
      throw new FormatException("Value '$value' is not a valid UUID");
    }

    _value = value;
  }

  static Guid get newGuid {
    return new Guid(Uuid().v4());
  }

  @override
  String toString() {
    return _value;
  }
}
