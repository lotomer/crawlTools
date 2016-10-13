create table T_POM_WEEKLY
(
   ID                   int not null auto_increment comment '流水号',
   YEAR                 int not null comment '年份',
   MONTH                int not null comment '月份',
   WEEK                 int not null comment '周',
   PATH                 varchar(512) not null comment '存储路径',
   FILE_TYPE            varchar(128) not null comment '文件类型',
   FILE_SIZE            bigint not null default 0 comment '文件大小',
   FILE_NAME            varchar(128) not null comment '原始文件名',
   IN_TIME              datetime not null comment '入库时间',
   primary key (ID)
);

alter table T_POM_WEEKLY comment '周报信息';
