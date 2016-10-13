create table T_ALERT_LOG
(
   ID                   bigint not null auto_increment comment '流水号',
   ALERT_ID             int not null comment '预警编号',
   ALERT_VALUE          varchar(128) comment '预警值',
   CURRENT_VALUE        varchar(128) comment '当前值',
   ALERT_TIME           datetime not null comment '预警时间',
   NOTIFY_STATUS        char not null default '0' comment '通知状态。0 未通知；1 已通知；2 通知失败。默认0',
   NOTIFY_TIME          datetime comment '通知时间',
   primary key (ID)
);

alter table T_ALERT_LOG comment '预警通知';