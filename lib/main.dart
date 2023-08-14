import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:practice/post.dart';
import 'post_asyncnotifier_provider.dart';

//StateProvider=フィルタの条件 / シンプルなステートオブジェクト
//KeyProvideというProviderを作成（初期化）
//俺がいつも使うProviderはサービスクラス / 算出プロパティ（リストのフィルタなど）
final keyProvider = StateProvider<String>((ref) {
  return '';
});

final postSearchProvider = StateProvider<List<Post>>((ref) {
  // キーに基づいて投稿をフィルタリングするためのプロバイダー
  final postState = ref.watch(postAsyncnotifierProviderProvider);
  final key = ref.watch(keyProvider);
  return postState.value!.posts!
      .where((element) =>
          element.description.contains(key) || element.name.contains(key))
      .toList();
});

void main() {
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github Search Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _searchBoolean = false; //検索ボタンを押したかどうかのフラグ
  final ScrollController _controller =
      ScrollController(); //スクロールの位置を取得するためのコントローラー
  int oldLength = 0; //リストの長さを取得するための変数

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (timer) async {
      //5秒ごとに実行
      //リストの最後までスクロールをしたかどうかをチェック
      //現在のスクロール位置＜最大下部のスクロール位置になったら発動
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent -
              MediaQuery.of(context).size.height) {
        //不意データの長さと現在のデータの長さが同じであれば次のページを読み込む
        if (oldLength ==
            ref.read(postAsyncnotifierProviderProvider).value!.posts!.length) {
          // make sure ListView has newest data after previous loadMore
          //さっきの条件がTrueであればこれを実行して読み込む
          ref.read(postAsyncnotifierProviderProvider.notifier).loadMorePost();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(postAsyncnotifierProviderProvider);
    return Scaffold(
      appBar: AppBar(
          title: !_searchBoolean
              ? Text("GithubSearch")
              : TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Enter to search!',
                  ),
                  onChanged: (newValue) {
                    ref.read(keyProvider.notifier).state = newValue;
                    // 新しい検索キーを状態に保存
                  },
                ),
          actions: !_searchBoolean
              ? [
                  IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = true;
                        });
                      })
                ]
              : [
                  IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = false;
                        });
                      })
                ]),
      body: asyncTodos.when(
        // 投稿のロード状態に応じて表示を変更
        data: (asyncTodos) => Consumer(
          builder: (ctx, watch, child) {
            final posts = ref.watch(postSearchProvider.notifier).state;

            //.notifierはインスタンへのアクセス許可・.stateはプロ杯だの現在の状態を取得
            //ref.watchはプロバイダーを監視するやつ(値も得るよ)
            // sync oldLength with post.length to make sure ListView has newest
            // data, so loadMore will work correctly
            //?.の部分はNullにならないので.だけにする
            //posts.length ?? 0;は左側がNullの場合に備えているが、Nullになることはないので、「0」は削除。
            oldLength = posts.length;
            // init data or error
            //（この部分わからんのでとりあえず誤魔化す）
            // ignore: unnecessary_null_comparison
            if (posts == null) {
              // error case
              if (asyncTodos.isLoading == false) {
                return const Center(
                  child: Text('error'),
                );
              }
              return const _Loading();
            }
            //上からひっぱた時に更新させるやつ
            return RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(postAsyncnotifierProviderProvider.notifier)
                    .refresh();
              },
              child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  controller: _controller,
                  itemCount: posts.length + 1, //リストに表示するデータの個数
                  itemBuilder: (ctx, index) {
                    // 現在ビルドされているリストのアイテムの位置を示す番号らしい。
                    //ctxはcontextの略
                    // 最後の要素（プログレスバー、エラー、または最後の要素に到達した場合はDone!とする）
                    if (index == posts.length) {
                      // さらにロードしてエラーが出た際に実行
                      if (asyncTodos.isLoadMoreError) {
                        return const Center(
                          child: Text('Error'),
                        );
                      }
                      // ロードしまくって最後の部分に到達した際に実行させる
                      if (asyncTodos.isLoadMoreDone) {
                        return const Center(
                          child: Text(
                            'Done!',
                            style: TextStyle(color: Colors.green, fontSize: 20),
                          ),
                        );
                      }
                      return const LinearProgressIndicator();
                    }
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            posts[index].name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(posts[index].description),
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(posts[index].avatar_url),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
            );
          },
        ),
        error: (err, stack) => const Text('error'),
        loading: () =>
            const _Loading(), //ローディング中はこいつを実行させてCircularProgressIndicatorを出す
      ),
    );
  }
}

//起動した時にローディング表示
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
