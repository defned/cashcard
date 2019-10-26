enum SnackBarType { error, message }

class SnackBarMessage extends Object {
  final String message;
  final SnackBarType type;

  String actionMessage;
  Function action;
  Duration duration;

  SnackBarMessage(this.message, this.type,
      {this.actionMessage, this.action, this.duration});
}
