---
title: luaの基本
---

## Luaの基本

### 変数

グローバル変数は、`変数名 = 値`の形で定義される。`local`を付けるとローカル変数を定義できる。

```lua
-- global variable
Global_var = "global"

local local_var = "local"

print("Global_var : " .. Global_var)
-- Global_var : global
print("local_var: " .. local_var)
-- local_var: local
```

### 暗黙の型変換

文字列連結演算子(`..`)では、数値(number)のみが自動的に文字列へと暗黙型変換される。
それ以外の型(`nil`、`table`、`boolean`など)については自動変換が行われず、実行時エラーになる。

```lua:examples/03_type_coercion.lua
print("12" .. nil)
-- attempt to concatenate a nil value

print("12" .. {})
-- attempt to concatenate a table value

print("12" .. true)
-- attempt to concatenate a boolean value

print("12" .. 12)
-- 1212
```

加算演算子(`+`)では、数値(number)および**数値に変換可能な文字列**が自動的に数値へと暗黙型変換される。
それ以外の型(`nil`、`table`、`boolean`、数値に変換できない文字列など)については自動変換が行われず、実行時エラーになる。

```lua:examples/04_arithmetic_coercion.lua
print("12" + nil)
-- attempt to perform arithmetic on a nil value

print("12" + {})
-- attempt to perform arithmetic on a table value

print("12" + true)
-- attempt to perform arithmetic on a boolean value

print("12" + "12")
-- 24

print("12" + 12)
-- 24
```

### テーブルの内部構造

テーブルの内部では、ハッシュテーブルと配列を組み合わせたハイブリッド構造が採用されている。この仕組みにより、配列アクセスと連想配列アクセスの双方向において、$O(1)$ の高速なパフォーマンスを実現している。

* **配列部**: `1, 2, 3, ...` といった連続した整数キーを効率的に格納し、インデックスアクセスを最適化する
* **ハッシュ部**: 上記以外のキー（文字列や不連続な値など）をハッシュテーブルで管理する

