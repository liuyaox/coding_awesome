set hive.auto.convert.join                   = true;
set mapred.job.priority                      = VERY_HIGH;
set mapred.output.compress                   = true;
set hive.exec.compress.output                = true;
set hive.default.fileformat                  = Orc;
set hive.exec.reducers.bytes.per.reducer     = 400000000;
set hive.exec.dynamic.partition.mode         = nonstrict;
set hive.exec.dynamic.partition              = true;
set hive.exec.max.dynamic.partitions         = 100000;
set hive.exec.max.dynamic.partitions.pernode = 100000;
set mapred.output.compression.codec          = com.hadoop.compression.lzo.LzopCodec;
set hive.input.format                        = org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
set hive.exec.parallel                       = true;
set hive.stats.dbclass                       = counter;     --降低文件数太对hdfs文件统计的压力和延迟

--粒度-日
insert overwrite table app.xxx partition(tp='day', dt='2018-05-23')
select 
    --部门&销售人员
    t1.dept_level,
    t1.bu_id,
    t1.bu_name,
    t1.dept_id_1,
    t1.dept_name_1,
    t1.dept_id_2,
    t1.dept_name_2,
    t1.dept_id_3,
    t1.dept_name_3,
    t1.oper_erp_id,
    t1.oper_name,
    
    --类目
    t1.cate_level,
    t1.cate1,
    t1.cate1_name,
    t1.cate2,
    t1.cate2_name,
    t1.cate3,
    t1.cate3_name,
    
    --成交指标
    t1.deal_plus_gmv,
    t1.deal_plus_vip_gmv,
    t1.deal_plus_ord_num,
    t1.deal_plus_vip_ord_num,
    t1.deal_plus_user_num,
    t3.deal_plus_user_new
from (
    select 
        case when conv(grouping__id, 10 ,2) in (0000110000001111, 0011110000001111, 1111110000001111) then 1
             when conv(grouping__id, 10, 2) in (0000110000111111, 0011110000111111, 1111110000111111) then 2
             when conv(grouping__id, 10, 2) in (0000110011111111, 0011110011111111, 1111110011111111) then 3
             else 100 
        end as dept_level,                  --部门级别
        concat(coalesce(dept_id_1, 'a'), '-', coalesce(dept_id_2, 'a'), '-', coalesce(dept_id_3, 'a')) as dept_str,    --用于与别的表成功join
        bu_id,
        bu_name,
        dept_id_1,
        dept_name_1,
        dept_id_2,
        dept_name_2,
        dept_id_3,
        dept_name_3,
        oper_erp_id,
        oper_name,
        
        case when conv(grouping__id, 10, 2) in (0000111111111111, 0000110011111111, 0000110000111111, 0000110000001111) then 1
             when conv(grouping__id, 10, 2) in (0011111111111111, 0011110011111111, 0011110000111111, 0011110000001111) then 2
             else 3 
        end as cate_level,                  --品类级别
        concat(coalesce(cate1, 'a'), '-', coalesce(cate2, 'a'), '-', coalesce(cate3, 'a')) as cate_str,    --用于与别的表成功join
        cate1,
        cate1_name,
        cate2,
        cate2_name,
        cate3,
        cate3_name, 
        
        sum(deal_gmv) deal_plus_gmv,
        sum(case when is_vip=1 then deal_gmv end) deal_plus_vip_gmv,
        count(distinct sale_ord_id) deal_plus_ord_num,
        count(distinct case when is_vip=1 then sale_ord_id end) deal_plus_vip_ord_num,
        count(distinct user_id) deal_plus_user_num
    from app.xxx2
    where dt='2018-05-23' 
    group by bu_id,
        bu_name,
        dept_id_1,
        dept_name_1,
        dept_id_2,
        dept_name_2,
        dept_id_3,
        dept_name_3,
        oper_erp_id,
        oper_name,
        cate1,
        cate1_name,
        cate2,
        cate2_name,
        cate3,
        cate3_name
    grouping sets(
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            oper_erp_id,oper_name,cate1,cate1_name,cate2,cate2_name,cate3,cate3_name),      --销售人员-3级类目 111111 111111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            oper_erp_id,oper_name,cate1,cate1_name,cate2,cate2_name),                       --销售人员-2级类目 001111 111111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            oper_erp_id,oper_name,cate1,cate1_name),                                        --销售人员-1级类目 000011 111111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            cate1,cate1_name,cate2,cate2_name,cate3,cate3_name),                            --3级部门-3级类目  111111 001111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            cate1,cate1_name,cate2,cate2_name),                                             --3级部门-2级类目  001111 001111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,dept_id_3,dept_name_3,
            cate1,cate1_name),                                                              --3级部门-1级类目  000011 001111 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,
            cate1,cate1_name,cate2,cate2_name,cate3,cate3_name),                            --2级部门-3级类目  111111 000011 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,
            cate1,cate1_name,cate2,cate2_name),                                             --2级部门-2级类目  001111 000011 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,dept_id_2,dept_name_2,
            cate1,cate1_name),                                                              --2级部门-1级类目  000011 000011 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,
            cate1,cate1_name,cate2,cate2_name,cate3,cate3_name),                            --1级部门-3级类目  111111 000000 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,
            cate1,cate1_name,cate2,cate2_name),                                             --1级部门-2级类目  001111 000000 1111
        (bu_id,bu_name,dept_id_1,dept_name_1,
            cate1,cate1_name))                                                              --1级部门-1级类目  000011 000000 1111
) t1

left outer join (
    select * from app.xxx3
    where tp='day' and dt='2018-05-23' 
        and brand_level=0            --部门+类目级别，而非品牌级别
) t3
on t1.dept_level=t3.dept_level
    and t1.dept_str=t3.dept_str
    and t1.cate_level=t3.cate_level
    and t1.cate_str=t3.cate_str
;