
create table T_CRAWL_R_CRAWLER_STATUS
(
   STATUS_ID            bigint not null auto_increment comment '状态编号',
   CRAWL_CODE           varchar(64) not null comment '爬虫编码',
   MATCHINE             varchar(128) not null comment '机器标识',
   START_TIME           datetime not null comment '开始时间',
   UPDATE_TIME          datetime not null comment '最后更新时间',
   MSG                  varchar(512) comment '最新状态信息',
   STATUS               char not null default '0' comment '状态。0 未开始；9正在运行；1 已完成；2 失败；3 异常终止。默认0',
   primary key (STATUS_ID)
);

alter table T_CRAWL_R_CRAWLER_STATUS comment '爬虫爬取状态';

create index IDX_CRAW_MATCHINE on T_CRAWL_R_CRAWLER_STATUS
(
   CRAWL_CODE,
   MATCHINE
);