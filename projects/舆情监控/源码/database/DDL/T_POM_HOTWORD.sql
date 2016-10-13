create table T_POM_HOTWORD
(
   ID                   int not null auto_increment comment '流水号',
   WORD                 varchar(128) not null comment '热词',
   HEAT                 int not null default 1 comment '热度',
   IN_TIME              datetime not null comment '入库时间',
   primary key (ID)
);

alter table T_POM_HOTWORD comment '热词';