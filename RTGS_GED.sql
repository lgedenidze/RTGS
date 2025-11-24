CREATE OR REPLACE PACKAGE RTGS_GED IS

  -- Your existing procedures...

  PROCEDURE GENERATE_XML_NEW(P_SEND_NO NUMBER, REF_CURS OUT SYS_REFCURSOR);

END;
/
CREATE OR REPLACE PACKAGE BODY RTGS_GED IS

  -- Your existing procedures...

  PROCEDURE GENERATE_XML_NEW(P_SEND_NO NUMBER, REF_CURS OUT SYS_REFCURSOR) AS
    v_txs          ISO20022_DOC_BUILDER.T_PACS008_TX_TAB := ISO20022_DOC_BUILDER.T_PACS008_TX_TAB();
    v_sender_bic   VARCHAR2(11) := 'DISNGE22';
    v_receiver_bic VARCHAR2(11) := 'GEATSAAA';
    v_biz_msg_id   VARCHAR2(35);
    v_apphdr       CLOB;
    v_document     CLOB;
    v_full_message CLOB;

    CURSOR c_transactions IS
      SELECT ISO20022_UTILS.GENERATE_INSTR_ID(d.NO, e.PRIV_NO) AS INSTR_ID,
             d.ID AS END_TO_END_ID,
             'TX' || d.NO AS TX_ID,
             ISO20022_UTILS.GENERATE_UETR() AS UETR,
             d.AMOUNT_CUR_1 AS INTRBANK_STTLM_AMT,
             'GEL' AS INTRBANK_STTLM_CCY,
             'SLEV' AS CHRG_BR,
             d.REMITTANT_NAME AS DBTR_NM,
             IBAN.GET_IBAN(d.DEBIT_ACC_ID, 0) AS DBTR_IBAN,
             (SELECT SWIFT_CODE FROM BNKSEEK WHERE NEWNUM = d.MFO_REM) AS DBTR_BIC,
             d.RECEIPIENT_NAME AS CDTR_NM,
             IBAN.GET_IBAN(d.CREDIT_ACC_ID, 0) AS CDTR_IBAN,
             (SELECT SWIFT_CODE FROM BNKSEEK WHERE NEWNUM = d.MFO_REC) AS CDTR_BIC,
             d.REMARKS AS REMITTANCE_INFO,
             d.PAYMENT_PURPOSE AS PURP_CD,
             d.CBC AS TTC_CODE,
             NULL AS CDTR_TAX_ID,
             NULL AS DBTR_ADDRESS,
             NULL AS CDTR_ADDRESS
        FROM DOCUMENTS d
        JOIN RKC_SEND_E e
          ON e.DOC_NO = d.NO
       WHERE e.SEND_NO = P_SEND_NO
       ORDER BY e.PRIV_NO;

    v_idx NUMBER := 0;
  BEGIN
    -- Fetch transactions into collection
    FOR rec IN c_transactions LOOP
      v_idx := v_idx + 1;
      v_txs.EXTEND(1);

      v_txs(v_idx).INSTR_ID := rec.INSTR_ID;
      v_txs(v_idx).END_TO_END_ID := rec.END_TO_END_ID;
      v_txs(v_idx).TX_ID := rec.TX_ID;
      v_txs(v_idx).UETR := rec.UETR;
      v_txs(v_idx).INTRBANK_STTLM_AMT := rec.INTRBANK_STTLM_AMT;
      v_txs(v_idx).INTRBANK_STTLM_CCY := rec.INTRBANK_STTLM_CCY;
      v_txs(v_idx).CHRG_BR := rec.CHRG_BR;
      v_txs(v_idx).DBTR_NM := rec.DBTR_NM;
      v_txs(v_idx).DBTR_IBAN := rec.DBTR_IBAN;
      v_txs(v_idx).DBTR_BIC := rec.DBTR_BIC;
      v_txs(v_idx).CDTR_NM := rec.CDTR_NM;
      v_txs(v_idx).CDTR_IBAN := rec.CDTR_IBAN;
      v_txs(v_idx).CDTR_BIC := rec.CDTR_BIC;
      v_txs(v_idx).REMITTANCE_INFO := rec.REMITTANCE_INFO;
      v_txs(v_idx).PURP_CD := rec.PURP_CD;
      v_txs(v_idx).TTC_CODE := rec.TTC_CODE;
      v_txs(v_idx).CDTR_TAX_ID := rec.CDTR_TAX_ID;
      v_txs(v_idx).DBTR_ADDRESS := rec.DBTR_ADDRESS;
      v_txs(v_idx).CDTR_ADDRESS := rec.CDTR_ADDRESS;
    END LOOP;

    -- Generate BizMsgId
    v_biz_msg_id := ISO20022_UTILS.GENERATE_BIZ_MSG_ID('RTGS');

    -- Build AppHdr
    v_apphdr := ISO20022_APPHDR_BUILDER.BUILD_APPHDR(P_PROFILE_CODE => 'RTGS',
                                                     P_BIZ_MSG_ID   => v_biz_msg_id,
                                                     P_MSG_DEF_ID   => 'pacs.008.001.08',
                                                     P_SENDER_BIC   => v_sender_bic,
                                                     P_RECEIVER_BIC => v_receiver_bic);

    -- Build Document
    v_document := ISO20022_DOC_BUILDER.BUILD_PACS008_V08(P_NAMESPACE_URI => 'urn:iso:std:iso:20022:tech:xsd:pacs.008.001.08',
                                                         P_TRANSACTIONS  => v_txs,
                                                         P_SENDER_BIC    => v_sender_bic,
                                                         P_STTLM_MTD     => 'CLRG',
                                                         P_CLR_SYS_CD    => 'RTGS');

    -- Assemble full message
    v_full_message := ISO20022_UTILS.ASSEMBLE_FULL_MESSAGE(P_PROFILE_CODE => 'RTGS',
                                                           P_APPHDR_XML   => v_apphdr,
                                                           P_DOCUMENT_XML => v_document);

    -- Return as cursor
    OPEN REF_CURS FOR
      SELECT v_biz_msg_id AS MESSAGE_ID,
             v_full_message AS XML_CONTENT,
             'SUCCESS' AS STATUS
        FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
RAISE;
  END GENERATE_XML_NEW;

END RTGS_GED;
/
