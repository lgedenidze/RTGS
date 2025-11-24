-- Create table
create table ISO20022_PROFILES
(
  profile_code      VARCHAR2(20) not null,
  profile_name      VARCHAR2(100) not null,
  description       VARCHAR2(500),
  apphdr_version    VARCHAR2(20) not null,
  bizsvc_required   VARCHAR2(1) default 'N',
  bizsvc_value      VARCHAR2(50),
  transport_type    VARCHAR2(20) not null,
  transport_config  CLOB,
  wrapper_namespace VARCHAR2(200),
  active_flag       VARCHAR2(1) default 'Y',
  created_by        VARCHAR2(100) default USER,
  created_date      DATE default SYSDATE,
  updated_by        VARCHAR2(100) default USER,
  updated_date      DATE default SYSDATE
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
comment on table ISO20022_PROFILES
  is 'Registry of payment rail profiles (RTGS, SWIFT CBPR+, etc.)';
-- Add comments to the columns 
comment on column ISO20022_PROFILES.profile_code
  is 'Unique profile identifier (e.g., RTGS, SWIFT_CBPR)';
comment on column ISO20022_PROFILES.apphdr_version
  is 'AppHdr schema version to use';
comment on column ISO20022_PROFILES.transport_config
  is 'JSON: endpoint URLs, timeouts, headers, credentials';
-- Create/Recreate indexes 
create index IDX_PROF_ACTIVE on ISO20022_PROFILES (ACTIVE_FLAG)
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
alter table ISO20022_PROFILES
  add primary key (PROFILE_CODE)
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
alter table ISO20022_PROFILES
  add check (BIZSVC_REQUIRED IN ('Y','N'));
alter table ISO20022_PROFILES
  add check (ACTIVE_FLAG IN ('Y','N'));
