CREATE OR REPLACE PACKAGE ISO20022_DOC_BUILDER AS

    -- Type definitions for transaction data
    TYPE T_PACS008_TX_REC IS RECORD (
        INSTR_ID            VARCHAR2(4000),
        END_TO_END_ID       VARCHAR2(4000),
        TX_ID               VARCHAR2(4000),
        UETR                VARCHAR2(4000),
        INTRBANK_STTLM_AMT  NUMBER,
        INTRBANK_STTLM_CCY  VARCHAR2(4000),
        CHRG_BR             VARCHAR2(4000),        -- SLEV, SHAR, CRED, DEBT
        DBTR_NM             VARCHAR2(4000),
        DBTR_IBAN           VARCHAR2(4000),
        DBTR_BIC            VARCHAR2(4000),
        CDTR_NM             VARCHAR2(4000),
        CDTR_IBAN           VARCHAR2(4000),
        CDTR_BIC            VARCHAR2(4000),
        REMITTANCE_INFO     VARCHAR2(4000),
        PURP_CD             VARCHAR2(4000),
        TTC_CODE            VARCHAR2(4000),
        CDTR_TAX_ID         VARCHAR2(4000),
        DBTR_ADDRESS        VARCHAR2(4000),
        CDTR_ADDRESS        VARCHAR2(4000)
    );

    TYPE T_PACS008_TX_TAB IS TABLE OF T_PACS008_TX_REC;

    -- pacs.008 v08 builder
    FUNCTION BUILD_PACS008_V08(
        P_NAMESPACE_URI VARCHAR2,
        P_TRANSACTIONS  T_PACS008_TX_TAB,
        P_SENDER_BIC    VARCHAR2,
        P_STTLM_MTD     VARCHAR2 DEFAULT 'CLRG',
        P_CLR_SYS_CD    VARCHAR2 DEFAULT 'RTGS'
    ) RETURN CLOB;

    -- pacs.009 v08 builder
    FUNCTION BUILD_PACS009_V08(
        P_NAMESPACE_URI VARCHAR2,
        P_INSTG_AGT_BIC VARCHAR2,
        P_INSTD_AGT_BIC VARCHAR2,
        P_STTLM_AMT     NUMBER,
        P_STTLM_CCY     VARCHAR2,
        P_INSTR_ID      VARCHAR2,
        P_END_TO_END_ID VARCHAR2,
        P_TX_ID         VARCHAR2,
        P_UETR          VARCHAR2 DEFAULT NULL,
        P_REMIT_INFO    VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    -- pacs.002 v10 builder (status report)
    FUNCTION BUILD_PACS002_V10(
        P_NAMESPACE_URI     VARCHAR2,
        P_ORGNL_MSG_ID      VARCHAR2,
        P_ORGNL_MSG_NM_ID   VARCHAR2,
        P_ORGNL_INSTR_ID    VARCHAR2,
        P_ORGNL_END_TO_END  VARCHAR2,
        P_ORGNL_TX_ID       VARCHAR2,
        P_TX_STS            VARCHAR2,        -- ACSC, ACTC, PDNG, RJCT
        P_STS_RSN_CD        VARCHAR2 DEFAULT NULL,
        P_ADDTL_INFO        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    -- pacs.004 v09 builder (payment return)
    FUNCTION BUILD_PACS004_V09(
        P_NAMESPACE_URI     VARCHAR2,
        P_MSG_ID            VARCHAR2,
        P_ORGNL_INSTR_ID    VARCHAR2,
        P_ORGNL_END_TO_END  VARCHAR2,
        P_ORGNL_TX_ID       VARCHAR2,
        P_ORGNL_UETR        VARCHAR2,
        P_RTR_AMT           NUMBER,
        P_RTR_CCY           VARCHAR2,
        P_RTR_RSN_CD        VARCHAR2,
        P_INSTG_AGT_BIC     VARCHAR2,
        P_INSTD_AGT_BIC     VARCHAR2
    ) RETURN CLOB;

END ISO20022_DOC_BUILDER;
/
CREATE OR REPLACE PACKAGE BODY ISO20022_DOC_BUILDER AS

    -- Build pacs.008.001.08 (FI to FI Customer Credit Transfer)
    FUNCTION BUILD_PACS008_V08(
        P_NAMESPACE_URI VARCHAR2,
        P_TRANSACTIONS  T_PACS008_TX_TAB,
        P_SENDER_BIC    VARCHAR2,
        P_STTLM_MTD     VARCHAR2 DEFAULT 'CLRG',
        P_CLR_SYS_CD    VARCHAR2 DEFAULT 'RTGS'
    ) RETURN CLOB AS
        V_XML CLOB;
        V_MSG_ID VARCHAR2(35);
        V_CRE_DT_TM VARCHAR2(50);
        V_NB_OF_TXS NUMBER;
        V_TTL_INTRBANK_STTLM_AMT NUMBER := 0;
        V_INTRBANK_STTLM_DT VARCHAR2(20);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_NB_OF_TXS := P_TRANSACTIONS.COUNT;

        -- Calculate total
        FOR I IN 1..V_NB_OF_TXS LOOP
            V_TTL_INTRBANK_STTLM_AMT := V_TTL_INTRBANK_STTLM_AMT +
                                         P_TRANSACTIONS(I).INTRBANK_STTLM_AMT;
        END LOOP;

        -- Generate IDs and dates
        V_MSG_ID := ISO20022_UTILS.GENERATE_MSG_ID();
        V_CRE_DT_TM := ISO20022_UTILS.FORMAT_ISO_DATETIME(SYSDATE, 'N') || 'Z';
        V_INTRBANK_STTLM_DT := ISO20022_UTILS.FORMAT_ISO_DATE(SYSDATE);

        -- Start Document
        DBMS_LOB.APPEND(V_XML, '<Document xmlns="' || P_NAMESPACE_URI || '">');
        DBMS_LOB.APPEND(V_XML, '<FIToFICstmrCdtTrf>');

        -- Group Header
        DBMS_LOB.APPEND(V_XML, '<GrpHdr>');
        DBMS_LOB.APPEND(V_XML, '<MsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(V_MSG_ID) || '</MsgId>');
        DBMS_LOB.APPEND(V_XML, '<CreDtTm>' || V_CRE_DT_TM || '</CreDtTm>');
        DBMS_LOB.APPEND(V_XML, '<NbOfTxs>' || V_NB_OF_TXS || '</NbOfTxs>');

        DBMS_LOB.APPEND(V_XML, '<TtlIntrBkSttlmAmt Ccy="' ||
            P_TRANSACTIONS(1).INTRBANK_STTLM_CCY || '">');
        DBMS_LOB.APPEND(V_XML, ISO20022_UTILS.FORMAT_AMOUNT(V_TTL_INTRBANK_STTLM_AMT, 2));
        DBMS_LOB.APPEND(V_XML, '</TtlIntrBkSttlmAmt>');

        DBMS_LOB.APPEND(V_XML, '<IntrBkSttlmDt>' || V_INTRBANK_STTLM_DT || '</IntrBkSttlmDt>');

        -- Settlement Info
        DBMS_LOB.APPEND(V_XML, '<SttlmInf>');
        DBMS_LOB.APPEND(V_XML, '<SttlmMtd>' || P_STTLM_MTD || '</SttlmMtd>');
        DBMS_LOB.APPEND(V_XML, '<ClrSys>');
        DBMS_LOB.APPEND(V_XML, '<Cd>' || P_CLR_SYS_CD || '</Cd>');
        DBMS_LOB.APPEND(V_XML, '</ClrSys>');
        DBMS_LOB.APPEND(V_XML, '</SttlmInf>');

        -- Instructing Agent
        DBMS_LOB.APPEND(V_XML, '<InstgAgt>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_SENDER_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</InstgAgt>');

        DBMS_LOB.APPEND(V_XML, '</GrpHdr>');

        -- Credit Transfer Transaction Information (for each transaction)
        FOR I IN 1..V_NB_OF_TXS LOOP
            DBMS_LOB.APPEND(V_XML, '<CdtTrfTxInf>');

            -- Payment ID
            DBMS_LOB.APPEND(V_XML, '<PmtId>');
            DBMS_LOB.APPEND(V_XML, '<InstrId>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).INSTR_ID) || '</InstrId>');
            DBMS_LOB.APPEND(V_XML, '<EndToEndId>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).END_TO_END_ID) || '</EndToEndId>');
            DBMS_LOB.APPEND(V_XML, '<TxId>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).TX_ID) || '</TxId>');

            -- UETR (mandatory for RTGS)
            IF P_TRANSACTIONS(I).UETR IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<UETR>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).UETR) || '</UETR>');
            END IF;

            DBMS_LOB.APPEND(V_XML, '</PmtId>');

            -- Payment Type Information (TTC Code)
            IF P_TRANSACTIONS(I).TTC_CODE IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<PmtTpInf>');
                DBMS_LOB.APPEND(V_XML, '<SvcLvl>');
                DBMS_LOB.APPEND(V_XML, '<Prtry>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).TTC_CODE) || '</Prtry>');
                DBMS_LOB.APPEND(V_XML, '</SvcLvl>');
                DBMS_LOB.APPEND(V_XML, '</PmtTpInf>');
            END IF;

            -- Interbank Settlement Amount
            DBMS_LOB.APPEND(V_XML, '<IntrBkSttlmAmt Ccy="' ||
                P_TRANSACTIONS(I).INTRBANK_STTLM_CCY || '">');
            DBMS_LOB.APPEND(V_XML,
                ISO20022_UTILS.FORMAT_AMOUNT(P_TRANSACTIONS(I).INTRBANK_STTLM_AMT, 2));
            DBMS_LOB.APPEND(V_XML, '</IntrBkSttlmAmt>');

            -- Charge Bearer (MANDATORY in pacs.008)
            DBMS_LOB.APPEND(V_XML, '<ChrgBr>' ||
                NVL(P_TRANSACTIONS(I).CHRG_BR, 'SLEV') || '</ChrgBr>');

            -- Debtor
            DBMS_LOB.APPEND(V_XML, '<Dbtr>');
            DBMS_LOB.APPEND(V_XML, '<Nm>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).DBTR_NM) || '</Nm>');

            IF P_TRANSACTIONS(I).DBTR_ADDRESS IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<PstlAdr>');
                DBMS_LOB.APPEND(V_XML, '<AdrLine>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).DBTR_ADDRESS) || '</AdrLine>');
                DBMS_LOB.APPEND(V_XML, '</PstlAdr>');
            END IF;

            DBMS_LOB.APPEND(V_XML, '</Dbtr>');

            -- Debtor Account
            DBMS_LOB.APPEND(V_XML, '<DbtrAcct>');
            DBMS_LOB.APPEND(V_XML, '<Id>');
            DBMS_LOB.APPEND(V_XML, '<IBAN>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).DBTR_IBAN) || '</IBAN>');
            DBMS_LOB.APPEND(V_XML, '</Id>');
            DBMS_LOB.APPEND(V_XML, '</DbtrAcct>');

            -- Debtor Agent
            DBMS_LOB.APPEND(V_XML, '<DbtrAgt>');
            DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
            DBMS_LOB.APPEND(V_XML, '<BICFI>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).DBTR_BIC) || '</BICFI>');
            DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
            DBMS_LOB.APPEND(V_XML, '</DbtrAgt>');

            -- Creditor Agent
            DBMS_LOB.APPEND(V_XML, '<CdtrAgt>');
            DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
            DBMS_LOB.APPEND(V_XML, '<BICFI>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).CDTR_BIC) || '</BICFI>');
            DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
            DBMS_LOB.APPEND(V_XML, '</CdtrAgt>');

            -- Creditor
            DBMS_LOB.APPEND(V_XML, '<Cdtr>');
            DBMS_LOB.APPEND(V_XML, '<Nm>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).CDTR_NM) || '</Nm>');

            IF P_TRANSACTIONS(I).CDTR_ADDRESS IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<PstlAdr>');
                DBMS_LOB.APPEND(V_XML, '<AdrLine>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).CDTR_ADDRESS) || '</AdrLine>');
                DBMS_LOB.APPEND(V_XML, '</PstlAdr>');
            END IF;

            -- Creditor Tax ID
            IF P_TRANSACTIONS(I).CDTR_TAX_ID IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<Id>');
                DBMS_LOB.APPEND(V_XML, '<OrgId>');
                DBMS_LOB.APPEND(V_XML, '<Othr>');
                DBMS_LOB.APPEND(V_XML, '<Id>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).CDTR_TAX_ID) || '</Id>');
                DBMS_LOB.APPEND(V_XML, '</Othr>');
                DBMS_LOB.APPEND(V_XML, '</OrgId>');
                DBMS_LOB.APPEND(V_XML, '</Id>');
            END IF;

            DBMS_LOB.APPEND(V_XML, '</Cdtr>');

            -- Creditor Account
            DBMS_LOB.APPEND(V_XML, '<CdtrAcct>');
            DBMS_LOB.APPEND(V_XML, '<Id>');
            DBMS_LOB.APPEND(V_XML, '<IBAN>' ||
                ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).CDTR_IBAN) || '</IBAN>');
            DBMS_LOB.APPEND(V_XML, '</Id>');
            DBMS_LOB.APPEND(V_XML, '</CdtrAcct>');

            -- Purpose
            IF P_TRANSACTIONS(I).PURP_CD IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<Purp>');
                DBMS_LOB.APPEND(V_XML, '<Prtry>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).PURP_CD) || '</Prtry>');
                DBMS_LOB.APPEND(V_XML, '</Purp>');
            END IF;

            -- Remittance Information
            IF P_TRANSACTIONS(I).REMITTANCE_INFO IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<RmtInf>');
                DBMS_LOB.APPEND(V_XML, '<Ustrd>' ||
                    ISO20022_UTILS.SAFE_XML_TEXT(P_TRANSACTIONS(I).REMITTANCE_INFO) || '</Ustrd>');
                DBMS_LOB.APPEND(V_XML, '</RmtInf>');
            END IF;

            DBMS_LOB.APPEND(V_XML, '</CdtTrfTxInf>');
        END LOOP;

        DBMS_LOB.APPEND(V_XML, '</FIToFICstmrCdtTrf>');
        DBMS_LOB.APPEND(V_XML, '</Document>');

        RETURN V_XML;

    END BUILD_PACS008_V08;

    -- Build pacs.009.001.08 (FI to FI Credit Transfer)
    FUNCTION BUILD_PACS009_V08(
        P_NAMESPACE_URI VARCHAR2,
        P_INSTG_AGT_BIC VARCHAR2,
        P_INSTD_AGT_BIC VARCHAR2,
        P_STTLM_AMT     NUMBER,
        P_STTLM_CCY     VARCHAR2,
        P_INSTR_ID      VARCHAR2,
        P_END_TO_END_ID VARCHAR2,
        P_TX_ID         VARCHAR2,
        P_UETR          VARCHAR2 DEFAULT NULL,
        P_REMIT_INFO    VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_XML CLOB;
        V_MSG_ID VARCHAR2(35);
        V_CRE_DT_TM VARCHAR2(50);
        V_INTRBANK_STTLM_DT VARCHAR2(20);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_MSG_ID := ISO20022_UTILS.GENERATE_MSG_ID();
        V_CRE_DT_TM := ISO20022_UTILS.FORMAT_ISO_DATETIME(SYSDATE, 'N') || 'Z';
        V_INTRBANK_STTLM_DT := ISO20022_UTILS.FORMAT_ISO_DATE(SYSDATE);

        -- Start Document
        DBMS_LOB.APPEND(V_XML, '<Document xmlns="' || P_NAMESPACE_URI || '">');
        DBMS_LOB.APPEND(V_XML, '<FIToFICdtTrf>');

        -- Group Header
        DBMS_LOB.APPEND(V_XML, '<GrpHdr>');
        DBMS_LOB.APPEND(V_XML, '<MsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(V_MSG_ID) || '</MsgId>');
        DBMS_LOB.APPEND(V_XML, '<CreDtTm>' || V_CRE_DT_TM || '</CreDtTm>');
        DBMS_LOB.APPEND(V_XML, '<NbOfTxs>1</NbOfTxs>');

        DBMS_LOB.APPEND(V_XML, '<TtlIntrBkSttlmAmt Ccy="' || P_STTLM_CCY || '">');
        DBMS_LOB.APPEND(V_XML, ISO20022_UTILS.FORMAT_AMOUNT(P_STTLM_AMT, 2));
        DBMS_LOB.APPEND(V_XML, '</TtlIntrBkSttlmAmt>');

        DBMS_LOB.APPEND(V_XML, '<IntrBkSttlmDt>' || V_INTRBANK_STTLM_DT || '</IntrBkSttlmDt>');

        -- Settlement Info
        DBMS_LOB.APPEND(V_XML, '<SttlmInf>');
        DBMS_LOB.APPEND(V_XML, '<SttlmMtd>CLRG</SttlmMtd>');
        DBMS_LOB.APPEND(V_XML, '</SttlmInf>');

        DBMS_LOB.APPEND(V_XML, '</GrpHdr>');

        -- Credit Transfer Transaction Information
        DBMS_LOB.APPEND(V_XML, '<CdtTrfTxInf>');

        -- Payment ID
        DBMS_LOB.APPEND(V_XML, '<PmtId>');
        DBMS_LOB.APPEND(V_XML, '<InstrId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_INSTR_ID) || '</InstrId>');
        DBMS_LOB.APPEND(V_XML, '<EndToEndId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_END_TO_END_ID) || '</EndToEndId>');
        DBMS_LOB.APPEND(V_XML, '<TxId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_TX_ID) || '</TxId>');

        IF P_UETR IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<UETR>' || ISO20022_UTILS.SAFE_XML_TEXT(P_UETR) || '</UETR>');
        END IF;

        DBMS_LOB.APPEND(V_XML, '</PmtId>');

        -- Interbank Settlement Amount
        DBMS_LOB.APPEND(V_XML, '<IntrBkSttlmAmt Ccy="' || P_STTLM_CCY || '">');
        DBMS_LOB.APPEND(V_XML, ISO20022_UTILS.FORMAT_AMOUNT(P_STTLM_AMT, 2));
        DBMS_LOB.APPEND(V_XML, '</IntrBkSttlmAmt>');

        -- NOTE: ChrgBr is FORBIDDEN in pacs.009

        -- Instructing Agent
        DBMS_LOB.APPEND(V_XML, '<InstgAgt>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_INSTG_AGT_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</InstgAgt>');

        -- Instructed Agent
        DBMS_LOB.APPEND(V_XML, '<InstdAgt>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_INSTD_AGT_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</InstdAgt>');

        -- Remittance Information (optional)
        IF P_REMIT_INFO IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<RmtInf>');
            DBMS_LOB.APPEND(V_XML, '<Ustrd>' || ISO20022_UTILS.SAFE_XML_TEXT(P_REMIT_INFO) || '</Ustrd>');
            DBMS_LOB.APPEND(V_XML, '</RmtInf>');
        END IF;

        DBMS_LOB.APPEND(V_XML, '</CdtTrfTxInf>');

        DBMS_LOB.APPEND(V_XML, '</FIToFICdtTrf>');
        DBMS_LOB.APPEND(V_XML, '</Document>');

        RETURN V_XML;

    END BUILD_PACS009_V08;

    -- Build pacs.002.001.10 (Payment Status Report)
    FUNCTION BUILD_PACS002_V10(
        P_NAMESPACE_URI     VARCHAR2,
        P_ORGNL_MSG_ID      VARCHAR2,
        P_ORGNL_MSG_NM_ID   VARCHAR2,
        P_ORGNL_INSTR_ID    VARCHAR2,
        P_ORGNL_END_TO_END  VARCHAR2,
        P_ORGNL_TX_ID       VARCHAR2,
        P_TX_STS            VARCHAR2,
        P_STS_RSN_CD        VARCHAR2 DEFAULT NULL,
        P_ADDTL_INFO        VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS
        V_XML CLOB;
        V_MSG_ID VARCHAR2(35);
        V_CRE_DT_TM VARCHAR2(50);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_MSG_ID := ISO20022_UTILS.GENERATE_MSG_ID();
        V_CRE_DT_TM := ISO20022_UTILS.FORMAT_ISO_DATETIME(SYSDATE, 'N') || 'Z';

        DBMS_LOB.APPEND(V_XML, '<Document xmlns="' || P_NAMESPACE_URI || '">');
        DBMS_LOB.APPEND(V_XML, '<FIToFIPmtStsRpt>');

        -- Group Header
        DBMS_LOB.APPEND(V_XML, '<GrpHdr>');
        DBMS_LOB.APPEND(V_XML, '<MsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(V_MSG_ID) || '</MsgId>');
        DBMS_LOB.APPEND(V_XML, '<CreDtTm>' || V_CRE_DT_TM || '</CreDtTm>');
        DBMS_LOB.APPEND(V_XML, '</GrpHdr>');

        -- Original Group Information
        DBMS_LOB.APPEND(V_XML, '<OrgnlGrpInfAndSts>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlMsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_MSG_ID) || '</OrgnlMsgId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlMsgNmId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_MSG_NM_ID) || '</OrgnlMsgNmId>');
        DBMS_LOB.APPEND(V_XML, '</OrgnlGrpInfAndSts>');

        -- Transaction Information and Status
        DBMS_LOB.APPEND(V_XML, '<TxInfAndSts>');

        -- Original Instruction Identification
        DBMS_LOB.APPEND(V_XML, '<OrgnlInstrId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_INSTR_ID) || '</OrgnlInstrId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlEndToEndId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_END_TO_END) || '</OrgnlEndToEndId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlTxId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_TX_ID) || '</OrgnlTxId>');

        -- Transaction Status
        DBMS_LOB.APPEND(V_XML, '<TxSts>' || P_TX_STS || '</TxSts>');

        -- Status Reason Information (optional)
        IF P_STS_RSN_CD IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<StsRsnInf>');
            DBMS_LOB.APPEND(V_XML, '<Rsn>');
            DBMS_LOB.APPEND(V_XML, '<Cd>' || P_STS_RSN_CD || '</Cd>');
            DBMS_LOB.APPEND(V_XML, '</Rsn>');

            IF P_ADDTL_INFO IS NOT NULL THEN
                DBMS_LOB.APPEND(V_XML, '<AddtlInf>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ADDTL_INFO) || '</AddtlInf>');
            END IF;

            DBMS_LOB.APPEND(V_XML, '</StsRsnInf>');
        END IF;

        DBMS_LOB.APPEND(V_XML, '</TxInfAndSts>');

        DBMS_LOB.APPEND(V_XML, '</FIToFIPmtStsRpt>');
        DBMS_LOB.APPEND(V_XML, '</Document>');

        RETURN V_XML;

    END BUILD_PACS002_V10;

    -- Build pacs.004.001.09 (Payment Return)
    FUNCTION BUILD_PACS004_V09(
        P_NAMESPACE_URI     VARCHAR2,
        P_MSG_ID            VARCHAR2,
        P_ORGNL_INSTR_ID    VARCHAR2,
        P_ORGNL_END_TO_END  VARCHAR2,
        P_ORGNL_TX_ID       VARCHAR2,
        P_ORGNL_UETR        VARCHAR2,
        P_RTR_AMT           NUMBER,
        P_RTR_CCY           VARCHAR2,
        P_RTR_RSN_CD        VARCHAR2,
        P_INSTG_AGT_BIC     VARCHAR2,
        P_INSTD_AGT_BIC     VARCHAR2
    ) RETURN CLOB AS
        V_XML CLOB;
        V_CRE_DT_TM VARCHAR2(50);
        V_INTRBANK_STTLM_DT VARCHAR2(20);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(V_XML, TRUE);

        V_CRE_DT_TM := ISO20022_UTILS.FORMAT_ISO_DATETIME(SYSDATE, 'N') || 'Z';
        V_INTRBANK_STTLM_DT := ISO20022_UTILS.FORMAT_ISO_DATE(SYSDATE);

        DBMS_LOB.APPEND(V_XML, '<Document xmlns="' || P_NAMESPACE_URI || '">');
        DBMS_LOB.APPEND(V_XML, '<PmtRtr>');

        -- Group Header
        DBMS_LOB.APPEND(V_XML, '<GrpHdr>');
        DBMS_LOB.APPEND(V_XML, '<MsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MSG_ID) || '</MsgId>');
        DBMS_LOB.APPEND(V_XML, '<CreDtTm>' || V_CRE_DT_TM || '</CreDtTm>');
        DBMS_LOB.APPEND(V_XML, '<NbOfTxs>1</NbOfTxs>');
        DBMS_LOB.APPEND(V_XML, '</GrpHdr>');

        -- Transaction Information
        DBMS_LOB.APPEND(V_XML, '<TxInf>');

        -- Return ID
        DBMS_LOB.APPEND(V_XML, '<RtrId>' || ISO20022_UTILS.GENERATE_MSG_ID() || '</RtrId>');

        -- Original Group Information
        DBMS_LOB.APPEND(V_XML, '<OrgnlGrpInf>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlMsgId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_MSG_ID) || '</OrgnlMsgId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlMsgNmId>pacs.008.001.08</OrgnlMsgNmId>');
        DBMS_LOB.APPEND(V_XML, '</OrgnlGrpInf>');

        -- Original Instruction Identification
        DBMS_LOB.APPEND(V_XML, '<OrgnlInstrId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_INSTR_ID) || '</OrgnlInstrId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlEndToEndId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_END_TO_END) || '</OrgnlEndToEndId>');
        DBMS_LOB.APPEND(V_XML, '<OrgnlTxId>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_TX_ID) || '</OrgnlTxId>');

        IF P_ORGNL_UETR IS NOT NULL THEN
            DBMS_LOB.APPEND(V_XML, '<OrgnlUETR>' || ISO20022_UTILS.SAFE_XML_TEXT(P_ORGNL_UETR) || '</OrgnlUETR>');
        END IF;

        -- Original Interbank Settlement Date
        DBMS_LOB.APPEND(V_XML, '<OrgnlIntrBkSttlmDt>' || V_INTRBANK_STTLM_DT || '</OrgnlIntrBkSttlmDt>');

        -- Returned Interbank Settlement Amount
        DBMS_LOB.APPEND(V_XML, '<RtrdIntrBkSttlmAmt Ccy="' || P_RTR_CCY || '">');
        DBMS_LOB.APPEND(V_XML, ISO20022_UTILS.FORMAT_AMOUNT(P_RTR_AMT, 2));
        DBMS_LOB.APPEND(V_XML, '</RtrdIntrBkSttlmAmt>');

        -- Interbank Settlement Date
        DBMS_LOB.APPEND(V_XML, '<IntrBkSttlmDt>' || V_INTRBANK_STTLM_DT || '</IntrBkSttlmDt>');

        -- Instructing Agent
        DBMS_LOB.APPEND(V_XML, '<InstgAgt>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_INSTG_AGT_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</InstgAgt>');

        -- Instructed Agent
        DBMS_LOB.APPEND(V_XML, '<InstdAgt>');
        DBMS_LOB.APPEND(V_XML, '<FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '<BICFI>' || ISO20022_UTILS.SAFE_XML_TEXT(P_INSTD_AGT_BIC) || '</BICFI>');
        DBMS_LOB.APPEND(V_XML, '</FinInstnId>');
        DBMS_LOB.APPEND(V_XML, '</InstdAgt>');

        -- Return Reason Information
        DBMS_LOB.APPEND(V_XML, '<RtrRsnInf>');
        DBMS_LOB.APPEND(V_XML, '<Rsn>');
        DBMS_LOB.APPEND(V_XML, '<Cd>' || P_RTR_RSN_CD || '</Cd>');
        DBMS_LOB.APPEND(V_XML, '</Rsn>');
        DBMS_LOB.APPEND(V_XML, '</RtrRsnInf>');

        DBMS_LOB.APPEND(V_XML, '</TxInf>');

        DBMS_LOB.APPEND(V_XML, '</PmtRtr>');
        DBMS_LOB.APPEND(V_XML, '</Document>');

        RETURN V_XML;

    END BUILD_PACS004_V09;

END ISO20022_DOC_BUILDER;
/
