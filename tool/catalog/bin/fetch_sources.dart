// Fetches and promotes TürKomp source snapshots.
//
//   dart run tool/catalog/bin/fetch_sources.dart index
//   dart run tool/catalog/bin/fetch_sources.dart fetch [--limit N] [--resume]
//                                                      [--delay-ms 1500]
//   dart run tool/catalog/bin/fetch_sources.dart promote
//       --selection tool/catalog/data/catalog_selection.json
//       [--allow-content-change]
//
// Three phases on purpose:
//
//   index    enumerates the public food list into a committed, ordered file.
//   fetch    downloads detail pages into a gitignored local cache. The TürKomp
//            record code (NN.NN.NNNN) only appears on the detail page, so the
//            code cannot be known before this step.
//   promote  copies the selected pages into the committed snapshot set and
//            merges them into snapshots/snapshot_index.json.
//
// This script never writes a gram or a nutrient value. It stores bytes and the
// sha256 of those bytes; build_pilot_manifest.dart is what reads numbers out.
import 'dart:convert';
import 'dart:io';

import '../src/hashing.dart';
import '../src/turkomp_parser.dart';

const _root = 'tool/catalog';
const _cacheDir = '$_root/.cache/turkomp';
const _snapshotDir = '$_root/snapshots/turkomp';
const _indexPath = '$_root/data/turkomp_index.json';
const _snapshotIndexPath = '$_root/snapshots/snapshot_index.json';

const _origin = 'https://turkomp.tarimorman.gov.tr';
const _listPath = '/database?type=foods';
const _sessionPath = '/main';
const _userAgent =
    'meal-clarity-catalog-bot/1 (+https://github.com/recepzgrmh; contact via repo issues)';

const _sourceName = 'TürKomp — Ulusal Gıda Kompozisyon Veri Tabanı';
const _publisher = 'T.C. Tarım ve Orman Bakanlığı';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: fetch_sources.dart <index|fetch|promote> [options]');
    exit(64);
  }
  final command = args.first;
  final options = _parseOptions(args.skip(1).toList());

  switch (command) {
    case 'index':
      await _runIndex();
    case 'fetch':
      await _runFetch(
        limit: int.tryParse(options['limit'] ?? ''),
        resume: options.containsKey('resume'),
        delayMs: int.tryParse(options['delay-ms'] ?? '') ?? 1500,
      );
    case 'promote':
      _runPromote(
        selectionPath: options['selection'],
        allowContentChange: options.containsKey('allow-content-change'),
      );
    default:
      stderr.writeln('Unknown command "$command".');
      exit(64);
  }
}

Map<String, String> _parseOptions(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final name = arg.substring(2);
    final next = i + 1 < args.length ? args[i + 1] : null;
    if (next != null && !next.startsWith('--')) {
      options[name] = next;
      i++;
    } else {
      options[name] = '';
    }
  }
  return options;
}

// ---------------------------------------------------------------- index

Future<void> _runIndex() async {
  final client = HttpClient()..userAgent = _userAgent;
  try {
    final cookie = await _openSession(client);
    final body = await _get(client, _listPath, cookie);
    final entries = _parseIndex(body);
    if (entries.isEmpty) {
      stderr.writeln(
        'Refusing to write an empty index: the list page returned no '
        'food links. The site layout may have changed.',
      );
      exit(1);
    }

    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'note':
          'Enumeration of the public TürKomp food list. Regenerate with: '
          'dart run tool/catalog/bin/fetch_sources.dart index',
      'sourceName': _sourceName,
      'publisher': _publisher,
      'indexUrl': '$_origin$_listPath',
      'retrievedAt': _nowIso(),
      'indexSha256': sha256OfBytes(utf8.encode(body)),
      'entryCount': entries.length,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
    File(_indexPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
      );
    stdout.writeln('index=${entries.length} -> $_indexPath');
  } finally {
    client.close(force: true);
  }
}

class TurkompIndexEntry {
  const TurkompIndexEntry({
    required this.href,
    required this.listName,
    required this.turkompId,
  });

  final String href;
  final String listName;
  final String turkompId;

  Map<String, dynamic> toJson() => {
    'href': href,
    'listName': listName,
    'turkompId': turkompId,
  };

  static TurkompIndexEntry fromJson(Map<String, dynamic> json) =>
      TurkompIndexEntry(
        href: json['href'] as String,
        listName: json['listName'] as String,
        turkompId: json['turkompId'] as String,
      );
}

final RegExp _linkPattern = RegExp(
  r'<a\s+href="(food-([^"]*?)-(\d+))"[^>]*>(.*?)</a>',
  dotAll: true,
);

List<TurkompIndexEntry> _parseIndex(String html) {
  final seen = <String>{};
  final entries = <TurkompIndexEntry>[];
  for (final match in _linkPattern.allMatches(html)) {
    final href = match.group(1)!;
    if (!seen.add(href)) continue;
    final name = match
        .group(4)!
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty) continue;
    entries.add(
      TurkompIndexEntry(href: href, listName: name, turkompId: match.group(3)!),
    );
  }
  entries.sort((a, b) => a.href.compareTo(b.href));
  return entries;
}

// ---------------------------------------------------------------- fetch

Future<void> _runFetch({
  required int? limit,
  required bool resume,
  required int delayMs,
}) async {
  final indexFile = File(_indexPath);
  if (!indexFile.existsSync()) {
    stderr.writeln(
      'Run `fetch_sources.dart index` first ($_indexPath missing).',
    );
    exit(1);
  }
  final index =
      jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
  var entries = (index['entries'] as List)
      .cast<Map<String, dynamic>>()
      .map(TurkompIndexEntry.fromJson)
      .toList();
  if (limit != null) entries = entries.take(limit).toList();

  Directory(_cacheDir).createSync(recursive: true);

  final client = HttpClient()..userAgent = _userAgent;
  var fetched = 0;
  var cached = 0;
  var failed = 0;
  final failures = <String>[];

  try {
    final cookie = await _openSession(client);
    for (final entry in entries) {
      if (resume && _cacheIsValid(entry.href)) {
        cached++;
        continue;
      }
      try {
        final html = await _getWithRetry(client, '/${entry.href}', cookie);
        // Parse BEFORE writing: a page we cannot attribute to a food code is
        // never allowed into the cache, so the cache is always promotable.
        final parsed = parseTurkompFoodPage(html);
        _writeCache(entry, html, parsed);
        fetched++;
        stdout.writeln(
          '[${fetched + cached}/${entries.length}] ${entry.href} '
          '-> ${parsed.sourceRecordId}',
        );
      } catch (error) {
        failed++;
        failures.add('${entry.href}: $error');
        stderr.writeln('FAILED ${entry.href}: $error');
        if (failed >= 10) {
          stderr.writeln(
            'Aborting after 10 failures — TürKomp is likely rejecting the '
            'crawl. Nothing partial is promoted; rerun with --resume later.',
          );
          break;
        }
      }
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  } finally {
    client.close(force: true);
  }

  stdout.writeln('fetched=$fetched cached=$cached failed=$failed');
  if (failures.isNotEmpty) {
    stdout.writeln('failures:\n  ${failures.join('\n  ')}');
  }
  if (failed > 0) exit(1);
}

bool _cacheIsValid(String href) {
  final page = File('$_cacheDir/$href.html.gz');
  final meta = File('$_cacheDir/$href.meta.json');
  if (!page.existsSync() || !meta.existsSync()) return false;
  try {
    final recorded =
        (jsonDecode(meta.readAsStringSync()) as Map<String, dynamic>)['sha256'];
    return recorded == sha256OfFile(page.path);
  } catch (_) {
    return false;
  }
}

void _writeCache(
  TurkompIndexEntry entry,
  String html,
  TurkompComposition parsed,
) {
  final bytes = gzip.encode(utf8.encode(html));
  final pagePath = '$_cacheDir/${entry.href}.html.gz';
  File(pagePath).writeAsBytesSync(bytes);
  final meta = <String, dynamic>{
    'href': entry.href,
    'listName': entry.listName,
    'turkompId': entry.turkompId,
    'sourceUrl': '$_origin/${entry.href}',
    'sourceRecordId': parsed.sourceRecordId,
    'recordName': parsed.recordName,
    'bytes': bytes.length,
    'sha256': sha256OfBytes(bytes),
    'retrievedAt': _nowIso(),
  };
  File(
    '$_cacheDir/${entry.href}.meta.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(meta)}\n');
}

// -------------------------------------------------------------- promote

void _runPromote({
  required String? selectionPath,
  required bool allowContentChange,
}) {
  if (selectionPath == null || selectionPath.isEmpty) {
    stderr.writeln('promote requires --selection <path>');
    exit(64);
  }
  final selectionFile = File(selectionPath);
  if (!selectionFile.existsSync()) {
    stderr.writeln('Selection file not found: $selectionPath');
    exit(1);
  }
  final selection =
      jsonDecode(selectionFile.readAsStringSync()) as Map<String, dynamic>;
  final selected = (selection['foods'] as List).cast<Map<String, dynamic>>();

  final indexJson =
      jsonDecode(File(_snapshotIndexPath).readAsStringSync())
          as Map<String, dynamic>;
  final artifacts = (indexJson['artifacts'] as List)
      .cast<Map<String, dynamic>>();
  final byId = {for (final a in artifacts) a['id'] as String: a};

  Directory(_snapshotDir).createSync(recursive: true);

  var promoted = 0;
  var unchanged = 0;
  var changed = 0;
  final missing = <String>[];

  for (final food in selected) {
    final href = food['href'] as String;
    final cachePage = File('$_cacheDir/$href.html.gz');
    final cacheMeta = File('$_cacheDir/$href.meta.json');
    if (!cachePage.existsSync() || !cacheMeta.existsSync()) {
      missing.add(href);
      continue;
    }
    final meta =
        jsonDecode(cacheMeta.readAsStringSync()) as Map<String, dynamic>;
    final id = 'turkomp-${meta['sourceRecordId']}';
    final target = '$_snapshotDir/$href.html.gz';
    final existing = byId[id];

    if (existing != null && File(target).existsSync()) {
      final currentHash = sha256OfFile(target);
      if (currentHash == meta['sha256']) {
        unchanged++;
        continue;
      }
      changed++;
      if (!allowContentChange) {
        stderr.writeln(
          'CONTENT CHANGED $id\n'
          '  committed sha256: $currentHash\n'
          '  cached    sha256: ${meta['sha256']}\n'
          '  Refusing to overwrite. Every published number was derived from '
          'the committed bytes; re-run with --allow-content-change only after '
          'confirming the source record itself changed.',
        );
        continue;
      }
    }

    cachePage.copySync(target);
    byId[id] = <String, dynamic>{
      'id': id,
      'sourceName': _sourceName,
      'publisher': _publisher,
      'sourceRecordId': meta['sourceRecordId'],
      'recordName': meta['recordName'],
      'sourceUrl': meta['sourceUrl'],
      'path': target,
      'retrievedAt': meta['retrievedAt'],
      'bytes': meta['bytes'],
      'sha256': meta['sha256'],
    };
    promoted++;
  }

  // TÜBER artifacts first (in their committed order), then TürKomp by id.
  final tuber = artifacts
      .where((a) => !(a['id'] as String).startsWith('turkomp-'))
      .toList();
  final turkomp =
      byId.values
          .where((a) => (a['id'] as String).startsWith('turkomp-'))
          .toList()
        ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  indexJson['artifacts'] = [...tuber, ...turkomp];
  File(_snapshotIndexPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(indexJson)}\n',
  );

  stdout.writeln(
    'promoted=$promoted unchanged=$unchanged content-changed=$changed '
    'missing-from-cache=${missing.length}',
  );
  if (missing.isNotEmpty) {
    stdout.writeln('missing:\n  ${missing.take(20).join('\n  ')}');
  }
  if (changed > 0 && !allowContentChange) exit(1);
}

// ----------------------------------------------------------------- http

Future<String> _openSession(HttpClient client) async {
  final request = await client.getUrl(Uri.parse('$_origin$_sessionPath'));
  request.followRedirects = false;
  final response = await request.close();
  await response.drain<void>();
  final cookies = response.cookies
      .map((c) => '${c.name}=${c.value}')
      .join('; ');
  if (cookies.isEmpty) {
    throw StateError(
      'TürKomp did not issue a session cookie; every detail request would 302.',
    );
  }
  return cookies;
}

Future<String> _get(HttpClient client, String path, String cookie) async {
  final request = await client.getUrl(Uri.parse('$_origin$path'));
  request.followRedirects = false;
  request.headers.set(HttpHeaders.cookieHeader, cookie);
  final response = await request.close();
  if (response.statusCode != 200) {
    await response.drain<void>();
    throw HttpException('HTTP ${response.statusCode} for $path');
  }
  return response.transform(const Utf8Decoder(allowMalformed: true)).join();
}

Future<String> _getWithRetry(
  HttpClient client,
  String path,
  String cookie, {
  int maxRetries = 3,
}) async {
  Object? lastError;
  for (var attempt = 0; attempt <= maxRetries; attempt++) {
    if (attempt > 0) {
      final backoff = Duration(seconds: 1 << attempt);
      stderr.writeln('  retry $attempt/$maxRetries in ${backoff.inSeconds}s');
      await Future<void>.delayed(backoff);
    }
    try {
      return await _get(client, path, cookie);
    } catch (error) {
      lastError = error;
    }
  }
  throw StateError('$path failed after $maxRetries retries: $lastError');
}

String _nowIso() =>
    '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
