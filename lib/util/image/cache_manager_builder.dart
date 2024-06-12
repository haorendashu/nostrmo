import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:nostrmo/main.dart';

import 'retry_http_file_service.dart';

class CacheManagerBuilder {
  static const key = 'cachedImageData';

  static void build() {
    var config = Config(key);
    imageCacheStore = CacheStore(config);

    imageLocalCacheManager = CacheManager.custom(config,
        cacheStore: imageCacheStore,
        webHelper: WebHelper(imageCacheStore, RetryHttpFileServcie()));
  }
}
