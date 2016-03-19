import 'dart:async';

/// Used in the [_gen/templates.dart] file, which should
/// contain a [templates] constant looking like this:
///
///     import 'templates/generated_id.dart' as generated_id;
///     import '../codegen_contract.dart';
///     final Map<String, TemplateFactory> templates = {
///       'generated_id': (_) => new generated_id.$_(_),
///     }
typedef Template TemplateFactory(Map<Symbol, dynamic> locals);

/// Generated templates should extend this class with
/// the subclass name of [$_].
///
///     import '../codegen_contract.dart' as _$_;
///     class $_ extends _$_.Template {
///       $_(_) : super('text/html', _);
///       render() async* {
///         yield 'content $someLocal';
///       }
///     }
@proxy
abstract class Template {
  final Map<Symbol, dynamic> _locals;
  final String contentType;

  Template(this.contentType, this._locals);

  Stream<String> render();

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter &&
        _locals.containsKey(invocation.memberName)
    ) {
      return _locals[invocation.memberName];
    }
    return super.noSuchMethod(invocation);
  }
}

