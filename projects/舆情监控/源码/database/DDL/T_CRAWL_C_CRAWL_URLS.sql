create table T_CRAWL_C_CRAWL_URLS
(
   ID                   int not null auto_increment comment '序号',
   SITE_ID              int not null comment '站点编号',
   URL                  varchar(512) not null comment 'URL',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (ID)
);

alter table T_CRAWL_C_CRAWL_URLS comment '站点爬取列表';