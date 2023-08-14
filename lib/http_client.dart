import 'dart:convert';
import 'post.dart';
import 'package:http/http.dart' as http;

//<Post>はpost.dartのPostクラスから引っ張っていている
//getPosts(int page)関数は引数としてページ番号を取得していて、$pageに入れる
//Futureは非同期処理ってやつで時間がかかる処理の時に使うぞ（他の処理を実行したい時にも使う）
//Future<>の<>は返り値
Future<List<Post>> getPosts(int page) async {
  print('httpClient loading page $page'); //コンソールに出力

//limit=10なので１０件ずつのデータを取得
  try {
    final response = await http.get(Uri.parse(
        'https://api.github.com/search/repositories?q=flutter&page=$page'));
    final List<Post> posts =
        (jsonDecode(response.body)['items'] as List) //itemsはjsonの中の配列をデコードする
            .map((e) => Post.fromJsonMap(e)) //PostクラスのfromJsonMapメソッドを使ってデコードする
            .toList(); //リストにする
    return posts; //postsを返す（どこに）　→　FutureBuilder<List<Post>>のList<Post>に返す
  } catch (ex, st) {
    // 例外が発生した場合は空のリストを返す
    print(ex); //例外オブジェクトというものを表示する（エラーの内容）
    print(st); //スタックトレースというものを表示する（エラーの場所）
    //なぜここが[null]ではダメで[]ならいいかっていうと、Future<List<Post>>でList型であり、nullは関数の戻り値に対応してないからエラーになる。
    //Listのnullは[]なのでこれに置き換える。ってことでOK？

    return []; //空のリストを返す(どこに)　→　FutureBuilder<List<Post>>のList<Post>に返す
  }
}
