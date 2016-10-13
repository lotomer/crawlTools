create table T_M_LANGUAGE
(
   LANG_ID              int not null auto_increment comment '语言编号',
   LANG_NAME            varchar(32) not null comment '语言名称',
   primary key (LANG_ID)
);

alter table T_M_LANGUAGE comment '语言';