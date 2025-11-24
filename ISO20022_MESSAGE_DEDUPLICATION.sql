-- Create table
create table ISO20022_MESSAGE_DEDUPLICATION
(
  dedup_id        NUMBER not null,
  profile_code    VARCHAR2(20) not null,
  message_type    VARCHAR2(20) not null,
  biz_msg_id      VARCHAR2(35) not null,
  msg_id          VARCHAR2(35),
  uetr            VARCHAR2(36),
  dedup_key_hash  VARCHAR2(64) not null,
  first_seen_date TIMESTAMP(6) default SYSTIMESTAMP,
  first_audit_id  NUMBER,
  duplicate_count NUMBER default 0,
  last_seen_date  TIMESTAMP(6),
  expire_date     DATE
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
comment on table ISO20022_MESSAGE_DEDUPLICATION
  is 'Deduplication registry to prevent duplicate processing';
-- Create/Recreate indexes 
create index IDX_DEDUP_BIZMSGID on ISO20022_MESSAGE_DEDUPLICATION (BIZ_MSG_ID)
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
create index IDX_DEDUP_EXPIRE on ISO20022_MESSAGE_DEDUPLICATION (EXPIRE_DATE)
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
alter table ISO20022_MESSAGE_DEDUPLICATION
  add primary key (DEDUP_ID)
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
alter table ISO20022_MESSAGE_DEDUPLICATION
  add constraint UNQ_DEDUP_KEY unique (DEDUP_KEY_HASH)
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
alter table ISO20022_MESSAGE_DEDUPLICATION
  add foreign key (FIRST_AUDIT_ID)
  references ISO20022_MESSAGE_AUDIT (AUDIT_ID);
