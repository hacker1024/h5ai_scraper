# h5ai scraper
A CLI tool and Dart package that can scrape file and directory URLs from
[h5ai](https://larsjung.de/h5ai/) instances.

## Usage
This tool requires the [Dart SDK](https://dart.dev). It can be compiled to a native
binary - I just haven't done so.

```
$ dart pub global activate --source git https://github.com/hacker1024/h5ai_scraper.git
$ h5ai-scrape --help
```

> ```
> Usage: h5ai-scrape -u <URL> [OPTIONS]
> Options:
> -u, --url      The URL of the h5ai instance.
>     --aria2    Output an aria2 compatible URL list.
> -h, --help     Show the usage information.
> ```

### JSON output
By default, the tool outputs a list of JSON objects with the following structure:

| Key          | Value                                                   |
|--------------|---------------------------------------------------------|
| name         | The name of the file or directory                       |
| location     | The file or directory URL                               |
| size         | The size of the file or directory, in bytes             |
| iconUrl      | The file or directory icon URL                          |
| dateModified | The file or directory's last modified date (ISO-8601)   |
| type         | Either "file" or "directory"                            |
| children     | The contents of the directory (directory only property) |

### aria2 usage
This tool can generate an [input file](https://aria2.github.io/manual/en/html/aria2c.html#input-file) for
[aria2](https://aria2.github.io), which is useful for downloading all the scraped files at once.

### Dart package
#### Preparation
In your `pubspec.yaml`:
```yaml
dependencies:
  h5ai_scraper:
    git: https://github.com/hacker1024/h5ai_scraper.git
```

#### Usage
```dart
import 'package:h5ai_scraper/h5ai_scraper.dart' as h5ai_scraper;

void main() async {
  final uri = Uri.parse('http://...');
  await for (final node in h5ai_scraper.scrape(uri)) {
    print(node);
  }
}
```
