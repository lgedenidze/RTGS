CREATE OR REPLACE PACKAGE BODY RTGS IS

  /* FUNCTION generate_xml1(p_send_no NUMBER) RETURN LONG AS
      xml_static_start LONG;
      xml_static_end LONG;
      xml_GrpHdr LONG;
      xml_CdtTrfTxInf LONG;
      xml_ LONG;
      
    
      rkc_send_h_dt DATE;
      MsgId VARCHAR2(35);
      CreDtTm VARCHAR2(50);
      NbOfTxs NUMBER;
      TtlIntrBkSttlmAmt NUMBER;
      TtlIntrBkSttlmAmtCcy VARCHAR2(3);
      IntrBkSttlmDt VARCHAR2(50);
      SttlmMtd VARCHAR2(50);
      Prtry VARCHAR2(50);
      FinInstnId VARCHAR2(50);
      InstrId VARCHAR2(50);
      EndToEndId VARCHAR2(50);
      
      TxId VARCHAR2(50);
      Cd  VARCHAR2(20);
      IntrBkSttlmAmt NUMBER;
      IntrBkSttlmAmtCcy VARCHAR2(3);
      ChrgBr VARCHAR2(50);
      DbtrNm VARCHAR2(300);
      DbtrIBAN VARCHAR2(50);
      DbtrBIC VARCHAR2(50);
      CdtrBIC VARCHAR2(50);
        CdtrNm VARCHAR2(300);
      CdtrIBAN VARCHAR2(50);
    
      Ustrd VARCHAR2(1000);
      mfo_d VARCHAR2(50);
      mfo_c VARCHAR2(50);
      cust_no NUMBER;
      purp VARCHAR2(1000);
      treasury_code VARCHAR2(50);
  len NUMBER;
      CURSOR trans IS
      SELECT doc_no, priv_no FROM rkc_send_e WHERE send_no=p_send_no ORDER BY priv_no;
      BEGIN
      
      xml_static_start:='<Document>
    <FIToFICstmrCdtTrf>
    ';
    
    xml_static_end:= '</FIToFICstmrCdtTrf>
  </Document>
  ';
  
  MsgId:=to_char(p_send_no);
  CreDtTm:=to_char(SYSDATE,'yyyy-mm-dd"T"hh:mi:ss');
  select created INTO rkc_send_h_dt  from rkc_send_h WHERE send_no=p_send_no;
  IntrBkSttlmDt:=to_Char(rkc_send_h_dt,'yyyy-mm-dd');
  SttlmMtd:='CLRG';
  Prtry:='ST2';
  FinInstnId:='DISNGE22';
  TtlIntrBkSttlmAmtCcy:='GEL';
  TtlIntrBkSttlmAmt:=0;
  NbOfTxs:=0;   
  
      
      xml_CdtTrfTxInf:='';
      FOR a IN trans 
        LOOP
        
          InstrId:=MsgId||'/'||a.priv_no;
          TxId:=InstrId;
          Cd:='SEPA';
      
  
          ChrgBr:='DEPT'; -- magalitshi ecera SLEV
          NbOfTxs:=NbOfTxs+1;
          SELECT iban.get_iban(debit_acc_id,0), iban.get_iban(credit_acc_id,0), amount_cur_1, currency_no_1,
          payment_purpose,remarks,mfo_rem, mfo_rec ,receipient_name, remittant_no, remittant_name,cbc, id
          
          INTO DbtrIBAN,CdtrIBAN,IntrBkSttlmAmt,IntrBkSttlmAmtCcy,purp,Ustrd,mfo_d,mfo_c,CdtrNm,cust_no,DbtrNm,treasury_code,EndToEndId
           FROM documents WHERE NO=a.doc_no;
          SELECT swift_code INTO DbtrBIC  FROM bnkseek WHERE newnum=mfo_d;
          SELECT swift_code INTO CdtrBIC FROM bnkseek WHERE newnum=mfo_c;
        
          
          TtlIntrBkSttlmAmt:=TtlIntrBkSttlmAmt+IntrBkSttlmAmt;
          
          
          IF (treasury_code IS NOT NULL) THEN  -- GASARKVEVIA SCOREDAA TU ARA
          DbtrIBAN:=treasury_code;
            END IF;
          len:= lengthb(xml_CdtTrfTxInf);
          xml_CdtTrfTxInf:=xml_CdtTrfTxInf||'
      <CdtTrfTxInf>
        <PmtId>
          <InstrId>'||InstrId||'</InstrId>
          <EndToEndId>'||EndToEndId ||'</EndToEndId>
          <TxId>'||TxId||'</TxId>
        </PmtId>
        <PmtTpInf>
          <SvcLvl>
            <Cd>'||Cd||'</Cd>
          </SvcLvl>
        </PmtTpInf>
        <IntrBkSttlmAmt Ccy="'||vb_currencies_s.get_character_ccy(IntrBkSttlmAmtCcy)||'">'||trim(to_char(IntrBkSttlmAmt,'999999999990.00'))||'</IntrBkSttlmAmt>
        <ChrgBr>'||ChrgBr||'</ChrgBr>
        <Dbtr>
          <Nm>'||DbtrNm||'</Nm>
        </Dbtr>
        <DbtrAcct>
          <Id>
            <IBAN>'||DbtrIBAN||'</IBAN>
          </Id>
        </DbtrAcct>
        <DbtrAgt>
          <FinInstnId>
            <BIC>'||DbtrBIC||'</BIC>
          </FinInstnId>
        </DbtrAgt>
        <CdtrAgt>
          <FinInstnId>
            <BIC>'||CdtrBIC||'</BIC>
          </FinInstnId>
        </CdtrAgt>
        <Cdtr>
          <Nm>'||CdtrNm||'</Nm>
        </Cdtr>
        <CdtrAcct>
          <Id>
            <IBAN>'||CdtrIBAN||'</IBAN>
          </Id>
        </CdtrAcct>
        <Purp>
           <Prtry>'||purp||'</Prtry>  
        </Purp>
        <RmtInf>
          <Ustrd>'||Ustrd||'</Ustrd>
        </RmtInf>
      </CdtTrfTxInf>';
          END LOOP;
      xml_GrpHdr:='<GrpHdr>
        <MsgId>'||MsgId||'</MsgId>
        <CreDtTm>'||CreDtTm||'</CreDtTm>
        <NbOfTxs>'||NbOfTxs||'</NbOfTxs>
        <TtlIntrBkSttlmAmt Ccy="'||TtlIntrBkSttlmAmtCcy||'">'||trim(to_char(TtlIntrBkSttlmAmt,'99999999999990.00'))||'</TtlIntrBkSttlmAmt>
        <IntrBkSttlmDt>'||IntrBkSttlmDt||'</IntrBkSttlmDt>
        <SttlmInf>
          <SttlmMtd>'||SttlmMtd||'</SttlmMtd>
          <ClrSys>
            <Prtry>'||Prtry||'</Prtry>
          </ClrSys>
        </SttlmInf>
        <InstgAgt>
          <FinInstnId>
            <BIC>'||FinInstnId||'</BIC>
          </FinInstnId>
        </InstgAgt>
      </GrpHdr>';
  
  xml_:=xml_static_start||xml_GrpHdr||xml_CdtTrfTxInf||xml_static_end;
  
  
      RETURN xml_;
        --RETURN 1;
        EXCEPTION
          WHEN OTHERS THEN
          VB_TRACE.Error_Handler(SQLERRM);
            RETURN SQLERRM;
        
        END;*/

  PROCEDURE GENERATE_XML(P_SEND_NO NUMBER, REF_CURS OUT SYS_REFCURSOR) AS
    XML_STATIC_START CLOB;
    XML_STATIC_END   CLOB;
    XML_GRPHDR       CLOB;
    XML_CDTTRFTXINF  CLOB;
    XML_             CLOB;
  
    RKC_SEND_H_DT        DATE;
    MSGID                VARCHAR2(35);
    CREDTTM              VARCHAR2(50);
    NBOFTXS              NUMBER;
    TTLINTRBKSTTLMAMT    NUMBER;
    TTLINTRBKSTTLMAMTCCY VARCHAR2(3);
    INTRBKSTTLMDT        VARCHAR2(50);
    STTLMMTD             VARCHAR2(50);
    PRTRY                VARCHAR2(50);
    FININSTNID           VARCHAR2(50);
    INSTRID              VARCHAR2(50);
    ENDTOENDID           VARCHAR2(50);
  
    TXID              VARCHAR2(50);
    CD                VARCHAR2(20);
    INTRBKSTTLMAMT    NUMBER;
    INTRBKSTTLMAMTCCY VARCHAR2(3);
    CHRGBR            VARCHAR2(50);
    DBTRNM            VARCHAR2(900);
    DBTRIBAN          VARCHAR2(50);
    DBTRBIC           VARCHAR2(50);
    CDTRBIC           VARCHAR2(50);
    CDTRNM            VARCHAR2(900);
    CDTRIBAN          VARCHAR2(50);
  
    USTRD            VARCHAR2(2000);
    MFO_D            VARCHAR2(50);
    MFO_C            VARCHAR2(50);
    CUST_NO          NUMBER;
    PURP             VARCHAR2(2000);
    TREASURY_CODE    VARCHAR2(50);
    IND              NUMBER;
    V_STRING         LONG;
    V_INDEX          NUMBER;
    DBTRTAX          VARCHAR(50);
    CDTRTAX          VARCHAR(50);
    CDTRTAXXML       VARCHAR2(500);
    ADRLINE          VARCHAR2(1000);
    LEN              NUMBER;
    ADRLINEXML       VARCHAR2(1500);
    THIRDPERSONTAX   VARCHAR2(50);
    THIRDPERSONNM    VARCHAR2(900);
    ADD_INFO         VARCHAR2(900);
    PAY_DT           DATE;
    SIGNED_DT        DATE;
    SIGNATURE_RESULT CLOB;
    SIGNATURE        CLOB;
    DBTRACC          VARCHAR2(50);
    TIN              VARCHAR2(50);
    TPN              VARCHAR2(900);
    PON              VARCHAR2(50);
    POD              VARCHAR2(50);
    PPD              VARCHAR2(50);
    ADI              VARCHAR2(900);
    TTC              VARCHAR2(50);
    VALUE_DT         DATE;
    ID_              VARCHAR2(50);
    resident          VARCHAR2(10);   
    COUNTER NUMBER;
    reference VARCHAR2(100);
    actual_reference VARCHAR2(100);
    found_slesh NUMBER;
    num_after_slash VARCHAR2(100);
    v_allowed_chars varchar2(100);
		v_allowed_chars_remarks varchar2(100);
    CURSOR TRANS IS
    SELECT DOC_NO, PRIV_NO
    FROM RKC_SEND_E
    WHERE SEND_NO = P_SEND_NO
    ORDER BY PRIV_NO;

  BEGIN
    v_allowed_chars:='[^a-zA-Z0-9/?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
    v_allowed_chars_remarks:='[^a-zA-Z0-9?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
		
    XML_STATIC_START := '<?xml version = "1.0" encoding = "UTF-8"?> 
<Document  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:iso:std:iso:20022:tech:xsd:pacs.008.001.02">
  <FIToFICstmrCdtTrf>
 ';
  
    XML_STATIC_END := '</FIToFICstmrCdtTrf>
</Document>
';
    IND            := 1;
    MSGID          := TO_CHAR(P_SEND_NO);
    CREDTTM        := TO_CHAR(SYSDATE, 'yyyy-mm-dd"T"hh:mi:ss');
    SELECT CREATED
      INTO RKC_SEND_H_DT
      FROM RKC_SEND_H
     WHERE SEND_NO = P_SEND_NO;
    --INTRBKSTTLMDT := TO_CHAR(RKC_SEND_H_DT, 'yyyy-mm-dd');
     INTRBKSTTLMDT        := TO_CHAR(SYSDATE, 'yyyy-mm-dd');
    STTLMMTD             := 'CLRG';
    PRTRY                := 'ST2';
    FININSTNID           := 'DISNGE22';
    TTLINTRBKSTTLMAMTCCY := 'GEL';
    TTLINTRBKSTTLMAMT    := 0;
    NBOFTXS              := 0;
  
    XML_CDTTRFTXINF := '';
    FOR A IN TRANS LOOP
    
    
    SELECT COUNT(*)
    INTO COUNTER
    FROM DOCUMENTS_ID_CODE
    WHERE NO = A.DOC_NO
    AND ID_CODE = 'MT_ID';
       
    IF (COUNTER=0) THEN
      reference:=to_char(A.DOC_NO);
    ELSE    
      SELECT id_value INTO actual_reference FROM  DOCUMENTS_ID_CODE
      WHERE NO = A.DOC_NO
      AND ID_CODE = 'MT_ID';

     found_slesh:=INSTR(actual_reference,'/',1,1);
             
      IF (found_slesh=0) THEN
        reference:=actual_reference||'/1';             
      ELSE
        num_after_slash:=substr(actual_reference,found_slesh+1);
        reference:=to_char(A.DOC_NO)||'/'||to_char(num_after_slash+1);          
      END IF;    
    END IF;
    
    BTA_MT.CREATE_REFERENCE(A.DOC_NO, reference);

/*    INSTRID := MSGID || '/' || A.PRIV_NO;
      TXID    := INSTRID;*/
      
    INSTRID:=reference;
    TXID    := INSTRID;
    CD      := 'SEPA';
    
      CHRGBR  := 'SLEV'; -- magalitshi ecera SLEV
      NBOFTXS := NBOFTXS + 1;
      SELECT DEBIT_ACC_ID,
             DEBIT_ACC_ID,
             CREDIT_ACC_ID,
             AMOUNT_CUR_1,
             CURRENCY_NO_1,
             GET_TEXT_SUBSTR(REGEXP_REPLACE(PAYMENT_PURPOSE,v_allowed_chars,''), 'PAYMENT_PURPOSE'),
             GET_TEXT_SUBSTR(REGEXP_REPLACE(REMARKS,v_allowed_chars_remarks,''), 'REMARKS'),
             MFO_REM,
             MFO_REC,
             RECEIPIENT_NAME,
             REMITTANT_NAME,
             trim(CBC),
             SUBSTR(REGEXP_REPLACE(TRIM(ID),'[^0-9]',''), 1, 6),
             nvl(REM_TAX_NUMBER,'11111111111'),
             REC_TAX_NUMBER,
             REGEXP_REPLACE(THIRD_PERSON_TAX_NUMBER,'[^0-9]',''),
						 GET_TEXT_SUBSTR(REGEXP_REPLACE(TRIM(THIRD_PERSON_NAME),v_allowed_chars,''), 'THIRD_PERSON_NAME'),
             PAYMENT_DATE,
             SIGNED,
             VALUE_DATE
      
        INTO DBTRACC,
             DBTRIBAN,
             CDTRIBAN,
             INTRBKSTTLMAMT,
             INTRBKSTTLMAMTCCY,
             PURP,
             ADD_INFO,
             MFO_D,
             MFO_C,
             CDTRNM,
             DBTRNM,
             TREASURY_CODE,
             ID_,
             DBTRTAX,
             CDTRTAX,
             THIRDPERSONTAX,
             THIRDPERSONNM,
             PAY_DT,
             SIGNED_DT,
             VALUE_DT
        FROM DOCUMENTS
       WHERE NO = A.DOC_NO;
    

DBTRIBAN:=SUBSTR(DBTRIBAN,1,LENGTH(DBTRIBAN)-3);

     /* IF (LENGTH(DBTRIBAN) != 25) THEN
        DBTRIBAN := IBAN.GET_IBAN(DBTRIBAN, 0);
      END IF;
    
      IF (LENGTH(CDTRIBAN) != 22) THEN
        CDTRIBAN := IBAN.GET_IBAN(CDTRIBAN, 0);
      END IF;*/
    
      SELECT CUSTOMER_NO
        INTO CUST_NO
        FROM ACCOUNTS_MAIN
       WHERE ID = DBTRACC;
      SELECT SWIFT_CODE INTO DBTRBIC FROM BNKSEEK WHERE NEWNUM = MFO_D;
      SELECT SWIFT_CODE INTO CDTRBIC FROM BNKSEEK WHERE NEWNUM = MFO_C;
      SELECT GET_TEXT_SUBSTR(REGEXP_REPLACE(TRIM(ADDRESS),v_allowed_chars,''), 'ADDRESS'),res_flag
        INTO ADRLINE,resident
        FROM CUSTOMERS
       WHERE NO = CUST_NO;    
    
      ENDTOENDID := ID_;
      IF (ENDTOENDID IS NULL) THEN
        ENDTOENDID := 'NOTPROVIDED';
      END IF;
    
      TTLINTRBKSTTLMAMT := TTLINTRBKSTTLMAMT + INTRBKSTTLMAMT;
    
      IF (TREASURY_CODE IS NOT NULL) THEN
        CDTRIBAN := TREASURY_CODE;
      END IF;
    
      TTC := '/TTC/8008';
      TIN := '';
      TPN := '';
      PON := '';
      POD := '';
      PPD := '';
      ADI := '';
    
      IF (resident IS NULL OR resident='Н' ) THEN
        /*BEGIN(RTGS-1055)*/
        THIRDPERSONTAX:='00000000000';
        /*END(RTGS-1055)*/
      END IF;

      IF (TRIM(THIRDPERSONTAX) IS NOT NULL AND
         TRIM(THIRDPERSONTAX) != '111111111') THEN
        TIN := '/TIN/' || TRIM(THIRDPERSONTAX);
      END IF;
			
      IF (TREASURY_CODE IS NOT NULL) THEN
        IF (TRIM(THIRDPERSONNM) IS NOT NULL OR TRIM(THIRDPERSONNM) != '') THEN
          TPN := '/TPN/' || TRIM(THIRDPERSONNM);
        END IF;
      END IF;
			
      IF (TRIM(ID_) IS NOT NULL OR TRIM(ID_) != '') THEN
        PON := '/PON/' || TRIM(ID_);
      END IF;
			
      IF (TRIM(TO_CHAR(PAY_DT, 'YYMMDD')) IS NOT NULL OR
         TRIM(TO_CHAR(PAY_DT, 'YYMMDD')) != '') THEN
        POD := '/POD/' || TRIM(TO_CHAR(PAY_DT, 'YYMMDD'));
      ELSE
        POD := '/POD/' || TRIM(TO_CHAR(VALUE_DT, 'YYMMDD'));
      END IF;
    
      IF (TRIM(TO_CHAR(SIGNED_DT, 'YYMMDD')) IS NOT NULL OR
         TRIM(TO_CHAR(SIGNED_DT, 'YYMMDD')) != '') THEN
        PPD := '/PPD/' || TRIM(TO_CHAR(SIGNED_DT, 'YYMMDD'));
      ELSE
        PPD := '/PPD/' || TRIM(TO_CHAR(VALUE_DT, 'YYMMDD'));
      END IF;
      
			IF (TRIM(ADD_INFO) IS NOT NULL OR TRIM(ADD_INFO) != '') THEN
        ADI := '/ADI/' || ADD_INFO;
      END IF;
    
      USTRD := TTC || TIN || TPN || PON || POD || PPD || ADI || '/';
    
      /*  USTRD := '/TTC/1112/TIN/' || TRIM(THIRDPERSONTAX) || '/TPN/' ||
      TRIM(THIRDPERSONNM) || '/PON/' || TRIM(ENDTOENDID) ||
      '/POD/' || TRIM(TO_CHAR(PAY_DT, 'YYMMDD')) || '/PPD/' ||
      TRIM(TO_CHAR(SIGNED_DT, 'YYMMDD')) || '/ADI/' ||
      TRIM(ADD_INFO);*/
    
      CDTRTAXXML := '';
      IF (CDTRTAX IS NOT NULL) THEN
        CDTRTAXXML := '<Id>
        <PrvtId>
          <Othr>
            <Id>' || CDTRTAX || '</Id>
          </Othr>
        </PrvtId>
      </Id>';
      END IF;
			
      ADRLINEXML := '';
      IF (ADRLINE IS NOT NULL) THEN
        ADRLINEXML := ADRLINE;
        IF (LENGTH(ADRLINEXML) > 70) THEN
          ADRLINEXML := '<PstlAdr>
          <AdrLine>' || SUBSTR(ADRLINEXML, 1, 70) ||
                        '</AdrLine>
          <AdrLine>' || SUBSTR(ADRLINEXML, 71, 70) ||
                        '</AdrLine>
        </PstlAdr>';
        ELSE
          ADRLINEXML := '<PstlAdr>
          <AdrLine>' || ADRLINEXML || '</AdrLine>
        </PstlAdr>';
        END IF;
      END IF;
			
			DBTRNM := GET_TEXT_SUBSTR(REGEXP_REPLACE(TRIM(get_token(DBTRNM,1,',')),v_allowed_chars,''), 'REMITTANT_NAME');
      CDTRNM := GET_TEXT_SUBSTR(REGEXP_REPLACE(TRIM(CDTRNM),v_allowed_chars,''), 'RECEIPIENT_NAME');
    
      XML_CDTTRFTXINF := XML_CDTTRFTXINF || '
    <CdtTrfTxInf>
      <PmtId>
        <InstrId>' || INSTRID || '</InstrId>
        <EndToEndId>' || ENDTOENDID || '</EndToEndId>
        <TxId>' || TXID || '</TxId>
      </PmtId>
      <PmtTpInf>
        <SvcLvl>
          <Cd>' || CD ||
                         '</Cd>
        </SvcLvl>
      </PmtTpInf>
      <IntrBkSttlmAmt Ccy="' ||
                         VB_CURRENCIES_S.GET_CHARACTER_CCY(INTRBKSTTLMAMTCCY) || '">' ||
                         TRIM(TO_CHAR(INTRBKSTTLMAMT, '999999999990.00')) ||
                         '</IntrBkSttlmAmt>
      <ChrgBr>' || CHRGBR || '</ChrgBr>
      <Dbtr>
        <Nm>' || DBTRNM || '</Nm>  
        ' || ADRLINEXML || '
        <Id>
          <OrgId>
            <Othr>
              <Id>' || DBTRTAX || '</Id>
            </Othr>
          </OrgId>
        </Id>
      </Dbtr>
      <DbtrAcct>
        <Id>
          <IBAN>' || DBTRIBAN || '</IBAN>
        </Id>
      </DbtrAcct>
      <DbtrAgt>
        <FinInstnId>
          <BIC>' || DBTRBIC || '</BIC>
        </FinInstnId>
      </DbtrAgt>
      <CdtrAgt>
        <FinInstnId>
          <BIC>' || CDTRBIC || '</BIC>
        </FinInstnId>
      </CdtrAgt>
      <Cdtr>
        <Nm>' || CDTRNM || '</Nm>' || CDTRTAXXML || '
      </Cdtr>
      <CdtrAcct>
        <Id>
          <IBAN>' || CDTRIBAN || '</IBAN>
        </Id>
      </CdtrAcct>
      <Purp>
        <Prtry>' || PURP || '</Prtry>  
      </Purp>
      <RmtInf>
        <Ustrd>' || USTRD || '</Ustrd>
      </RmtInf>
    </CdtTrfTxInf>';
    
    /*xml_CdtTrfTxInf:=xml_CdtTrfTxInf||'
                                                <CdtTrfTxInf>
                                                    <SvcLvl>
                                                      <Cd>'||Cd||'</Cd>
                                                    </SvcLvl>
                                                  </PmtTpInf>
                                                  <ChrgBr>'||ChrgBr||'</ChrgBr>';
                                                signature_result:=sign(xml_CdtTrfTxInf);*/
    END LOOP;
    XML_GRPHDR := '<GrpHdr>
      <MsgId>' || MSGID || '</MsgId>
      <CreDtTm>' || CREDTTM || '</CreDtTm>
      <NbOfTxs>' || NBOFTXS ||
                  '</NbOfTxs>
      <TtlIntrBkSttlmAmt Ccy="' || TTLINTRBKSTTLMAMTCCY || '">' ||
                  TRIM(TO_CHAR(TTLINTRBKSTTLMAMT, '99999999999990.00')) ||
                  '</TtlIntrBkSttlmAmt>
      <IntrBkSttlmDt>' || INTRBKSTTLMDT ||
                  '</IntrBkSttlmDt>
      <SttlmInf>
        <SttlmMtd>' || STTLMMTD || '</SttlmMtd>
        <ClrSys>
          <Prtry>' || PRTRY || '</Prtry>
        </ClrSys>
      </SttlmInf>
      <InstgAgt>
        <FinInstnId>
          <BIC>' || FININSTNID || '</BIC>
        </FinInstnId>
      </InstgAgt>
    </GrpHdr>';
  
    XML_ := XML_STATIC_START || XML_GRPHDR || XML_CDTTRFTXINF ||
            XML_STATIC_END;
    /*signature_result:=sign('asdasdasdad""adasdasdasd');*/
  
    IND     := 1;
    V_INDEX := 0;
  
    DELETE FROM TEMP_RKC_XML WHERE SEND_NO = P_SEND_NO;
    COMMIT;
  
    LOOP
      V_STRING := NULL;
    
      V_STRING := DBMS_LOB.SUBSTR(XML_, 10000, 1 + V_INDEX * 10000);
      IF (V_STRING IS NOT NULL) THEN
        INSERT INTO TEMP_RKC_XML VALUES (IND, V_STRING, P_SEND_NO, NULL);
        COMMIT;
        V_INDEX := V_INDEX + 1;
        IND     := IND + 1;
      ELSE
        EXIT;
      END IF;
    
    END LOOP;
    OPEN REF_CURS FOR
      SELECT XML_VALUE
        FROM TEMP_RKC_XML
       WHERE SEND_NO = P_SEND_NO
       ORDER BY ORD_NO;
  
  EXCEPTION
    WHEN OTHERS THEN
      VB_TRACE.ERROR_HANDLER(SQLERRM);
    
      REF_CURS := NULL;
    
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
  PROCEDURE SERIALIZE_BULK_INTO_PAYMENT(P_XML CLOB, P_MSG_ID VARCHAR2) AS
    XML            XMLTYPE;
    XML_RECEIVED   CLOB;
    S_BANK_BIC     VARCHAR2(50);
    S_BANK_MFO     VARCHAR2(50);
    S_ACC          VARCHAR2(50);
    S_TAX          VARCHAR2(50);
    S_NAME         VARCHAR2(500);
    R_ACC          VARCHAR2(50);
    R_TAX          VARCHAR(50);
    R_NAME         VARCHAR2(500);
    AM             NUMBER;
    REMARKS        VARCHAR2(1000);
    PURPOSE        VARCHAR2(1000);
    VIPNO          NUMBER;
    DOC_NO         VARCHAR2(50);
    ERROR_MSG      VARCHAR2(2000);
    ACC_COUNTER    NUMBER;
    ACC_FROM_IBAN  VARCHAR2(100);
    START_POS      NUMBER;
    END_POS        NUMBER;
    DOC_ID         VARCHAR2(50);
    THIRD_PERS_TAX VARCHAR2(50);
    THIRD_PERS_NM  VARCHAR2(500);
    ADITIONAL_INFO VARCHAR2(500);
    POD            VARCHAR2(10);
    PPD            VARCHAR2(10);
    PAYMENT_DT     DATE;
    SIGNED         DATE;
    msg_id     VARCHAR2(500);
    settlmntdate VARCHAR2(50);
    totalamount VARCHAR2(50);
    bic VARCHAR2(50);
    dublicate NUMBER;
    dubl_exc EXCEPTION;
    CURSOR XML_PIECES IS
      SELECT COLUMN_VALUE
        FROM TABLE(XMLSEQUENCE(XMLTYPE(XML_RECEIVED)
                               .EXTRACT('/Document/FIToFICstmrCdtTrf/CdtTrfTxInf'))) T;
  
  BEGIN
    XML_RECEIVED := P_XML;
    XML          := XMLTYPE.CREATEXML(XML_RECEIVED);
    VIPNO        := INSERT_RKC_HEADER('BULK');
    IF (VIPNO = 0) THEN
      ERROR_MSG := 'Procedure: serialize_xml_into_payment; ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERROR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERROR_MSG);
    END IF;
    
    BEGIN
        msg_id := TRIM(XML.EXTRACT('/Document/FIToFICstmrCdtTrf/GrpHdr/MsgId/text()')
                       .GETSTRINGVAL());
      EXCEPTION
        WHEN others THEN
       msg_id:='';
      END;
        BEGIN
        settlmntdate := TRIM(XML.EXTRACT('/Document/FIToFICstmrCdtTrf/GrpHdr/IntrBkSttlmDt/text()')
                       .GETSTRINGVAL());
      EXCEPTION
              WHEN others THEN
       settlmntdate:='';
      END;
    
            BEGIN
        totalamount := TRIM(XML.EXTRACT('/Document/FIToFICstmrCdtTrf/GrpHdr/TtlIntrBkSttlmAmt/text()')
                       .GETSTRINGVAL());
      EXCEPTION
              WHEN others THEN
       totalamount:='';
      END;
      
      BEGIN
         bic := TRIM(XML.EXTRACT('/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/BIC/text()')
                       .GETSTRINGVAL());
      EXCEPTION
              WHEN others THEN
       bic:='';
      END;
    
                  dublicate :=bta_mt.is_dublicate_msg(msg_id,totalamount,settlmntdate,bic,'BULK');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
    
    
    IF (P_MSG_ID != 0 AND VIPNO > 0) THEN
      UPDATE RTGS_RECEIVED
         SET REFER = TO_CHAR(VIPNO)
       WHERE MSG_ID = P_MSG_ID;
      COMMIT;
    END IF;
    FOR A IN XML_PIECES LOOP
      --CdtTrfTxInf:=a.xml_piece;
      
       
      
      
      BEGIN
        DOC_NO := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/PmtId/EndToEndId/text()')
                       .GETSTRINGVAL());
      EXCEPTION
        WHEN OTHERS THEN
          SELECT MAX(NO_STR) + 1
            INTO DOC_NO
            FROM RKC_VIP_E
           WHERE VIP_NO = VIPNO;
      END;
      BEGIN
        S_BANK_BIC := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/DbtrAgt/FinInstnId/BIC/text()')
                           .GETSTRINGVAL());
        SELECT NEWNUM
          INTO S_BANK_MFO
          FROM BNKSEEK T
         WHERE SWIFT_CODE = S_BANK_BIC
           AND IS_HEAD = 1; -- MAX DROEBITIA
        S_ACC := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/DbtrAcct/Id/IBAN/text()')
                      .GETSTRINGVAL());
        BEGIN
          S_TAX := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Dbtr/Id/PrvtId/Othr/Id/text()')
                        .GETSTRINGVAL());
        EXCEPTION
          WHEN OTHERS THEN
            BEGIN
              S_TAX := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Dbtr/Id/OrgId/Othr/Id/text()')
                            .GETSTRINGVAL());
            EXCEPTION
              WHEN OTHERS THEN
                S_TAX := '';
            END;
        END;
        BEGIN
          S_NAME := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Dbtr/Nm/text()')
                         .GETSTRINGVAL());
          S_NAME := REPLACE(S_NAME, '&quot;', '"');
          S_NAME := REPLACE(S_NAME, '&apos;', '''');
          S_NAME := REPLACE(S_NAME, '&amp;', '&');
        EXCEPTION
          WHEN OTHERS THEN
            S_NAME := '';
        END;
        BEGIN
          AM := TO_NUMBER(TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/IntrBkSttlmAmt/text()')
                               .GETSTRINGVAL()));
        EXCEPTION
          WHEN OTHERS THEN
            AM := '';
        END;
        BEGIN
          R_ACC := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/CdtrAcct/Id/IBAN/text()')
                        .GETSTRINGVAL());
        EXCEPTION
          WHEN OTHERS THEN
            R_ACC := '';
        END;
        IF (R_ACC IS NOT NULL) THEN
        
          R_ACC := R_ACC || 'GEL';
          SELECT COUNT(*)
            INTO ACC_COUNTER
            FROM ACCOUNTS_MAIN
           WHERE ID = R_ACC;
          IF (ACC_COUNTER = 0) THEN
          begin
            ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(R_ACC);
            Exception
              when others then
                null;
                end;
            IF (ACC_FROM_IBAN IS NOT NULL) THEN
              SELECT COUNT(*)
                INTO ACC_COUNTER
                FROM ACCOUNTS_MAIN
               WHERE ID = ACC_FROM_IBAN;
              IF (ACC_COUNTER = 1) THEN
                R_ACC := IBAN.GET_ACC_FROM_IBAN(R_ACC);
              END IF;
            END IF;
          
          END IF;
        END IF;
        BEGIN
          R_TAX := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Cdtr/Id/PrvtId/Othr/Id/text()')
                        .GETSTRINGVAL());
        EXCEPTION
          WHEN OTHERS THEN
            BEGIN
              R_TAX := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Cdtr/Id/OrgId/Othr/Id/text()')
                            .GETSTRINGVAL());
            EXCEPTION
              WHEN OTHERS THEN
                R_TAX := '';
            END;
        END;
        BEGIN
          R_NAME := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Cdtr/Nm/text()')
                         .GETSTRINGVAL());
          R_NAME := REPLACE(R_NAME, '&quot;', '"');
          R_NAME := REPLACE(R_NAME, '&apos;', '''');
          R_NAME := REPLACE(R_NAME, '&amp;', '&');
        EXCEPTION
          WHEN OTHERS THEN
            R_NAME := '';
        END;
        BEGIN
          PURPOSE := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/Purp/Prtry/text()')
                          .GETSTRINGVAL());
          PURPOSE := REPLACE(PURPOSE, '&quot;', '"');
          PURPOSE := REPLACE(PURPOSE, '&apos;', '''');
          PURPOSE := REPLACE(PURPOSE, '&amp;', '&');
        EXCEPTION
          WHEN OTHERS THEN
            PURPOSE := '';
        END;
        BEGIN
          REMARKS := TRIM(A.COLUMN_VALUE.EXTRACT('/CdtTrfTxInf/RmtInf/Ustrd/text()')
                          .GETSTRINGVAL());
          REMARKS := REPLACE(REMARKS, '&quot;', '"');
          REMARKS := REPLACE(REMARKS, '&apos;', '''');
          REMARKS := REPLACE(REMARKS, '&amp;', '&');
        EXCEPTION
          WHEN OTHERS THEN
            REMARKS := '';
        END;
      
        IF (REMARKS IS NOT NULL) THEN
          /* START_POS := INSTR(REMARKS, '/PON', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          DOC_ID := SUBSTR(REMARKS, START_POS + 5, END_POS - START_POS - 5);*/
          DOC_ID := trim(GET_STRUCT_FIELD_VALUE(REMARKS, 'PON'));
        
          /* START_POS := INSTR(REMARKS, '/TIN', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          THIRD_PERS_TAX := SUBSTR(REMARKS,
                                   START_POS + 5,
                                   END_POS - START_POS - 5);*/
          THIRD_PERS_TAX := GET_STRUCT_FIELD_VALUE(REMARKS, 'TIN');
        
          /*  START_POS := INSTR(REMARKS, '/TPN', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          THIRD_PERS_NM := SUBSTR(REMARKS,
                                  START_POS + 5,
                                  END_POS - START_POS - 5);*/
        
          THIRD_PERS_NM := GET_STRUCT_FIELD_VALUE(REMARKS, 'TPN');
        
          /*START_POS := INSTR(REMARKS, '/ADI', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          ADITIONAL_INFO := SUBSTR(REMARKS,
                                   START_POS + 5,
                                   END_POS - START_POS - 5);*/
        
          ADITIONAL_INFO := GET_STRUCT_FIELD_VALUE(REMARKS, 'ADI');
        
          /*  START_POS := INSTR(REMARKS, '/POD', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          POD        := SUBSTR(REMARKS,
                               START_POS + 5,
                               END_POS - START_POS - 5);*/
          POD        := GET_STRUCT_FIELD_VALUE(REMARKS, 'POD');
          PAYMENT_DT := NVL(TO_DATE(POD, 'YYMMDD'), TRUNC(SYSDATE));
        
          /* START_POS := INSTR(REMARKS, '/PPD', 1, 1);
          END_POS   := INSTR(REMARKS, '/', START_POS + 5, 1);
          IF (END_POS = 0 AND START_POS != 0) THEN
            END_POS := LENGTH(REMARKS) + 1;
          END IF;
          PPD    := SUBSTR(REMARKS, START_POS + 5, END_POS - START_POS - 5);*/
        
          PPD    := GET_STRUCT_FIELD_VALUE(REMARKS, 'PPD');
          SIGNED := NVL(TO_DATE(PPD, 'YYMMDD'), TRUNC(SYSDATE));
        END IF;
      
      EXCEPTION
        WHEN OTHERS THEN
          ERROR_MSG := 'Procedure: serialize_xml_into_payment; ERROR TEXT: ' || SUBSTR(SQLERRM, 1, 1000);
          SEND_MAIL('rtgs@bta.ge',
                    'error_log@bta.ge',
                    'RTGS_ERROR',
                    ERROR_MSG);
          ROLLBACK;
          RAISE_APPLICATION_ERROR(-20000, ERROR_MSG);
      END;
      INSERT_RKC_ENTRY(VIPNO,
                       DOC_ID,
                       S_BANK_MFO,
                       S_ACC,
                       S_TAX,
                       S_NAME,
                       AM,
                       '220101827',
                       R_ACC,
                       R_TAX,
                       R_NAME,
                       TRUNC(SYSDATE),
                       ADITIONAL_INFO,
                       PURPOSE,
                       PAYMENT_DT,
                       SIGNED);
    END LOOP;
    COMMIT;
  
  EXCEPTION
    WHEN dubl_exc THEN 
      ERROR_MSG := 'BULK is DUBLICATED: '||msg_id||' '||totalamount||' '||settlmntdate;
        RAISE_APPLICATION_ERROR(-20001, ERROR_MSG); 
  
    WHEN OTHERS THEN
      ERROR_MSG := 'Procedure: SERIALIZE_BULK_INTO_PAYMENT; ERROR TEXT: ' || SUBSTR(SQLERRM, 1, 1500);
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERROR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERROR_MSG);
    
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE SERIALIZE_BULK_STATUS(P_XML CLOB, P_MSG_ID VARCHAR2) AS
    XML          XMLTYPE;
    XML_RECEIVED CLOB;
    MSG_ID       VARCHAR2(100);
    CRE_DT_TM    VARCHAR2(100);
    REC_BIC      VARCHAR2(50);
    ORGNL_MSG_ID VARCHAR2(100);
    ORGNL_MSG_NM VARCHAR2(100);
    GRP_STATUS   VARCHAR2(50);
    GRP_REASON   VARCHAR2(100);
  
    TRAN_STAT_ID        VARCHAR2(100);
    ORG_TRN_ID          VARCHAR2(100);
    ORG_TRN_ENDTOEND_ID VARCHAR2(100);
    TRN_STAT            VARCHAR2(50);
    VB_TRN_NO           VARCHAR2(50);
    ERROR_MSG           VARCHAR2(2000);
    SENDNO              NUMBER;
    PRIVNO              NUMBER;
    DOCNO               NUMBER;
    CURSOR XML_PIECES IS
      SELECT COLUMN_VALUE
        FROM TABLE(XMLSEQUENCE(XMLTYPE(XML_RECEIVED)
                               .EXTRACT('/Document/FIToFIPmtStsRpt/TxInfAndSts'))) T;
  
    CURSOR RKC_DOCS_PART IS
    /*  SELECT E.DOC_NO
        FROM RKC_SEND_E E
       WHERE E.SEND_NO = SENDNO
         AND E.PRIV_NO = PRIVNO;*/
         SELECT E.DOC_NO
        FROM RKC_SEND_E E
       WHERE E.SEND_NO = SENDNO
         AND E.DOC_NO = DOCNO;
  
    CURSOR RKC_DOCS_FULL IS
      SELECT E.DOC_NO FROM RKC_SEND_E E WHERE E.SEND_NO = SENDNO;
  
  BEGIN
    XML_RECEIVED := P_XML;
    XML          := XMLTYPE.CREATEXML(XML_RECEIVED);
  
    BEGIN
      MSG_ID := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/GrpHdr/MsgId/text()')
                     .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        MSG_ID := '';
    END;
  
    BEGIN
      CRE_DT_TM := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/GrpHdr/CreDtTm/text()')
                        .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        CRE_DT_TM := '';
    END;
  
    BEGIN
      REC_BIC := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/GrpHdr/InstdAgt/FinInstnId/BIC/text()')
                      .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        REC_BIC := '';
    END;
  
    BEGIN
      ORGNL_MSG_ID := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlMsgId/text()')
                           .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        ORGNL_MSG_ID := '';
    END;
    IF (P_MSG_ID != '0' AND ORGNL_MSG_ID IS NOT NULL) THEN
      UPDATE RTGS_RECEIVED
         SET REFER = ORGNL_MSG_ID
       WHERE MSG_ID = TO_NUMBER(P_MSG_ID);
      COMMIT;
    END IF;
    BEGIN
      ORGNL_MSG_NM := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlMsgNmId/text()')
                           .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        ORGNL_MSG_NM := '';
    END;
  
    BEGIN
      GRP_STATUS := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/GrpSts/text()')
                         .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        GRP_STATUS := '';
    END;
  
    BEGIN
      GRP_REASON := TRIM(XML.EXTRACT('/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/StsRsnInf/Rsn/Cd/text()')
                         .GETSTRINGVAL());
    EXCEPTION
      WHEN OTHERS THEN
        GRP_REASON := '';
    END;
    FOR A IN XML_PIECES LOOP
      BEGIN
        TRAN_STAT_ID := TRIM(A.COLUMN_VALUE.EXTRACT('/TxInfAndSts/StsId/text()')
                             .GETSTRINGVAL());
      EXCEPTION
        WHEN OTHERS THEN
          TRAN_STAT_ID := '';
      END;
    
      BEGIN
        ORG_TRN_ID := TRIM(A.COLUMN_VALUE.EXTRACT('/TxInfAndSts/OrgnlInstrId/text()')
                           .GETSTRINGVAL());
      EXCEPTION
        WHEN OTHERS THEN
          ORG_TRN_ID := '';
      END;
    
      BEGIN
        ORG_TRN_ENDTOEND_ID := TRIM(A.COLUMN_VALUE.EXTRACT('/TxInfAndSts/OrgnlEndToEndId/text()')
                                    .GETSTRINGVAL());
      EXCEPTION
        WHEN OTHERS THEN
          ORG_TRN_ENDTOEND_ID := '';
      END;
    
      BEGIN
        TRN_STAT := TRIM(A.COLUMN_VALUE.EXTRACT('/TxInfAndSts/TxSts/text()')
                         .GETSTRINGVAL());
      EXCEPTION
        WHEN OTHERS THEN
          TRN_STAT := '';
      END;
    
      IF (ORG_TRN_ID IS NOT NULL) THEN
     /*   VB_TRN_NO := SUBSTR(ORG_TRN_ID, INSTR(ORG_TRN_ID, '/', 1, 1) + 1);*/
     VB_TRN_NO  :=ORG_TRN_ID;
        IF (TRN_STAT = 'RJCT') THEN
          SENDNO := TO_NUMBER(ORGNL_MSG_ID);
         /* PRIVNO := TO_NUMBER(VB_TRN_NO);*/
           SELECT NO
      INTO DOCNO
      FROM DOCUMENTS_ID_CODE
     WHERE ID_CODE = 'MT_ID'
       AND ID_VALUE = VB_TRN_NO;
         
          FOR A IN RKC_DOCS_PART LOOP
            REJECT_DOCUMENT(A.DOC_NO);
          
          END LOOP;
         /* DELETE FROM RKC_SEND_E E
           WHERE E.SEND_NO = SENDNO
             AND E.PRIV_NO = PRIVNO;*/
             DELETE FROM RKC_SEND_E E
           WHERE E.SEND_NO = SENDNO
             AND E.DOC_NO = DOCNO;
          COMMIT;
        END IF;
      
      END IF;
    
    END LOOP;
  
    IF (GRP_STATUS = 'ACCP') THEN
      UPDATE RKC_SEND_H H
         SET H.REMARKS = GRP_STATUS
       WHERE H.SEND_NO = TO_NUMBER(ORGNL_MSG_ID);
      COMMIT;
      SENDNO := TO_NUMBER(ORGNL_MSG_ID);
    ELSIF (GRP_STATUS = 'RJCT') THEN
      SENDNO := TO_NUMBER(ORGNL_MSG_ID);
    
      FOR A IN RKC_DOCS_FULL LOOP
        REJECT_DOCUMENT(A.DOC_NO);
      
      END LOOP;
    
      UPDATE RKC_SEND_H H
         SET H.REMARKS = GRP_STATUS
       WHERE H.SEND_NO = SENDNO;
      COMMIT;
      DELETE FROM RKC_SEND_E E WHERE E.SEND_NO = SENDNO;
      COMMIT;
    
    ELSIF (GRP_STATUS = 'PART') THEN
      UPDATE RKC_SEND_H H
         SET H.REMARKS = GRP_STATUS
       WHERE H.SEND_NO = TO_NUMBER(ORGNL_MSG_ID);
      COMMIT;
    
    ELSE
      NULL;
    END IF;
  
    FOR R IN RKC_DOCS_FULL LOOP
      BEGIN
        FIN_DOC(R.DOC_NO);
      EXCEPTION
        WHEN OTHERS THEN
          ERROR_MSG := 'Procedure: SERIALIZE_BULK_STATUS; CANNOT FINALIZE DOC: ' ||
                       R.DOC_NO || ' ERROR TEXT: ' || SUBSTR(SQLERRM, 1, 1500);
          WRITE_REC_MSG_ERR(0, ERROR_MSG);
          COMMIT;
          SEND_MAIL('rtgs@bta.ge',
                    'error_log@bta.ge',
                    'RTGS_ERROR',
                    ERROR_MSG);
      END;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      ERROR_MSG := 'Procedure: SERIALIZE_BULK_STATUS; ERROR TEXT: ' || SUBSTR(SQLERRM, 1, 1500);
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERROR_MSG);
    
      RAISE_APPLICATION_ERROR(-20000, ERROR_MSG);
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  FUNCTION INSERT_RKC_HEADER(P_MSG_TYPE VARCHAR2) RETURN NUMBER AS
    VIPNO  NUMBER;
    REISNO NUMBER;
  BEGIN
    SELECT RKC_VIP_NO.NEXTVAL INTO VIPNO FROM DUAL;
    SELECT COUNT(*)
      INTO REISNO
      FROM RKC_VIP_H
     WHERE CREATED = TRUNC(SYSDATE);
  
    INSERT INTO RKC_VIP_H H
      (H.BRANCH,
       H.VIP_NO,
       H.NO_RKC,
       H.NO_CORR,
       H.T_DT,
       H.P_DT,
       H.CREATED,
       H.INSERTED,
       H.CREATED_BY,
       H.AMOUNT_BEG,
       H.AMOUNT_END,
       H.TYPE_FLAG,
       H.REMARKS,
       H.REIS_NO,
       H.EDNO,
       H.EDAUTHOR)
    VALUES
      ('SRB',
       VIPNO,
       '220101107',
       1,
       TRUNC(SYSDATE),
       TRUNC(SYSDATE),
       TRUNC(SYSDATE),
       SYSDATE,
       USER,
       NULL,
       NULL,
       'C',
       P_MSG_TYPE, -- failis saxeli unda ikos
       REISNO,
       NULL,
       NULL);
    --COMMIT;
    RETURN VIPNO;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE INSERT_RKC_ENTRY(P_VIP_NO       NUMBER,
                             P_DOC_NO       VARCHAR2,
                             P_S_BN_MFO     VARCHAR2,
                             P_SENDER_ACC   VARCHAR2,
                             P_SENDER_TAX   VARCHAR2,
                             P_SENDER_NM    VARCHAR2,
                             P_AMOUNT       NUMBER,
                             P_R_BN_MFO     VARCHAR2,
                             P_REC_ACC      VARCHAR2,
                             P_REC_TAX      VARCHAR2,
                             P_REC_NM       VARCHAR2,
                             P_CREATED      DATE,
                             P_REMARKS      VARCHAR2,
                             P_PURPOSE      VARCHAR2,
                             P_PAYMENT_DATE DATE,
                             P_SIGNED       DATE) AS
    NO_STR NUMBER;
    REISNO NUMBER;
  BEGIN
    SELECT COUNT(*) INTO NO_STR FROM RKC_VIP_E WHERE VIP_NO = P_VIP_NO;
    SELECT REIS_NO INTO REISNO FROM RKC_VIP_H WHERE VIP_NO = P_VIP_NO;
    NO_STR := NO_STR + 1;
  
    INSERT INTO RKC_VIP_E
    VALUES
      (P_VIP_NO,
       '01',
       NVL(P_DOC_NO, '0'),
       P_S_BN_MFO,
       P_SENDER_ACC,
       P_AMOUNT,
       NULL,
       'К',
       NO_STR,
       P_REC_ACC,
       NULL,
       NULL,
       NULL,
       P_CREATED,
       P_CREATED,
       USER,
       P_REMARKS,
       NULL,
       NULL,
       NULL,
       P_SENDER_TAX,
       P_SENDER_NM,
       P_R_BN_MFO,
       NULL,
       P_REC_TAX,
       NULL,
       P_REC_NM,
       P_PAYMENT_DATE,
       NULL,
       TO_CHAR(REISNO || '-' || NO_STR),
       P_PURPOSE,
       NULL,
       P_SIGNED,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       P_CREATED,
       NULL,
       NULL);
    -- COMMIT;
  
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  FUNCTION SIGN(FILE_PATH VARCHAR2) RETURN VARCHAR2 AS
    SIGN_RESULT VARCHAR2(1000);
    PARAMS      WEB_SERVICE_CLOB.PARAMETERS_TABLE;
  BEGIN
  
    PARAMS(1).PARAM := 'file_path';
    PARAMS(1).VALUE := FILE_PATH;
/*BEGIN(ORA-WS-826)*/  
    SIGN_RESULT := WEB_SERVICE_CLOB.EXECUTE_WEB_SERVICE(get_web_service_path('PKCS_CRYPT','REAL'),
                                                        'SignFile',
                                                        PARAMS);
/*END(ORA-WS-826)*/                                                       
  
    RETURN SIGN_RESULT;
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  FUNCTION SEND_BULK_MSG(SEND_NO NUMBER) RETURN VARCHAR2 AS
    RES VARCHAR2(50);
  
    PARAMS WEB_SERVICE.PARAMETERS_TABLE;
  BEGIN
  
    PARAMS(1).PARAM := 'bulk_id';
    PARAMS(1).VALUE := TO_CHAR(SEND_NO);
/*BEGIN(ORA-WS-826)*/  
    RES := WEB_SERVICE.EXECUTE_WEB_SERVICE(get_web_service_path('RTGS_SENDER','REAL'), 'sendBulk', PARAMS);
/*END(ORA-WS-826)*/   
  
    RETURN RES;
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  FUNCTION SEND_MT_MSG(P_MT_MSG VARCHAR2) RETURN VARCHAR2 AS
  
    RES VARCHAR2(50);
  
    PARAMS WEB_SERVICE.PARAMETERS_TABLE;
  BEGIN
  
    PARAMS(1).PARAM := 'MT_msg';
    PARAMS(1).VALUE := P_MT_MSG;
/*BEGIN(ORA-WS-826)*/  
    RES := WEB_SERVICE.EXECUTE_WEB_SERVICE(get_web_service_path('RTGS_SENDER','REAL'), 'sendMT', PARAMS);
/*END(ORA-WS-826)*/  
    RETURN RES;
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE JOB_SEND_BULK_MESSAGE AS
    REF_CURSOR SYS_REFCURSOR;
  
    SEND_RESLT VARCHAR2(50);
    RSLT       VARCHAR2(50);
    STATUS     VARCHAR2(50);
    NO         NUMBER;
    ERROR_TXT  CLOB;
    CURSOR UNSENT_MSG IS
      SELECT H.SEND_NO FROM RKC_SEND_H H WHERE H.REMARKS IS NULL;
    /*   IS NULL;*/
    CURSOR MSG_CLOB IS
      SELECT XML_VALUE
        FROM TEMP_RKC_XML
       WHERE SEND_NO = NO
       ORDER BY ORD_NO;
    MSG_TEXT CLOB;
  BEGIN
  IF (OPERATION_AVALAIBLE('BULK') = 1) THEN
    FOR A IN UNSENT_MSG LOOP
      NO       := A.SEND_NO;
      STATUS   := '';
      MSG_TEXT := '';
      BEGIN
        GENERATE_XML(A.SEND_NO, REF_CURSOR);
      EXCEPTION
        WHEN OTHERS THEN
          STATUS := 'GEN_ERR';
          UPDATE RKC_SEND_H H SET H.REMARKS = STATUS WHERE H.SEND_NO = NO;
          COMMIT;
        
          ERROR_TXT := SQLERRM;
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'BULK SEND',
                    ERROR_TXT);
          RTGS.WRITE_BULK_LOG(A.SEND_NO, 0, STATUS, ERROR_TXT);
          COMMIT;
          CLOSE REF_CURSOR;
      END;
      CLOSE REF_CURSOR;
      IF (STATUS IS NULL OR STATUS = '') THEN
        FOR X IN MSG_CLOB LOOP
          MSG_TEXT := MSG_TEXT || X.XML_VALUE;
        END LOOP;
        SEND_RESLT := SEND_BULK_MSG(A.SEND_NO);
      
        IF (SEND_RESLT = 'OK') THEN
          STATUS := 'SENT';
          BTA_MT.WRITEMTLOG(A.SEND_NO, 0, STATUS, ERROR_TXT);
          COMMIT;
        ELSE
          STATUS    := 'SEND ERROR';
          ERROR_TXT := 'ERROR SENDING BULK, SEND_NO:' || A.SEND_NO || '; Status: ' || STATUS || '; ' || ERROR_TXT;
        END IF;
        BTA_MT.WRITEMTLOG(A.SEND_NO, 0, STATUS, ERROR_TXT);
        COMMIT;
        UPDATE RKC_SEND_H H SET H.REMARKS = STATUS WHERE H.SEND_NO = NO;
        WRITE_MSG_GEN_LOG(A.SEND_NO, MSG_TEXT, STATUS, 'BULK');
        COMMIT;
      END IF;
      /*BEGIN(RTGS-1229)*/
      delete TEMP_RKC_XML r where r.send_no= A.SEND_NO;
      commit;
      /*END(RTGS-1229)*/
    END LOOP;
  END IF;
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE JOB_SEND_MT_MESSAGE AS
  
    SEND_RESLT VARCHAR2(50);
    RSLT       VARCHAR2(50);
    STATUS     VARCHAR2(50);
    MT_MSG     VARCHAR2(5000);
    ERROR_TXT  CLOB;
    v_s00_result NUMBER;
    v_teams_result     varchar2(500);
  
    /*CURSOR UNSENT_MSG IS
    SELECT T.NO, T.CLASS_OP
      FROM DOCUMENTS T
     WHERE CLASS_OP IN ('БНР_103', 'БНР_202')
       AND STATUS = 'E01'
       AND GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT' ORDER BY t.no;*/
  
    CURSOR UNSENT_MSG IS
    SELECT T.NO, T.CLASS_OP
        FROM DOCUMENTS T
       WHERE T.BRANCH = 'SRB'
            --  AND STATUS IN ('E01')
         AND VALUE_DATE between (TRUNC(SYSDATE) - 7) and trunc(sysdate)           
         AND ((CLASS_OP IN
             ('БНР_103', 'БНР_202', 'БНР_БЮДЖЕТ_103','БНР_ИНКАССО_103') AND
             STATUS IN ('E01') AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT') OR
             (CLASS_OP IN ('БНР',
                            'БНР_БЮДЖЕТ',
                            'БНР_ИНКАССО') AND
             T.AMOUNT_CUR_1 >= 10000 AND STATUS IN ('E01') AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT') OR
             (CLASS_OP IN ('БНР_ПС') AND T.AMOUNT_CUR_1 >= 10000 AND
             STATUS IN ('E00') AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DT'))
         
       ORDER BY T.NO;
     /* SELECT T.NO, T.CLASS_OP
        FROM DOCUMENTS T
       WHERE T.BRANCH = 'SRB'
            --  AND STATUS IN ('E01')
         AND VALUE_DATE > (TRUNC(SYSDATE) - 5)
            
         AND ((CLASS_OP IN
             ('БНР_103', 'БНР_202', 'БНР_БЮДЖЕТ_103','БНР_ИНКАССО_103') AND
             STATUS IN ('E01')) OR
             (CLASS_OP IN ('БНР',
                            'БНР_БЮДЖЕТ',
                            'БНР_ИНКАССО') AND
             T.AMOUNT_CUR_1 >= 10000 AND STATUS IN ('E01')) OR
             (CLASS_OP IN ('БНР_ПС') AND T.AMOUNT_CUR_1 >= 10000 AND
             STATUS IN ('E00')))
         AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT'
       ORDER BY T.NO;*/
  
    ---------------- SATESTO 5000 doc -------------------------------
    /* CURSOR UNSENT_MSG IS
        SELECT T.NO, T.CLASS_OP
    FROM DOCUMENTS T
         WHERE T.BRANCH = 'SRB'
           AND STATUS = 'E01'
           AND VALUE_DATE = (trunc(SYSDATE) - 6)
    
           AND (CLASS_OP IN ('БНР_103', 'БНР_202') )
           AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT'
         ORDER BY T.NO;
    */
    ---------------- SATESTO 5000 doc -------------------------------
    ---------------- SATESTO -------------------------------
    /*                          CURSOR UNSENT_MSG IS     
                SELECT T.NO, T.CLASS_OP
     FROM DOCUMENTS T
    WHERE  t.branch='SRB' AND STATUS = 'E01'
    AND value_date>to_date('3/2/2010')
    AND (CLASS_OP IN ('БНР_БЮДЖЕТ','БНР_ИНКАССО') AND t.amount_cur_1>10000)
     AND RTGS.GET_MSG_STATUS(T.OBJECT_KEY) = 'DTWFSELECT'   ORDER BY t.no;*/
    ---------------- SATESTO -------------------------------
    --  AND gagzavnilia AUCILEBLAD
  
    /*   IS NULL;*/
  BEGIN
    --IF (OPERATION_AVALAIBLE = 1) THEN
    FOR A IN UNSENT_MSG LOOP
      IF (OPERATION_AVALAIBLE(A.CLASS_OP) = 1) THEN
      STATUS := '';
      BEGIN
        IF (A.CLASS_OP IN ('БНР_103',
                           'БНР',
                           'БНР_БЮДЖЕТ',
                           'БНР_БЮДЖЕТ_103',
                           'БНР_ИНКАССО',
                           'БНР_ИНКАССО_103',
                           'БНР_ПС')) THEN
          MT_MSG := BTA_MT.CREATEMT103(A.NO);
        END IF;
        IF (A.CLASS_OP = 'БНР_202') THEN
          MT_MSG := BTA_MT.CREATEMT202(A.NO);
        END IF;
      
      EXCEPTION
        WHEN OTHERS THEN
          STATUS    := 'GEN_ERR';
          ERROR_TXT := SQLERRM;
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT SEND',
                    ERROR_TXT);
          BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
      END;
      IF (STATUS IS NULL OR STATUS = '') THEN
        v_s00_result:=0;
        /*SEND_RESLT := SEND_MT_MSG(MT_MSG);
        --SEND_RESLT := SEND_MT_MSG(A.NO);
        IF (SEND_RESLT = 'OK') THEN
          STATUS := 'SENT';
          BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
          BEGIN
            S00_DOC(A.NO);
          EXCEPTION
            WHEN OTHERS THEN
              ERROR_TXT := 'ERROR AUTHORIZE MT TO S00, DOC_NO:' || A.NO || '
        ' || SQLERRM;
              SEND_MAIL('RTGS@bta.ge',
                        'error_log@bta.ge',
                        'MT SEND',
                        ERROR_TXT);
              BTA_MT.WRITEMTLOG(A.NO, 0, 'SENT/AUTH ERR', ERROR_TXT);
          END;
        
        ELSE
          STATUS    := 'SEND ERROR';
          ERROR_TXT := 'ERROR SENDING MT, DOC_NO:' || A.NO || '; Status: ' ||
                       STATUS || '
        ' || ERROR_TXT;
        
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT SEND',
                    ERROR_TXT);
          BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
        END IF;*/
        
        BEGIN
            S00_DOC(A.NO);
            v_s00_result:=1;
          EXCEPTION
            WHEN OTHERS THEN
              ERROR_TXT := 'ERROR AUTHORIZE MT TO S00, DOC_NO:' || A.NO || '; ' || SQLERRM;
              SEND_MAIL('RTGS@bta.ge',
                        'error_log@bta.ge',
                        'MT SEND',
                        ERROR_TXT);
              BTA_MT.WRITEMTLOG(A.NO, 0, 'SENT/AUTH ERR', ERROR_TXT);
              
            v_teams_result:=TEAMS_NOTIFY('RTGS','0076D7','ვერ მოხერხდა სწრაფი გადარიცხვის ავტორიზება S00 სტატუსზე','','დოკ. #:'||to_char(A.NO)||';ოპ.ტიპი:'||a.class_op);
          
          END;
        
        IF (v_s00_result=1) THEN
          SEND_RESLT := SEND_MT_MSG(MT_MSG);
        
        IF (SEND_RESLT = 'OK') THEN
          STATUS := 'SENT';
          BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
        ELSE
          
        
        
        
            STATUS    := 'SEND ERROR';
          ERROR_TXT := 'ERROR SENDING MT, DOC_NO:' || A.NO || '; Status: ' || STATUS || '; ' || ERROR_TXT;
        
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT SEND',
                    ERROR_TXT);
          BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
          
          
          BEGIN
          S00_TO_E01(A.NO);
          EXCEPTION
            WHEN OTHERS THEN
              
             ERROR_TXT := 'CANNOT S00 TO E01, DOC_NO:' || A.NO || '; Status: ' || STATUS || '; ' || ERROR_TXT;
    
             SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT SEND',
                    ERROR_TXT);
            
               BTA_MT.WRITEMTLOG(A.NO, 0, STATUS, ERROR_TXT);
          COMMIT;
              END;
          
          v_teams_result:=TEAMS_NOTIFY('RTGS','0076D7','სწრაფი გადარიცხვის გაგზავნისას RTGS-ში მოხდა შეცდომა','','დოკ. #:'||to_char(A.NO)||';ოპ.ტიპი:'||a.class_op);


        END IF;
        
        
        
        END IF;
      
        WRITE_MSG_GEN_LOG(A.NO, MT_MSG, STATUS, 'MT');
        COMMIT;
      
      END IF;
    END IF;
    END LOOP;
 -- END IF;
  END;

  PROCEDURE INSERT_SIGNATURE(P_SEND_NO   NUMBER,
                             P_SIGNATURE CLOB,
                             P_ORD_NO    NUMBER) AS
  BEGIN
    INSERT INTO TEMP_RKC_SIGNATURE
    VALUES
      (P_SEND_NO, P_SIGNATURE, P_ORD_NO);
    COMMIT;
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

  PROCEDURE INSERT_RTGS_MESSAGE(P_MSG CLOB) AS
    ID NUMBER;
  BEGIN
    --RAISE_APPLICATION_ERROR(-20014, 'magari erroria');
    SELECT RTGS_RECEIVED_SEQ.NEXTVAL INTO ID FROM DUAL;
  
    INSERT INTO RTGS_RECEIVED
    VALUES
      (ID, NULL, P_MSG, NULL, 0, SYSDATE, NULL);
    COMMIT;
  
  END;

  PROCEDURE TRANSFORM_MESSAGES AS
  
    MSG_TRANS CLOB;
    CURSOR TRANSFORMER IS
      SELECT MSG_ID, MSG_RECEIVED
        FROM RTGS_RECEIVED
       WHERE TRUNC(INSERTED) BETWEEN TRUNC(SYSDATE-7) and TRUNC(SYSDATE) 
			 AND MSG_TRANSFORMED IS NULL;
    ERR_MSG VARCHAR2(1500);
  BEGIN
  
    FOR A IN TRANSFORMER LOOP
      BEGIN
        MSG_TRANS := SUBSTR(A.MSG_RECEIVED,
                            1,
                            INSTR(A.MSG_RECEIVED, '|', -1, 1) - 1);
      
        MSG_TRANS := REPLACE(MSG_TRANS,
                             SUBSTR(MSG_TRANS,
                                    INSTR(MSG_TRANS, '<Document', 1, 1) + 9,
                                    INSTR(MSG_TRANS, '>', 1, 2) -
                                    INSTR(MSG_TRANS, '<Document', 1, 1) - 9),
                             '');
      
        UPDATE RTGS_RECEIVED
           SET MSG_TRANSFORMED = MSG_TRANS
         WHERE MSG_ID = A.MSG_ID;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          ERR_MSG := 'PROC: TRANSFORM_MESSAGES; ERROR: ' ||
                     SUBSTR(SQLERRM, 1, 900);
          WRITE_REC_MSG_ERR(A.MSG_ID, ERR_MSG);
          COMMIT;
      END;
    END LOOP;
  
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
  PROCEDURE SET_MSG_TYPES AS
    MSG       CLOB;
    XML       XMLTYPE;
    DOM_XML   DBMS_XMLDOM.DOMDOCUMENT;
    NODE_LIST DBMS_XMLDOM.DOMNODELIST;
    NODE      DBMS_XMLDOM.DOMNODE;
    NODE_NAME VARCHAR2(200);
    ERR_MSG   VARCHAR2(1500);
    MSGTYPE   VARCHAR2(200);
  
    START_POS NUMBER;
    MT_TYPE   VARCHAR2(50);
    ERROR_MSG VARCHAR2(1000);
    CURSOR TYPER IS
      SELECT MSG_ID, MSG_TRANSFORMED AS MSG
        FROM RTGS_RECEIVED
       WHERE TRUNC(INSERTED) BETWEEN TRUNC(SYSDATE-7) and TRUNC(SYSDATE) 
			   AND MSG_TYPE IS NULL
         AND MSG_TRANSFORMED IS NOT NULL;
  BEGIN
    FOR A IN TYPER LOOP
      BEGIN
        BEGIN
        
          XML       := XMLTYPE.CREATEXML(A.MSG);
          DOM_XML   := DBMS_XMLDOM.NEWDOMDOCUMENT(A.MSG);
          NODE_LIST := DBMS_XMLDOM.GETELEMENTSBYTAGNAME(DOM_XML, '*');
        
          NODE := DBMS_XMLDOM.ITEM(NODE_LIST, 1);
        
          NODE_NAME := DBMS_XMLDOM.GETNODENAME(NODE);
          MSGTYPE   := NODE_NAME;
        EXCEPTION
          WHEN OTHERS THEN
            START_POS := INSTR(A.MSG, '{2:', 1, 1);
            MT_TYPE   := SUBSTR(A.MSG, START_POS + 4, 3);
          
            CASE
              WHEN MT_TYPE IN ('103', '202', '204', '205', '198', '298','900','910') THEN
                MSGTYPE := 'MT' || MT_TYPE;
              ELSE
                MSGTYPE   := 'ERROR';
                ERROR_MSG := 'Cannot define Message type for MSG_ID - ' ||
                             A.MSG_ID;
               /* SEND_MAIL('RTGS@bta.ge',
                          'error_log@bta.ge',
                          'RTGS MSG TYPE ERROR',
                          ERROR_MSG);*/
                ERR_MSG := 'PROC: TRANSFORM_MESSAGES; ERROR: ' ||
                           SUBSTR(SQLERRM, 1, 900);
                WRITE_REC_MSG_ERR(A.MSG_ID, ERROR_MSG);
                COMMIT;
            END CASE;
        END;
      
        UPDATE RTGS_RECEIVED
           SET MSG_TYPE = MSGTYPE
         WHERE MSG_ID = A.MSG_ID;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          ERROR_MSG := 'PROC: SET_MSG_TYPES; ERROR: ' ||
                       SUBSTR(SQLERRM, 1, 900);
          WRITE_REC_MSG_ERR(A.MSG_ID, ERROR_MSG);
        
          UPDATE RTGS_RECEIVED
             SET MSG_TYPE = 'ERROR'
           WHERE MSG_ID = A.MSG_ID;
          COMMIT;
      END;
    END LOOP;
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

  PROCEDURE JOB_PROCESS_MESSAGES AS
    CURSOR PROCESSOR IS
      SELECT MSG_ID AS ID, MSG_TYPE, MSG_TRANSFORMED, STATUS
        FROM RTGS_RECEIVED
       WHERE STATUS = 0
         AND MSG_TYPE != 'ERROR'
				 AND TRUNC(INSERTED) BETWEEN TRUNC(SYSDATE-7) and TRUNC(SYSDATE)
       ORDER BY MSG_ID;
    ERROR_MSG VARCHAR2(1500);
  
    STATUS_TO_SET NUMBER;
  BEGIN
    TRANSFORM_MESSAGES;
    SET_MSG_TYPES;
  
    FOR A IN PROCESSOR LOOP
      BEGIN
        CASE
          WHEN A.MSG_TYPE = 'FIToFICstmrCdtTrf' THEN
            SERIALIZE_BULK_INTO_PAYMENT(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'FIToFIPmtStsRpt' THEN
            SERIALIZE_BULK_STATUS(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT103' THEN
            BTA_MT.CREATEMT103DOC(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT202' THEN
            BTA_MT.CREATEMT202DOC(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT204' THEN
            BTA_MT.CREATEMT204DOC(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT205' THEN
            BTA_MT.CREATEMT205DOC(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT198' THEN
            BTA_MT.PROCEEDMT198(A.MSG_TRANSFORMED, A.ID);
          WHEN A.MSG_TYPE = 'MT298' THEN
            BTA_MT.PROCEEDMT198(A.MSG_TRANSFORMED, A.ID);
             WHEN A.MSG_TYPE = 'MT900' THEN
            BTA_MT.CREATEMT900DOC(A.MSG_TRANSFORMED, A.ID);
            WHEN A.MSG_TYPE = 'MT910' THEN
            BTA_MT.CREATEMT910DOC(A.MSG_TRANSFORMED, A.ID);
        
          ELSE
          
            NULL;
        END CASE;
        STATUS_TO_SET := 1;
      EXCEPTION
        WHEN OTHERS THEN
          IF (SQLCODE=-20002) THEN
            UPDATE rtgs_received r SET r.msg_type='ERROR', r.status=0
            WHERE r.msg_id=a.id;
            COMMIT;
             STATUS_TO_SET := 0;
          ELSE
        
        
        
          STATUS_TO_SET := -1;
          WRITE_REC_MSG_ERR(A.ID, SUBSTR(SQLERRM, 1, 900));
          COMMIT;
          END IF;
      END;
    
      UPDATE RTGS_RECEIVED R
         SET R.STATUS = STATUS_TO_SET
       WHERE R.MSG_ID = A.ID;
      COMMIT;
    
    END LOOP;
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

  PROCEDURE REJECT_DOCUMENT(DOC_NO NUMBER) AS
    OBJ_KEY NUMBER;
  BEGIN
    UPDATE DOCUMENTS D SET D.RKC_OUT = NULL WHERE D.NO = DOC_NO;
    COMMIT;
    SELECT OBJECT_KEY INTO OBJ_KEY FROM DOCUMENTS WHERE NO = DOC_NO;
    /*DELETE FROM SM_MSG
     WHERE OBJECT_KEY = OBJ_KEY
        AND MSG_TYPE != ('DTWFSELECT');
    COMMIT;*/
  
    SM_SCT_U.DELETE_ACTION(OBJ_KEY, 'DTSELECT');
  
    COMMIT;
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

  PROCEDURE WRITE_REC_MSG_ERR(P_MSG_ID NUMBER, P_ERR_MSG VARCHAR2) AS
  BEGIN
    INSERT INTO RTGS_RECEIVED_ERR_LOG
    VALUES
      (P_MSG_ID, SYSDATE, P_ERR_MSG);
  END;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
  PROCEDURE WRITE_MSG_GEN_LOG(P_REF_ID   NUMBER,
                              P_MSG      CLOB,
                              P_STATUS   VARCHAR2,
                              P_MSG_TYPE VARCHAR2) AS
    V_STRING LONG;
    v_user VARCHAR2(100);
  BEGIN
    V_STRING := DBMS_LOB.SUBSTR(P_MSG, 10000, 1);
    INSERT INTO RTGS_GENERATE_LOG
    VALUES
      (P_REF_ID, SYSDATE, P_MSG, P_STATUS, P_MSG_TYPE, V_STRING);
  END;

  PROCEDURE FIN_DOC(P_DOC_ID NUMBER) AS
    OBJ_KEY NUMBER;
    OP_CODE VARCHAR2(50);
    N       NUMBER;
    v_user VARCHAR2(100);
  BEGIN
    SELECT OBJECT_KEY, CLASS_OP,authorized_by
      INTO OBJ_KEY, OP_CODE,v_user
      FROM DOCUMENTS
     WHERE NO = P_DOC_ID;
  
    UPDATE DOCUMENTS
       SET RKC_OUT = '2', DATE_RKC_OUT = SYSDATE
     WHERE NO = P_DOC_ID;
    COMMIT;
    N := SM_SCT_U.EXECUTE_OPERATION(OP_CODE, NULL, OBJ_KEY, 'DTSEND');
  
    COMMIT;
    
    
    UPDATE documents SET authorized_by=v_user WHERE NO = P_DOC_ID;
    COMMIT;
  
  END;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE S00_DOC(P_DOC_ID NUMBER) AS
    OBJ_KEY NUMBER;
    OP_CODE VARCHAR2(50);
    N       NUMBER;
    v_user VARCHAR2(100);
  BEGIN
    SELECT OBJECT_KEY, CLASS_OP,authorized_by
      INTO OBJ_KEY, OP_CODE,v_user
      FROM DOCUMENTS
     WHERE NO = P_DOC_ID;
  
    UPDATE DOCUMENTS
       SET RKC_OUT = '1', DATE_RKC_OUT = SYSDATE
     WHERE NO = P_DOC_ID;
    COMMIT;
    N := SM_SCT_U.EXECUTE_OPERATION(OP_CODE, NULL, OBJ_KEY, 'DTSELECT');
  
    COMMIT;
  
  
    UPDATE documents SET authorized_by=v_user WHERE no=P_DOC_ID;
    COMMIT;
  
  END;

  PROCEDURE S00_TO_E01(P_DOC_ID NUMBER) AS
    OBJ_KEY NUMBER;
    v_user VARCHAR2(100);
  BEGIN
    SELECT OBJECT_KEY,authorized_by INTO OBJ_KEY,v_user  FROM DOCUMENTS WHERE NO = P_DOC_ID;
    /*DELETE FROM SM_MSG
     WHERE OBJECT_KEY = OBJ_KEY
       AND MSG_TYPE != ('DTWFSELECT');
    COMMIT;*/
    UPDATE DOCUMENTS
       SET RKC_OUT = 1, DATE_RKC_OUT = SYSDATE
     WHERE NO = P_DOC_ID;
    COMMIT;
    SM_SCT_U.DELETE_ACTION(OBJ_KEY, 'DTSELECT');
    COMMIT;
    
    
    
    UPDATE documents SET authorized_by=v_user WHERE no=P_DOC_ID;
    COMMIT;
  END;

  FUNCTION GET_MSG_STATUS(P_OBJ_KEY NUMBER) RETURN VARCHAR2 AS
    MSGTYPE VARCHAR2(50);
  BEGIN
    SELECT MSG_TYPE
      INTO MSGTYPE
      FROM SM_MSG
     WHERE OBJECT_KEY = P_OBJ_KEY
       AND MSG_ORDER_BY IN (SELECT MAX(MSG_ORDER_BY)
                              FROM SM_MSG
                             WHERE OBJECT_KEY = P_OBJ_KEY);
    RETURN MSGTYPE;
  END;

  PROCEDURE WRITE_BULK_LOG(P_DOC_ID NUMBER,
                           P_REF_ID NUMBER,
                           P_STATUS VARCHAR2,
                           P_ERROR  CLOB) AS
  BEGIN
    INSERT INTO RTGS_BULK_SEND_LOG
    VALUES
      (P_DOC_ID, SYSDATE, P_STATUS, P_ERROR, P_REF_ID);
  END;

  FUNCTION VERIFY_SIGNATURE(P_SIGNATURE_MSG VARCHAR2) RETURN VARCHAR2 AS
  
    RES VARCHAR2(50);
  
    PARAMS WEB_SERVICE.PARAMETERS_TABLE;
  BEGIN
  
    PARAMS(1).PARAM := 'p_msg';
    PARAMS(1).VALUE := P_SIGNATURE_MSG;
/*BEGIN(ORA-WS-826)*/  
    RES := WEB_SERVICE.EXECUTE_WEB_SERVICE(get_web_service_path('RTGS_SENDER','REAL'), 'Verify', PARAMS);
/*END(ORA-WS-826)*/  
    RETURN RES;
  END;

  FUNCTION CTRL_BNR(P_OBJ_KEY IN VARCHAR2,
                    P_ACT_KEY IN VARCHAR2,
                    P_DOC_NO  IN VARCHAR2) RETURN VARCHAR2 AS
  
  BEGIN
  
    RETURN 'FALSE';
  END;

  PROCEDURE MT_MESSAGE_FILE(P_MSG_ID NUMBER, P_MSG_TEXT VARCHAR2) AS
  
    SEND_RESLT VARCHAR2(50);
    RSLT       VARCHAR2(50);
    STATUS     VARCHAR2(50);
    MT_MSG     VARCHAR2(5000);
    ERROR_TXT  CLOB;
  
  BEGIN
  
    BEGIN
      S00_DOC(P_MSG_ID);
    EXCEPTION
      WHEN OTHERS THEN
        ERROR_TXT := 'ERROR AUTHORIZE MT TO S00, DOC_NO:' || P_MSG_ID || '
        ' || SQLERRM;
        SEND_MAIL('RTGS@bta.ge', 'error_log@bta.ge', 'MT SEND', ERROR_TXT);
        BTA_MT.WRITEMTLOG(P_MSG_ID, 0, 'SENT/AUTH ERR', ERROR_TXT);
    END;
  
    STATUS := 'SENT';
    BTA_MT.WRITEMTLOG(P_MSG_ID, 0, STATUS, ERROR_TXT);
  
    WRITE_MSG_GEN_LOG(P_MSG_ID, P_MSG_TEXT, STATUS, 'MT');
  
  END;

  PROCEDURE BULK_MESSAGE_FILE(P_MSG_ID NUMBER, P_MSG_TEXT VARCHAR2) AS
  
    REF_CURSOR SYS_REFCURSOR;
  
    SEND_RESLT VARCHAR2(50);
    RSLT       VARCHAR2(50);
    STATUS     VARCHAR2(50);
    NO         NUMBER;
    ERROR_TXT  CLOB;
  
    MSG_TEXT CLOB;
  BEGIN
  
    STATUS := 'SENT';
  
    BTA_MT.WRITEMTLOG(P_MSG_ID, 0, STATUS, ERROR_TXT);
  
    UPDATE RKC_SEND_H H SET H.REMARKS = STATUS WHERE H.SEND_NO = P_MSG_ID;
    WRITE_MSG_GEN_LOG(P_MSG_ID, P_MSG_TEXT, STATUS, 'BULK');
  
  END;

  PROCEDURE REGISTER_FILE(P_FILE_NAME VARCHAR2) AS
  BEGIN
    INSERT INTO RTGS_RECEIVED_FILES VALUES (P_FILE_NAME, SYSDATE);
    COMMIT;
  END;

  FUNCTION ALREADY_REGISTERED(P_FILE_NAME VARCHAR2) RETURN NUMBER AS
    COUNTER NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO COUNTER
      FROM RTGS_RECEIVED_FILES
     WHERE FILE_NAME = P_FILE_NAME;
  
    IF (COUNTER > 0) THEN
    
      RETURN 1;
    ELSE
      RETURN 0;
    
    END IF;
  
  END;

 FUNCTION CHECK_SYMBOLS(P_TEXT VARCHAR2, P_FIELD_NM VARCHAR2)
    RETURN VARCHAR2 IS
    RESULT_TEXT VARCHAR2(2000);
    TAX_ID      NUMBER;
    ID          NUMBER;
    v_restr_symb varchar2(500);
    v_restr_symb_count number;
    v_replace_symbols varchar2(500);
  BEGIN
    --%!@#$^&*_=\|<>[]{};"
  /*BEGIN(RTGS-907)*/
  begin
  
    select restricted_symbols into v_restr_symb from 
    RTGS_FIELD_RESTR_SYMBOLS where field_nm=P_FIELD_NM;
    v_restr_symb_count:=length(v_restr_symb);
    
    while (v_restr_symb_count>0)
  Loop
    v_replace_symbols:=v_replace_symbols||'%';
    v_Restr_symb_count:=v_Restr_symb_count-1;
  
  END LOOP;
    
    Exception
      when others then
        v_restr_symb:='';
  end;
    /*END(RTGS-907)*/
    
    IF (P_FIELD_NM = 'ID') THEN
      BEGIN
        ID := TO_NUMBER(P_TEXT);
        IF (ID IS NULL) THEN
            RAISE_APPLICATION_ERROR(-20020, '');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RESULT_TEXT := get_geo_msg('sabuTis nomerSi dasaSvebia')||': 1234567890';
      END;
    
    END IF;
  /*BEGIN(RTGS-907)*/
    IF (P_FIELD_NM = 'RECEIPIENT_NAME') THEN
      IF (NUM_CHARS(TRANSLATE(P_TEXT,v_restr_symb,v_replace_symbols),'%') > 0) THEN
        RESULT_TEXT := get_geo_msg('dauSvebeli simboloebi mimRebis dasaxelebaSi');
      END IF;
    END IF;
    
    
    IF (P_FIELD_NM = 'DEBIT_ACC_ID') THEN
      IF (NUM_CHARS(TRANSLATE(P_TEXT,v_restr_symb,v_replace_symbols),'%') > 0) THEN
        RESULT_TEXT := get_geo_msg('gamgzavnis angariSSi')||': space,tab,enter';
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'PAYMENT_PURPOSE') THEN
           IF (NUM_CHARS(TRANSLATE(P_TEXT,
                              v_restr_symb,
                              v_replace_symbols),
                    '%') > 0) THEN  
        RESULT_TEXT := get_geo_msg('dauSvebeli simboloebi daniSnulebaSi');
      END IF;
    END IF;
 /*END(RTGS-907)*/ 
    IF (P_FIELD_NM = 'THIRD_PERSON_TAX_NUMBER') THEN
    
      BEGIN
        TAX_ID := TO_NUMBER(P_TEXT);
      EXCEPTION
        WHEN OTHERS THEN
          RESULT_TEXT := get_geo_msg('me-3 piris said. nomerSi dasaSvebia')||': 1234567890';
      END;
    
    END IF;
   /*BEGIN(RTGS-907)*/ 
    IF (P_FIELD_NM = 'THIRD_PERSON_NAME') THEN
           IF (NUM_CHARS(TRANSLATE(P_TEXT,
                              v_restr_symb,
                              v_replace_symbols),
                    '%') > 0) THEN  
        RESULT_TEXT := get_geo_msg('dauSvebeli simboloebi me-3 piris dasaxelebaSi');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'REMARKS') THEN
           IF (NUM_CHARS(TRANSLATE(P_TEXT,
                              v_restr_symb,
                              v_replace_symbols),
                    '%') > 0) THEN  
        RESULT_TEXT :=  get_geo_msg('dauSvebeli simboloebi damat. informaciaSi');
      END IF;
    END IF;
  /*END(RTGS-907)*/ 
    IF (RESULT_TEXT IS NOT NULL) THEN
      RETURN RESULT_TEXT;
    END IF;
  
    RETURN 'TRUE';
  
  END;

 FUNCTION CHECK_LENGTH(P_TEXT VARCHAR2, P_FIELD_NM VARCHAR2) RETURN VARCHAR2 IS
    TEXT_LENGTH NUMBER;
    RESULT_TEXT VARCHAR2(200);
  BEGIN
    TEXT_LENGTH := LENGTH(P_TEXT);
  
    IF (P_FIELD_NM = 'ID') THEN
      IF (TEXT_LENGTH > GET_FIELD_SIZE('ID')) THEN
        RESULT_TEXT := get_geo_msg('dokumentis #-is zoma metia ') ||
                       TO_CHAR(GET_FIELD_SIZE('ID')) || get_geo_msg(' simboloze');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'RECEIPIENT_NAME') THEN
      IF (TEXT_LENGTH > GET_FIELD_SIZE('RECEIPIENT_NAME')) THEN
        RESULT_TEXT := get_geo_msg('mimRebis dasaxelebis velis zoma metia ') ||
                       TO_CHAR(GET_FIELD_SIZE('RECEIPIENT_NAME')) ||
                        get_geo_msg(' simboloze');
      END IF;
      
       IF (TEXT_LENGTH = 0  OR TEXT_LENGTH IS NULL) THEN
        RESULT_TEXT := get_geo_msg('gTxovT SeavsoT veli mimRebis dasaxeleba');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'PAYMENT_PURPOSE') THEN
      IF (TEXT_LENGTH > GET_FIELD_SIZE('PAYMENT_PURPOSE')) THEN
        RESULT_TEXT := get_geo_msg('daniSnulebis velis zoma metia ') ||
                       TO_CHAR(GET_FIELD_SIZE('PAYMENT_PURPOSE')) ||
                        get_geo_msg(' simboloze');
      END IF;
       IF (TEXT_LENGTH = 0  OR TEXT_LENGTH IS NULL) THEN
        RESULT_TEXT := get_geo_msg('gTxovT SeavsoT veli daniSnuleba');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'THIRD_PERSON_TAX_NUMBER') THEN
      IF (TEXT_LENGTH NOT IN (9, 11)) THEN
        RESULT_TEXT :=  get_geo_msg('me-3 piris said. nomerSi dasaSvebia: 1234567890');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'THIRD_PERSON_NAME') THEN
      IF (TEXT_LENGTH > GET_FIELD_SIZE('THIRD_PERSON_NAME')) THEN
        RESULT_TEXT := get_geo_msg('me-3 piris dasax-is velis zoma metia ') ||
                       TO_CHAR(GET_FIELD_SIZE('THIRD_PERSON_NAME')) ||
                        get_geo_msg(' simboloze');
      END IF;
    END IF;
  
    IF (P_FIELD_NM = 'REMARKS') THEN
      IF (TEXT_LENGTH > GET_FIELD_SIZE('REMARKS')) THEN
        RESULT_TEXT := get_geo_msg('damat. informaciis velis zoma metia ') ||
                       TO_CHAR(GET_FIELD_SIZE('REMARKS'))  || get_geo_msg(' simboloze');
      END IF;
    END IF;
  
    IF (RESULT_TEXT IS NOT NULL) THEN
      RETURN RESULT_TEXT;
    END IF;
  
    RETURN 'TRUE';
  END;


  FUNCTION GET_TEXT_SUBSTR(P_TEXT VARCHAR2, P_FIELD_NM VARCHAR2)
    RETURN VARCHAR2 IS
  
    TEXT_LENGTH NUMBER;
    RESULT_TEXT VARCHAR2(2000);
  BEGIN
    TEXT_LENGTH := LENGTH(P_TEXT);
  
    IF (P_FIELD_NM = 'ID') THEN
    
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('ID'));
    
    ELSIF (P_FIELD_NM = 'RECEIPIENT_NAME') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('RECEIPIENT_NAME'));
    
    ELSIF (P_FIELD_NM = 'REMITTANT_NAME') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('REMITTANT_NAME'));
    
    ELSIF (P_FIELD_NM = 'PAYMENT_PURPOSE') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('PAYMENT_PURPOSE'));
    
    ELSIF (P_FIELD_NM = 'THIRD_PERSON_TAX_NUMBER') THEN
      RESULT_TEXT := SUBSTR(P_TEXT,
                            1,
                            GET_FIELD_SIZE('THIRD_PERSON_TAX_NUMBER'));
    
    ELSIF (P_FIELD_NM = 'THIRD_PERSON_NAME') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('THIRD_PERSON_NAME'));
    
    ELSIF (P_FIELD_NM = 'REMARKS') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('REMARKS'));
    
    ELSIF (P_FIELD_NM = 'ADDRESS') THEN
      RESULT_TEXT := SUBSTR(P_TEXT, 1, GET_FIELD_SIZE('ADDRESS'));
    
    ELSE
      RESULT_TEXT := P_TEXT;
    END IF;
  
    RETURN RESULT_TEXT;
  END;

  FUNCTION GET_FIELD_SIZE(P_FIELD_NM VARCHAR2) RETURN NUMBER IS
    F_SIZE NUMBER;
  BEGIN
    SELECT FIELD_SIZE
      INTO F_SIZE
      FROM RTGS_FIELD_SIZE
     WHERE FIELD_NM = P_FIELD_NM;
  
    RETURN F_SIZE;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
    
  END;

  FUNCTION GET_STRUCT_FIELD_VALUE(P_TEXT VARCHAR2, P_CODE VARCHAR2)
    RETURN VARCHAR2 AS
    START_POS NUMBER;
  
    END_POS NUMBER;
  
    END_POS_TEMP NUMBER;
    I            NUMBER;
    V_VALUE      VARCHAR2(1000);
  
    A VARCHAR2(100);
  BEGIN
    START_POS := INSTR(P_TEXT, '/' || P_CODE || '/', 1, 1);
  
    I            := 1;
    END_POS_TEMP := INSTR(P_TEXT,
                          '/' || P_CODE || '/',
                          START_POS + LENGTH('/' || P_CODE || '/'),
                          I);
    END_POS      := 0;
    WHILE (END_POS_TEMP > 0) LOOP
      I := I + 1;
      IF (END_POS_TEMP > 0) THEN
        END_POS := END_POS_TEMP;
      END IF;
      END_POS_TEMP := INSTR(P_TEXT,
                            '/' || P_CODE || '/',
                            START_POS + LENGTH('/' || P_CODE || '/'),
                            I);
    
    END LOOP;
  
    IF (END_POS = 0) THEN
      END_POS := INSTR(P_TEXT,
                       '/',
                       START_POS + LENGTH('/' || P_CODE || '/'),
                       1);
    ELSE
      END_POS := INSTR(P_TEXT,
                       '/',
                       END_POS + LENGTH('/' || P_CODE || '/'),
                       1);
    END IF;
  
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(P_TEXT) + 1;
    END IF;
    V_VALUE := SUBSTR(P_TEXT,
                      START_POS + LENGTH('/' || P_CODE || '/'),
                      END_POS - START_POS - LENGTH('/' || P_CODE || '/'));
    V_VALUE := REPLACE(V_VALUE, '/' || P_CODE || '/', '');
    V_VALUE := REPLACE(V_VALUE, CHR(13), '');
    V_VALUE :=REPLACE(V_VALUE,chr(10),'');
    RETURN V_VALUE;
  
  END;

  FUNCTION OPERATION_AVALAIBLE
    RETURN NUMBER AS
  BEGIN
    IF (BTA_JOBS.IS_HOLIDAY(TRUNC(SYSDATE)) = TRUE OR
       (TO_CHAR(TRUNC(SYSDATE), 'DY', 'nls_date_language=english') = 'SAT'))
 THEN
   
 if (trunc(sysdate)!='31/03/2012' and trunc(sysdate)!='03/05/2024') then
      RETURN 0;
      end if;
    END IF;
  
    IF (SYSDATE BETWEEN
       TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' 10:10:00',
                'DD/MM/YYYY HH24:MI:SS') AND
       TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' 16:50:00',
                'DD/MM/YYYY HH24:MI:SS')) THEN
    
     RETURN 1;
    
    ELSE
    
      RETURN 0;
    
    END IF;
  END;
  
  
  FUNCTION OPERATION_AVALAIBLE(p_msg_type VARCHAR2)
    RETURN NUMBER AS
    
    st_dt VARCHAR2(50);
    end_dt  VARCHAR2(50);
    
    
    startdt DATE;
    enddt DATE;
    
  BEGIN
    
  BEGIN
  SELECT start_dt, end_dt INTO st_dt,end_dt FROM rtgs_send_interval WHERE msg_type=p_msg_type
  AND DAY=TO_CHAR(TRUNC(SYSDATE), 'DY', 'nls_date_language=english');
  EXCEPTION
    WHEN OTHERS THEN
      
    RETURN 0;
/*  if (trunc(sysdate) in ('30/03/2013','31/03/2013')) then
    st_dt:='09:33:00';
    end_dt:='18:00:00';
  else
    
    
      
      end if;*/
  END;
  
    IF (BTA_JOBS.IS_HOLIDAY(TRUNC(SYSDATE)) = TRUE and trunc(sysdate)!='03/05/2024') THEN
      RETURN 0;
    END IF;
    
    BEGIN
      startdt:=TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' '||st_dt,
                'DD/MM/YYYY HH24:MI:SS');
                
      enddt:=TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' '||end_dt,
                'DD/MM/YYYY HH24:MI:SS');   
                
      EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;           
    END;
    
  
    IF (SYSDATE BETWEEN
       TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' '||st_dt,
                'DD/MM/YYYY HH24:MI:SS') AND
       TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY') || ' '||end_dt,
                'DD/MM/YYYY HH24:MI:SS')) THEN
    
     RETURN 1;
    
    ELSE
    
      RETURN 0;
    
    END IF;
  END;

END RTGS;
/
