import 'package:http/http.dart' as http;
import 'package:proper_filesize/proper_filesize.dart';
import 'package:universal_html/controller.dart';
import 'package:universal_html/html.dart';

/// Scrapes a h5ai mirror page for files and directories.
///
/// A custom [http.Client] can be provided with the [customClient]
/// parameter.
Stream<H5aiNode> scrape(Uri uri, [http.Client? customClient]) async* {
  final httpClient = customClient ?? http.Client();
  final htmlText = await httpClient.read(uri);
  final controller = WindowController()..openContent(htmlText);
  final html = controller.window!.document;
  final fileTable = html
      .getElementById('fallback')!
      .children
      .whereType<TableElement>()
      .first
      .children
      .whereType<TableSectionElement>()
      .first;
  final fileEntries = fileTable.children.whereType<TableRowElement>().skip(2);
  final nodeFutures = <Future<H5aiNode>>[];
  for (final entry in fileEntries) {
    final anchorElement = entry.querySelector('.fb-n a')! as AnchorElement;
    final uriText = anchorElement.href!;
    final isDirectory = uriText.endsWith('/');
    final name = anchorElement.text!;
    final location = uri.replace(path: Uri.parse(uriText).path);
    final size = ProperFilesize.parseHumanReadableFilesize(
      entry.querySelector('.fb-s')!.text!,
    ).toInt();
    final dateModified = DateTime.parse(entry.querySelector('.fb-d')!.text!);
    final iconUrl = uri.replace(
      path: Uri.parse((entry.querySelector('.fb-i img')! as ImageElement).src!)
          .path,
    );
    if (isDirectory) {
      nodeFutures.add(
        scrape(location, httpClient).toList().then(
          (children) {
            return H5aiDirectory(
              name: name,
              location: location,
              size: size,
              iconUrl: iconUrl,
              dateModified: dateModified,
              children: children,
            );
          },
        ),
      );
    } else {
      nodeFutures.add(
        Future.value(
          H5aiFile(
            name: name,
            location: location,
            size: size,
            dateModified: dateModified,
            iconUrl: iconUrl,
          ),
        ),
      );
    }
  }
  yield* Stream.fromFutures(nodeFutures);
  if (!identical(customClient, httpClient)) httpClient.close();
}

abstract class H5aiNode {
  final String name;
  final Uri location;
  final int size;
  final DateTime dateModified;
  final Uri iconUrl;

  const H5aiNode({
    required this.name,
    required this.location,
    required this.size,
    required this.dateModified,
    required this.iconUrl,
  });

  Map<String, Object> toJson() => {
        'name': name,
        'location': location.toString(),
        'size': size,
        'iconUrl': iconUrl.toString(),
        'dateModified': dateModified.toIso8601String(),
      };

  @override
  String toString() =>
      'H5aiNode{name: $name, location: $location, size: $size, dateModified: $dateModified, iconUrl: $iconUrl}';
}

class H5aiDirectory extends H5aiNode {
  final List<H5aiNode> children;

  const H5aiDirectory({
    required String name,
    required Uri location,
    required int size,
    required Uri iconUrl,
    required DateTime dateModified,
    required this.children,
  }) : super(
          name: name,
          location: location,
          size: size,
          dateModified: dateModified,
          iconUrl: iconUrl,
        );

  @override
  Map<String, Object> toJson() => super.toJson()
    ..['type'] = 'directory'
    ..['children'] =
        children.map((child) => child.toJson()).toList(growable: false);

  @override
  String toString() =>
      'H5aiDirectory{name: $name, location: $location, size: $size, dateModified: $dateModified, iconUrl: $iconUrl, children: $children}';
}

class H5aiFile extends H5aiNode {
  const H5aiFile({
    required String name,
    required Uri location,
    required int size,
    required DateTime dateModified,
    required Uri iconUrl,
  }) : super(
          name: name,
          location: location,
          size: size,
          dateModified: dateModified,
          iconUrl: iconUrl,
        );

  @override
  Map<String, Object> toJson() => super.toJson()..['type'] = 'file';

  @override
  String toString() =>
      'H5aiFile{name: $name, location: $location, size: $size, dateModified: $dateModified, iconUrl: $iconUrl}';
}
