-- Create table
create table ISO20022_MESSAGE_AUDIT
(
  audit_id           NUMBER not null,
  profile_code       VARCHAR2(20) not null,
  message_type       VARCHAR2(20) not null,
  message_version    VARCHAR2(20),
  direction          VARCHAR2(10) not null,
  biz_msg_id         VARCHAR2(35) not null,
  msg_id             VARCHAR2(35),
  uetr               VARCHAR2(36),
  end_to_end_id      VARCHAR2(35),
  tx_id              VARCHAR2(35),
  status             VARCHAR2(20) not null,
  sub_status         VARCHAR2(50),
  error_code         VARCHAR2(20),
  error_message      VARCHAR2(4000),
  message_xml        CLOB,
  response_xml       CLOB,
  transport_type     VARCHAR2(20),
  endpoint_url       VARCHAR2(500),
  http_status        NUMBER,
  created_date       TIMESTAMP(6) default SYSTIMESTAMP,
  sent_date          TIMESTAMP(6),
  received_date      TIMESTAMP(6),
  confirmed_date     TIMESTAMP(6),
  processing_time_ms NUMBER,
  send_no            NUMBER,
  doc_no             NUMBER,
  created_by         VARCHAR2(100) default USER,
  archived_flag      VARCHAR2(1) default 'N',
  archive_date       DATE
)
tablespace DATA_SRB
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Add comments to the table 
comment on table ISO20022_MESSAGE_AUDIT
  is 'Complete audit trail of all ISO 20022 messages';
-- Add comments to the columns 
comment on column ISO20022_MESSAGE_AUDIT.biz_msg_id
  is 'Unique business message identifier';
comment on column ISO20022_MESSAGE_AUDIT.processing_time_ms
  is 'End-to-end processing time in milliseconds';
-- Create/Recreate indexes 
create index IDX_AUDIT_BIZMSGID on ISO20022_MESSAGE_AUDIT (BIZ_MSG_ID)
  tablespace DATA_SRB
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
create index IDX_AUDIT_DIRECTION on ISO20022_MESSAGE_AUDIT (DIRECTION, CREATED_DATE)
  tablespace DATA_SRB
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
create index IDX_AUDIT_SENDNO on ISO20022_MESSAGE_AUDIT (SEND_NO)
  tablespace DATA_SRB
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
create index IDX_AUDIT_STATUS on ISO20022_MESSAGE_AUDIT (STATUS, CREATED_DATE)
  tablespace DATA_SRB
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table ISO20022_MESSAGE_AUDIT
  add primary key (AUDIT_ID)
  using index 
  tablespace DATA_SRB
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate check constraints 
alter table ISO20022_MESSAGE_AUDIT
  add check (DIRECTION IN ('INBOUND','OUTBOUND'));
