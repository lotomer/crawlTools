create table T_ALERT_SETTING
(
   ALERT_ID             int not null auto_increment comment '预警编号',
   ALERT_NAME           varchar(64) not null comment '预警名称',
   ALERT_TYPE           char not null default '0' comment '通知方式。0 站内通知；1 邮件通知；2 短信通知。默认0',
   ALERT_VALUE          varchar(128) comment '预警值',
   NOTIFIERS            varchar(512) not null comment '通知人编号列表。多个人员编号直接用英文逗号分隔',
   METRICS              varchar(512) not null comment '指标编号列表。多个编号之间用英文逗号分隔',
   UPDATE_TIME          datetime not null comment '更新时间',
   IS_VALID             char not null default '1' comment '是否有效。0 无效；1 有效。默认1',
   primary key (ALERT_ID)
);

alter table T_ALERT_SETTING comment '预警设置';