create table T_CRAWL_M_SITE_TYPE
(
   SITE_TYPE_ID         int not null comment '站点类型编号',
   SITE_TYPE_NAME       varchar(64) not null comment '站点类型名称',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (SITE_TYPE_ID)
);

alter table T_CRAWL_M_SITE_TYPE comment '站点类型';