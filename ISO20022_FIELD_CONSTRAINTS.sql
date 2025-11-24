-- Create table
create table ISO20022_FIELD_CONSTRAINTS
(
  constraint_id  NUMBER not null,
  profile_code   VARCHAR2(20),
  message_type   VARCHAR2(20),
  field_path     VARCHAR2(500) not null,
  field_name     VARCHAR2(100),
  min_length     NUMBER,
  max_length     NUMBER,
  pattern        VARCHAR2(500),
  allowed_values VARCHAR2(4000),
  active_flag    VARCHAR2(1) default 'Y',
  created_date   DATE default SYSDATE
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
-- Create/Recreate indexes 
create index IDX_FLDCONST_PROFILE on ISO20022_FIELD_CONSTRAINTS (PROFILE_CODE, MESSAGE_TYPE)
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
alter table ISO20022_FIELD_CONSTRAINTS
  add primary key (CONSTRAINT_ID)
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
