---
title: "Java 17以降のパターンマッチングの変遷"
emoji: "🐙"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["java"]
published: false
---

Java 25 は、パターンマッチングが一通り出揃った最初のリリースです。完成ではありません。1つはまだプレビューです。ただし部品同士が噛み合い、その作法のままプログラム全体を書けるようになりました。あるメソッドで使い、次のメソッドでは諦める、という状態ではなくなっています。

ここまでに9年と12本ほどの JEP がかかりました。しかも届いた順番がばらばらなため、個々のリリースノートからは全体像が見えません。この記事は Java 25 という遠い側から全体を眺め、結局何が変わったのかを問い直す試みです。

ここに書いた主張は、記憶ではなく計測に基づきます。「あるリリースでコンパイルでき、別のリリースではできない」と書いた箇所は、`javac --release N` を実行した結果です。「この式はこの値になる」と書いた箇所には、対応するテストがリポジトリにあります。Java 17 に関する2つの観察だけは実物の JDK 17 を必要としました。その箇所は明示してあります。

コードは [`hypatia-tile/java-pattern-match`](https://github.com/hypatia-tile/java-pattern-match) に置いてあります。各節は根拠となるファイル名を示します。`nix develop` のあと `gradle test` で全て実行できます。

## タイムライン

よくある紹介は JEP 番号の一覧です。しかしこれは最も役に立たない枠組みでもあります。JEP 番号は「いつ実際に使えるようになったか」を何も教えないからです。switch のパターンマッチングには5本の JEP がありますが、コードを書く側に関係するのは最後の1本だけです。

そこでこの表は逆から作りました。各構文を `--release` 17 から 25 まで順にコンパイルし、受け付けられた最小の値を記録しています。

計測環境は Zulu OpenJDK 25.0.3 (`javac --release N`)、2026-09-12 時点です。

| 機能 | 構文 | 最小の `--release` | プレビュー | ファイル |
| --- | --- | --- | --- | --- |
| instanceof のパターンマッチング | `o instanceof Circle c` | 17 以下 | - | `features/InstanceofPattern.java` |
| sealed / permits | `sealed interface S permits A` | 17 以下 | - | `features/Sealed.java` |
| record | `record P(int x)` | 17 以下 | - | `common/` 全体 |
| switch 式 / yield | `switch (x) { ... yield v; }` | 17 以下 | - | `features/SwitchExpression.java` |
| switch のパターンマッチング | `case Circle c ->` | **21** | - | `features/SwitchPattern.java` |
| record パターン | `case P(int x, int y) ->` | **21** | - | `features/RecordPattern.java` |
| when ガード | `case P p when p.x() > 1 ->` | **21** | - | `features/Guard.java` |
| case null | `case null ->` | **21** | - | `features/NullCase.java` |
| MatchException | - | **21** (`@since 21`) | - | `features/Exhaustiveness.java` |
| 名前なしパターン | `case P(int x, _) ->` | **22** | - | `features/UnnamedPattern.java` |
| 名前なし変数 | `var _ = f();` | **22** | - | `features/UnnamedPattern.java` |
| モジュールインポート | `import module java.base;` | **25** | - | `features/ModuleImport.java` |
| 簡潔なソースファイル | package 宣言なし + `void main()` | **25** | - | `samples/` |
| **プリミティブ型パターン** | `case int i ->` / `o instanceof byte` | **25** | **あり (JEP 507)** | `features/PrimitivePattern.java` |

「17 以下」は、この調査を 17 から始めたという意味にすぎません。instanceof のパターンマッチングと record は Java 16 で、switch 式は Java 14 で正式化されています。

掃き出しの生の出力です。`o` がコンパイルできたことを表します。

```text
feature                   17    18    19    20    21    22    23    24    25 25+pv
instanceof_pattern         o     o     o     o     o     o     o     o     o     o
sealed                     o     o     o     o     o     o     o     o     o     o
switch_pattern             -     -     -     -     o     o     o     o     o     o
record_pattern             -     -     -     -     o     o     o     o     o     o
when_guard                 -     -     -     -     o     o     o     o     o     o
case_null                  -     -     -     -     o     o     o     o     o     o
unnamed_pattern            -     -     -     -     -     o     o     o     o     o
unnamed_variable           -     -     -     -     -     o     o     o     o     o
module_import              -     -     -     -     -     -     -     -     o     o
primitive_pattern          -     -     -     -     -     -     -     -     -     o
```

## 実物の JDK 17 と 21 が必要だった観察

このリポジトリには JDK 25 しか入っていません。以下は設計中に実物の JDK 17.0.19 と JDK 21.0.11 で計測した結果です。リポジトリの中から再現する方法はありません。

- `javac` は `--enable-preview` をコンパイラ自身のリリースにしか許さない。JDK 25 は `--release 17 --enable-preview` を拒否する。つまり Java 17 当時のプレビュー機能は、実物の JDK 17 なしには再現できない。
- Java 17 のプレビュー版 switch パターンでは、ガードは `when` ではなく `&&` だった。JDK 17 に `--enable-preview` を付けた場合、`case A a when a.v() > 10 ->` は `error: : or -> expected` で失敗する。一方 `case A a && a.v() > 10 ->` は通る。`when` の到着は Java 19 (JEP 427) である。
- JDK 17 で record パターンを書くと `error: '.class' expected` になる。`P(int x, int y)` を式として解析するためである。この診断は機能の不在を伝えない。
- 名前なしパターンの `_` は `--release 21` で失敗する。到着は Java 22 である。

## 1. なぜパターンマッチングなのか

表にある全ての機能を貫く筋が1本あります。1つずつ見ていく前に、名前を与えておきます。

> どれも、プログラマが知っていてコンパイラが知らない箇所を1つ消している。

話はこれで尽きています。キャストは、あなたが型を知っていてコンパイラが鵜呑みにしている箇所です。if 連鎖の末尾にある到達不能な `throw` は、あなたが一覧の完全性を知っていてコンパイラに判定できない箇所です。「新しいノード型はここにも追加すること」というコメントは、あなたが将来の変更の危うさを知っていて、何もそれを強制しない箇所です。

パターンマッチングの主眼は、記述量を減らすことではありません。そうした知識をあなたの頭からコンパイラの検査できる形へ移すことです。結果として、次にこのコードへ触れる人 (たいていは後日のあなた) は、推測ではなく指摘を受け取れます。

文字数の節約は本物ですが副次的です。そこを主眼と取り違えると、「これは好きなときに取り入れればよい糖衣構文だ」という誤った結論に至ります。9節の網羅性検査は糖衣ではありません。サブタイプを追加したときに、コンパイル時に気づくか本番で気づくかの違いです。

1つだけ断りを書いておきます。この設計が最も映えるのは、データモデルが record と sealed 型だけでできている場合です。そして現実のモデルの多くは違います。13節では JSON の木を歩きます。そこでは容器が `List` と `Map` を抱えるため、分解は途中で止まります。むしろその状況こそ普通です。それでも結果が十分に良いことは、見ておく価値があります。

## 2. instanceof のパターンマッチング

参照するファイルは `features/InstanceofPattern.java` です。

参照を絞り込む作業には、かつて3手を要しました。型を調べ、キャストし、結果に名前を付ける、という3手です。

```java
if (value instanceof Circle) {
    Circle c = (Circle) value;
    return "circle r=" + c.radius();
}
```

型を2回書いており、2つの出現を結び付けるものは何もありません。調べる型だけを変えてキャストを直し忘れると、対称に見えるコードから実行時に `ClassCastException` が飛びます。型パターンは3手を1つに畳みます。

```java
if (value instanceof Shape.Circle c) {
    return "circle r=" + c.radius();
}
```

ここまでは平凡です。面白いのは、これを成り立たせるために発明されたスコープ規則のほうです。`c` は条件の内側で宣言され、外側で使われるからです。

### フロースコープ

束縛変数のスコープは、囲みのブロックではありません。**パターンが一致したとコンパイラが証明できる範囲**です。これをフロースコープと呼びます。波括弧の形ではなく制御フローの形に従う点が特徴で、Java の他のローカル変数は誰もこう振る舞いません。

JDK 25 でコンパイルした8通りです。

| 書き方 | 結果 |
| --- | --- |
| `o instanceof C c && c.r() > 0` | OK |
| `o instanceof C c \|\| c.r() > 0` | `cannot find symbol` |
| `if (o instanceof C c) { c.r(); }` | OK |
| `if (o instanceof C c) { } c.r();` | `cannot find symbol` |
| `if (!(o instanceof C c)) return 0; c.r();` | OK |
| `if (!(o instanceof C c)) { c.r(); }` | `cannot find symbol` |
| `!(o instanceof C c) \|\| c.r() > 0` | OK |
| `if (o instanceof C c) {...} else { c.r(); }` | `cannot find symbol` |

8行ありますが規則は1つです。`&&` なら通り、`||` では通りません。`&&` の右辺は左辺が成功したときだけ評価され、`||` の右辺はまさに失敗したときに評価されるからです。人がつまずくのは下3行です。否定は束縛を無効にするのではなく、**移動**させます。`if (!(o instanceof C c)) return;` の次の行は、パターンが一致したときにしか到達しません。だからそこが `c` のスコープです。

こう読めば暗記するものは残りません。一致したと分かっている場所が束縛のスコープであり、その範囲はコンパイラが求めてくれます。

### null の扱い

`describe(null)` は、どこにも null 検査を書かずに `"unknown"` を返します。

```java
public static String describe(Object value) {
    if (value instanceof Shape.Circle c) { ... }
    else if (value instanceof Shape.Rect r) { ... }
    else if (value instanceof Shape.Group g) { ... }
    return "unknown";
}
```

`null instanceof anything` は Java 1.1 から `false` です。どの型パターンも一致せず、連鎖はそのまま抜けます。規則そのものより、その帰結のほうが大事です。**一致した分岐の中で、束縛変数が `null` になることはありません。** これを覚えておいてください。8節は、同じ期待を `switch` に持ち込んだときの話です。

### equals の実装

日々の効き目が一番分かりやすいのは、おそらく `equals` です。

```java
public final class Legacy {
    private final double x;

    Legacy(double x) {
        this.x = x;
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof Legacy other && other.x == this.x;
    }
}
```

null 検査とキャストと比較が1つの式に収まります。`instanceof` は `null` に `false` を返すので、明示的な null 検査は要りません。ただし `getClass()` による比較とは違い、サブクラスも同じ型として扱う点には注意してください。継承を許す設計では対称性を崩す恐れもあります。

## 3. sealed と permits

参照するファイルは `features/Sealed.java` です。

インタフェースは誰でも実装できます。だからそれを対象にした `switch` は原理的に完全になりません。`sealed` はその自由を取り上げ、選択肢に名前を与えます。

```java
public sealed interface Shape {
    record Point(double x, double y) {}
    record Circle(Point center, double radius) implements Shape {}
    record Rect(Point topLeft, double width, double height) implements Shape {}
    record Group(List<Shape> members) implements Shape {}
}
```

`permits` 節はありません。これは弱い封印ではありません。全てのサブタイプを同じファイルで宣言した場合、節は推論されます。しかも推論は名目上のものではなく、クラスファイルに焼かれ、読み出せます。

```java
Arrays.stream(Shape.class.getPermittedSubclasses()).map(Class::getSimpleName).toList()
// => [Circle, Rect, Group]
```

この一覧が網羅性検査の土台の全てです。9節の内容は、この3つの名前がコンパイラの見つけられる場所に書かれているという一点から生まれます。

封印は1段下でも保たれなければ意味を失います。そのため sealed 型のサブタイプは、それ自身も `final` / `sealed` / `non-sealed` のどれかである必要があります。誰かが構成要素を継承して集合を開き直せないようにするためです。`Shape` が `final` と書かないのは、record が既にそうだからです。

`Point` が `Shape` の内側にありながら実装していない点にも触れておきます。これは `Circle` と `Rect` へ入れ子にする相手を与えるために置いてあり、6節で使います。インタフェースの内側にあることと、階層の一員であることは別です。

## 4. switch 式と yield

参照するファイルは `features/SwitchExpression.java` です。

パターンマッチングが乗っているもう1つの土台は、もっと早く到着していたので見落とされがちです。switch **文**は何をするかを選びます。switch **式**は値を作ります。この違いが3つの規則を連れてきます。

- 式は何かを返さなければならないので、網羅的である必要がある。
- 各アームはフォールスルーしない。
- 全てのアームが共通の型の値を返す。

5節でラベルの定数がパターンに置き換わったとき、そのまま引き継がれるのがこの3つです。これなしにパターンは成り立ちません。ラベルが重なり得る世界でフォールスルーは筋が通らず、網羅性はこの設計全体が寄りかかる性質だからです。

```java
return switch (size) {
    case SMALL -> 1;
    case MEDIUM -> 2;
    case LARGE -> 3;
};
```

`default` はありません。enum が相手なら、全ての定数を並べるだけで足ります。

コロン形式も健在で、`yield` を使えば値を返せます。

```java
return switch (size) {
    case SMALL: yield 1;
    case MEDIUM: yield 2;
    case LARGE: yield 3;
};
```

矢印アームの本体をブロックにしたときも、値を返す手段は `yield` です。switch 式の中の `return` は囲みのメソッドから抜けてしまうため、そもそも禁止されています。

この例を書きながら踏んだ罠を1つ。`yield` は switch が*式*であることを要求します。上のコロン形式から `return` と `;` を外して素の文にすると、`yield outside of switch expression` で失敗します。正確な診断ですが、直し方はすぐには浮かびません。

## 5. switch のパターンマッチング

参照するファイルは `features/SwitchPattern.java` です。

Java 21 より前、switch のラベルに置けるのは定数だけでした。整数、文字列、enum 定数です。そこにパターンを許したことが変更の全てで、2節の連鎖はこう変わります。

```java
return switch (value) {
    case Shape.Circle c -> "circle r=" + c.radius();
    case Shape.Rect r   -> "rect " + r.width() + "x" + r.height();
    case Shape.Group g  -> "group of " + g.members().size();
    default             -> "unknown";
};
```

短くはなりました。しかしそこが論点ではありません。if 連鎖も動きます。動かないのは「何かを*述べる*」ことのほうです。分岐が1つの値に対する選択肢であるとは、どこにも書かれていません。値の名前は検査のたびに繰り返されます。順序は効いているのに、そのことは黙っています。分岐の書き漏らしは末尾への素通りとなり、初めから不要だった分岐と見分けが付きません。

`switch` はその全てを構造として述べます。そして選択子が `Object` ではなく sealed 型になると、`default` が消えます。

```java
public static String area(Shape shape) {
    return switch (shape) {
        case Shape.Circle c -> ...;
        case Shape.Rect r   -> ...;
        case Shape.Group g  -> ...;
    };
}
```

どれか1つのアームを消せば、これはコンパイルを通らなくなります。if 連鎖には決して持てなかった性質です。

### 順序は使われるだけでなく検査される

広いパターンを狭いパターンより前に置くと、狭いほうのアームは到達不能になります。コンパイラは先に一致したほうを黙って選ぶのではなく、これを拒否します。

```java
static String describe(Shape value) {
    return switch (value) {
        // case Shape s -> "shape";
        // 先頭に書くと後続を支配し
        // "this case label is dominated by a preceding case label"
        // でコンパイルエラーになる
        case Shape.Circle c -> "circle";
        case Shape.Rect r -> "rect";
        case Shape.Group g -> "group";
    };
}
```

### enum 定数との併用

Java 21 は修飾付きの enum 定数もラベルに許します。enum を sealed 階層へ組み込めば、定数と構造を1つの分岐表に並べられます。

```java
sealed interface Signal permits Level, Analog { }
enum Level implements Signal { LOW, HIGH }
record Analog(double volt) implements Signal { }

static String describe(Signal s) {
    return switch (s) {
        case Level.LOW -> "low";
        case Level.HIGH -> "high";
        case Analog(double v) -> "analog " + v;
    };
}
```

### 書き換えが1つだけ変えてしまうもの

ここは立ち止まる価値があります。単なるリファクタリングに見えるものの内側に、本物の挙動差が隠れているからです。

リポジトリには、if 連鎖と `switch` が全ての入力で一致することを確かめるテストがあります。1つを除いて一致します。

```java
InstanceofPattern.describe(null)  // "unknown"
SwitchPattern.describe(null)      // NullPointerException を投げる
```

連鎖は2節の通り素通りします。`switch` はラベルを見る前に投げます。`default` も助けになりません。`default` が拾うのはラベルまで届いた値であり、`null` はそこまで到達しないからです。

つまり `instanceof` 連鎖を `switch` へ書き換えると、これまで処理できていた値が例外に変わり得ます。警告もなく、呼び出し側の見た目も変わりません。それが8節の話です。

## 6. record パターンと入れ子

参照するファイルは `features/RecordPattern.java` です。

型パターンは値の全体を束縛し、アクセサ呼び出しはこちらに任されます。record パターンは成分を直接束縛します。形を調べているその場で形を記述でき、本体で解きほぐす必要がありません。

```java
case Shape.Circle(Shape.Point(var x, var y), var r) -> "circle (" + x + "," + y + ") r=" + r;
```

2段の深さを1つのラベルで扱い、点のための中間変数も要りません。

`var` は成分の宣言型を推論します。型を書き下した場合は**キャストではありません**。それはさらなる検査であり、一致しなければそのアームは飛ばされます。この区別が、次の例の `case Box(String s)` を意味のあるものにします。

### 分解が実際に行うこと

分解はアクセサを宣言順に呼びます。フィールド読み出しではなくアクセサ呼び出しです。多くの場合この違いは表に出ません。アクセサを上書きする record は珍しいからです。上書きされていれば、パターンは忠実にその上書きを呼びます。アクセサが暴れたときの代償は9節で見ます。

### ジェネリクス

成分の型は選択子から推論されます。

```java
static String unwrapString(Box<String> box) {
    return switch (box) {
        case Box(String s) -> s;
    };
}
```

`default` はなく、必要もありません。選択子が `Box<String>` である以上、`Box(String s)` はそこに入り得る全ての値を覆います。仮引数を `Box<?>` に変えると、同じラベルは失敗し得る本物の検査に変わり、switch には仲間が要ります。

```java
case Box(String s)  -> "string " + s;
case Box(Integer i) -> "int " + i;
case Box(Object o)  -> "other " + o;
```

同じ構文で意味が違います。決めているのは、選択子の型引数が何を固定しているかだけです。

## 7. when ガード

参照するファイルは `features/Guard.java` です。

パターンが問えるのは形だけです。「円である」はパターンですが、「半径が10より大きい円である」はパターンではありません。残りを供給するのが `when` です。

```java
case Shape.Circle c when c.radius() > 10 -> "big circle";
case Shape.Circle c                      -> "small circle";
```

ここから2つの帰結が続きます。どちらもつまずきやすい場所です。

**ガード付きのアームは網羅性に数えられません。** コンパイラは条件を評価できないため、そのアームが飛ばされる可能性を前提に置くしかありません。だから後続のどれかが値を受け取れる必要があります。実務ではサブタイプごとにガードなしのアームを1つ残すという形になり、上の例で `Circle` のアームが2つある理由もそこにあります。

**順序が、素のパターン以上に効きます。** 同じパターンでガードだけが違うアームは両方とも到達可能で、ガードが最初に成立したほうが勝ちます。

```java
case Shape.Circle c when c.radius() > 100 -> "huge";
case Shape.Circle c when c.radius() > 10  -> "large";
case Shape.Circle c                       -> "small";
```

先頭2つを入れ替えると、100を超えるものまで `"large"` として出てきます。しかも何の苦情もありません。到達不能な*パターン*は5節の通り拒否されますが、ガードはコンパイラにとって不透明です。`> 100` が `> 10` を含意することは見えません。重なり合うガードは、この設計の中で唯一、上から順に読んで気を付ける必要がある場所です。

### `&&` は誤った演算子で、かつては正しい演算子だった

Java 17 のプレビューでは、ガードは `&&` で書いていました。

```java
case Shape.Circle c && c.radius() > 10 -> "big circle";   // Java 17 のプレビュー限定
```

`when` が置き換えたのは Java 19 (JEP 427) です。JDK 25 で `&&` 形式は解析できず、`: or -> expected` で失敗します。診断はガードについて何も言いません。

これを歴史としてではなく覚えておく価値があります。人が手を伸ばすのがまさにこの形だからです。`&&` は既に「かつ」の演算子で、ガードは見るからに「かつ」であり、2節では `&&` の右辺で束縛が使えると説明したばかりです。手が伸びるのは自然な動きで、実際この記事の例を書く最中にも起きました。

## 8. case null

参照するファイルは `features/NullCase.java` です。

`switch` は導入以来ずっと、選択子が `null` なら例外を投げてきました。ラベルが定数だけの時代には筋が通っていました。`null` はどの定数とも等しくなく、できることもなかったからです。しかしパターンマッチングとは相性が悪くなります。どれかのアームが受け取ってくれる、というのが自然な期待だからです。

挙動そのものを変えると既存のコードが壊れます。そこで Java 21 は条件付きにしました。**`switch` が `null` で投げるかどうかは、`case null` があるかどうかで決まります。** なければ従来通り投げます。あれば `null` はそのアームへ行きます。

```java
case null -> "nothing";
```

`default` はそのアームではありません。`default` はラベルまで届いた値を拾いますが、`null` は届きません。「null を含めた全て」と言いたいなら、1つのアームに両方書きます。

```java
case null, default -> "anything else";
```

### 全体パターンでも救われない

ここは、そんなはずはないと思える箇所です。

```java
static String totalPatternStillThrowsOnNull(Object value) {
    return switch (value) {
        case Object o -> "matched " + o;
    };
}
```

`case Object o` があれば、`default` なしでこの switch は網羅的です。あらゆる参照は `Object` だからです。それでも `null` は投げます。

規則が見ているのは*パターン*であって、被覆ではありません。型パターンは `instanceof` を問い、何物も何かのインスタンスではありません。したがって `case Object o` が `null` に一致しないのは `case String s` と同じです。「判定基準は被覆ではない」と捉え直せば驚きは消えますが、最初の遭遇はやはり面食らいます。

### どちらのラベルもガードできない

```java
case null when strict -> ...    // 拒否される
default when strict   -> ...    // 拒否される
```

どちらも `guards are only allowed for case with a pattern` で失敗します。ガードはパターンを狭める道具です。`null` と `default` のどちらもパターンに当たりません。条件付きの null 分岐が必要なら、switch の手前で処理してください。

## 9. 網羅性と MatchException

参照するファイルは `features/Exhaustiveness.java` です。

ここが、他の全てを正当化する節です。

switch 式は全ての入力に対して値を作らなければならず、したがって網羅的である必要があります。sealed 型が相手なら、コンパイラは3節の許可済みサブタイプを数え上げて証明します。`area` に `default` が要らないのはそのためです。

`default` を省くのは、きれい好きだからではありません。**`default` のアームは、後から追加されたサブタイプを黙って吸い込みます。** `default` がなければ、サブタイプの追加は直すべき switch 全てでビルドを壊し、その一覧が手に入ります。型を封印して得られる見返りはこれが全てで、反射的に書いた `default -> throw new IllegalStateException()` の一行で失われます。

同じ論法は13節の `Json` にも効きます。そこではスカラーの場合を対象にした switch 文が、`default -> {}` ではなく場合を書き下しています。

```java
case Json.JNull(), Json.JBool(_), Json.JStr(_) -> {
    // ここに数値は来ない。そう書くほうが default より良い。
    // default は後から追加されたノード型まで飲み込んでしまう
}
```

### MatchException

証明が成り立つのはコンパイル時です。実行時に食い違った場合のために、Java 21 は `java.lang.MatchException` を追加しました。`@since 21` であることは、JDK 25 同梱の `src.zip` で確認しています。

よくある説明は分割コンパイルです。サブタイプ3つの階層に対してコンパイルした switch を、4つに再コンパイルした階層に対して実行する、というものです。実際に起こり得ますが仕込むのが面倒で、この例外が一生出会わない珍種のように響いてしまいます。

もう1つの経路があり、そちらはありふれています。分解はアクセサを呼びます。アクセサはメソッドです。メソッドは例外を投げます。

```java
public record Exploding(int value) {
    @Override public int value() { throw new IllegalStateException("accessor blew up"); }
}
```

```java
case Exploding(int v) -> "exploding " + v;      // MatchException を投げる
case Exploding e      -> "exploding, not read"; // 問題なし
```

`IllegalStateException` は外へ出ません。`MatchException` に包まれます。呼び出し側から見て失敗したのは照合そのものであり、どれかのアームの本体ではないからです。元の例外は cause として保持されます。

このアームの対は、6節の主張に対する最も明快な実演にもなっています。アクセサを呼ぶのは分解形式だけです。同じ record への型パターンは成分を求めないので、例外も飛びません。

## 10. 名前なしパターン `_`

参照するファイルは `features/UnnamedPattern.java` です。

分解は全ての成分の始末を要求します。要らない成分も含めてです。名前を付けるのは雑音であり、雑音より悪くもあります。もっともらしい名前は、存在しない用途を読み手に探させるからです。

```java
case Shape.Circle(_, var r) -> "r=" + r;
```

成分に名前を付けて無視する場合との実質的な違いは、`_` が何も宣言しない点にあります。だから同じパターンの中に何度でも書けます。

```java
case Shape.Rect(Shape.Point(var x, _), _, _) -> "rect x=" + x;
```

捨てるものが3つ、でっち上げた名前はゼロです。ここで効くのが `x` だけであることも一目で分かります。

record パターンは1つも束縛せずに書けます。その場合は純粋な形の検査になります。`case Shape.Circle(_, _)` と `case Shape.Circle c` は同じ値を受け付けます。前者は分解する分だけ高くつくので、選択は挙動ではなく意図の問題です。

### パターンの外の同じ記号

`_` は、ローカルを宣言して読まない場所であればどこでも使えます。`catch` の仮引数、`for` の変数、ラムダの仮引数、try-with-resources の資源です。

```java
try { return Integer.parseInt(text); }
catch (NumberFormatException _) { return fallback; }
```

これらはパターンではありません。同じリリースで届いたのは、同じ不満に答えるからです。Java は用のないものにまで名前を付けさせていました。

この記事で唯一、Java 21 と Java 25 のどちらにも属さない機能です。正式化は **Java 22** で、`--release 21` ではコンパイルできません。

## 11. プリミティブ型パターン (プレビュー)

参照するファイルは `features/PrimitivePattern.java` です。

ここまでは全て正式機能です。この節は違います。JEP 507 は Java 25 で**3度目のプレビュー**であり、コンパイル時と実行時の両方で `--enable-preview` を必要とします。

これまでパターンが扱えたのは参照型だけでした。`case Integer i` は書けても `case int i` は書けません。その隙間は、パターンが `int` と言えないという理由だけでボックス型が switch に現れる、という形で表面化していました。

面白い問いは、プリミティブ型パターンが何を*意味する*のかです。参照型のパターンは `instanceof` を問います。プリミティブにそういう問いはないので、相似なものを問います。すなわち**この値をその型で損失なく表現できるか**です。

そのため、これは範囲検査になります。

```java
static boolean fitsInByte(int value) { return value instanceof byte; }

fitsInByte(100)  // true
fitsInByte(300)  // false
```

同じ変数、同じ宣言型で、答えが違います。言われてみれば当然ですが、押さえておく価値はあります。参照とプリミティブのどちら側にいるかで、`instanceof` は関連しつつも別の意味を持つからです。

期待通りに組み合わさります。

```java
return switch (value) {
    case byte b  -> "byte " + b;
    case short s -> "short " + s;
    case int i   -> "int " + i;
};
```

狭いものが先です。理由は他のパターンの順序と同じで、`byte` に収まる値は全て `short` にも収まるからです。

小さな帰結が2つ落ちてきます。`int` の選択子に対する `case int i` は**全体**アームなので、`default` なしで網羅的になります。プリミティブに対する全体アームは、これまで書きようがありませんでした。もう1つ、`Object` を対象にした switch でプリミティブと参照のパターンは共存し、書いた順に試されます。

```java
case Integer i when i > 100 -> "big boxed " + i;
case int i                  -> "int " + i;
case double d               -> "double " + d;
```

`case int i` はボックス型の `Integer` をアンボックスして一致させます。そして上のガード付き参照アームは、ガードが成立する限り依然として勝ちます。参照パターンが一律に優先されるわけではなく、アームは書いた順に試されます。

## 12. 実践: 式の評価器

参照するファイルは `usecase/ExprEval.java` です。

これはパターンマッチングが狙って設計された形そのものです。閉じたノード型の集合、その上の場合分けで定義される関数、子ごとに1回の再帰呼び出しという形です。

Java にはこれまで3つの答えがあり、最初の2つは良くありませんでした。

**キャスト付きの `instanceof` 連鎖。** 動きますし、たいていのコードはこうでした。

```java
if (expr instanceof Expr.Add) {
    Expr.Add add = (Expr.Add) expr;
    return evalLegacy(add.left(), env) + evalLegacy(add.right(), env);
}
...
throw new IllegalStateException("unreachable, but the compiler cannot know that");
```

どの分岐も型を2回書き、再帰はキャストの内側に埋もれ、メソッドは決して発火しない `throw` で終わります。最後の行が証拠です。この行は、行き場のない事実の置き場所として存在しているだけです。

**Visitor パターン。** 完全性は回復しますが、代償としてコードが裏返ります。関数はクラス上のメソッドへ散らばり、新しい操作のたびにクラスを1つ書くことになり、再帰は `accept` の内側へ隠れます。いまや `switch` が直接与えてくれる性質を取り戻すには、儀式が多すぎます。

**パターン。**

```java
return switch (expr) {
    case Expr.Num(int value)             -> value;
    case Expr.Var(String name)           -> lookup(name, env);
    case Expr.Neg(Expr operand)          -> -eval(operand, env);
    case Expr.Add(Expr left, Expr right) -> eval(left, env) + eval(right, env);
    case Expr.Mul(Expr left, Expr right) -> eval(left, env) * eval(right, env);
};
```

各分岐が選択肢であると一目で分かります。被演算子はラベルで分解されるので、再帰が再帰として読めます。`default` と到達不能な `throw` はどちらもありません。`Expr` が sealed なので、その不在は約束になります。ノード型を追加すれば、これはコンパイルを通らなくなります。

### 入れ子が効いてくる場所

定数畳み込みは、record パターンが便利であることをやめて表現力になる場所です。

```java
case Pair(Expr.Num(int a), Expr.Num(int b)) -> new Expr.Num(a + b);
case Pair(Expr.Num(int a), Expr r) when a == 0 -> r;
case Pair(Expr l, Expr.Num(int b)) when b == 0 -> l;
case Pair(Expr l, Expr r) -> new Expr.Add(l, r);
```

4行に4つの代数規則が、紙に書くときの形に近いまま1回ずつ述べられています。「リテラル同士の加算はリテラル」「左に0を足すのは恒等」といった具合です。最初の1行だけでも、旧来版ならキャスト4つと入れ子の `if` 2つになり、規則はもう見えません。

ガードも見どころです。0や1は形ではないので、どんなパターン言語でもこれらの恒等式は表現できません。必要なのは任意のコードであり、`when` は普通の Java にそれを供給させます。パターン言語の側が0という概念を持つ必要はありません。

### 主張ではなく検査にする

リポジトリには両方の実装が残してあり、式の集合に対して一致することをテストが確かめます。「等価だが短い」は主張ではなく検査の対象です。

主題に関わらず真似する価値のあるテストがもう1つあります。

```java
assertEquals(eval(expr, env), eval(simplify(expr), env));
```

簡約は値を変えてはいけません。定数畳み込みが実際に主張しているのはこの性質です。そして例示ベースのテストでは捕まらない形で誤った畳み込みを書くのは、とても簡単です。

## 13. 実践: JSON を歩く

参照するファイルは `usecase/JsonWalk.java` です。

12節は都合の良い側の例でした。全てのノードが record なので、どの段でも分解できます。JSON は正直な側です。

```java
public sealed interface Json {
    record JNull() implements Json {}
    record JBool(boolean value) implements Json {}
    record JNum(double value) implements Json {}
    record JStr(String value) implements Json {}
    record JArr(List<Json> elements) implements Json {}
    record JObj(Map<String, Json> members) implements Json {}
}
```

容器が抱えるのは `List` と `Map` です。これらは record に当たりません。そのため record パターンは容器まで届いた時点で分解する相手を失います。配列の3番目の要素まで分解で辿り着く道はありません。

これが普通の状況なので、この点は重要です。現実のデータモデルの多くで、端だけが record であり、中間はコレクションになります。式の木しか見せない記事は、パターンマッチングはコンパイラ向けのものだという印象を残します。

これは失敗ではありません。結果として、パターンは振り分けを担って後を渡します。

```java
case Json.JStr(String value) -> "\"" + value + "\"";
case Json.JArr(List<Json> elements) ->
    elements.stream().map(JsonWalk::render).collect(joining(",", "[", "]"));
```

スカラーのアームは分解し、容器のアームはコレクションを束縛して普通のストリームのコードへ続きます。1つの `switch` に両者が混ざった形は、どちらか片方だけの場合より読みやすくなります。継ぎ目が隠れずに見えている点も良さです。

### 持ち帰る価値のある書き方

JSON には式の木にない場合があります。例外ではなく「見つからない」を返すべき問い合わせです。ここでパターンは `Optional` とよく噛み合います。一致しないアームは、まさに返すものがないアームだからです。

```java
public static Optional<String> stringAt(Json json, String dotted) {
    return path(json, dotted).flatMap(found -> switch (found) {
        case Json.JStr(String value) -> Optional.of(value);
        default -> Optional.empty();
    });
}
```

`flatMap` の中に `switch` があります。パターンが型検査と取り出しを1手で済ませるので、キャストも前置きの `instanceof` もありません。外れ方は3通りあります。オブジェクトでない場合、キーがない場合、末端の型が違う場合です。どれも空の `Optional` として返ります。入れ子の `if` はどこにもありません。

switch に*していない*ものにも注目してください。`path` は素の `for` ループで各区切りを辿ります。パターンが得意なのは「このノードは何か」であって、経路の走査はその問いではありません。無理に `switch` へ押し込めば、コードは悪くなります。

## 14. Java 25 の手触り: モジュールインポートと簡潔なソースファイル

参照するファイルは `features/ModuleImport.java` と `samples/` です。

どちらもパターンマッチングではありません。それでもここに置くのは、短い例の見た目を変えるからです。そして短い例こそ、言語機能が人に届く経路です。

`import module java.base;` は、そのモジュールがエクスポートする全パッケージの公開 API を取り込みます。`List`、`Map`、`Optional` といった型が1行で揃い、例が育つほど伸びるインポートの塊は消えます。package 宣言のある普通のクラスを含め、どこでも使えます。唯一の代償は曖昧さです。`List` をエクスポートするモジュールを2つ取り込むと、単一型インポートで決着を付けるまで名前は曖昧なままです。

簡潔なソースファイルはさらに進みます。以下は完結した実行可能プログラムです。

```java
import module java.base;

sealed interface Shape {
    record Point(double x, double y) {}
    record Circle(Point center, double radius) implements Shape {}
    record Rect(Point topLeft, double width, double height) implements Shape {}
    record Group(List<Shape> members) implements Shape {}
}

String describe(Shape shape) {
    return switch (shape) {
        case Shape.Circle(Shape.Point(var x, var y), var r) when r > 10 -> "big circle at (" + x + "," + y + ")";
        case Shape.Circle(_, var r) -> "circle r=" + r;
        case Shape.Rect(_, var w, var h) when w == h -> "square " + w;
        case Shape.Rect(_, var w, var h) -> "rect " + w + "x" + h;
        case Shape.Group(var members) -> "group of " + members.size();
    };
}

void main() {
    var origin = new Shape.Point(0, 0);
    List<Shape> shapes = List.of(new Shape.Circle(origin, 1), new Shape.Circle(origin, 99),
            new Shape.Rect(origin, 2, 2), new Shape.Rect(origin, 2, 3),
            new Shape.Group(List.of(new Shape.Circle(origin, 1))));

    shapes.stream().map(this::describe).forEach(IO::println);
}
```

```console
$ java samples/ShapeMatch.java
circle r=1.0
big circle at (0.0,0.0)
square 2.0
rect 2.0x3.0
group of 1
```

package 宣言は要りません。インポートの塊も不要です。クラス宣言と `public static void main(String[])` は書きません。ビルドツールを使わず、コンパイル手順も踏みません。プレビューフラグも要りません。ここで使っているものは、1つ残らず Java 25 で正式だからです。`IO.println` も新顔で、`java.lang.IO` は `@since 25` です。

### 誰も触れない制約

簡潔なソースファイルは **package 宣言を持てません**。

```text
error: compact source file should not have package declaration
```

したがって常に無名パッケージにいます。パッケージ付きのソースツリーの中には置けず、テストのソースセットからインポートもできません。このリポジトリで `samples/` が Gradle の外に置いてある理由もそこにあります。代わりに、サブプロセスとして実行し出力を比較するテストを用意しました。そうしないと「単体で実行できる」という主張だけが、誰も検査していない項目になってしまいます。

`javac` でコンパイルすると正体が見えます。内側で宣言した型は `ShapeMatch$Circle.class` などとして出てきます。ファイル名に由来する暗黙のクラスのメンバーです。

## 結局どうなったのか

機能の一覧として読むと、これは長くてやや恣意的な並びです。1つの変化として読むと短くなります。

Java はずっと、正しさがあなただけの知識に依存するコードを書かせてきました。検査と対応するキャスト。全ての場合を覆っている連鎖。このメソッドも直すこと、というコメント。タイムラインにある機能はどれも、そのうち1つを取り上げてコンパイラが持つものへ変えています。

最良の証拠は、消えたもののほうです。12節の if 連鎖は決して実行されない `throw` で終わっていました。あれは防御的プログラミングではありません。行き場のない事実を置くための仮置き場でした。封印が事実に居場所を与え、その行は消えます。より短い行に置き換わったからではなく、必要でなくなったからです。

気を付ける場所は2つで、どちらもこの記事の中にあります。重なり合うガードはコンパイラにとって不透明なので、7節では上から順に読む世界に戻ります。そして `instanceof` 連鎖を `switch` へ書き換えると `null` の扱いが黙って変わります。ここで唯一、挙動を保存しないリファクタリングです。

## 例を実行する

```console
nix develop
gradle test
java samples/ShapeMatch.java
```

環境について3点、いずれも見つけるのに時間を使いました。

**nixpkgs の `gradle` は 8.14.4 で、Java 25 のツールチェーンを解決できません。** `gradle_9` (9.7.1) が必要です。これはプロジェクトの構成段階で失敗しますが、メッセージは Gradle のバージョンではなくツールチェーンについて語ります。

**`--enable-preview` はコンパイル時と実行時の両方で必要です。** Gradle では `JavaCompile.options.compilerArgs` *と* `Test.jvmArgs` の両方を意味します。片方だけ設定すると、コンパイルは通って起動で落ちるビルドができあがります。

**jdtls は Java 25 のプロジェクトでプレビュー機能を有効にせず、設定で回避もできません。** `JVMConfigurator.configureJVMSettings` がプレビューを有効にする条件は1つです。プロジェクトの Java バージョンが `JavaCore.latestSupportedJavaVersion()` 以上であることです。それ以外では `disabled` を書き込みます。同梱の JDT 3.46.100 に対して直接呼ぶと、この最新バージョンは **26** でした。つまり `compareJavaVersions("25", "26")` は `-1` となり、答えは常に `disabled` です。`.settings/org.eclipse.jdt.core.prefs` に設定を書いてコミットしても残りません。jdtls はプロジェクト構成のたびにこのキーを書き換えます。

実務上の帰結はこうです。エディタはプレビュー構文にエラーを出し、`gradle test` は緑になります。信じるべきはビルドのほうです。両者はクラスファイルで見分けられます。Gradle はマイナーバージョン 65535 を、jdtls は 0 を出力します。

同じファイルが教えてくれることがもう1つありますが、こちらは無害です。jdtls は Gradle Tooling API 8.9 を同梱するので、devShell がどの Gradle を提供しても `.settings` には Gradle 8.9 と記録されます。依存関係の解決は問題なく動くので、これは見た目だけの話です。
