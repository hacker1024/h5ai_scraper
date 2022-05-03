import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:h5ai_scraper/h5ai_scraper.dart';
import 'package:path/path.dart';

Future<void> main(List<String> argumentList) async {
  final parser = ArgParser()
    ..addOption(
      'url',
      abbr: 'u',
      help: 'The URL of the h5ai instance.',
    )
    ..addFlag(
      'aria2',
      help: 'Output an aria2 compatible URL list.',
      negatable: false,
      aliases: const ['aria2c', 'aria'],
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show the usage information.',
      negatable: false,
    );

  final ArgResults arguments;
  try {
    arguments = parser.parse(argumentList);
  } on ArgParserException catch (e) {
    stderr.writeln(e.message);
    exit(2);
  }

  void printUsage(Stdout output) {
    output
      ..writeln(
        'Usage: ${Platform.script.pathSegments.last} -u <URL> [OPTIONS]',
      )
      ..writeln('Options:')
      ..writeln(parser.usage);
  }

  if (arguments['help'] as bool) {
    printUsage(stdout);
    exit(0);
  }

  if (!arguments.wasParsed('url')) {
    stderr.writeln('The url option is mandatory.');
    printUsage(stderr);
    exit(2);
  }

  final uri = Uri.tryParse(arguments['url'] as String);
  if (uri == null) {
    stderr.writeln('Invalid URL.');
    exit(2);
  }

  if (arguments['aria2'] as bool) {
    final basePath = uri.path;
    await for (final node in scrape(uri)) {
      void printNode(H5aiNode node) {
        if (node is H5aiFile) {
          stdout.writeln(
            '${node.location}\n\tout=${relative(node.location.path, from: basePath)}',
          );
        } else if (node is H5aiDirectory) {
          node.children.forEach(printNode);
        }
      }

      printNode(node);
    }
  } else {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(await scrape(uri).toList()),
    );
  }
}
