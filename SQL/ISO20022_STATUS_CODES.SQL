-- Create table
create table ISO20022_STATUS_CODES
(
  status_code        VARCHAR2(20) not null,
  status_category    VARCHAR2(20) not null,
  status_description VARCHAR2(200) not null,
  is_final           VARCHAR2(1) default 'N',
  severity           VARCHAR2(10),
  active_flag        VARCHAR2(1) default 'Y'
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
alter table ISO20022_STATUS_CODES
  add primary key (STATUS_CODE)
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

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('CREATED', 'MESSAGE', 'Message created', 'N', 'INFO', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('VALIDATED', 'MESSAGE', 'Message validated', 'N', 'INFO', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('SENT', 'MESSAGE', 'Message sent', 'N', 'INFO', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('ACSC', 'TRANSACTION', 'AcceptedSettlementCompleted', 'Y', 'SUCCESS', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('ACTC', 'TRANSACTION', 'AcceptedTechnicalValidation', 'N', 'INFO', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('PDNG', 'TRANSACTION', 'Pending', 'N', 'WARNING', 'Y');

insert into ISO20022_STATUS_CODES (STATUS_CODE, STATUS_CATEGORY, STATUS_DESCRIPTION, IS_FINAL, SEVERITY, ACTIVE_FLAG)
values ('RJCT', 'TRANSACTION', 'Rejected', 'Y', 'ERROR', 'Y');

