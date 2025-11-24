CREATE OR REPLACE PACKAGE ISO20022_APPHDR_BUILDER AS

    -- Main AppHdr builder
    FUNCTION BUILD_APPHDR(
        P_PROFILE_CODE   VARCHAR2,
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE DEFAULT SYSDATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL,
        P_MKT_INFRA      VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    -- Build head.001.001.01
    FUNCTION BUILD_APPHDR_V01(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    -- Build head.001.001.02 (most common)
    FUNCTION BUILD_APPHDR_V02(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    -- Build head.001.001.03
    FUNCTION BUILD_APPHDR_V03(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL,
        P_MKT_INFRA      VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

END ISO20022_APPHDR_BUILDER;
/
CREATE OR REPLACE PACKAGE BODY ISO20022_APPHDR_BUILDER AS

    -- Main AppHdr builder (routes to version-specific builder)
    FUNCTION BUILD_APPHDR(
        P_PROFILE_CODE   VARCHAR2,
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE DEFAULT SYSDATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL,
        P_MKT_INFRA      VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_PROFILE ISO20022_PROFILES%ROWTYPE;
        V_APPHDR CLOB;
        V_BIZSVC VARCHAR2(50);
    BEGIN
        -- Get profile configuration
        SELECT *
        INTO V_PROFILE
        FROM ISO20022_PROFILES
        WHERE PROFILE_CODE = P_PROFILE_CODE
        AND ACTIVE_FLAG = 'Y';

        -- Determine BizSvc
        IF P_BIZ_SVC IS NOT NULL THEN
            V_BIZSVC := P_BIZ_SVC;
        ELSIF V_PROFILE.BIZSVC_REQUIRED = 'Y' THEN
            V_BIZSVC := V_PROFILE.BIZSVC_VALUE;
        END IF;

        -- Route to appropriate version builder
        IF V_PROFILE.APPHDR_VERSION = 'head.001.001.01' THEN
            V_APPHDR := BUILD_APPHDR_V01(
                P_BIZ_MSG_ID    => P_BIZ_MSG_ID,
                P_MSG_DEF_ID    => P_MSG_DEF_ID,
                P_SENDER_BIC    => P_SENDER_BIC,
                P_RECEIVER_BIC  => P_RECEIVER_BIC,
                P_CREATION_DATE => P_CREATION_DATE,
                P_BIZ_SVC       => V_BIZSVC
            );

        ELSIF V_PROFILE.APPHDR_VERSION = 'head.001.001.02' THEN
            V_APPHDR := BUILD_APPHDR_V02(
                P_BIZ_MSG_ID    => P_BIZ_MSG_ID,
                P_MSG_DEF_ID    => P_MSG_DEF_ID,
                P_SENDER_BIC    => P_SENDER_BIC,
                P_RECEIVER_BIC  => P_RECEIVER_BIC,
                P_CREATION_DATE => P_CREATION_DATE,
                P_BIZ_SVC       => V_BIZSVC
            );

        ELSIF V_PROFILE.APPHDR_VERSION = 'head.001.001.03' THEN
            V_APPHDR := BUILD_APPHDR_V03(
                P_BIZ_MSG_ID    => P_BIZ_MSG_ID,
                P_MSG_DEF_ID    => P_MSG_DEF_ID,
                P_SENDER_BIC    => P_SENDER_BIC,
                P_RECEIVER_BIC  => P_RECEIVER_BIC,
                P_CREATION_DATE => P_CREATION_DATE,
                P_BIZ_SVC       => V_BIZSVC,
                P_MKT_INFRA     => P_MKT_INFRA
            );

        ELSE
            RAISE_APPLICATION_ERROR(-20005,
                'Unsupported AppHdr version: ' || V_PROFILE.APPHDR_VERSION);
        END IF;

        RETURN V_APPHDR;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006,
                'Profile not found or inactive: ' || P_PROFILE_CODE);
    END BUILD_APPHDR;

    -- Build head.001.001.01
    FUNCTION BUILD_APPHDR_V01(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_XML CLOB;
        V_CRE_DT VARCHAR2(50);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_CRE_DT := ISO20022_UTILS.FORMAT_ISO_DATETIME(P_CREATION_DATE, 'Y');

        DBMS_LOB.APPEND(V_XML, '<AppHdr xmlns="urn:iso:std:iso:20022:tech:xsd:head.001.001.01">');

        -- From
        DBMS_LOB.APPEND(V_XML, '<Fr>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BIC>' || ISO20022_UTILS.SAFE_XML_TEXT(P_SENDER_BIC) || '</BIC>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</Fr>');

        -- To
        DBMS_LOB.APPEND(V_XML, '<To>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BIC>' || ISO20022_UTILS.SAFE_XML_TEXT(P_RECEIVER_BIC) || '</BIC>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</To>');

        -- BizMsgIdr
        DBMS_LOB.APPEND(V_XML, '<BizMsgIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_MSG_ID) || '</BizMsgIdr>');

        -- MsgDefIdr
        DBMS_LOB.APPEND(V_XML, '<MsgDefIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MSG_DEF_ID) || '</MsgDefIdr>');

        -- BizSvc (optional)
        IF P_BIZ_SVC IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<BizSvc>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_SVC) || '</BizSvc>');
        END IF;

        -- CreDt
        DBMS_LOB.APPEND(V_XML, '<CreDt>' || V_CRE_DT || '</CreDt>');

        DBMS_LOB.APPEND(V_XML, '</AppHdr>');

        RETURN V_XML;
    END BUILD_APPHDR_V01;

    -- Build head.001.001.02 (RTGS, SWIFT CBPR+)
    FUNCTION BUILD_APPHDR_V02(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_XML CLOB;
        V_CRE_DT VARCHAR2(50);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_CRE_DT := ISO20022_UTILS.FORMAT_ISO_DATETIME(P_CREATION_DATE, 'Y');

        DBMS_LOB.APPEND(V_XML, '<AppHdr xmlns="urn:iso:std:iso:20022:tech:xsd:head.001.001.02">');

        -- From
        DBMS_LOB.APPEND(V_XML, '<Fr>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_SENDER_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</Fr>');

        -- To
        DBMS_LOB.APPEND(V_XML, '<To>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_RECEIVER_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</To>');

        -- BizMsgIdr
        DBMS_LOB.APPEND(V_XML, '<BizMsgIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_MSG_ID) || '</BizMsgIdr>');

        -- MsgDefIdr
        DBMS_LOB.APPEND(V_XML, '<MsgDefIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MSG_DEF_ID) || '</MsgDefIdr>');

        -- BizSvc (optional)
        IF P_BIZ_SVC IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<BizSvc>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_SVC) || '</BizSvc>');
        END IF;

        -- CreDt
        DBMS_LOB.APPEND(V_XML, '<CreDt>' || V_CRE_DT || '</CreDt>');

        DBMS_LOB.APPEND(V_XML, '</AppHdr>');

        RETURN V_XML;
    END BUILD_APPHDR_V02;

    -- Build head.001.001.03
    FUNCTION BUILD_APPHDR_V03(
        P_BIZ_MSG_ID     VARCHAR2,
        P_MSG_DEF_ID     VARCHAR2,
        P_SENDER_BIC     VARCHAR2,
        P_RECEIVER_BIC   VARCHAR2,
        P_CREATION_DATE  DATE,
        P_BIZ_SVC        VARCHAR2 DEFAULT NULL,
        P_MKT_INFRA      VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_XML CLOB;
        V_CRE_DT VARCHAR2(50);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_CRE_DT := ISO20022_UTILS.FORMAT_ISO_DATETIME(P_CREATION_DATE, 'Y');

        DBMS_LOB.APPEND(V_XML, '<AppHdr xmlns="urn:iso:std:iso:20022:tech:xsd:head.001.001.03">');

        -- From
        DBMS_LOB.APPEND(V_XML, '<Fr>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_SENDER_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</Fr>');

        -- To
        DBMS_LOB.APPEND(V_XML, '<To>');
        DBMS_LOB.APPEND(V_XML, '<FIId>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_RECEIVER_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</FIId>');
        DBMS_LOB.APPEND(V_XML, '</To>');

        -- BizMsgIdr
        DBMS_LOB.APPEND(V_XML, '<BizMsgIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_MSG_ID) || '</BizMsgIdr>');

        -- MsgDefIdr
        DBMS_LOB.APPEND(V_XML, '<MsgDefIdr>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MSG_DEF_ID) || '</MsgDefIdr>');

        -- BizSvc (optional)
        IF P_BIZ_SVC IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<BizSvc>' || ISO20022_UTILS.SAFE_XML_TEXT(P_BIZ_SVC) || '</BizSvc>');
        END IF;

        -- MktPrctc (optional - new in v03)
        IF P_MKT_INFRA IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<MktPrctc>');
            DBMS_LOB.APPEND(V_XML, '<Regy>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MKT_INFRA) || '</Regy>');
            DBMS_LOB.APPEND(V_XML, '</MktPrctc>');
        END IF;

        -- CreDt
        DBMS_LOB.APPEND(V_XML, '<CreDt>' || V_CRE_DT || '</CreDt>');

        DBMS_LOB.APPEND(V_XML, '</AppHdr>');

        RETURN V_XML;
    END BUILD_APPHDR_V03;

END ISO20022_APPHDR_BUILDER;
/
