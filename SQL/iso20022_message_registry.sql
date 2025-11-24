-- Create table
create table ISO20022_MESSAGE_REGISTRY
(
  registry_id         NUMBER not null,
  profile_code        VARCHAR2(20) not null,
  message_type        VARCHAR2(20) not null,
  message_version     VARCHAR2(20) not null,
  full_msg_defn       VARCHAR2(50) not null,
  namespace_uri       VARCHAR2(200) not null,
  root_element        VARCHAR2(100),
  is_default_version  VARCHAR2(1) default 'N',
  builder_package     VARCHAR2(100),
  builder_procedure   VARCHAR2(100),
  validator_procedure VARCHAR2(100),
  parser_procedure    VARCHAR2(100),
  active_flag         VARCHAR2(1) default 'Y',
  effective_date      DATE default SYSDATE,
  end_date            DATE,
  created_by          VARCHAR2(100) default USER,
  created_date        DATE default SYSDATE
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
comment on table ISO20022_MESSAGE_REGISTRY
  is 'Message type and version registry per profile';
-- Add comments to the columns 
comment on column ISO20022_MESSAGE_REGISTRY.full_msg_defn
  is 'Full message definition identifier for MsgDefIdr';
comment on column ISO20022_MESSAGE_REGISTRY.is_default_version
  is 'Y if this is the default version to use';
-- Create/Recreate indexes 
create index IDX_MSGREG_DEFAULT on ISO20022_MESSAGE_REGISTRY (PROFILE_CODE, MESSAGE_TYPE, IS_DEFAULT_VERSION)
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
create index IDX_MSGREG_PROFILE on ISO20022_MESSAGE_REGISTRY (PROFILE_CODE, MESSAGE_TYPE)
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
alter table ISO20022_MESSAGE_REGISTRY
  add primary key (REGISTRY_ID)
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
alter table ISO20022_MESSAGE_REGISTRY
  add constraint UNQ_PROFILE_MSG_VER unique (PROFILE_CODE, MESSAGE_TYPE, MESSAGE_VERSION)
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
alter table ISO20022_MESSAGE_REGISTRY
  add foreign key (PROFILE_CODE)
  references ISO20022_PROFILES (PROFILE_CODE);
-- Create/Recreate check constraints 
alter table ISO20022_MESSAGE_REGISTRY
  add check (IS_DEFAULT_VERSION IN ('Y','N'));
alter table ISO20022_MESSAGE_REGISTRY
  add check (ACTIVE_FLAG IN ('Y','N'));
