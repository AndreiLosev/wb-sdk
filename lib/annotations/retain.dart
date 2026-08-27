import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class Retain {
  final dynamic init;

  const Retain(this.init);
}
