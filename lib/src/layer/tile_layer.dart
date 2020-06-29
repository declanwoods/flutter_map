import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:tuple/tuple.dart';

import 'layer.dart';

/// Describes the needed properties to create a tile-based layer.
/// A tile is an image binded to a specific geographical position.
class TileLayerOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles.
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be
  /// displayed (inclusive).
  /// In most tile providers goes from 0 to 19.
  final double maxZoom;

  // Minimum zoom number the tile source has available. If it is specified,
  // the tiles on all zoom levels lower than minNativeZoom will be loaded
  // from minNativeZoom level and auto-scaled.
  final double minNativeZoom;

  // Maximum zoom number the tile source has available. If it is specified,
  // the tiles on all zoom levels higher than maxNativeZoom will be loaded
  // from maxNativeZoom level and auto-scaled.
  final double maxNativeZoom;

  // If set to true, the zoom number used in tile URLs will be reversed (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  // The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  ///Color shown behind the tiles.
  final Color backgroundColor;

  ///Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is CachedNetworkTileProvider,
  /// which loads tile images from network and caches them offline.
  ///
  /// If you don't want to cache the tiles, use NetworkTileProvider instead.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Placeholder to show until tile images are fetched by the provider.
  final ImageProvider placeholderImage;

  /// Tile image to show in place of the tile that failed to load.
  final ImageProvider errorImage;

  /// Static informations that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  final Map<String, String> additionalOptions;

  // Tiles will not update more than once every `updateInterval` milliseconds
  // (default 200) when panning.
  // It can be 0 (but it will calculating for loading tiles every frame when panning / zooming, flutter is fast)
  // This can save some fps and even bandwidth
  // (ie. when fast panning / animating between long distances in short time)
  final Duration updateInterval;

  // Tiles fade in duration in milliseconds (default 100),
  // it can 0 to avoid fade in
  final Duration tileFadeInDuration;

  TileLayerOptions(
      {this.urlTemplate,
      this.tileSize = 256.0,
      this.minZoom = 0.0,
      this.maxZoom = 18.0,
      this.minNativeZoom,
      this.maxNativeZoom,
      this.zoomReverse = false,
      this.zoomOffset = 0.0,
      this.additionalOptions = const <String, String>{},
      this.subdomains = const <String>[],
      this.keepBuffer = 2,
      this.backgroundColor = const Color(0xFFE0E0E0),
      this.placeholderImage,
      this.errorImage,
      this.tileProvider = const CachedNetworkTileProvider(),
      this.tms = false,
      // ignore: avoid_init_to_null
      this.wmsOptions = null,
      this.opacity = 1.0,
      // Tiles will not update more than once every `updateInterval` milliseconds
      // (default 200) when panning.
      // It can be 0 (but it will calculating for loading tiles every frame when panning / zooming, flutter is fast)
      // This can save some fps and even bandwidth
      // (ie. when fast panning / animating between long distances in short time)
      int updateInterval = 200,
      // Tiles fade in duration in milliseconds (default 100),
      // it can 0 to avoid fade in
      int tileFadeInDuration = 100,
      rebuild})
      : updateInterval =
            updateInterval <= 0 ? null : Duration(milliseconds: updateInterval),
        tileFadeInDuration = tileFadeInDuration <= 0
            ? null
            : Duration(milliseconds: tileFadeInDuration),
        super(rebuild: rebuild);
}

class WMSTileLayerOptions {
  final service = 'WMS';
  final request = 'GetMap';

  /// url of WMS service.
  /// Ex.: 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// list of WMS layers to show
  final List<String> layers;

  /// list of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// tile transperency flag
  final bool transparent;

  // TODO find a way to implicit pass of current map [Crs]
  final Crs crs;

  /// other request parameters
  final Map<String, String> otherParameters;

  String _encodedBaseUrl;

  double _versionNumber;

  WMSTileLayerOptions({
    @required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.crs = const Epsg3857(),
    this.otherParameters = const {},
  }) {
    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
    _encodedBaseUrl = _buildEncodedBaseUrl();
  }

  String _buildEncodedBaseUrl() {
    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
    final buffer = StringBuffer(baseUrl)
      ..write('&service=$service')
      ..write('&request=$request')
      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
      ..write('&format=${Uri.encodeComponent(format)}')
      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
      ..write('&version=${Uri.encodeComponent(version)}')
      ..write('&transparent=$transparent');
    otherParameters
        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
    return buffer.toString();
  }

  String getUrl(Coords coords, int tileSize) {
    final tileSizePoint = CustomPoint(tileSize, tileSize);
    final nvPoint = coords.scaleBy(tileSizePoint);
    final sePoint = nvPoint + tileSizePoint;
    final nvCoords = crs.pointToLatLng(nvPoint, coords.z);
    final seCoords = crs.pointToLatLng(sePoint, coords.z);
    final nv = crs.projection.project(nvCoords);
    final se = crs.projection.project(seCoords);
    final bounds = Bounds(nv, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.y, bounds.min.x, bounds.max.y, bounds.max.x]
        : [bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y];

    final buffer = StringBuffer(_encodedBaseUrl);
    buffer.write('&width=$tileSize');
    buffer.write('&height=$tileSize');
    buffer.write('&bbox=${bbox.join(',')}');
    return buffer.toString();
  }
}

class TileLayer extends StatefulWidget {
  final TileLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  TileLayer({
    this.options,
    this.mapState,
    this.stream,
  });

  @override
  State<StatefulWidget> createState() {
    return _TileLayerState();
  }
}

class _TileLayerState extends State<TileLayer> {
  MapState get map => widget.mapState;
  TileLayerOptions get options => widget.options;

  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;
  Level _level;
  StreamSubscription _moveSub;
  StreamController<LatLng> _throttleUpdate;
  CustomPoint _tileSize;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  @override
  void initState() {
    _initState();
    super.initState();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _initState() {
    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _moveSub = widget.stream.listen((_) => _handleMove());

    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng>(sync: true);
      _throttleUpdate.stream.transform(
        util.throttleStreamTransformerWithTrailingCall<LatLng>(
          options.updateInterval,
        ),
      )..listen((_) {
          setState(_abortLoading);
        });
    }
  }

  void _dispose() {
    _removeAllTiles();
    _moveSub?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();
  }

  List<Coords<num>> _createGrid(LatLng center) {
    var pixelBounds = _getTiledPixelBounds(map.center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords>[];

    for (var key in _tiles.keys) {
      var c = _tiles[key].coords;
      if (c.z != _tileZoom) {
        _tiles[key].current = false;
      }
    }

    _setView(map.center, map.zoom);

    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom;

        if (!_isValidTile(coords)) {
          continue;
        }

        queue.add(coords);
      }
    }

    var tilesToRender = <Tile>[
      for (var tile in _tiles.values)
        if ((tile.coords.z - _level.zoom).abs() <= 1) tile
    ];

    tilesToRender.sort((aTile, bTile) {
      final a = aTile.coords;
      final b = bTile.coords;
      if (a.z != b.z) {
        return (b.z - a.z).toInt();
      }
      return (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt();
    });

    return queue;
  }

  @override
  Widget build(BuildContext context) {
    var coords = _createGrid(map.center);

    var tileWidgets = <Widget>[];
    for (var coord in coords) {
      tileWidgets.add(_createTileWidget(coord));
    }

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
      ),
    );
  }

  Widget _createTileWidget(Coords<num> coords) {
    var tilePos = _getTilePos(coords);
    var level = _levels[coords.z];
    var tileSize = getTileSize();
    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    var width = tileSize.x * level.scale;
    var height = tileSize.y * level.scale;
    var key = _tileCoordsToKey(coords);

    var tile = _tiles[key];
    tile ??= _addTile(coords);
    tile.current = true;

    var child = TileWidget(
      coords: coords,
      tile: tile,
      fadeAnimationInMs: options.tileFadeInDuration,
    );

    return Positioned(
      key: ValueKey(key),
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: child,
    );
  }

  void _abortLoading() {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (var key in toRemove) {
      var tile = _tiles[key];

      tile.tileReady = null;
      tile.dispose();
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom) ??
          CustomPoint(0.0, 0.0);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    if (map == null) {
      return;
    }

    var zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      tile.retain = tile.current;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.current && !tile.active) {
        var coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeAllTiles() {
    var toRemove = Map<String, Tile>.from(_tiles);

    for (var key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    var x2 = (x / 2).floorToDouble();
    var y2 = (y / 2).floorToDouble();
    var z2 = z - 1;
    var coords2 = Coords(x2, y2);
    coords2.z = z2;

    var key = _tileCoordsToKey(coords2);

    var tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        var coords = Coords(i, j);
        coords.z = z + 1;

        var key = _tileCoordsToKey(coords);

        var tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom) {
      return options.minNativeZoom;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom < zoom) {
      return options.maxNativeZoom;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    var tileZoom = _clampZoom(zoom.roundToDouble());
    if ((options.maxZoom != null && tileZoom > options.maxZoom) ||
        (options.minZoom != null && tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();
    _pruneTiles();

    _setZoomTransforms(center, zoom);
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i], center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first =
          (map.project(LatLng(0.0, crs.wrapLng.item1), tileZoom).x / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(0.0, crs.wrapLng.item2), tileZoom).x / tileSize.y)
              .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first =
          (map.project(LatLng(crs.wrapLat.item1, 0.0), tileZoom).y / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(crs.wrapLat.item2, 0.0), tileZoom).y / tileSize.y)
              .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _handleMove() {
    var tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restory fully via _setView call if we are back on trail
      if ((options.maxZoom != null && tileZoom <= options.maxZoom) &&
          (options.minZoom != null && tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);
        });
      }
    } else {
      if ((tileZoom - _tileZoom).abs() >= 1) {
        _setView(map.center, tileZoom);
      } else {
        if (null == _throttleUpdate) {
          setState(_abortLoading);
        } else {
          _throttleUpdate.add(null);
        }
      }
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var scale = map.getZoomScale(map.zoom, _tileZoom);
    var pixelCenter = map.project(center, _tileZoom).floor();
    var halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  bool _isValidTile(Coords coords) {
    var crs = map.options.crs;

    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    var k = key.split(':');
    var coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    if (_tiles.containsKey(key)) {
      var tile = _tiles[key];
      tile.dispose();
      _tiles.remove(key);
    }
  }

  Tile _addTile(Coords<double> coords) {
    var tileCoordsToKey = _tileCoordsToKey(coords);
    var tile = Tile(
      coords: coords,
      coordsKey: tileCoordsToKey,
      current: true,
      level: _levels[coords.z],
      imageProvider: options.tileProvider.getImage(
        _wrapCoords(coords),
        options,
      ),
    );

    _tiles[tileCoordsToKey] = tile;
    return tile;
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z];
    return coords.scaleBy(getTileSize()) - level.origin;
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }
}

typedef TileReady = void Function(
    Coords<double> coords, dynamic error, Tile tile);

class Tile implements Comparable<Tile> {
  final String coordsKey;
  final Coords<double> coords;
  final ImageProvider imageProvider;

  bool current;
  bool retain;
  bool active;
  DateTime loaded;
  Level level;

  // callback when tile is ready / error occurred
  // it maybe be null forinstance when download aborted
  TileReady tileReady;
  ImageInfo imageInfo;
  ImageStream _imageStream;
  ImageStreamListener _listener;

  Tile({
    this.coordsKey,
    this.coords,
    this.imageProvider,
    this.tileReady,
    this.current = false,
    this.active = false,
    this.retain = false,
    this.level,
  });

  // call this before GC!
  void dispose([bool evict = false]) {
    if (evict && imageProvider != null) {
      imageProvider
          .evict()
          .then((bool succ) => print('evict tile: $coords -> $succ'))
          .catchError((error) => print('evict tile: $coords -> $error'));
    }
    _imageStream?.removeListener(_listener);
  }

  void fetchImage() {
    try {
      _imageStream = imageProvider.resolve(ImageConfiguration());
      _listener = ImageStreamListener(_tileOnLoad, onError: _tileOnError);
      _imageStream.addListener(_listener);
    } catch (e, s) {
      // make sure all exception is handled - #444 / #536
      _tileOnError(e, s);
    }
  }

  void _tileOnLoad(ImageInfo imageInfo, bool synchronousCall) {
    if (null != tileReady) {
      loaded = DateTime.now();
      this.imageInfo = imageInfo;
      tileReady(coords, null, this);
    }
  }

  void _tileOnError(dynamic exception, StackTrace stackTrace) {
    if (null != tileReady) {
      tileReady(coords, exception, this);
    }
  }

  @override
  int compareTo(Tile other) {
    var zIndexA = level.zIndex;
    var zIndexB = other.level.zIndex;

    if (zIndexA == zIndexB) {
      return 0;
    } else {
      return zIndexB.compareTo(zIndexA);
    }
  }

  @override
  int get hashCode => coords.hashCode;

  @override
  bool operator ==(other) {
    return other is Tile && coords == other.coords;
  }
}

class Level {
  double zIndex;
  CustomPoint origin;
  double zoom;
  CustomPoint translatePoint;
  double scale;
}

class Coords<T extends num> extends CustomPoint<T> {
  T z;

  Coords(T x, T y) : super(x, y);

  @override
  String toString() => 'Coords($x, $y, $z)';

  @override
  bool operator ==(dynamic other) {
    if (other is Coords) {
      return x == other.x && y == other.y && z == other.z;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
}

class TileWidget extends StatefulWidget {
  final Coords<num> coords;
  final ImageProvider errorImage;
  final Tile tile;
  final Duration fadeAnimationInMs;

  TileWidget({
    @required this.coords,
    @required this.tile,
    @required this.fadeAnimationInMs,
    this.errorImage,
  });

  @override
  State<StatefulWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with TickerProviderStateMixin {
  ImageInfo _rawImage;
  AnimationController _controller;
  bool _hasError = false;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeAnimationInMs,
    );
    if (null == widget.tile.imageInfo) {
      _fetchImage();
    } else {
      _rawImage = widget.tile.imageInfo;
      _controller?.forward();
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    widget.tile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    return FadeTransition(
      opacity: animation,
      child: _buildTileImage(),
    );
  }

  void _fetchImage() {
    widget.tile.tileReady = (_, error, tile) {
      if (mounted) {
        setState(() {
          _hasError = null != error;
          _rawImage = tile.imageInfo;
        });
        _controller?.forward();
      }
    };
    widget.tile.fetchImage();
  }

  Widget _buildTileImage() {
    if (_hasError && widget.errorImage != null) {
      return Image(
        image: widget.errorImage,
        fit: BoxFit.fill,
      );
    }
    return RawImage(
      image: _rawImage?.image,
      fit: BoxFit.fill,
    );
  }
}
