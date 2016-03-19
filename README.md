# Template Cache for Dart

Templates in Dart can be implemented in different ways:

### 1. Parsing at runtime
This approach is the most straightforward approach, requiring no special compiling.
This can be bad for performance, though. To counterweight that, templating languages
implemented in this way can end up lacking in features instead.

### 2. Static precompilation
For static pages, all templates can be rendered ahead of time. This is great for
performance since all the complexity is handled at build time. However, this means
that logic cannot be computed at runtime.

### 3. Precompilation into Dart
The third way to do it is to precompile the templates into native Dart code, which
will be super fast at runtime, and can be built into the main code base using
Dart2JS for production. This can be confusing, though, because Dart files must
be imported in the source code.

## Usage
This library simplifies option 3 from above. Here's how to use it:

Consider this project.

```
├── bin
│   └── server.dart
├── templates
│   └── my_template.some_ext
├── tool
│   └── compile_templates.dart
└── web
    ├── index.html
    └── index.dart
```

In this example, we keep the templates in a `templates` directory.

To compile our templates, we run `dart tool/compile_templates.dart`:

```dart
import 'package:template_cache/cache.dart';
import 'package:SOME_PACKAGE_THAT_GIVES_US_A_COMPILER';

final cache = new Cache([
  new SomeThirdPartyCompiler() // <-- This compiler compiles ".some_ext" files
]);

main() async {
  await cache.compile('templates/my_template.some_ext');
}
```

Now, to render the template, in both the `web/main.dart` or `bin/server.dart` files,
we can simply use the `render` function:

```dart
import 'package:template_cache/render.dart';

main() {
  var view = render('templates/my_template.some_ext');
}
```

The `render` function returns a `Stream<String>`, so that compilers can incorporate
asynchrony in the most performant way.

If the compiler supports it, `render` has a named `locals` parameter, accepting variables
into the template. The `locals` are supplied as `Map<Symbol, dynamic>`.

```dart
render('my_template.hbs', locals: {
  #someVariable: "some value"
});
```

> **Note:** Using symbols rather than strings as keys allows the template code to access
> locals directly without using mirrors. This is explained below.

## Compilers
A compiler must satisfy a simple contract, and can take configuration in its constructor, since
that will be exposed to the consumer (as shown above).

The `compile` method in the contract returns a special `GeneratedTemplateCode` data object,
containing the generated code as two strings. The first one contains imports for the generated
script. The second contains the main render method body, in a `async*` context.

```dart
import 'dart:async';

import 'package:template_cache/cache.dart';

class MyCompiler implements Compiler {
  final ContentType contentType = ContentType.HTML; // Supplied for use with servers
  final Iterable<String> extensions = ['.my_ext', '.my_other_ext'];

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    // Use the [file] and [source] arguments to generate the code

    return new GeneratedTemplateCode(
      '''
        import "some_specific_import_that_the_template_will_require" as package;
      ''',

      r'''
        yield r"A line!\n";

        yield someLocal + r'\n';

        package.someImportedMethod();

        if (someBooleanLocal) {
          yield r"A conditional line!\n";
        }
      '''
    );
  }
}
```

Using the above `MyCompiler`, the workflow would be something like this:

#### Build time
```dart
final cache = new Cache([
  new MyCompiler()
]);

cache.compile('some_template.my_ext');
```

#### Runtime
```dart
render('some_template.my_ext', {
  #someLocal: 'Hello, World!',
  #someBooleanLocal: true
});
```

#### Output
```
A line!
Hello, World!
A conditional line!

```
