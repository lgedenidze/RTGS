CREATE OR REPLACE PACKAGE ISO20022_UTILS AS

    -- Generate unique Business Message Identifier
    FUNCTION GENERATE_BIZ_MSG_ID(
        P_PROFILE_CODE VARCHAR2
    ) RETURN VARCHAR2;

    -- Generate Message ID for GrpHdr
    FUNCTION GENERATE_MSG_ID RETURN VARCHAR2;

    -- Generate UETR (UUID format)
    FUNCTION GENERATE_UETR RETURN VARCHAR2;

    -- Generate InstrId
    FUNCTION GENERATE_INSTR_ID(
        P_SEND_NO NUMBER,
        P_PRIV_NO NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    -- Format ISO 8601 timestamp
    FUNCTION FORMAT_ISO_DATETIME(
        P_DATE DATE DEFAULT SYSDATE,
        P_INCLUDE_TIMEZONE VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    -- Format ISO date (YYYY-MM-DD)
    FUNCTION FORMAT_ISO_DATE(
        P_DATE DATE DEFAULT SYSDATE
    ) RETURN VARCHAR2;

    -- Assemble full message (AppHdr + Document)
    FUNCTION ASSEMBLE_FULL_MESSAGE(
        P_PROFILE_CODE VARCHAR2,
        P_APPHDR_XML   CLOB,
        P_DOCUMENT_XML CLOB
    ) RETURN CLOB;

    -- Calculate hash for deduplication
    FUNCTION CALCULATE_DEDUP_HASH(
        P_BIZ_MSG_ID VARCHAR2,
        P_MSG_ID     VARCHAR2,
        P_UETR       VARCHAR2
    ) RETURN VARCHAR2;

    -- Safe XML text conversion (prevents injection)
    FUNCTION SAFE_XML_TEXT(
        P_TEXT VARCHAR2
    ) RETURN VARCHAR2;

    -- Format amount for XML
    FUNCTION FORMAT_AMOUNT(
        P_AMOUNT NUMBER,
        P_DECIMALS NUMBER DEFAULT 2
    ) RETURN VARCHAR2;

    -- Extract BIC from participant
    FUNCTION GET_PARTICIPANT_BIC(
        P_PROFILE_CODE VARCHAR2,
        P_BANK_CODE    VARCHAR2
    ) RETURN VARCHAR2;

    -- Check if system is operational
    FUNCTION IS_OPERATIONAL(
        P_PROFILE_CODE VARCHAR2,
        P_MESSAGE_TYPE VARCHAR2,
        P_CHECK_TIME   DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN;

END ISO20022_UTILS;
/
CREATE OR REPLACE PACKAGE BODY ISO20022_UTILS AS

    -- Generate unique Business Message Identifier
    FUNCTION GENERATE_BIZ_MSG_ID(
        P_PROFILE_CODE VARCHAR2
    ) RETURN VARCHAR2 AS
        V_PREFIX VARCHAR2(10);
        V_SEQUENCE NUMBER;
        V_BIZ_MSG_ID VARCHAR2(35);
    BEGIN
        -- Determine prefix based on profile
        IF P_PROFILE_CODE = 'RTGS' THEN
            V_PREFIX := 'GATS';
        ELSIF P_PROFILE_CODE = 'SWIFT_CBPR' THEN
            V_PREFIX := 'SWFT';
        ELSIF P_PROFILE_CODE = 'SWIFT_IAP' THEN
            V_PREFIX := 'SWIA';
        ELSE
            V_PREFIX := 'MSG';
        END IF;

        -- Get sequence
        SELECT ISO20022_MSG_SEQ.NEXTVAL INTO V_SEQUENCE FROM DUAL;

        -- Format: PREFIX + YYYYMMDD + 12-digit-sequence
        -- Example: GATS202410280000000001234
        V_BIZ_MSG_ID := V_PREFIX ||
                        TO_CHAR(SYSDATE, 'YYYYMMDD') ||
                        LPAD(V_SEQUENCE, 12, '0');

        RETURN V_BIZ_MSG_ID;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error generating BizMsgId: ' || SQLERRM);
    END GENERATE_BIZ_MSG_ID;

    -- Generate Message ID
    FUNCTION GENERATE_MSG_ID RETURN VARCHAR2 AS
        V_SEQUENCE NUMBER;
    BEGIN
        SELECT ISO20022_MSG_SEQ.NEXTVAL INTO V_SEQUENCE FROM DUAL;
        RETURN 'MSG' || TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(V_SEQUENCE, 10, '0');
    END GENERATE_MSG_ID;

    -- Generate UETR (UUID v4 format)
    FUNCTION GENERATE_UETR RETURN VARCHAR2 AS
        V_UUID RAW(16);
        V_UETR VARCHAR2(36);
    BEGIN
        -- Generate UUID
        V_UUID := SYS_GUID();

        -- Format as: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        V_UETR := LOWER(
            SUBSTR(RAWTOHEX(V_UUID), 1, 8) || '-' ||
            SUBSTR(RAWTOHEX(V_UUID), 9, 4) || '-' ||
            '4' || SUBSTR(RAWTOHEX(V_UUID), 14, 3) || '-' ||
            SUBSTR(RAWTOHEX(V_UUID), 17, 4) || '-' ||
            SUBSTR(RAWTOHEX(V_UUID), 21, 12)
        );

        RETURN V_UETR;
    END GENERATE_UETR;

    -- Generate Instruction ID
    FUNCTION GENERATE_INSTR_ID(
        P_SEND_NO NUMBER,
        P_PRIV_NO NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 AS
    BEGIN
        IF P_PRIV_NO IS NOT NULL THEN
            RETURN TO_CHAR(P_SEND_NO) || '/' || TO_CHAR(P_PRIV_NO);
        ELSE
            RETURN TO_CHAR(P_SEND_NO);
        END IF;
    END GENERATE_INSTR_ID;

    -- Format ISO 8601 datetime
    FUNCTION FORMAT_ISO_DATETIME(
        P_DATE DATE DEFAULT SYSDATE,
        P_INCLUDE_TIMEZONE VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 AS
        V_FORMATTED VARCHAR2(50);
    BEGIN
        IF P_INCLUDE_TIMEZONE = 'Y' THEN
            -- Format: 2024-10-28T14:30:00Z (UTC)
            V_FORMATTED := TO_CHAR(P_DATE, 'YYYY-MM-DD"T"HH24:MI:SS"+00:00"');
        ELSE
            -- Format: 2024-10-28T14:30:00
            V_FORMATTED := TO_CHAR(P_DATE, 'YYYY-MM-DD"T"HH24:MI:SS');
        END IF;

        RETURN V_FORMATTED;
    END FORMAT_ISO_DATETIME;

    -- Format ISO date
    FUNCTION FORMAT_ISO_DATE(
        P_DATE DATE DEFAULT SYSDATE
    ) RETURN VARCHAR2 AS
    BEGIN
        RETURN TO_CHAR(P_DATE, 'YYYY-MM-DD');
    END FORMAT_ISO_DATE;

    -- Assemble full message
    FUNCTION ASSEMBLE_FULL_MESSAGE(
        P_PROFILE_CODE VARCHAR2,
        P_APPHDR_XML   CLOB,
        P_DOCUMENT_XML CLOB
    ) RETURN CLOB AS
        V_FULL_MSG CLOB;
        V_NAMESPACE VARCHAR2(200);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_FULL_MSG, TRUE);

        -- Get wrapper namespace from profile
        SELECT WRAPPER_NAMESPACE
        INTO V_NAMESPACE
        FROM ISO20022_PROFILES
        WHERE PROFILE_CODE = P_PROFILE_CODE
        AND ACTIVE_FLAG = 'Y';

        -- Build message
        DBMS_LOB.APPEND(V_FULL_MSG, '<?xml version="1.0" encoding="UTF-8"?>');
        DBMS_LOB.APPEND(V_FULL_MSG, CHR(10));

        IF V_NAMESPACE IS NOT NULL THEN
            -- RTGS style with wrapper namespace
            DBMS_LOB.APPEND(V_FULL_MSG, '<Message xmlns="' || V_NAMESPACE || '">');
            DBMS_LOB.APPEND(V_FULL_MSG, CHR(10));
        ELSE
            -- Pure ISO 20022 (no wrapper)
            DBMS_LOB.APPEND(V_FULL_MSG, '<Message>');
            DBMS_LOB.APPEND(V_FULL_MSG, CHR(10));
        END IF;

        -- Append AppHdr
        DBMS_LOB.APPEND(V_FULL_MSG, P_APPHDR_XML);
        DBMS_LOB.APPEND(V_FULL_MSG, CHR(10));

        -- Append Document
        DBMS_LOB.APPEND(V_FULL_MSG, P_DOCUMENT_XML);
        DBMS_LOB.APPEND(V_FULL_MSG, CHR(10));

        DBMS_LOB.APPEND(V_FULL_MSG, '</Message>');

        RETURN V_FULL_MSG;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Profile not found: ' || P_PROFILE_CODE);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error assembling message: ' || SQLERRM);
    END ASSEMBLE_FULL_MESSAGE;

    -- Calculate deduplication hash
   FUNCTION CALCULATE_DEDUP_HASH(
    P_BIZ_MSG_ID VARCHAR2,
    P_MSG_ID     VARCHAR2,
    P_UETR       VARCHAR2
) RETURN VARCHAR2 AS
    V_COMPOSITE VARCHAR2(200);
    V_HASH VARCHAR2(32);
BEGIN
    -- Create composite key
    V_COMPOSITE := NVL(P_BIZ_MSG_ID, '') || '|' ||
                   NVL(P_MSG_ID, '') || '|' ||
                   NVL(P_UETR, '');
    
    -- Calculate MD5 hash (available in Oracle 10g)
    V_HASH := DBMS_OBFUSCATION_TOOLKIT.MD5(
        input => UTL_RAW.CAST_TO_RAW(V_COMPOSITE)
    );
    
    RETURN RAWTOHEX(V_HASH);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback: if DBMS_OBFUSCATION_TOOLKIT not available
        -- Just return a simple hash
        RETURN TO_CHAR(DBMS_UTILITY.GET_HASH_VALUE(V_COMPOSITE, 1, 4294967295));
END CALCULATE_DEDUP_HASH;

    -- Safe XML text conversion
    FUNCTION SAFE_XML_TEXT(
        P_TEXT VARCHAR2
    ) RETURN VARCHAR2 AS
    BEGIN
        -- Use Oracle's built-in XML encoding
        RETURN DBMS_XMLGEN.CONVERT(P_TEXT);
    END SAFE_XML_TEXT;

    -- Format amount
    FUNCTION FORMAT_AMOUNT(
        P_AMOUNT NUMBER,
        P_DECIMALS NUMBER DEFAULT 2
    ) RETURN VARCHAR2 AS
        V_FORMAT VARCHAR2(50);
    BEGIN
        -- Build format mask
        IF P_DECIMALS = 2 THEN
            V_FORMAT := 'FM999999999990.00';
        ELSIF P_DECIMALS = 3 THEN
            V_FORMAT := 'FM999999999990.000';
        ELSE
            V_FORMAT := 'FM999999999990.00';
        END IF;

        RETURN TRIM(TO_CHAR(P_AMOUNT, V_FORMAT));
    END FORMAT_AMOUNT;

    -- Get participant BIC
    FUNCTION GET_PARTICIPANT_BIC(
        P_PROFILE_CODE VARCHAR2,
        P_BANK_CODE    VARCHAR2
    ) RETURN VARCHAR2 AS
        V_BIC VARCHAR2(11);
    BEGIN
        -- Try to get from participants registry
        BEGIN
            SELECT BIC_CODE
            INTO V_BIC
            FROM ISO20022_PARTICIPANTS
            WHERE PROFILE_CODE = P_PROFILE_CODE
            AND (BIC_CODE = P_BANK_CODE OR PARTICIPANT_ID = P_BANK_CODE)
            AND ACTIVE_FLAG = 'Y'
            AND ROWNUM = 1;

            RETURN V_BIC;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Fall back to existing BNKSEEK table
                BEGIN
                    SELECT SWIFT_CODE
                    INTO V_BIC
                    FROM BNKSEEK
                    WHERE NEWNUM = P_BANK_CODE
                    AND ROWNUM = 1;

                    RETURN V_BIC;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        -- Return as-is if it looks like a BIC
                        IF LENGTH(P_BANK_CODE) IN (8, 11) THEN
                            RETURN P_BANK_CODE;
                        ELSE
                            RAISE_APPLICATION_ERROR(-20004,
                                'Cannot resolve BIC for bank code: ' || P_BANK_CODE);
                        END IF;
                END;
        END;
    END GET_PARTICIPANT_BIC;

    -- Check if operational
    FUNCTION IS_OPERATIONAL(
        P_PROFILE_CODE VARCHAR2,
        P_MESSAGE_TYPE VARCHAR2,
        P_CHECK_TIME   DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN AS
        V_COUNT NUMBER;
        V_DAY VARCHAR2(10);
        V_TIME VARCHAR2(8);
        V_IS_HOLIDAY NUMBER;
    BEGIN
        -- Get day of week
        V_DAY := TO_CHAR(P_CHECK_TIME, 'DY', 'nls_date_language=english');
        V_TIME := TO_CHAR(P_CHECK_TIME, 'HH24:MI:SS');

        -- Check if holiday (using existing BTA_JOBS.IS_HOLIDAY)
        BEGIN
            IF BTA_JOBS.IS_HOLIDAY(TRUNC(P_CHECK_TIME)) THEN
                V_IS_HOLIDAY := 1;
            ELSE
                V_IS_HOLIDAY := 0;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                V_IS_HOLIDAY := 0;
        END;

        IF V_IS_HOLIDAY = 1 THEN
            RETURN FALSE;
        END IF;

        -- Check operating schedule
        SELECT COUNT(*)
        INTO V_COUNT
        FROM ISO20022_OPERATING_SCHEDULE
        WHERE PROFILE_CODE = P_PROFILE_CODE
        AND (MESSAGE_TYPE = P_MESSAGE_TYPE OR MESSAGE_TYPE IS NULL)
        AND DAY_OF_WEEK = V_DAY
        AND V_TIME BETWEEN START_TIME AND END_TIME
        AND ACTIVE_FLAG = 'Y';

        RETURN (V_COUNT > 0);

    EXCEPTION
        WHEN OTHERS THEN
            -- Default to operational if no schedule defined
            RETURN TRUE;
    END IS_OPERATIONAL;

END ISO20022_UTILS;
/
