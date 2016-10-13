
create table T_POM_C_WORD
(
   ID                   int not null auto_increment comment '序号',
   WORD                 varchar(128) not null comment '词汇内容',
   TENDENCY             varchar(2) not null default '0' comment '倾向性。-1 贬义；0 中性；1 褒义。默认1',
   LANG_ID              int not null default 0 comment '语言编号',
   IN_TIME              datetime not null comment '入库时间',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (ID)
);

alter table T_POM_C_WORD comment '词汇库';

create unique index UNI_WORD on T_POM_C_WORD
(
   WORD
);
