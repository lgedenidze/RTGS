prompt Importing table ISO20022_VALIDATION_RULES...
set feedback off
set define off

insert into ISO20022_VALIDATION_RULES (RULE_ID, PROFILE_CODE, MESSAGE_TYPE, MESSAGE_VERSION, FIELD_PATH, FIELD_NAME, RULE_TYPE, RULE_EXPRESSION, RULE_PARAMS, ERROR_CODE, ERROR_MESSAGE, SEVERITY, ACTIVE_FLAG, CREATED_BY, CREATED_DATE)
values (1, 'RTGS', 'pacs.008', null, '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgBr', 'Charge Bearer', 'MANDATORY', null, null, 'VAL_001', 'ChrgBr is mandatory in pacs.008', 'ERROR', 'Y', 'SRB', to_date('28-10-2025 17:04:09', 'dd-mm-yyyy hh24:mi:ss'));

insert into ISO20022_VALIDATION_RULES (RULE_ID, PROFILE_CODE, MESSAGE_TYPE, MESSAGE_VERSION, FIELD_PATH, FIELD_NAME, RULE_TYPE, RULE_EXPRESSION, RULE_PARAMS, ERROR_CODE, ERROR_MESSAGE, SEVERITY, ACTIVE_FLAG, CREATED_BY, CREATED_DATE)
values (2, 'RTGS', 'pacs.009', null, '/Document/FIToFICdtTrf/CdtTrfTxInf/ChrgBr', 'Charge Bearer', 'FORBIDDEN', null, null, 'VAL_002', 'ChrgBr must not be present in pacs.009', 'ERROR', 'Y', 'SRB', to_date('28-10-2025 17:04:09', 'dd-mm-yyyy hh24:mi:ss'));

insert into ISO20022_VALIDATION_RULES (RULE_ID, PROFILE_CODE, MESSAGE_TYPE, MESSAGE_VERSION, FIELD_PATH, FIELD_NAME, RULE_TYPE, RULE_EXPRESSION, RULE_PARAMS, ERROR_CODE, ERROR_MESSAGE, SEVERITY, ACTIVE_FLAG, CREATED_BY, CREATED_DATE)
values (3, 'RTGS', 'pacs.008', null, '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtId/UETR', 'UETR', 'MANDATORY', null, null, 'VAL_003', 'UETR is mandatory for RTGS payments', 'ERROR', 'Y', 'SRB', to_date('28-10-2025 17:04:09', 'dd-mm-yyyy hh24:mi:ss'));

prompt Done.
