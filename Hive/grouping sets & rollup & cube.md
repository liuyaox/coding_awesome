# HiveSQL 语法 Demo

## grouping sets & rollup & cube

**Reference**:

- Hive: <https://cwiki.apache.org/confluence/display/Hive/Enhanced+Aggregation%2C+Cube%2C+Grouping+and+Rollup>

### grouping sets

grouping sets 是一个很高效的工具，当用于分组的有多个 key，且这些 key 中需要有多种组合时，grouping sets 可把代码量节省为原来的1/2,1/3,1/4甚至是1/20，毫不夸张，我对着毛主席发誓！这样代码的可读性、可维护性、优雅性大大提升。

举例来说：某事业部 bu 下面有若干一级部门 dept1，各 dept1 下又有若干二级部门 dept2，各 dept2 下又有若干三级部门 dept3，各 dept3 下又有各销售人员 operr 来分别负责若干 sku。某天，老板说他想看看以下汇总数据：

- 总销量
- 各事业部每天的销量
- 各一级部门每天的销量
- 各二级部门总销量
- 各三级部门每天的销量
- 各销量人员总销量

不使用 grouping sets 的话，要写6份几乎相同的代码块，使用 grouping sets 的话，相同的逻辑完全只用写一次，各个级别的汇总数据可用 **grouping__id** (注意有2个下划线)来区分。分析过程如下表：

| 汇总数据 | bu | dept1 | dept2 | dept3 | operr | dt | 对应二进制 | 反向(grouping__id) |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| 总销量 | 0 | 0 | 0 | 0 | 0 | 0 | 000000 | 000000 |
| 各事业部每天的销量 | 1 | 0 | 0 | 0 | 0 | 1 | 100001 | 100001 |
| 各一级部门每天的销量 | 1 | 1 | 0 | 0 | 0 | 1 | 110001 | 100011 |
| 各二级部门总销量 | 1 | 1 | 1 | 0 | 0 | 0 | 111000 | 000111 |
| 各三级部门每天的销量 | 1 | 1 | 1 | 1 | 0 | 1 | 111101 | 101111 |
| 各销量人员总销量 | 1 | 1 | 1 | 1 | 1 | 0 | 111110 | 011111 |

> 注意！注意！grouping__id 是对应二进制的**反向(首尾颠倒)**

对应的代码如下：

```sql
select bu,
    dept1,
    dept2,
    dept3,
    operr,
    dt,
    case conv(grouping__id, 10, 2)   --转化为二进制，也可用十进制
        when 000000 then 0
        when 100001 then 1
        when 100011 then 2
        when 000111 then 3
        when 101111 then 4
        when 011111 then 5
    end as data_id,
    sum(sale_qtty) as sale_qtty
from tablexx
group by bu,
    dept1,
    dept2,
    dept3,
    operr,
    dt
grouping sets(
    (),                                 --000000
    (bu, dt),                           --100001
    (bu, dept1, dt),                    --100011
    (bu, dept1, dept2),                 --000111
    (bu, dept1, dept2, dept3, dt),      --101111
    (bu, dept1, dept2, dept3, operr)    --011111
);
```

更详细的示例代码请参考 [grouping_sets使用Demo.py](./grouping_sets使用Demo.py)

### rollup & cube

类似于 grouping sets，不过 rollup 和 cube 对于 key 规定好了固定的组合：

- rollup: **从右到左递减多级**的统计，显示统计某一层次结构的聚合

    若key是 a,b,c，则相当于 grouping sets 中的

    ```sql
    ...
    group by a,
        b,
        c
    --with rollup
    grouping sets(
        (),
        (a),
        (a, b),
        (a, b, c)
    )
    ```

- cube: 任意维度的查询，会统计所选列中值的**所有组合**的聚合

    若 key 是 a,b,c,则相当于 grouping sets 中的

    ```sql
    ...
    group by a,
        b,
        c
    --with cube
    grouping sets(
        (),
        (a),
        (b),
        (c),
        (a, b),
        (a, c),
        (b, c),
        (a, b, c)
    )
    ```


详情请参考上面的 Reference。