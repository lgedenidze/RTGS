-- Create table
create table ISO20022_PARTICIPANTS
(
  participant_id     NUMBER not null,
  profile_code       VARCHAR2(20) not null,
  bic_code           VARCHAR2(11) not null,
  participant_name   VARCHAR2(200) not null,
  participant_type   VARCHAR2(20),
  is_direct          VARCHAR2(1) default 'Y',
  is_online          VARCHAR2(1) default 'Y',
  supported_messages VARCHAR2(500),
  max_amount         NUMBER,
  active_flag        VARCHAR2(1) default 'Y',
  effective_date     DATE default SYSDATE,
  end_date           DATE,
  created_date       DATE default SYSDATE
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
comment on table ISO20022_PARTICIPANTS
  is 'Registry of participants/counterparties per profile';
-- Create/Recreate indexes 
create unique index UNQ_PARTICIPANT_BIC on ISO20022_PARTICIPANTS (PROFILE_CODE, BIC_CODE)
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
alter table ISO20022_PARTICIPANTS
  add primary key (PARTICIPANT_ID)
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
