---
title: "3.6. Coercions"
---

LeanにおけるCoercion(暗黙型変換みたいなやつ)に関する説明。

## 3.6.1. Strings and Path

以下の例において、`IO.FS.readFile`[^1]は`fname : System.FilePath`を要求するが、渡されているのは`String`型である。
ここでは`String`から`System.FilePath`型へのCoercionが行われている。
匿名コンストラクタなどを使って`⟨f⟩`などと書く必要もない。

```lean
def fileDumper : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  stdout.putStr "Which file? "
  stdout.flush
  let f := (← stdin.getLine).trimAscii.copy
  stdout.putStrLn s!"'The file {f}' contains:"
  stdout.putStrLn (← IO.FS.readFile f)
```

## 3.6.2. Positive Numbers

3.1節で定義した`Pos`を`Nat`が期待される位置に書いたとき、`Nat`に変換されると嬉しい。

```lean
/--
info: Application type mismatch: The argument
  2
has type
  Pos
but is expected to have type
  Nat
in the application
  List.drop 2
---
info: List.drop sorry [1, 2, 3, 4] : List Nat
-/
#guard_msgs in
#check_failure [1, 2, 3, 4].drop (2 : Pos)
```

`drop`は`Nat`型を期待するので、`Pos`型の値をここに入れることはできない。
`Pos`型の値を`Nat`型にcoerceするには[Coe](https://lean-lang.org/doc/reference/4.26.0/Coercions/#Coe___mk)インスタンスを定義する必要がる。

```lean
/-- info: Coe.coe.{u, v} {α : semiOutParam (Sort u)} {β : Sort v} [self : Coe α β] : α → β -/
#guard_msgs in
#check Coe.coe

instance : Coe Pos Nat where
  coe x := x.toNat
```

`Nat`型が期待されている場所に`Pos`型の値があるとき、`Coe.coe`が定義されていることが、暗黙的な型変換を可能にする。

```lean
#guard [1, 2, 3, 4].drop (2 : Pos) = [3, 4]
```

`#check`コマンドを使うことで、`Coe.coe`メソッドに定義した`Pos.toNat`の変換が働いていることを確認できる。

```lean
/-- info: List.drop (Pos.toNat 2) [1, 2, 3, 4] : List Nat -/
#guard_msgs in
#check [1, 2, 3, 4].drop (2 : Pos)
```

## 3.6.3. Chaining Coercions

### coercionの伝搬

$\alpha, \beta, \gamma$を型とする。$\beta \rightarrow \gamma$のcoercionが定義されているとき、$\alpha \rightarrow \beta$へのcoercionを定義すると、$\alpha \rightarrow \gamma$のcoercionを行うことができるようになる。

例として、`Nat`は`Int`にcoerceできるので`Pos`からも変換可能となる。

```lean
def oneInt : Int := Pos.one

/--
info: def «3.6. Coercions».oneInt : Int :=
↑Pos.one.toNat
-/
#guard_msgs in
#print oneInt
```

ここで`↑`は`Coe.coe`の構文糖であり、特にここでは`Nat`から`Int`への変換を指している。

```lean
/-- info: fun [Coe α β] x => Coe.coe x : [Coe α β] → α → β -/
#guard_msgs in
#check ((↑ ·) : [Coe α β] → α → β)
```

### `Option`型のcoercion

Leanの標準ライブラリは`Option α`型から`α`型へのcoercionを定義している。
例えば、`List.last?`として、Listの最期の要素を取り出す関数を返す関数を定義してみる。空リストの場合は返すものがないので、結果の型は`Option`に包むのが自然だろう。

```lean
def List.last? : List α → Option α
  | [] => none
  | [x] => x
  | _ :: x :: xs => last? (x :: xs)
```

`[x] => x`と書かれている部分は、本来`Option α`型が期待されるため、本来入るのは`[x] => some x`だが、coercionが働くので`x`と書くだけでよい。

[^1]: https://lean-lang.org/doc/reference/4.26.0/IO/Files___-File-Handles___-and-Streams/#IO___FS___readFile
