import 'http_client.dart';
import 'post.dart';
import 'post_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_asyncnotifier_provider.g.dart'; // このファイルはコード生成によって作成される

//これはRverpodを使用して非同期に投稿データを取得するロジックを実装している。
@Riverpod(
    keepAlive:
        true) // Riverpodアノテーションを使用し、ProviderのkeepAliveオプションを有効化。Trueにすると使わないプロパイダを破棄する
// コードジェネレーションを利用するための設定

class PostAsyncnotifierProvider extends _$PostAsyncnotifierProvider {
  @override
  // 初期状態を構築するメソッド
  FutureOr<PostState> build() async {
    final posts = await _initPosts(1); // 1ページ目の投稿を非同期に取得
    return PostState(posts: posts); // 初期状態を返す
  }
  // 初期ページの投稿を取得する非同期メソッド

  Future<List<Post>> _initPosts(int initPage) async {
    final posts = await getPosts(initPage);
    return posts;
  }
  // より多くの投稿を非同期にロードするメソッド

  Future<void> loadMorePost() async {
    final currentState = state.value; // 現在の状態を取得
    //isLoadingっだとバグるが、isLoadMoreErrorだと動いたのでおかしい。
    //いや、そもそもこれエラー吐いた時に動かす処理だからisLoadMoreErrorじゃないとおかしくね？
    if (currentState == null || currentState.isLoadMoreError) {
      print('Loading failed or already loading.'); // ロード中かエラーならリターン
      return;
    }

    // ロード開始のログ出力
    print(
        'try to request loading ${currentState.isLoading} at ${currentState.page + 1}');

    // 新しい状態をセットしてロード開始
    state = AsyncValue.data(currentState.copyWith(
        isLoading: true, isLoadMoreDone: false, isLoadMoreError: false));

    final posts = await getPosts(currentState.page + 1); // 次のページの投稿を非同期に取得
    // エラー時の処理
    state = AsyncValue.data(
        currentState.copyWith(isLoadMoreError: true, isLoading: false));

    // ロード完了のログ出力
    print('load more ${posts.length} posts at page ${currentState.page + 1}');
    if (posts.isNotEmpty) {
      // 投稿が取得できた場合、ページを増やして新しい状態をセット
      state = AsyncValue.data(currentState.copyWith(
          page: currentState.page + 1,
          isLoading: false,
          isLoadMoreDone: false,
          posts: [...?currentState.posts, ...posts]));
    } else {
      // 投稿が空の場合、ページを増やさずに新しい状態をセット
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        isLoadMoreDone: true,
      ));
    }
  }

  Future<void> refresh() async {
    // リフレッシュ開始のログ出力
    print('リフレッシュ中');

    try {
      // 1ページ目の投稿を非同期に取得
      final posts = await _initPosts(1);

      // 新しい状態をセットしてリフレッシュ完了(初期状態に戻す)
      state = AsyncValue.data(PostState(posts: posts));

      print('リフレッシュ完了'); // リフレッシュ完了のログ出力
    } catch (error, stack) {
      // エラー時の処理
      print('リフレッシュ失敗$error$stack');
      state = AsyncValue.error(error, stack);
    }
  }
}
