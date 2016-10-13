create table T_POM_S_STAT_SITE
(
   STAT_SEQ             bigint not null auto_increment comment '流水号',
   TYPE_ID              int not null comment '舆论词编号',
   STAT_TIME            datetime not null comment '统计时间',
   SIZE_ZM              bigint not null default 0 comment '正面数据量',
   SIZE_FM              bigint not null default 0 comment '负面数据量',
   SIZE_ZM_E            bigint not null default 0 comment '英文正面数据量',
   SIZE_FM_E            bigint not null default 0 comment '英文负面数据量',
   SITE_ID              int not null comment '站点编号',
   UPDATE_TIME          datetime not null comment '更新时间',
   primary key (STAT_SEQ)
);

alter table T_POM_S_STAT_SITE comment '站点舆论信息统计';