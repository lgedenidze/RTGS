-- Create table
create table ISO20022_OPERATING_SCHEDULE
(
  schedule_id  NUMBER not null,
  profile_code VARCHAR2(20) not null,
  message_type VARCHAR2(20),
  day_of_week  VARCHAR2(10) not null,
  start_time   VARCHAR2(8) not null,
  end_time     VARCHAR2(8) not null,
  is_holiday   VARCHAR2(1) default 'N',
  holiday_date DATE,
  active_flag  VARCHAR2(1) default 'Y',
  created_date DATE default SYSDATE
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
comment on table ISO20022_OPERATING_SCHEDULE
  is 'Operating hours schedule per profile and message type';
-- Create/Recreate indexes 
create index IDX_OPSCHED_PROFILE on ISO20022_OPERATING_SCHEDULE (PROFILE_CODE, MESSAGE_TYPE)
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
alter table ISO20022_OPERATING_SCHEDULE
  add primary key (SCHEDULE_ID)
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
