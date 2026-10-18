---
title: "Lean Proof"
---

Leanで自分で数学の証明を書きながら詰った部分のメモを書いていく。

### Neg型クラス

:::: details ℝのNegインスタンス

実数$\mathbb{R}$に対する`neg`みたいなものが定義されていないだろうかと思ったので、`#synth`で$\mathbb{R}$に対する`Neg`のインスタンスが作られていないかを調べることにした。

```lean
/-- info: Real.instNeg -/
#guard_msgs in
#synth Neg ℝ

/--
info: @[instance_reducible] def Real.instNeg : Neg ℝ :=
{ neg := Real.neg✝ }
-/
#guard_msgs in
#print Real.instNeg
```

Leanにおいて、ダガー`✝`のついた変数は使えないので、`-`でnegateするのが正解っぽい。
:::message
ところで、このようなダガー変数はどのように実装されているのだろうか?
:::

::::

### noncomputable

:::details noncomputable

```lean
def Cpx.inv (z : Cpx) : Cpx :=
  let r : ℝ := z.re * z.re + z.im * z.im
  ⟨z.re / r, - z.im / r⟩
```

$\mathbb{R}$における除算はnoncomputableで定義されているため、次のようなエラーが出る。

```
failed to compile definition, consider marking it as 'noncomputable' because it depends on 'Real.instDivInvMonoid', which is 'noncomputable'

Error code: lean.dependsOnNoncomputable
```

#### 対処方法

noncomputableを付ければ良い。

```lean
noncomputable def Cpx.inv (z : Cpx) : Cpx :=
  let r : ℝ := z.re * z.re + z.im * z.im
  ⟨z.re / r, - z.im / r⟩
```

noncomputableは[DecModifiers](https://lean-lang.org/doc/reference/4.35.0-rc3/Definitions/Modifiers/#declaration-modifiers)の一つで、DecModifierにはDocCommentなども含まれるらしい。
noncomputableに関しては[こちら](https://lean-lang.org/doc/reference/4.35.0-rc3/Error-Explanations/About___--dependsOnNoncomputable/#lean___dependsOnNoncomputable)を参照

:::
