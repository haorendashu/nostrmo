import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';

import 'retry_http_file_service.dart';

class CacheManagerBuilder {
  static const key = 'cachedImageData';

  static CacheManager build() {
    var config = Config(key);
    var store = CacheStore(config);

    return CacheManager.custom(config,
        cacheStore: store, webHelper: WebHelper(store, RetryHttpFileServcie()));
  }
}
