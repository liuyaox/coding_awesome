

# 语法







### 

1. 横向重排：非空字段置前，附带上对应的附属字段

原数据：字段col1_id,col1_name,col2_id,col2_name,col3_id,col3_name,col4_id,col4_name,col5_id,col5_name 有先后顺序，id是键，对应着name，有些id取值为空的字段位于非空字段前面。

新数据：保持原字段顺序，非空字段置于空字段之间，要附带上id对应的name

```sql
select col0,
    elt(cast(indices[0] as int), col1_id, col2_id, col3_id, col4_id, col5_id) as col1_id,
    elt(cast(indices[0] as int), col1_name, col2_name, col3_name, col4_name, col5_name) as col1_name,
    elt(cast(indices[1] as int), col1_id, col2_id, col3_id, col4_id, col5_id) as col2_id,
    elt(cast(indices[1] as int), col1_name, col2_name, col3_name, col4_name, col5_name) as col2_name,
    elt(cast(indices[2] as int), col1_id, col2_id, col3_id, col4_id, col5_id) as col3_id,
    elt(cast(indices[2] as int), col1_name, col2_name, col3_name, col4_name, col5_name) as col3_name,
    elt(cast(indices[3] as int), col1_id, col2_id, col3_id, col4_id, col5_id) as col4_id,
    elt(cast(indices[3] as int), col1_name, col2_name, col3_name, col4_name, col5_name) as col4_name,
    elt(cast(indices[4] as int), col1_id, col2_id, col3_id, col4_id, col5_id) as col5_id,
    elt(cast(indices[4] as int), col1_name, col2_name, col3_name, col4_name, col5_name) as col5_name
from (
    select *,
        sort_array(array(
            if(isnotnull(col1_id), '1', '99'),
            if(isnotnull(col2_id), '2', '99'),
            if(isnotnull(col3_id), '3', '99'),
            if(isnotnull(col4_id), '4', '99'),
            if(isnotnull(col5_id), '5', '99')
        )) as indices                        --比如，'1','99','3','99','5' --> ['1','3','5','99','99']  表示非空字段的index
    from tablex 
    where coalesce(col1_id, col2_id, col3_id, col4_id, col5_id) is not null  --字段不能全是空
) a
```