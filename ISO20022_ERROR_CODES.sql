-- Create table
create table ISO20022_ERROR_CODES
(
  error_code        VARCHAR2(20) not null,
  error_category    VARCHAR2(20) not null,
  error_description VARCHAR2(500) not null,
  severity          VARCHAR2(10) not null,
  is_retryable      VARCHAR2(1) default 'N',
  active_flag       VARCHAR2(1) default 'Y'
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table ISO20022_ERROR_CODES
  add primary key (ERROR_CODE)
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
