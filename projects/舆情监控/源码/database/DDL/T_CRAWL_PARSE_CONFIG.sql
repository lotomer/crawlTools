
create table T_CRAWL_PARSE_CONFIG
(
   ID                   int not null auto_increment comment '序号',
   HOST                 varchar(256) not null comment '站点编号',
   FIELD                varchar(64) not null comment 'URL',
   XPATH                varchar(512) not null,
  `VALUE_TYPE` varchar(16) DEFAULT 'string' COMMENT '值类型。string 字符串；datetime 日期；relative_time 相对时间',
  `VALUE_FORMAT` varchar(128) DEFAULT NULL COMMENT '值格式。主要针对时间类型的值',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (ID)
);

alter table T_CRAWL_PARSE_CONFIG comment '网站解析配置表';