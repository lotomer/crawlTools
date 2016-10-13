create table T_CRAWL_M_CRAWLER
(
   CRAWL_CODE           varchar(64) not null comment '爬虫编码',
   CRAWL_NAME           varchar(64) not null comment '爬虫名称',
   CRAWL_FREQUENCY      int not null comment '爬取频率。单位：分钟',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (CRAWL_CODE)
);

alter table T_CRAWL_M_CRAWLER comment '爬虫设置';