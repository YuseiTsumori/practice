import 'post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'post_state.freezed.dart'; //このファイルを生成する

@freezed
abstract class PostState with _$PostState {
  //PostStateクラスを生成する
  const factory PostState({
    //PostStateクラスのコンストラクタを生成する
    @Default(1) int page, //デフォルト値は1
    List<Post>? posts, //Postクラスのリスト
    @Default(true) bool isLoading, //デフォルト値はtrue
    @Default(false) bool isLoadMoreError, //デフォルト値はfalse
    @Default(false) bool isLoadMoreDone, //デフォルト値はfalse
  }) = _PostState; //PostStateクラスのコンストラクタを生成する

  const PostState._(); //PostStateクラスのコンストラクタを生成する
}
