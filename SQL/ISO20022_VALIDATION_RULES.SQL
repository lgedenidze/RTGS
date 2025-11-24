-- Create table
create table ISO20022_VALIDATION_RULES
(
  rule_id         NUMBER not null,
  profile_code    VARCHAR2(20),
  message_type    VARCHAR2(20),
  message_version VARCHAR2(20),
  field_path      VARCHAR2(500) not null,
  field_name      VARCHAR2(100),
  rule_type       VARCHAR2(20) not null,
  rule_expression VARCHAR2(4000),
  rule_params     VARCHAR2(1000),
  error_code      VARCHAR2(20) not null,
  error_message   VARCHAR2(500) not null,
  severity        VARCHAR2(10) default 'ERROR',
  active_flag     VARCHAR2(1) default 'Y',
  created_by      VARCHAR2(100) default USER,
  created_date    DATE default SYSDATE
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
comment on table ISO20022_VALIDATION_RULES
  is 'Dynamic validation rules per profile and message type';
-- Add comments to the columns 
comment on column ISO20022_VALIDATION_RULES.rule_type
  is 'Type of validation to perform';
comment on column ISO20022_VALIDATION_RULES.rule_expression
  is 'Regex, SQL condition, or validation logic';
-- Create/Recreate indexes 
create index IDX_VALRULE_PROFILE_MSG on ISO20022_VALIDATION_RULES (PROFILE_CODE, MESSAGE_TYPE, ACTIVE_FLAG)
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
alter table ISO20022_VALIDATION_RULES
  add primary key (RULE_ID)
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
alter table ISO20022_VALIDATION_RULES
  add foreign key (PROFILE_CODE)
  references ISO20022_PROFILES (PROFILE_CODE);
-- Create/Recreate check constraints 
alter table ISO20022_VALIDATION_RULES
  add check (ACTIVE_FLAG IN ('Y','N'));
