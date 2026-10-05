---
title: "Functional Programming in Leanの読書メモ(第3章)"
---

# Functional Programming in Lean (第3章)

https://lean-lang.org/functional_programming_in_lean/Overloading-and-Type-Classes

---

## 3. Overloading and Type Classes


### 3.5. Standard Classes


> This section presents a variety of operators and functions that can be
> overloaded using type classes in Lean. Each operator or function corresponds
> to a method of a type class. Unlike C++, infix operators in Lean are defined
> as abbreviations for named functions; this means that overloading them for
> new types is not done using the operator itself, but rather using the
> underlying name (such as HAdd.hAdd).

意訳(かきかけ):

型クラスによってオーバーロードされた演算子や関数を照会する。 各演算子や関数は型クラスのメソッドに対応するものである。 C++などとは異なり、Leanにおける中置演算子は関数の別の記法(abbreviation)として定義されているので、 新しい型に対する演算子のオーバーローディングを定義することは、abbreviationの元になった関数に 対して定義することによって達成される。例えば、`+`は`HAdd.hAdd`のabbreviationだが、Overloadingの 定義の軸になるのは`HAdd.hAdd`である。

---

#### 3.5.1. Arithmetic

多くのarithmetic operatorsはHeterogeneous formを持っている。Heterogeneous operatorを考えるとき、対応するHomogeneous operatorが考えられて、`h`を抜いた形で表される(e.g. `HAdd.hAdd` → `Add.add`)。

---

#### 3.5.2. Bitwise Operators

bitwise operatorたちは`UInt8`, `UInt16`, `UInt32`, `UInt64`, `USize` などのインスタンスを持つ。

例として、bitwise andは`x &&& y`で、`HAnd.hAnd`が関数名。
ただし、homogeneousバージョンでは`And`と`Or`は予約語のため、`AndOp`、`OrOp`という名前が使われる。

---

#### 3.5.3. Equality And Ordering

等価判定と順序判定について。

##### Equality

`BEq` (Boolean Equality) クラスが使われる。Leanは定理証明支援系なので、Equalityには2つの種類がある。

- Boolean Equality
- Propositional Equality

Leanにおいては`==` は`BEq.beq`の略記である。

---

## 残タスク

prerequisites用のソースコードとか、各節で追加するソースコードとかの例を貼っつけたいな。
それだけで大分読めるようになりそう。
-  [ ] ライセンスとかを調べる
  必要だけど、自分用にまとめるのが主なので公開したくなったときで良いか




