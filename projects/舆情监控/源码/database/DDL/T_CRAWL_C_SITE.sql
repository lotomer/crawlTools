create table T_CRAWL_C_SITE
(
   SITE_ID              int not null auto_increment comment '站点编号',
   SITE_NAME            varchar(64) not null comment '站点名称',
   SITE_HOST            varchar(128) not null comment '域名。不包含协议及路径。如163.com、baidu.com',
   SITE_TYPE_ID         int not null default 0 comment '站点类型编号。默认0',
   LANG_ID              int not null default 2 comment '语言编号。默认2，中文',
   COUNTRY_CODE         int not null default 0 comment '国家编码。默认0，中国',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (SITE_ID)
);

alter table T_CRAWL_C_SITE comment '站点信息';


create unique index U_SITE_HOST on T_CRAWL_C_SITE
(
   SITE_HOST
);
