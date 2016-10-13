create table T_CRAWL_R_CRAWLER_STATUS_HIS
(
   LOG_HIS_SEQ          bigint not null auto_increment comment '流水号',
   STATUS_ID            bigint not null comment '状态编号',
   START_TIME           datetime not null comment '开始时间',
   UPDATE_TIME          datetime not null comment '最后更新时间',
   STATUS               char not null comment '状态。1 成功；2 失败；3 异常终止',
   MSG                  varchar(512) comment '最后状态信息',
   IN_TIME              datetime not null comment '入库时间',
   primary key (LOG_HIS_SEQ)
);

alter table T_CRAWL_R_CRAWLER_STATUS_HIS comment '爬虫爬取历史状态';
