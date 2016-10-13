create table T_POM_C_RULE
(
   TYPE_ID              int not null auto_increment comment '舆论词类别编号',
   TYPE_NAME            varchar(128) not null comment '类别名称',
   TEMPLATE_ZM          varchar(4000) not null comment '正面模板',
   TEMPLATE_FM          varchar(4000) comment '负面模板',
   TEMPLATE_ZM_E        varchar(4000) comment '英文正面模板',
   TEMPLATE_FM_E        varchar(4000) comment '英文负面模板',
   IN_TIME              datetime not null comment '入库时间',
   IS_VALID             char not null default '1' comment '是否启用。0 不启用；1 启用。默认1',
   primary key (TYPE_ID)
);

alter table T_POM_C_RULE comment '舆论词规则库';