# HiveSQL 语法 Demo

## UDTF & lateral view

UDTF 可单独使用，lateral view 一般和 UDTF 一起使用。

**Reference**: 

- UDTF: <https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF#LanguageManualUDF-Built-inTable-GeneratingFunctions(UDTF)>
- lateral view: <https://cwiki.apache.org/confluence/display/Hive/LanguageManual+LateralView>

讲真，没有比官网更清晰更详细的demo了！

### UDTF

Reference 写得非常详细了，这里不粘贴复制了，没啥意义，总结一些官网没重点强调的。

| UDTF | 列变化 | 行变化 |
| :-: | :-: | :-: |
| explode(ARRAY\<T\> a) | 1列变1列 | 1行变多行：a中每个元素都是1行 |
| explode(MAP\<T\_key, T\_val\> m) | 1列变2列：key和val | 1行变多行：m中每个key-val对都是1行 |
| posexplode(ARRAY\<T\> a) | 1列变2列，比explode多一列：index in ARRAY | 1行变多行，同explode |
| inline(ARRAY\<STRUT\<f1:T1,...,fn:Tn\>\> a) | 1列变n列：f1,f2,...,fn | 1行变多行：a中每个STRUCT都是1行 |
| stack(int r, <br>T1 v11, T2 v12, ..., Tn v1n, <br>T1 v21, T2 v22, ..., Tn v2n, <br>...<br>T1 vr1, T2 vr2, ..., Tn vrn) | 1列变n列：T1,T2,...,Tn | 1行变r行：stack中除r外每n个元素为一行 |

### lateral view

咱们先来瞅一瞅官网上的 Description:

> Lateral view is used in conjunction with UDTF functions such as explode(). A UDTF generates zero or more output rows for each input row. A lateral view first applies the UDTF to each row of base table and then joins resulting output rows to the input rows to form a virtual table having the supplied table alias.

大白话就是，lateral view 干以下3件事情：

- 在 base table (记为 t1 )上应用 UDTF 函数，产生中间结果(记为 t2 )
- 把 t1 和 t2 join 在一起（问：用于 join 的 key 是啥？官网没说，尧哥猜测是 base table 中每 row 的 row_id 之类的）
- join 在一起后，可使用 t1 和 t2 这些别名来表示相关的字段，以进行后续操作

### Demo

- 若干字段一起拆分，字段平铺，复制一行再反转，一行变多行，如下表，左侧一行变成右侧两行

	| col1 | col2 | col11 | col12 | col21 | col22 |
	| :-: | :-: | :-: | :-: | :-: | :-: |
	| aa##bb | 11@@22 | aa | bb | 11 | 22 |
	|  |  | bb | aa | 22 | 11 |

	```sql
	select t1.col0,
		t2.col11,
		t2.col12,
		t2.col21,
		t2.col22
	from (
		select col0,
			split(col1, '##') as col1,
			split(col2, '@@') as col2
		from tablexxx
		where xxx
	) t1
	--以下方法1与方法2功能相同，任选其一即可

	--方法1：使用inline
	lateral view inline(array(
		struct(col1[0], col1[1], col2[0], col2[1]),
		struct(col1[1], col1[0], col2[1], col2[0])
	)) t2 as col11, col12, col21, col22

	--方法2：使用stack
	lateral view stack(2,
		col1[0], col1[1], col2[0], col2[1],
		col1[1], col1[0], col2[1], col2[0]
	) t2 as col11, col12, col21, col22
	;
	```

- 行转列：各字段先变成array，然后再explode

	字段col1,col2,col3变成同一列col4，三行取值分别是col1,col2,col3

	```sql
	select t1.col0,
		t2.col4
	from tablex t1
	lateral view explode(array(col1, col2, col3)) t2 as col4;
	```