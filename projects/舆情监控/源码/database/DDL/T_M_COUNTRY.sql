create table T_M_COUNTRY
(
   COUNTRY_CODE         int not null comment '国家编码',
   COUNTRY_NAME         varchar(128) not null comment '国家名称',
   primary key (COUNTRY_CODE)
);

alter table T_M_COUNTRY comment '国家信息';