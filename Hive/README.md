

# 语法

## Lateral View

关键点：本质上是变形后的表t2与原表t1进行**left join**，select时可直接用t1和t2取各自的字段

1.若干字段一起拆分，字段平铺，复制一行再反转，一行变多行，如下表，左侧一行变成右侧两行

| col1 | col2 | col11 | col12 | col21 | col22 |
| :-: | :-: | :-: | :-: | :-: | :-: |
| aa##bb | 11@@22 | aa | bb | 11 | 22 |
| | | bb | aa | 22 | 11 |

```sql
select t1.col0,
	t2.col11,
	t2.col12,
	t2.col21,
	t2.col22
from (
	select col0,
		split(col1, '，') as col1,
		split(col2, '，') as col2
	from app.app_kg_dapei_pw
	where pt=2
) t1
lateral view inline(array(
	struct(col1[0], col1[1], col2[0], col2[1]),
	struct(col1[1], col1[0], col2[1], col2[0])
)) t2 as col11, col12, col21, col22
;
```

# 架构

