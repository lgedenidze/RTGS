CREATE OR REPLACE PACKAGE BTA_MT IS
  HTTP_NETSEND CONSTANT VARCHAR2(50) := 'http://10.1.1.73/NETSEND/service.asmx';
  PROCEDURE PARSEMT103(MT103 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T23B  OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T50K  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T57A  OUT NVARCHAR2,
                       T59   OUT NVARCHAR2,
                       T70   OUT NVARCHAR2,
                       T71A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2,
                       T77T  OUT NVARCHAR2);
  PROCEDURE PARSEMT204(MT204 VARCHAR2,
                       T201  OUT NVARCHAR2,
                       T19   OUT NVARCHAR2,
                       T30   OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T202  OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32B  OUT NVARCHAR2,
                       T53A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2);
  PROCEDURE PARSEMT205(MT205 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2);

  PROCEDURE PARSEMT202(MT202 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2);

  PROCEDURE PARSEMT198(MT198     CLOB,
                       T20       OUT VARCHAR2,
                       T12       OUT VARCHAR2,
                       T77E      OUT VARCHAR2,
                       T21       OUT VARCHAR2,
                       T11S      OUT VARCHAR2,
                       ERROR_TXT OUT CLOB);

  FUNCTION CREATEMT103(DOC_NO VARCHAR2) RETURN VARCHAR2;
  FUNCTION CREATEMT202(DOC_NO VARCHAR2) RETURN VARCHAR2;
  FUNCTION INSERTDOC(DEBITACC      VARCHAR2,
                     CREDITACC     VARCHAR2,
                     SENDERNAME    VARCHAR2,
                     RECNAME       VARCHAR2,
                     SENDERBANK    VARCHAR2,
                     RECBANK       VARCHAR2,
                     SENDERNO      VARCHAR2,
                     RECNO         VARCHAR2,
                     CURRENCY      VARCHAR2,
                     AMOUNT        NUMBER,
                     OPERDATE      DATE,
                     MSGFORMAT     VARCHAR2,
                     REFER         VARCHAR2,
                     PURPOSE       VARCHAR2,
                     REMARKS       VARCHAR2,
                     THIRD_PAY_TAX VARCHAR2,
                     THIRD_PAY_NM  VARCHAR2,
                     SENDER_TAX    VARCHAR2,
                     RECEIVER_TAX  VARCHAR2) RETURN NUMBER;

  PROCEDURE CREATEMT103DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
  PROCEDURE CREATEMT202DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
  PROCEDURE CREATEMT204DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
  PROCEDURE CREATEMT205DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
  PROCEDURE CREATEMT900DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
	PROCEDURE CREATEMT910DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2);
  PROCEDURE PROCEEDMT198(P_MSG CLOB, p_msg_id VARCHAR2);
  PROCEDURE WRITEMTLOG(P_DOC_ID NUMBER,
                       P_REF_ID NUMBER,
                       P_STATUS VARCHAR2,
                       P_ERROR  CLOB);

  PROCEDURE CREATE_REFERENCE(P_DOC_NO NUMBER, P_REF_ID VARCHAR2);

  PROCEDURE AUTH_INC_MT(P_VIP_NO NUMBER);
  
  FUNCTION tokenize_string(p_text VARCHAR2, p_line_len NUMBER, p_max_line NUMBER, p_new_line_char VARCHAR2 DEFAULT '') RETURN VARCHAR2;
  
  
  FUNCTION check_receiver(p_acc VARCHAR2, p_tax VARCHAR2) RETURN NUMBER;
  
  FUNCTION repl_char(p_text VARCHAR2, p_index NUMBER, p_old_char VARCHAR2,p_new_char VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION is_iban(p_acc VARCHAR2) RETURN NUMBER;
  
  FUNCTION is_dublicate_msg(p_refer VARCHAR2, p_amount VARCHAR2, p_value_date VARCHAR2, p_sending_bank VARCHAR2,p_msg_type VARCHAR2) RETURN NUMBER;
	
	PROCEDURE notify(p_ip VARCHAR2, p_msg VARCHAR2);
  
END;
/
CREATE OR REPLACE PACKAGE BODY BTA_MT IS

  PROCEDURE PARSEMT103(MT103 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T23B  OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T50K  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T57A  OUT NVARCHAR2,
                       T59   OUT NVARCHAR2,
                       T70   OUT NVARCHAR2,
                       T71A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2,
                       T77T  OUT NVARCHAR2) IS
    P20  NUMBER;
    P23B NUMBER;
    P32A NUMBER;
    P50K NUMBER;
    P52A NUMBER;
    P57A NUMBER;
    P59  NUMBER;
    P70  NUMBER;
    P71A NUMBER;
    P72  NUMBER;
    P77T NUMBER;
    PEND NUMBER;
  
  BEGIN
  
    /*select '{1:F01RTGSGETBAXXX0000000013}' || chr(10) ||
         '{2:O1031328100121AB000000XXXX00000000131001211328N}' || chr(10) ||
         '{3:{113:40}}' || chr(10) || '{4:' || chr(10) || ':20:' || T20 ||
         chr(10) || ':23B:' || T23b || chr(10) || ':32A:' || T32a ||
         chr(10) || ':50K:' || T50k || chr(10) || ':52A:' || T52a ||
         chr(10) || ':57A:' || T57a || chr(10) || ':59:' || T59 ||
         chr(10) || ':70:' || T70 || chr(10) || ':71A:' || T71a ||
         chr(10) || ':72:' || T72 || chr(10) || ':77T:' || T77t ||
         chr(10) || '-}'
    into MT103
    
    from (select d.no T20,
                 'CRED' T23b,
                 to_char(d.value_Date, 'YYMMDD') ||
                 vb_currencies_s.get_cur_code(d.currency_no_1) ||
                 trim(to_char(d.amount_cur_1, '999,999,999.00')) T32a,
                 '/' || iban.get_iban(d.debit_acc_id, 0) || chr(10) ||
                 trim((select name_short
                        from customers c
                       where c.no = (select customer_no
                                       from accounts_main a
                                      where a.id = d.debit_Acc_id))) ||
                 chr(10) ||
                 trim((select tax_number
                        from customers c
                       where no = (select customer_no
                                     from accounts_main a
                                    where a.id = d.debit_Acc_id))) T50k,
                 'DISNGE22' T52a,
                 d.mfo_rec || chr(10) ||
                 trim((select k.swift_code
                        from bnkseek k
                       where k.newnum = d.mfo_rec)) T57a,
                 trim(nvl(d.rec_tax_number, '')) || chr(10) ||
                 trim(d.receipient_name) T59,
                 trim(d.payment_purpose) T70,
                 'OUR' T71a,
                 '/TTC/1112/TIN/' || trim(d.third_person_tax_number) ||
                 '/TPN/' || trim(d.third_person_name) || '/PON/' ||
                 trim(d.id) || '/POD/' ||
                 trim(to_char(d.payment_date, 'YYMMDD')) || '/PPD/' ||
                 trim(to_char(d.signed, 'YYMMDD')) T72,
                 trim(d.remarks) T77t
          
            from documents d
           where d.no = Doc_No);*/
  
    P20  := INSTR(MT103, ':20:');
    P23B := INSTR(MT103, ':23B:');
    P32A := INSTR(MT103, ':32A:');
    P50K := INSTR(MT103, ':50K:');
    P52A := INSTR(MT103, ':52A:');
    P57A := INSTR(MT103, ':57A:');
    P59  := INSTR(MT103, ':59:');
    P70  := INSTR(MT103, ':70:');
    P71A := INSTR(MT103, ':71A:');
    P72  := INSTR(MT103, ':72:');
    P77T := INSTR(MT103, ':77T:');
    PEND := INSTR(MT103, '-}');
  
    T20  := TRIM(SUBSTR(MT103, P20 + 4, P23B - P20 - 4));
    T23B := TRIM(SUBSTR(MT103, P23B + 5, P32A - P23B - 5));
    T32A := TRIM(SUBSTR(MT103, P32A + 5, P50K - P32A - 5));
    T50K := TRIM(SUBSTR(MT103, P50K + 5, P52A - P50K - 5));
    T52A := TRIM(SUBSTR(MT103, P52A + 5, P57A - P52A - 5));
    T57A := TRIM(SUBSTR(MT103, P57A + 5, P59 - P57A - 5));
    T59  := TRIM(SUBSTR(MT103, P59 + 4, P70 - P59 - 4));
    T70  := TRIM(SUBSTR(MT103, P70 + 4, P71A - P70 - 4));
    T71A := TRIM(SUBSTR(MT103, P71A + 5, P72 - P71A - 5));
    T70  := TRIM(SUBSTR(MT103, P70 + 4, P71A - P70 - 4));
    T72  := TRIM(SUBSTR(MT103, P72 + 4, P77T - P72 - 4));
    T77T := TRIM(SUBSTR(MT103, P77T + 5, PEND - P77T - 5));
  END;
  PROCEDURE PARSEMT204(MT204 VARCHAR2,
                       T201  OUT NVARCHAR2,
                       T19   OUT NVARCHAR2,
                       T30   OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T202  OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32B  OUT NVARCHAR2,
                       T53A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2) IS
    P201 NUMBER;
    P19  NUMBER;
    P30  NUMBER;
    P58A NUMBER;
    P202 NUMBER;
    P21  NUMBER;
    P32B NUMBER;
    P53A NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  BEGIN
    P201 := INSTR(MT204, ':20:');
    P19  := INSTR(MT204, ':19:');
    P30  := INSTR(MT204, ':30:');
    P58A := INSTR(MT204, ':58A:');
    P202 := INSTR(SUBSTR(MT204, P58A, 500), ':20:') + P58A - 1;
    P21  := INSTR(MT204, ':21:');
    P32B := INSTR(MT204, ':32B:');
    P53A := INSTR(MT204, ':53A:');
    P72  := INSTR(MT204, ':72:');
    PEND := INSTR(MT204, '-}');
  
    T201 := TRIM(SUBSTR(MT204, P201 + 4, P19 - P201 - 4));
    T19  := TRIM(SUBSTR(MT204, P19 + 4, P30 - P19 - 4));
    T30  := TRIM(SUBSTR(MT204, P30 + 4, P58A - P30 - 5));
    T58A := TRIM(SUBSTR(MT204, P58A + 5, P202 - P58A - 5));
    T202 := TRIM(SUBSTR(MT204, P202 + 4, P21 - P202 - 4));
    T21  := TRIM(SUBSTR(MT204, P21 + 4, P32B - P21 - 5));
    T32B := TRIM(SUBSTR(MT204, P32B + 5, P53A - P32B - 5));
    T53A := TRIM(SUBSTR(MT204, P53A + 5, P72 - P53A - 5));
    T72  := TRIM(SUBSTR(MT204, P72 + 4, PEND - P72 - 4));
  END;

  PROCEDURE PARSEMT205(MT205 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2) IS
    P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
    P58A NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  BEGIN
    P20  := INSTR(MT205, ':20:');
    P21  := INSTR(MT205, ':21:');
    P32A := INSTR(MT205, ':32A:');
    P52A := INSTR(MT205, ':52A:');
    P58A := INSTR(MT205, ':58A:');
    P72  := INSTR(MT205, ':72:');
    PEND := INSTR(MT205, '-}');
  
    T20  := TRIM(SUBSTR(MT205, P20 + 4, P21 - P20 - 4));
    T21  := TRIM(SUBSTR(MT205, P21 + 4, P32A - P21 - 5));
    T32A := TRIM(SUBSTR(MT205, P32A + 5, P52A - P32A - 5));
    T52A := TRIM(SUBSTR(MT205, P52A + 5, P58A - P52A - 5));
    T58A := TRIM(SUBSTR(MT205, P58A + 5, P72 - P58A - 5));
    T72  := TRIM(SUBSTR(MT205, P72 + 4, PEND - P72 - 4));
  END;

  PROCEDURE PARSEMT202(MT202 VARCHAR2,
                       T20   OUT NVARCHAR2,
                       T21   OUT NVARCHAR2,
                       T32A  OUT NVARCHAR2,
                       T52A  OUT NVARCHAR2,
                       T58A  OUT NVARCHAR2,
                       T72   OUT NVARCHAR2) IS
    P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
    P58A NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  
  BEGIN
    P20  := INSTR(MT202, ':20:');
    P21  := INSTR(MT202, ':21:');
    P32A := INSTR(MT202, ':32A:');
    P52A := INSTR(MT202, ':52A:');
    P58A := INSTR(MT202, ':58A:');
    P72  := INSTR(MT202, ':72:');
    PEND := INSTR(MT202, '-}');
  
    T20  := TRIM(SUBSTR(MT202, P20 + 4, P21 - P20 - 4));
    T21  := TRIM(SUBSTR(MT202, P21 + 4, P32A - P21 - 5));
    T32A := TRIM(SUBSTR(MT202, P32A + 5, P52A - P32A - 5));
    T52A := TRIM(SUBSTR(MT202, P52A + 5, P58A - P52A - 5));
    T58A := TRIM(SUBSTR(MT202, P58A + 5, P72 - P58A - 5));
    T72  := TRIM(SUBSTR(MT202, P72 + 4, PEND - P72 - 4));
  END;
  PROCEDURE PARSEMT198(MT198     CLOB,
                       T20       OUT VARCHAR2,
                       T12       OUT VARCHAR2,
                       T77E      OUT VARCHAR2,
                       T21       OUT VARCHAR2,
                       T11S      OUT VARCHAR2,
                       ERROR_TXT OUT CLOB) AS
    P20     NUMBER;
    P12     NUMBER;
    P77E    NUMBER;
    P21     NUMBER;
    P11S    NUMBER;
    PEND    NUMBER;
    I       NUMBER;
    COUNTER NUMBER;
    PM02    NUMBER;
    P16S    NUMBER;
  BEGIN
  
    P20  := INSTR(MT198, ':20:');
    P12  := INSTR(MT198, ':12:');
    P77E := INSTR(MT198, ':77E:');
    P21  := INSTR(MT198, ':21:');
    P11S := INSTR(MT198, ':11S:');
    PEND := INSTR(MT198, '-}');
  
    T20  := TRIM(SUBSTR(MT198, P20 + 4, P12 - P20 - 6));
    T12  := TRIM(SUBSTR(MT198, P12 + 4, P77E - P12 - 6));
    T77E := TRIM(SUBSTR(MT198, P77E + 5, P21 - P77E - 6));
    T21  := TRIM(SUBSTR(MT198, P21 + 4, P11S - P21 - 6));
  
    T11S := TRIM(SUBSTR(MT198,
                        P11S + 5,
                        INSTR(MT198, CHR(10), P11S + 5, 3) - P11S - 6));
  
    COUNTER := NUM_CHARS_CLOB(MT198, ':M02:');
  
    I         := 1;
    ERROR_TXT := '';
    WHILE (I < COUNTER + 1) LOOP
      PM02      := INSTR(MT198, ':M02:', 1, I);
      P16S      := INSTR(MT198, ':16S:', 1, I);
      ERROR_TXT := ERROR_TXT || SUBSTR(MT198, PM02 + 5, P16S - PM02 - 6);
      I         := I + 1;
    END LOOP;
  
  END;

  FUNCTION CREATEMT103(DOC_NO VARCHAR2) RETURN VARCHAR2 IS
  
    MT103  VARCHAR2(32767);
    SEQ_ID NUMBER;
    HEAD   VARCHAR2(1000);
    T20    VARCHAR2(1000);
    T23B   VARCHAR2(1000);
    T32A   VARCHAR2(1000);
    T50K   VARCHAR2(1000);
    T52A   VARCHAR2(1000);
    T57A   VARCHAR2(1000);
    T59    VARCHAR2(1000);
    T70    VARCHAR2(1000);
    T71A   VARCHAR2(1000);
    T72    VARCHAR2(1000);
    T77    VARCHAR2(1000);
    MFOREM VARCHAR2(100);
    MFOREC VARCHAR2(100);
    PPD VARCHAR2(20);
    POD VARCHAR2(20);
    PON VARCHAR2(20);
    TIN VARCHAR2(20);
    TPN VARCHAR2(1000);
    TTC VARCHAR2(20);
    i NUMBER;
    c NUMBER;
    token VARCHAR2(100);
    TPN_temp VARCHAR2(500);
    len NUMBER;
    COUNTER NUMBER;
    reference VARCHAR2(100);
    actual_reference VARCHAR2(100);
    found_slesh NUMBER;
    num_after_slash VARCHAR2(100);
    resident VARCHAR2(10);
		v_allowed_chars varchar2(100);
		v_allowed_chars_remarks varchar2(100);
  BEGIN
    v_allowed_chars:='[^a-zA-Z0-9/?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
		v_allowed_chars_remarks:='[^a-zA-Z0-9?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
		SELECT SEQ_RTGS_MT.NEXTVAL INTO SEQ_ID FROM DUAL;
    
     SELECT COUNT(*)
      INTO COUNTER
      FROM DOCUMENTS_ID_CODE
     WHERE NO = DOC_NO
       AND ID_CODE = 'MT_ID';
       
      IF (COUNTER=0) THEN
        reference:=to_char(DOC_NO);
        CREATE_REFERENCE(DOC_NO, reference);
      else
        SELECT id_value INTO reference FROM  DOCUMENTS_ID_CODE
        WHERE NO = DOC_NO
        AND ID_CODE = 'MT_ID';  
      end if; 
       
/*       IF (COUNTER=0) THEN
        
         reference:=to_char(DOC_NO);
       ELSE
          
         SELECT id_value INTO actual_reference FROM  DOCUMENTS_ID_CODE
       WHERE NO = DOC_NO
         AND ID_CODE = 'MT_ID';

         found_slesh:=INSTR(actual_reference,'/',1,1);
         
         IF (found_slesh=0) THEN
           reference:=actual_reference||'/1';
           
         ELSE
           num_after_slash:=substr(actual_reference,found_slesh+1);
           reference:=to_char(DOC_NO)||'/'||to_char(num_after_slash+1);
            
         END IF;
       
       
       END IF;
          CREATE_REFERENCE(DOC_NO, reference);*/
    
    
    
    --CREATE_REFERENCE(DOC_NO, SEQ_ID);
  
    HEAD := '{1:F01GEATSAAAAXXX' || TRIM(TO_CHAR(SEQ_ID, '0000000000')) ||
            '}{2:O103' || TO_CHAR(SYSDATE, 'HHMI') ||
            TO_CHAR(SYSDATE, 'YYMMDD') || 'DISNGE22XXXX' ||
            TRIM(TO_CHAR(SEQ_ID, '0000000000')) ||
            TO_CHAR(SYSDATE, 'YYMMDD') || TO_CHAR(SYSDATE, 'HHMI') ||
            'N}{3:{113:60}}{4:';
  
    --T20  := TO_CHAR(SEQ_ID);
    T20 :=reference;
    T23B := 'CRED';
    T71A :='OUR';
    SELECT TO_CHAR(CASE WHEN GLOBAL_PARAMS.IS_PROD = 1 then SYSDATE else D.VALUE_DATE end, 'YYMMDD') 
           || VB_CURRENCIES_S.GET_CUR_CODE(D.CURRENCY_NO_1) ||
           REPLACE(TRIM(TO_CHAR(D.AMOUNT_CUR_1, '9999999999999990.00')),
                   '.',
                   ','),
          '/' || SUBSTR(D.DEBIT_ACC_ID, 1, LENGTH(D.DEBIT_ACC_ID) - 3)  /*DECODE(LENGTH(d.debit_acc_id),25,substr(d.debit_acc_id,1,22),iban.get_iban(d.debit_acc_id,0))*/
           || CHR(13) || CHR(10) ||
           
          TRIM(NVL(D.REM_TAX_NUMBER, '--'))
           
           || CHR(13) || CHR(10) || 
           tokenize_string(rtgs.get_text_substr(REGEXP_REPLACE(TRIM(get_token(D.REMITTANT_NAME,1,',')), v_allowed_chars, ''),'REMITTANT_NAME'),33,2),
           D.MFO_REM,
           D.MFO_REC,
          '/' || TRIM(DECODE(trim(D.CBC),
                              '',
                              D.CREDIT_ACC_ID /*DECODE(LENGTH(d.credit_acc_id),22,substr(d.credit_acc_id,1,22),iban.get_iban(d.credit_acc_id,0))*/,
                              trim(D.CBC))) || CHR(13) || CHR(10) ||
           TRIM(NVL(D.REC_TAX_NUMBER, '--')) || CHR(13) || CHR(10) ||
           tokenize_string(rtgs.get_text_substr(TRIM(REGEXP_REPLACE(D.RECEIPIENT_NAME, v_allowed_chars, '')),'RECEIPIENT_NAME'),33,2), 
           tokenize_string(rtgs.get_text_substr(REGEXP_REPLACE(TRIM(D.PAYMENT_PURPOSE),v_allowed_chars, ''),'PAYMENT_PURPOSE'),33,4) ,rtgs.get_text_substr(REGEXP_REPLACE(TRIM(D.REMARKS), v_allowed_chars_remarks, ''),'REMARKS'),
                   TRIM(NVL(TO_CHAR(D.PAYMENT_DATE, 'YYMMDD'),
                            TO_CHAR(D.VALUE_DATE, 'YYMMDD'))),
                   TRIM(NVL(TO_CHAR(D.SIGNED, 'YYMMDD'),
                            TO_CHAR(D.VALUE_DATE, 'YYMMDD'))), 
                          SUBSTR(REGEXP_REPLACE(TRIM(D.ID),'[^0-9]',''),1,6) ,
                            DECODE(d.cbc, '', '','/TIN/'|| REGEXP_REPLACE(nvl(TRIM(D.THIRD_PERSON_TAX_NUMBER),d.rem_tax_number),'[^0-9]','')),
                               DECODE(d.cbc, '', '', rtgs.get_text_substr(REGEXP_REPLACE(nvl(TRIM(D.THIRD_PERSON_NAME),d.remittant_name), v_allowed_chars, ''),'THIRD_PERSON_NAME'))
      INTO T32A, T50K, MFOREM, MFOREC, T59,T70,T77,POD,PPD,PON,TIN,TPN
      FROM DOCUMENTS D
     WHERE D.NO = TO_NUMBER(DOC_NO);
  
    SELECT TRIM(K.SWIFT_CODE)
      INTO T52A
      FROM BNKSEEK K
     WHERE K.NEWNUM = MFOREM;
  
    SELECT TRIM(K.SWIFT_CODE)
      INTO T57A
      FROM BNKSEEK K
     WHERE K.NEWNUM = MFOREC;
     
     
     TTC:='/TTC/0103';
        i:=1;
  c:=1;
     T72:=TTC||'/POD/'||POD||'/PPD/'||PPD || CHR(13) || CHR(10) ||
     '/PON/'||PON||TIN;
     len :=28-length(substr(T72,instr(T72, CHR(13) || CHR(10),1,1)+2));
  WHILE (substr(TPN,i,len) IS NOT NULL AND c<4)
    LOOP
      token:=substr(TPN,i,len);

     IF (c>1) THEN
      
       TPN_temp:=TPN_temp||CHR(13) || CHR(10)||'/TPN/' ||token;
       ELSE
         TPN_temp:='/TPN/' ||token;
     END IF;
      i:=i+len;
      c:=c+1;
       len:=28;
    END LOOP;
    TPN:=TPN_temp;
     T72:=TTC||'/POD/'||POD||'/PPD/'||PPD || CHR(13) || CHR(10) ||
     '/PON/'||PON||TIN||TPN;
     

       
     
     IF (T77 IS NOT NULL)
       THEN
         T77:=CHR(13) || CHR(10) || ':77T:' || T77;
       END IF;
    
     MT103:=head || CHR(13) ||
           CHR(10) || ':20:' || T20 || CHR(13) || CHR(10) || ':23B:' || T23B ||
           CHR(13) || CHR(10) || ':32A:' || T32A || CHR(13) || CHR(10) ||
           ':50K:' || T50K || CHR(13) || CHR(10) || ':52A:' || T52A ||
           CHR(13) || CHR(10) || ':57A:' || T57A || CHR(13) || CHR(10) ||
           ':59:' || T59 || CHR(13) || CHR(10) || ':70:' || T70 || CHR(13) ||
           CHR(10) || ':71A:' || T71A || CHR(13) || CHR(10) || ':72:' || T72 ||
        T77 ||
           CHR(13) || CHR(10) || '-}';
           
           
  /*  SELECT '{1:F01GEATSAAAAXXX' || TRIM(TO_CHAR(T20, '0000000000')) ||
           '}{2:O103' || TO_CHAR(SYSDATE, 'HHMI') ||
           TO_CHAR(SYSDATE, 'YYMMDD') || 'DISNGE22XXXX' ||
           TRIM(TO_CHAR(T20, '0000000000')) || TO_CHAR(SYSDATE, 'YYMMDD') ||
           TO_CHAR(SYSDATE, 'HHMI') || 'N}{3:{113:40}}{4:' || CHR(13) ||
           CHR(10) || ':20:' || T20 || CHR(13) || CHR(10) || ':23B:' || T23B ||
           CHR(13) || CHR(10) || ':32A:' || T32A || CHR(13) || CHR(10) ||
           ':50K:' || T50K || CHR(13) || CHR(10) || ':52A:' || T52A ||
           CHR(13) || CHR(10) || ':57A:' || T57A || CHR(13) || CHR(10) ||
           ':59:' || T59 || CHR(13) || CHR(10) || ':70:' || T70 || CHR(13) ||
           CHR(10) || ':71A:' || T71A || CHR(13) || CHR(10) || ':72:' || T72 ||
           DECODE(T77T, '', '', CHR(13) || CHR(10) || ':77T:' || T77T) ||
           CHR(13) || CHR(10) || '-}'
      INTO MT103
    
      FROM (SELECT T20,
                   'CRED' T23B,
                   TO_CHAR(SYSDATE, 'YYMMDD') \*SATESTO*\ \*TO_CHAR(D.VALUE_DATE, 'YYMMDD') *\
                   || VB_CURRENCIES_S.GET_CUR_CODE(D.CURRENCY_NO_1) ||
                   REPLACE(TRIM(TO_CHAR(D.AMOUNT_CUR_1, '999999999999999.00')),
                           '.',
                           ',') T32A,
                   '/' ||
                   SUBSTR(D.DEBIT_ACC_ID, 1, LENGTH(D.DEBIT_ACC_ID) - 3) \*DECODE(LENGTH(d.debit_acc_id),25,substr(d.debit_acc_id,1,22),iban.get_iban(d.debit_acc_id,0))*\
                   || CHR(13) || CHR(10) ||
                   
                   TRIM(NVL(D.REM_TAX_NUMBER, '--'))
                   
                   || CHR(13) || CHR(10) ||
                   TRANSLATE(TRIM(D.REMITTANT_NAME),
                             '%!@#$^&*_=\|<>[]{};" ',
                             ' ') T50K,
                   TRIM((SELECT K.SWIFT_CODE
                          FROM BNKSEEK K
                         WHERE K.NEWNUM = D.MFO_REM)) T52A,
                   TRIM((SELECT K.SWIFT_CODE
                          FROM BNKSEEK K
                         WHERE K.NEWNUM = D.MFO_REC)) T57A,
                   '/' || TRIM(DECODE(D.CBC,
                                      '',
                                      D.CREDIT_ACC_ID \*DECODE(LENGTH(d.credit_acc_id),22,substr(d.credit_acc_id,1,22),iban.get_iban(d.credit_acc_id,0))*\,
                                      D.CBC)) || CHR(13) || CHR(10) ||
                   TRIM(NVL(D.REC_TAX_NUMBER, '--')) || CHR(13) || CHR(10) ||
                   TRIM(TRANSLATE(D.RECEIPIENT_NAME,
                                  '%!@#$^&*_=\|<>[]{};" ',
                                  ' ')) T59,
                   TRANSLATE(TRIM(D.PAYMENT_PURPOSE),
                             '%!@#$^&*_=\|<>[]{};" ',
                             ' ') T70,
                   'OUR' T71A,
                   '/TTC/0103/' ||
                   DECODE(D.CBC,
                          '',
                          '',
                          'TIN/' || NVL(TRIM(D.THIRD_PERSON_TAX_NUMBER),
                                        D.REM_TAX_NUMBER) || '/') || CHR(13) ||
                   CHR(10) || DECODE(D.CBC,
                                     '',
                                     '',
                                     '/TPN/' || TRANSLATE(SUBSTR(NVL(TRIM('LTD KEYBOARD'),
                                                                     'LTD KEYBOARD'),
                                                                 1,
                                                                 30),
                                                          '%!@#$^&*_=\|<>[]{};" ',
                                                          ' ') || '/' ||
                                     CHR(13) || CHR(10)) || '/PON/' ||
                   SUBSTR(TRIM(D.ID), 1, 6) || '/POD/' ||
                   TRIM(NVL(TO_CHAR(D.PAYMENT_DATE, 'YYMMDD'),
                            TO_CHAR(D.VALUE_DATE, 'YYMMDD'))) || '/PPD/' ||
                   TRIM(NVL(TO_CHAR(D.SIGNED, 'YYMMDD'),
                            TO_CHAR(D.VALUE_DATE, 'YYMMDD'))) T72,
                   TRANSLATE(TRIM(D.REMARKS), '%!@#$^&*_=\|<>[]{};" ', ' ') T77T
            
              FROM DOCUMENTS D
             WHERE D.NO = DOC_NO);
  */
    RETURN MT103;
  END;

  FUNCTION CREATEMT202(DOC_NO VARCHAR2) RETURN VARCHAR2 IS
  
    MT202  VARCHAR2(32767);
    SEQ_ID NUMBER;
        COUNTER NUMBER;
    reference VARCHAR2(100);
    actual_reference VARCHAR2(100);
    found_slesh NUMBER;
    num_after_slash VARCHAR2(100);
		v_allowed_chars varchar2(100);
		v_allowed_chars_remarks varchar2(100);
  BEGIN
    v_allowed_chars:='[^a-zA-Z0-9/?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
		v_allowed_chars_remarks:='[^a-zA-Z0-9?:().,''+აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ ' || CHR(13) || CHR(10) || '-]';
		SELECT SEQ_RTGS_MT.NEXTVAL INTO SEQ_ID FROM DUAL;
    
     SELECT COUNT(*)
      INTO COUNTER
      FROM DOCUMENTS_ID_CODE
     WHERE NO = DOC_NO
       AND ID_CODE = 'MT_ID';
       
      IF (COUNTER=0) THEN
        reference:=to_char(DOC_NO);
        CREATE_REFERENCE(DOC_NO, reference);
      else
        SELECT id_value INTO reference FROM  DOCUMENTS_ID_CODE
        WHERE NO = DOC_NO
        AND ID_CODE = 'MT_ID';  
      end if; 
       
/*       IF (COUNTER=0) THEN
        
         reference:=to_char(DOC_NO);
       ELSE
          
         SELECT id_value INTO actual_reference FROM  DOCUMENTS_ID_CODE
       WHERE NO = DOC_NO
         AND ID_CODE = 'MT_ID';

         found_slesh:=INSTR(actual_reference,'/',1,1);
         
         IF (found_slesh=0) THEN
           reference:=actual_reference||'/1';
           
         ELSE
           num_after_slash:=substr(actual_reference,found_slesh+1);
           reference:=to_char(DOC_NO)||'/'||to_char(num_after_slash+1);
            
         END IF;
       
       
       END IF;
          CREATE_REFERENCE(DOC_NO, reference);*/
    
    
   /* CREATE_REFERENCE(DOC_NO, SEQ_ID);*/
    
    
    
    
    SELECT '{1:F01GEATSAAAAXXX0000000000' /*|| lpad(T20,10,'0')*//*TRIM(TO_CHAR(T20, '0000000000'))*/ ||
           '}{2:O202' || TO_CHAR(SYSDATE, 'HHMI') ||
           TO_CHAR(SYSDATE, 'YYMMDD') || 'DISNGE22XXXX' || TRIM(lpad(TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'),20,'0'))
           /*TRIM(lpad(T20,10,'0')) || TO_CHAR(SYSDATE, 'YYMMDD') ||
           TO_CHAR(SYSDATE, 'HHMI') ||*/ ||'N}{3:{113:34}}{4:' || CHR(13) ||
           CHR(10) || ':20:' || T20 || CHR(13) || CHR(10) || ':21:' || T21 ||
           CHR(13) || CHR(10) || ':32A:' || T32A || CHR(13) || CHR(10) ||
           ':52A:' || T52A || CHR(13) || CHR(10) || ':58A:' || T58A ||
           CHR(13) || CHR(10) || ':72:' || T72 || CHR(13) || CHR(10) || '-}'
      INTO MT202
    
      FROM (SELECT /*SEQ_ID*/reference  T20,
                   REGEXP_REPLACE(NVL(TRIM(D.REMARKS), 'NONREF'),
                             v_allowed_chars, 
                             '') T21,
                   TO_CHAR(CASE WHEN GLOBAL_PARAMS.IS_PROD = 1 then SYSDATE else D.VALUE_DATE end, 'YYMMDD')  ||
                   VB_CURRENCIES_S.GET_CUR_CODE(D.CURRENCY_NO_1) ||
                   REPLACE(TRIM(TO_CHAR(D.AMOUNT_CUR_1, '999999999999990.00')),
                           '.',
                           ',') T32A,
                   '/' ||
                   SUBSTR(D.DEBIT_ACC_ID, 1, LENGTH(D.DEBIT_ACC_ID) - 3) /*DECODE(LENGTH(d.debit_acc_id),25,substr(d.debit_acc_id,1,22),iban.get_iban(d.debit_acc_id,0)) */
                   || CHR(13) || CHR(10) ||
                   TRIM((SELECT K.SWIFT_CODE
                          FROM BNKSEEK K
                         WHERE K.NEWNUM = D.MFO_REM)) T52A,
                   '/' || D.CREDIT_ACC_ID /*DECODE(LENGTH(d.credit_acc_id),22,substr(d.credit_acc_id,1,22),iban.get_iban(d.credit_acc_id,0))*/
                   || CHR(13) || CHR(10) ||
                   TRIM((SELECT K.SWIFT_CODE
                          FROM BNKSEEK K
                         WHERE K.NEWNUM = D.MFO_REC)) T58A,
                   
                   /*'/TTC/0202' || *//*'TIN/' || TRIM(D.THIRD_PERSON_TAX_NUMBER) ||
                                     '/TPN/' || TRIM(D.THIRD_PERSON_NAME) || */
                   '/PPD/' ||
                   TRIM(NVL(TO_CHAR(D.SIGNED, 'YYMMDD'),
                            TO_CHAR(D.VALUE_DATE, 'YYMMDD'))) || decode(d.payment_purpose,'','',CHR(13) || CHR(10) ||'//'||tokenize_string(rtgs.get_text_substr
  (REGEXP_REPLACE(TRIM(d.payment_purpose),v_allowed_chars_remarks, ''),'PAYMENT_PURPOSE'),31,3,'//')
  ) T72
            
              FROM DOCUMENTS D
             WHERE D.NO = DOC_NO);
  
    RETURN MT202;
  END;

  FUNCTION INSERTDOC(DEBITACC      VARCHAR2,
                     CREDITACC     VARCHAR2,
                     SENDERNAME    VARCHAR2,
                     RECNAME       VARCHAR2,
                     SENDERBANK    VARCHAR2,
                     RECBANK       VARCHAR2,
                     SENDERNO      VARCHAR2,
                     RECNO         VARCHAR2,
                     CURRENCY      VARCHAR2,
                     AMOUNT        NUMBER,
                     OPERDATE      DATE,
                     MSGFORMAT     VARCHAR2,
                     REFER         VARCHAR2,
                     PURPOSE       VARCHAR2,
                     REMARKS       VARCHAR2,
                     THIRD_PAY_TAX VARCHAR2,
                     THIRD_PAY_NM  VARCHAR2,
                     SENDER_TAX    VARCHAR2,
                     RECEIVER_TAX  VARCHAR2) RETURN NUMBER AS
    REC_ID     NUMBER;
    ISO        INT;
    OBJ_KEY_NO NUMBER;
    OPP        VARCHAR2(100);
    V_USER     VARCHAR2(50);
  BEGIN
    IF  MSGFORMAT = 'MT103' THEN
      OPP := 'БНР_103';
    ELSIF MSGFORMAT = 'MT202' THEN
      OPP := 'БНР_202';
    ELSE
      OPP := 'БНР';
    
    END IF;
    SELECT DOCUMENTS_NO_S.NEXTVAL INTO REC_ID FROM DUAL;
    OBJ_KEY_NO := SM_SCT_U.SET_REFERENCE(OPP, 'SRB', REC_ID);
    SELECT 'MAIA' INTO V_USER FROM DUAL;
    INSERT INTO DOCUMENTS
      (BRANCH,
       NO,
       ID,
       DOC_TYPE,
       CLASS_OP,
       CREATED,
       INSERTED_BY,
       DEBIT_ACC_ID,
       CREDIT_ACC_ID,
       AMOUNT_CUR_1,
       CURRENCY_NO_1,
       COURSE_ID_1,
       PAYMENT_PURPOSE,
       REMARKS,
       MFO_REC,
       MFO_REM,
       VALUE_DATE,
       PARENT_MDL,
       PARENT_SCN,
       OBJECT_KEY,
       PLAN_TYPE,
       DIVISION,
       REMITTANT_NAME,
       RECEIPIENT_NAME,
       THIRD_PERSON_TAX_NUMBER,
       THIRD_PERSON_NAME,
       REM_TAX_NUMBER,
       REC_TAX_NUMBER,
       REIS_NO)
    VALUES
      ('SRB',
       REC_ID,
       REFER,
       '01',
       OPP,
       SYSDATE,
       V_USER,
       DEBITACC,
       CREDITACC,
       AMOUNT,
       ISO,
       'ОК',
       PURPOSE,
       REMARKS,
       RECBANK,
       SENDERBANK,
       OPERDATE,
       'CRF',
       'БНР_ВНУТР',
       OBJ_KEY_NO,
       'ACC',
       '00',
       SENDERNAME,
       RECNAME,
       THIRD_PAY_TAX,
       THIRD_PAY_NM,
       SENDER_TAX,
       RECEIVER_TAX,
       1);
    COMMIT;
    RETURN REC_ID;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, SQLERRM);
      RETURN 0;
  END;

  PROCEDURE CREATEMT103DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS
  
    MT103   CLOB;
    INS_RES NUMBER;
    P20     NUMBER;
    P23B    NUMBER;
    P32A    NUMBER;
    P50K    NUMBER;
    P52A    NUMBER;
    P57A    NUMBER;
    P59     NUMBER;
    P70     NUMBER;
    P71A    NUMBER;
    P72     NUMBER;
    P77T    NUMBER;
    PEND    NUMBER;
  
    T20            NVARCHAR2(500);
    T23B           VARCHAR2(500);
    T32A           VARCHAR2(500);
    T50K           VARCHAR2(500);
    T52A           VARCHAR2(500);
    T57A           VARCHAR2(500);
    T59            VARCHAR2(500);
    T70            VARCHAR2(1000);
    T71A           VARCHAR2(500);
    T72            VARCHAR2(500);
    T77T           VARCHAR2(1000);
    ACC_COUNTER    NUMBER;
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    SENDER_NAME    VARCHAR2(500);
    RECEIVER_NAME  VARCHAR2(500);
    CCY            VARCHAR2(50);
    SENDER_TAX     VARCHAR2(50);
    RECEIVER_TAX   VARCHAR2(50);
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
    AMOUNT         NUMBER;
    VALUE_DT       DATE;
    DOC_ID         VARCHAR2(50);
    DESCR          VARCHAR2(1000);
    REM            VARCHAR2(1000);
    THIRD_PERS_TAX VARCHAR2(50);
    THIRD_PERS_NM  VARCHAR2(500);
    ERR_MSG        VARCHAR2(1500);
    ACC_FROM_IBAN  VARCHAR2(50);
    START_POS      NUMBER;
    END_POS        NUMBER;
    VIP_NO         NUMBER;
    T59_3          NUMBER;
    check_result NUMBER;
    POD VARCHAR2(10);
    PPD VARCHAR2(10);
    payment_dt DATE;
    signed DATE;
    dublicate NUMBER;
    dubl_exc EXCEPTION;
  BEGIN
    MT103 := P_MSG;
  
    MT103 := REPLACE(MT103, CHR(10) || CHR(13), CHR(13));
    MT103 := REPLACE(MT103, CHR(13) || CHR(10), CHR(13));
    P20   := INSTR(MT103, ':20:');
    P23B  := INSTR(MT103, ':23B:');
    P32A  := INSTR(MT103, ':32A:');
    P50K  := INSTR(MT103, ':50K:');
    P52A  := INSTR(MT103, ':52A:');
    P57A  := INSTR(MT103, ':57A:');
    P59   := INSTR(MT103, ':59:');
    P70   := INSTR(MT103, ':70:');
    P71A  := INSTR(MT103, ':71A:');
    P72   := INSTR(MT103, ':72:');
    P77T  := INSTR(MT103, ':77T:');
  
    PEND := INSTR(MT103, '-}');
  
    T20  := TRIM(SUBSTR(MT103, P20 + 4, P23B - P20 - 5));
    T23B := TRIM(SUBSTR(MT103, P23B + 5, P32A - P23B - 6));
    T32A := TRIM(SUBSTR(MT103, P32A + 5, P50K - P32A - 6));
    T50K := TRIM(SUBSTR(MT103, P50K + 5, P52A - P50K - 6));
    T52A := TRIM(SUBSTR(MT103, P52A + 5, P57A - P52A - 6));
  
    T57A := TRIM(SUBSTR(MT103, P57A + 5, P59 - P57A - 6));
    T59  := TRIM(SUBSTR(MT103, P59 + 4, P70 - P59 - 5));
    T70  := TRIM(SUBSTR(MT103, P70 + 4, P71A - P70 - 5));
    T71A := TRIM(SUBSTR(MT103, P71A + 5, P72 - P71A - 5));
    IF (P77T = 0) THEN
    
      T72 := TRIM(SUBSTR(MT103, P72 + 4, PEND - P72 - 5));
    ELSE
      T72 := TRIM(SUBSTR(MT103, P72 + 4, P77T - P72 - 5));
    
      T77T := TRIM(SUBSTR(MT103, P77T + 5, PEND - P77T - 6));
    END IF;
  
    CCY         := SUBSTR(T32A, 7, 3);
    CCY         := REPLACE(CCY, CHR(13), '');
    DEB_ACC_ID  := SUBSTR(T50K, 2, INSTR(T50K, CHR(13), 1, 1) - 2);
    DEB_ACC_ID  := REPLACE(DEB_ACC_ID, CHR(13), '');
    DEB_ACC_ID  := SUBSTR(DEB_ACC_ID, 1, 25);
    CRED_ACC_ID := SUBSTR(T59, 2, INSTR(T59, CHR(13), 1, 1) - 2);
    CRED_ACC_ID := REPLACE(CRED_ACC_ID, CHR(13), '');
    CRED_ACC_ID := SUBSTR(CRED_ACC_ID, 1, 22) || CCY;
  
    SELECT COUNT(*)
      INTO ACC_COUNTER
      FROM ACCOUNTS_MAIN
     WHERE ID = CRED_ACC_ID;
    IF (ACC_COUNTER = 0) THEN
    
      ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
      IF (ACC_FROM_IBAN IS NOT NULL) THEN
        SELECT COUNT(*)
          INTO ACC_COUNTER
          FROM ACCOUNTS_MAIN
         WHERE ID = ACC_FROM_IBAN;
        IF (ACC_COUNTER = 1) THEN
          CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
        END IF;
      END IF;
    
    END IF;
  
    SENDER_TAX := SUBSTR(T50K,
                         INSTR(T50K, CHR(13), 1, 1) + 1,
                         INSTR(T50K, CHR(13), 1, 2) -
                         INSTR(T50K, CHR(13), 1, 1) - 1);
    SENDER_TAX := REPLACE(SENDER_TAX, CHR(13), '');
    IF (SENDER_TAX = '--') THEN
      SENDER_TAX := '';
    END IF;
    SENDER_NAME := TRIM(SUBSTR(T50K, INSTR(T50K, CHR(13), 1, 2) + 1));
    SENDER_NAME := REPLACE(SENDER_NAME, CHR(13), '');
  
    IF (SENDER_TAX IS NOT NULL) THEN
      SENDER_NAME := SENDER_NAME || ', ' || SENDER_TAX;
    END IF;
    
   /* T59_3 := INSTR(T59, CHR(13), 1, 3);
    IF (T59_3 = 0) THEN
    
      RECEIVER_NAME := TRIM(SUBSTR(T59, INSTR(T59, CHR(13), 1, 2) + 1));
      RECEIVER_NAME := REPLACE(RECEIVER_NAME, CHR(13), '');
    ELSE
      RECEIVER_NAME := SUBSTR(T59,
                              INSTR(T59, CHR(13), 1, 2) + 1,
                              INSTR(T59, CHR(13), 1, 3) -
                              INSTR(T59, CHR(13), 1, 2) - 1);

     RECEIVER_NAME := REPLACE(RECEIVER_NAME, CHR(13), '');                                                
    END IF;*/
     RECEIVER_NAME := TRIM(SUBSTR(T59, INSTR(T59, CHR(13), 1, 2) + 1));
      RECEIVER_NAME := REPLACE(RECEIVER_NAME, CHR(13), '');
    
    
    
    RECEIVER_TAX := SUBSTR(T59,
                           INSTR(T59, CHR(13), 1, 1) + 1,
                           INSTR(T59, CHR(13), 1, 2) -
                           INSTR(T59, CHR(13), 1, 1) - 1);
    RECEIVER_TAX := REPLACE(RECEIVER_TAX, CHR(13), '');
  
    IF (RECEIVER_TAX = '--') THEN
      RECEIVER_TAX := '';
    END IF;
    SENDER_SWIFT   := T52A;
    SENDER_SWIFT   := REPLACE(SENDER_SWIFT, CHR(13), '');
    RECEIVER_SWIFT := T57A;
    RECEIVER_SWIFT := REPLACE(RECEIVER_SWIFT, CHR(13), '');
    SELECT NEWNUM
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT
       AND IS_HEAD = 1;
    SELECT NEWNUM
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT
       AND IS_HEAD = 1;
    AMOUNT    := TO_NUMBER(REPLACE(SUBSTR(T32A, 10), ',', '.'),
                           '999999999999999999.00');
    VALUE_DT  := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
    
    
    dublicate :=is_dublicate_msg(T20,REPLACE(SUBSTR(T32A, 10), ',', '.'),SUBSTR(T32A, 1, 6),SENDER_SWIFT,'MT103');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
    
    /*START_POS := INSTR(T72, '/PON', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    DOC_ID    := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);*/
    
    DOC_ID:=rtgs.get_struct_field_value(T72,'PON');
    
    
    /*START_POS := INSTR(T72, '/POD', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    POD    := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);*/
    POD:=rtgs.get_struct_field_value(T72,'POD');
    payment_dt := nvl(to_date(POD,'YYMMDD'),trunc(SYSDATE));
    
    
  /*  START_POS := INSTR(T72, '/PPD', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    PPD    := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);*/
      PPD:=rtgs.get_struct_field_value(T72,'PPD');
    signed := nvl(to_date(PPD,'YYMMDD'),trunc(SYSDATE));
    
   /* START_POS := INSTR(T72, '/TIN', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    THIRD_PERS_TAX := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);*/
    
    THIRD_PERS_TAX:=rtgs.get_struct_field_value(T72,'TIN');
    
    /*
    START_POS      := INSTR(T72, '/TPN', 1, 1);
    END_POS        := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    THIRD_PERS_NM := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);*/
    
        THIRD_PERS_NM:=rtgs.get_struct_field_value(T72,'TPN');
    THIRD_PERS_NM := REPLACE(THIRD_PERS_NM, ',', ' ');
    
    
    DESCR         := T70;
    REM           := T77T;
  
    VIP_NO := RTGS.INSERT_RKC_HEADER('MT_103');
    IF (VIP_NO = 0) THEN
      ERR_MSG := 'Procedure: CREATEMT103DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END IF;
    
    IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
    
    
    RTGS.INSERT_RKC_ENTRY(VIP_NO,
                          DOC_ID,
                          SENDER_MFO,
                          DEB_ACC_ID,
                          SENDER_TAX,
                          SENDER_NAME,
                          AMOUNT,
                          '220101827',
                          CRED_ACC_ID,
                          RECEIVER_TAX,
                          RECEIVER_NAME,
                          VALUE_DT,
                          REM,
                          DESCR,
                          payment_dt,
                          signed);
    COMMIT;
  

  if((SENDER_MFO !='220101222' or SENDER_TAX not in ('200293315','202178927')) or  (SENDER_MFO != '220101601' )) then
    BEGIN
      
    --check_result:=check_receiver(CRED_ACC_ID,RECEIVER_TAX);
    check_result:=is_iban(SUBSTR(CRED_ACC_ID, 1, 22));
    IF (check_result=1) THEN
      AUTH_INC_MT(VIP_NO);
    END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ERR_MSG := 'PROC: CREATEMT103DOC; ERROR: cannot authorize document, vip_no: ' ||
                   VIP_NO || '
      ' || SQLERRM;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END;
    end if;
    /*    INS_RES        := INSERTDOC(DEB_ACC_ID,
    CRED_ACC_ID,
    SENDER_NAME,
    RECEIVER_NAME,
    SENDER_MFO,
    RECEIVER_MFO,
    '',
    '',
    VB_CURRENCIES_S.GET_NUMERIC_CCY(CCY),
    AMOUNT,
    VALUE_DT,
    'MT103',
    DOC_ID,
    DESCR,
    REM,
    THIRD_PERS_TAX,
    THIRD_PERS_NM,
    SENDER_TAX,
    RECEIVER_TAX);*/
  
  EXCEPTION
    WHEN dubl_exc THEN
      ERR_MSG := 'MT_103 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32A, 10), ',', '.')||' '||SUBSTR(T32A, 1, 6)||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
        ERR_MSG := 'PROC: CREATEMT103DOC; ERROR: ' ||
                   SUBSTR(SQLERRM, 1, 900);
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    
  END;

  PROCEDURE CREATEMT202DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS
    P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
    P58A NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  
    T20            VARCHAR2(200);
    T21            VARCHAR2(200);
    T32A           VARCHAR2(200);
    T52A           VARCHAR2(200);
    T58A           VARCHAR2(200);
    T72            VARCHAR2(200);
    MT202          VARCHAR2(32767);
    ERR_MSG        VARCHAR2(1500);
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    CCY            VARCHAR2(50);
    AMOUNT         NUMBER;
    VALUE_DT       DATE;
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
    THIRD_PERS_TAX VARCHAR2(50);
    THIRD_PERS_NM  VARCHAR2(500);
    INS_RES        NUMBER;
    REL_REF        VARCHAR2(500);
    ACC_COUNTER    NUMBER;
    ACC_FROM_IBAN  VARCHAR2(50);
    VIP_NO         NUMBER;
    START_POS      NUMBER;
        POD VARCHAR2(10);
    PPD VARCHAR2(10);
  
    END_POS NUMBER;
    AM_CHAR VARCHAR2(50);
    DOC_ID  VARCHAR2(50);
        payment_dt DATE;
    signed DATE;
    payment_purp VARCHAR2(500);
    /*BEGIN(RTGS-1324)*/
    check_result NUMBER;
    /*END(RTGS-1324)*/
      dublicate NUMBER;
    dubl_exc EXCEPTION;
  BEGIN
    MT202 := P_MSG;
    MT202 := REPLACE(MT202, CHR(10) || CHR(13), CHR(13));
    MT202 := REPLACE(MT202, CHR(13) || CHR(10), CHR(13));
    P20   := INSTR(MT202, ':20:');
    P21   := INSTR(MT202, ':21:');
    P32A  := INSTR(MT202, ':32A:');
    P52A  := INSTR(MT202, ':52A:');
    P58A  := INSTR(MT202, ':58A:');
    P72   := INSTR(MT202, ':72:');
    PEND  := INSTR(MT202, '-}');
  
    T20  := TRIM(SUBSTR(MT202, P20 + 4, P21 - P20 - 5));
    T21  := TRIM(SUBSTR(MT202, P21 + 4, P32A - P21 - 5));
    T32A := TRIM(SUBSTR(MT202, P32A + 5, P52A - P32A - 6));
  
    T52A := TRIM(SUBSTR(MT202, P52A + 5, P58A - P52A - 6));
    IF (P72 = 0) THEN
      T58A := TRIM(SUBSTR(MT202, P58A + 5, PEND - P58A - 6));
    ELSE
      T58A := TRIM(SUBSTR(MT202, P58A + 5, P72 - P58A - 6));
      T72  := TRIM(SUBSTR(MT202, P72 + 4, PEND - P72 - 5));
    END IF;
  
    CCY         := SUBSTR(T32A, 7, 3);
    CCY         := REPLACE(CCY, CHR(13), '');
    AM_CHAR     := REPLACE(SUBSTR(T32A, 10), ',', '.');
    AMOUNT      := TO_NUMBER(AM_CHAR, '999999999999999999.00');
    VALUE_DT    := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
    DEB_ACC_ID  := SUBSTR(T52A, 2, INSTR(T52A, CHR(13), 1, 1) - 2);
    DEB_ACC_ID  := SUBSTR(DEB_ACC_ID, 1, 25);

    
    CRED_ACC_ID := SUBSTR(T58A, 2, INSTR(T58A, CHR(13), 1, 1) - 2);
    CRED_ACC_ID := REPLACE(CRED_ACC_ID, CHR(13), '');

    IF (CRED_ACC_ID IS NOT NULL) THEN
      CRED_ACC_ID := SUBSTR(CRED_ACC_ID, 1, 22);
      CRED_ACC_ID := CRED_ACC_ID || CCY;
    END IF;
    SELECT COUNT(*)
      INTO ACC_COUNTER
      FROM ACCOUNTS_MAIN
     WHERE ID = CRED_ACC_ID;
    IF (ACC_COUNTER = 0) THEN
    
      ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
      IF (ACC_FROM_IBAN IS NOT NULL) THEN
        SELECT COUNT(*)
          INTO ACC_COUNTER
          FROM ACCOUNTS_MAIN
         WHERE ID = ACC_FROM_IBAN;
        IF (ACC_COUNTER = 1) THEN
          CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
        END IF;
      END IF;
    
    END IF;
  
    SENDER_SWIFT   := TRIM(SUBSTR(T52A, INSTR(T52A, CHR(13), 1, 1) + 1));
    SENDER_SWIFT   := REPLACE(SENDER_SWIFT, CHR(13), '');

    RECEIVER_SWIFT := TRIM(SUBSTR(T58A, INSTR(T58A, CHR(13), 1, 1) + 1));
    RECEIVER_SWIFT := REPLACE(RECEIVER_SWIFT, CHR(13), '');

    REL_REF        := T21;
    REL_REF        := REPLACE(REL_REF, CHR(13), '');
    SELECT NEWNUM
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT
       AND IS_HEAD = 1;
    SELECT NEWNUM
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT
       AND IS_HEAD = 1;
  
  
      dublicate :=is_dublicate_msg(T20,REPLACE(SUBSTR(T32A, 10), ',', '.'),SUBSTR(T32A, 1, 6),SENDER_SWIFT,'MT202');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
  
    /*START_POS := INSTR(T72, '/PON', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      DOC_ID := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    END IF;*/
        DOC_ID:=rtgs.get_struct_field_value(T72,'PON');
    
    
   /* START_POS := INSTR(T72, '/TIN', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      THIRD_PERS_TAX := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    END IF;*/
    
            THIRD_PERS_TAX:=rtgs.get_struct_field_value(T72,'TIN');
    
   /* START_POS := INSTR(T72, '/TPN', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      THIRD_PERS_NM := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    
    END IF;*/
    
          THIRD_PERS_NM:=rtgs.get_struct_field_value(T72,'TPN');
    
    /*
     START_POS := INSTR(T72, '/PPD', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      PPD := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
        signed := nvl(to_date('PPD','YYMMDD'),trunc(SYSDATE));
    END IF;*/
      PPD:=rtgs.get_struct_field_value(T72,'PPD');
            signed := nvl(to_date(PPD,'YYMMDD'),trunc(SYSDATE));
    
      /* START_POS := INSTR(T72, '/POD', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      POD := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
        payment_dt := nvl(to_date('POD','YYMMDD'),trunc(SYSDATE));
    END IF;*/
          POD:=rtgs.get_struct_field_value(T72,'POD');
            payment_dt := nvl(to_date(POD,'YYMMDD'),trunc(SYSDATE));
            
            
      /*  START_POS := INSTR(T72, '//', 1, 1);
      END_POS   := PEND;
    
      IF (START_POS != 0) THEN
        payment_purp := SUBSTR(T72, START_POS + 2, END_POS - START_POS - 2);
      END IF;     */
      
      
      payment_purp:=  rtgs.get_struct_field_value(T72,'');
            
    --  payment_purp:=  rtgs.get_struct_field_value(T72,'ADI');   
    
    VIP_NO := RTGS.INSERT_RKC_HEADER('MT_202');
    IF (VIP_NO = 0) THEN
      ERR_MSG := 'Procedure: CREATEMT202DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END IF;
        IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
    RTGS.INSERT_RKC_ENTRY(VIP_NO,
                          DOC_ID,
                          SENDER_MFO,
                          DEB_ACC_ID,
                          '',
                          '',
                          AMOUNT,
                          '220101827',
                          CRED_ACC_ID,
                          '',
                          '',
                          VALUE_DT,
                          REL_REF,
                          nvl(payment_purp,'გარიგების თანახმად'),
                          payment_dt,
                          signed);
    COMMIT;
  
   /* BEGIN
      AUTH_INC_MT(VIP_NO);
    
    EXCEPTION
      WHEN OTHERS THEN
        ERR_MSG := 'PROC: CREATEMT202DOC; ERROR: cannot authorize document, vip_no: ' ||
                   VIP_NO || '
      ' || SQLERRM;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END;*/
  
    /* BEGIN
      INS_RES := INSERTDOC(DEB_ACC_ID,
                           CRED_ACC_ID,
                           '',
                           '',
                           SENDER_MFO,
                           RECEIVER_MFO,
                           '',
                           '',
                           VB_CURRENCIES_S.GET_NUMERIC_CCY(CCY),
                           AMOUNT,
                           VALUE_DT,
                           'MT202',
                           '',
                           'გარიგების თანახმად',
                           REL_REF,
                           THIRD_PERS_TAX,
                           THIRD_PERS_NM,
                           '',
                           '');
    EXCEPTION
      WHEN OTHERS THEN
        ERR_MSG := 'PROC: CREATEMT202DOC; ERROR: cannot insert document' || '
     ' || SQLERRM;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END;*/
    
    /*BEGIN(RTGS-1324)*/
        BEGIN
      
  
    check_result:=is_iban(SUBSTR(CRED_ACC_ID, 1, 22));
    IF (check_result=1) THEN
      AUTH_INC_MT(VIP_NO);
    END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ERR_MSG := 'PROC: CREATEMT202DOC; ERROR: cannot authorize document, vip_no: ' ||
                   VIP_NO || '
      ' || SQLERRM;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END;
    /*END(RTGS-1324)*/
  EXCEPTION
    WHEN dubl_exc THEN
      ERR_MSG := 'MT_202 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32A, 10), ',', '.')||' '||SUBSTR(T32A, 1, 6)||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
        ERR_MSG := 'PROC: CREATEMT202DOC; ERROR: cannot insert document' ||
                   SQLERRM;
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
  END;

  PROCEDURE CREATEMT204DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS
    P20_MASTER NUMBER;
    P20        NUMBER;
    P19        NUMBER;
    P30        NUMBER;
    P58A       NUMBER;
  
    P21  NUMBER;
    P32B NUMBER;
    P53A NUMBER;
    P72  NUMBER;
  
    PEND NUMBER;
  
    T20_MASTER VARCHAR2(200);
    T20        VARCHAR2(200);
    T19        VARCHAR2(200);
    T30        VARCHAR2(200);
    T58A       VARCHAR2(200);
    T21        VARCHAR2(200);
    T32B       VARCHAR2(200);
    T53A       VARCHAR2(200);
    T72        VARCHAR2(200);
  
    COUNT_TRAN NUMBER;
    MT204      VARCHAR2(32767);
    TRAN_NUM   NUMBER;
    I          NUMBER;
    VIP_NO     NUMBER;
    START_POS  NUMBER;
  
    END_POS        NUMBER;
    DOC_ID         VARCHAR2(50);
    ERR_MSG        VARCHAR2(1500);
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    CCY            VARCHAR2(50);
    AMOUNT         NUMBER;
    VALUE_DT       DATE;
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
    THIRD_PERS_TAX VARCHAR2(50);
    THIRD_PERS_NM  VARCHAR2(500);
    INS_RES        NUMBER;
    REL_REF        VARCHAR2(500);
    ACC_COUNTER    NUMBER;
    ACC_FROM_IBAN  VARCHAR2(50);
    AM_CHAR        VARCHAR2(50);
    PURP           VARCHAR2(500);
      dublicate NUMBER;
    dubl_exc EXCEPTION;
  BEGIN
    MT204 := P_MSG;
  
    MT204      := REPLACE(MT204, CHR(10) || CHR(13), CHR(13));
    MT204      := REPLACE(MT204, CHR(13) || CHR(10), CHR(13));
    COUNT_TRAN := NUM_CHARS_CLOB(MT204, ':20:');
    TRAN_NUM   := COUNT_TRAN - 1;
  
    P20_MASTER := INSTR(MT204, ':20:', 1, 1);
    P19        := INSTR(MT204, ':19:');
    P30        := INSTR(MT204, ':30:');
    P58A       := INSTR(MT204, ':58A:');
  
    PEND := INSTR(MT204, '-}');
  
    T20_MASTER := TRIM(SUBSTR(MT204, P20_MASTER + 4, P19 - P20_MASTER - 5));
    T19        := TRIM(SUBSTR(MT204, P19 + 4, P30 - P19 - 5));
    T30        := TRIM(SUBSTR(MT204, P30 + 4, P58A - P30 - 5));
    VALUE_DT   := TO_DATE(SUBSTR(T30, 1, 6), 'YYMMDD');
  
    P20 := INSTR(MT204, ':20:', 1, 2);
  
    T58A           := TRIM(SUBSTR(MT204, P58A + 5, P20 - P58A - 6));
    CRED_ACC_ID    := SUBSTR(T58A, 2, INSTR(T58A, CHR(13), 1, 1) - 2);
    RECEIVER_SWIFT := TRIM(SUBSTR(T58A, INSTR(T58A, CHR(13), 1, 1) + 1));
    RECEIVER_SWIFT := REPLACE(RECEIVER_SWIFT, CHR(13), '');
    I              := 0;
    WHILE (I < TRAN_NUM) LOOP
      P20  := INSTR(MT204, ':20:', 1, I + 2);
      P21  := INSTR(MT204, ':21:');
      P32B := INSTR(MT204, ':32B:');
      P53A := INSTR(MT204, ':53A:');
      P72  := INSTR(MT204, ':72:');
    
      T20  := TRIM(SUBSTR(MT204, P20 + 4, P21 - P20 - 5));
      T21  := TRIM(SUBSTR(MT204, P21 + 4, P32B - P21 - 5));
      T32B := TRIM(SUBSTR(MT204, P32B + 5, P53A - P32B - 6));
      IF (P72 = 0) THEN
        T53A := TRIM(SUBSTR(MT204, P53A + 5, PEND - P53A - 6));
      ELSE
        T53A := TRIM(SUBSTR(MT204, P53A + 5, P72 - P53A - 6));
      END IF;
    
      IF (INSTR(MT204, ':20:', 1, I + 3) = 0) THEN
        IF (P72 != 0) THEN
        T72 := TRIM(SUBSTR(MT204, P72 + 4, PEND - P72 - 5));
        END IF;
      ELSE
        T72 := TRIM(SUBSTR(MT204,
                           P72 + 4,
                           (INSTR(MT204, ':20:', 1, I + 3) + 4) - P72 - 5));
      END IF;
    
      REL_REF := T21;
    
      CCY          := SUBSTR(T32B, 1, 3);
      CCY          := REPLACE(CCY, CHR(13), '');
      AM_CHAR      := REPLACE(SUBSTR(T32B, 4), ',', '.');
      AMOUNT       := TO_NUMBER(AM_CHAR, '999999999999999999.00');
      DEB_ACC_ID   := SUBSTR(T53A, 2, INSTR(T53A, CHR(13), 1, 1) - 2);
      DEB_ACC_ID   := REPLACE(DEB_ACC_ID, CHR(13), '');
      SENDER_SWIFT := TRIM(SUBSTR(T53A, INSTR(T53A, CHR(13), 1, 1) + 1));
      SENDER_SWIFT := REPLACE(SENDER_SWIFT, CHR(13), '');
      SELECT NEWNUM
        INTO SENDER_MFO
        FROM BNKSEEK K
       WHERE SWIFT_CODE = SENDER_SWIFT
         AND IS_HEAD = 1;
      SELECT NEWNUM
        INTO RECEIVER_MFO
        FROM BNKSEEK K
       WHERE SWIFT_CODE = RECEIVER_SWIFT
         AND IS_HEAD = 1;
         
              dublicate :=is_dublicate_msg(T20_MASTER,REPLACE(SUBSTR(T32B, 4), ',', '.'),T30,RECEIVER_SWIFT,'MT204');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
         
         
     /* START_POS := INSTR(T72, '/PON', 1, 1);
      END_POS   := INSTR(T72, '/', START_POS + 5, 1);
      IF (END_POS = 0 AND START_POS != 0) THEN
        END_POS := LENGTH(T72) + 1;
      END IF;
      IF (START_POS != 0) THEN
        DOC_ID := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
      END IF;*/
    
      DOC_ID:=rtgs.get_struct_field_value(T72,'PON');
    
    
/*      START_POS := INSTR(T72, '//', 1, 1);
      END_POS   := PEND;
    
      IF (START_POS != 0) THEN
        PURP := SUBSTR(T72, START_POS + 2, END_POS - START_POS - 2);
      END IF;*/
    PURP:=  rtgs.get_struct_field_value(T72,'');
    
    /* START_POS := INSTR(T72, '/ADI',1,1);
    END_POS   := PEND;
  
    IF (START_POS != 0) THEN
      PURP := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
      PURP:= REPLACE(PURP,'/ADI/','');
    END IF;*/
    
    --PURP:=rtgs.get_struct_field_value(T72,'ADI');
    
    
      IF (SENDER_SWIFT = 'DISNGE22' AND DEB_ACC_ID IS NOT NULL) THEN
        DEB_ACC_ID := SUBSTR(DEB_ACC_ID, 1, 22);
        DEB_ACC_ID := DEB_ACC_ID || CCY;
      
        SELECT COUNT(*)
          INTO ACC_COUNTER
          FROM ACCOUNTS_MAIN
         WHERE ID = DEB_ACC_ID;
        IF (ACC_COUNTER = 0) THEN
        
          ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(DEB_ACC_ID);
          IF (ACC_FROM_IBAN IS NOT NULL) THEN
            SELECT COUNT(*)
              INTO ACC_COUNTER
              FROM ACCOUNTS_MAIN
             WHERE ID = ACC_FROM_IBAN;
            IF (ACC_COUNTER = 1) THEN
              DEB_ACC_ID := IBAN.GET_ACC_FROM_IBAN(DEB_ACC_ID);
            END IF;
          END IF;
        
        END IF;
      ELSE
        IF (CRED_ACC_ID IS NOT NULL) THEN
          CRED_ACC_ID := CRED_ACC_ID || CCY;
          CRED_ACC_ID := SUBSTR(CRED_ACC_ID, 1, 22);
          SELECT COUNT(*)
            INTO ACC_COUNTER
            FROM ACCOUNTS_MAIN
           WHERE ID = CRED_ACC_ID;
          IF (ACC_COUNTER = 0) THEN
          
            ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
            IF (ACC_FROM_IBAN IS NOT NULL) THEN
              SELECT COUNT(*)
                INTO ACC_COUNTER
                FROM ACCOUNTS_MAIN
               WHERE ID = ACC_FROM_IBAN;
              IF (ACC_COUNTER = 1) THEN
                CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
              END IF;
            END IF;
          
          END IF;
        END IF;
      END IF;
     /* IF (RECEIVER_SWIFT = 'DISNGE22' AND DEB_ACC_ID IS NULL) THEN
        --DEB_ACC_ID  := '10520000GEL';
        CRED_ACC_ID := '25030003GEL';
      END IF;
      IF (SENDER_SWIFT = 'DISNGE22' AND CRED_ACC_ID IS NULL) THEN
        CRED_ACC_ID := '10520000GEL';
       -- DEB_ACC_ID  := '25030003GEL';
      END IF;*/
    
    
       IF (RECEIVER_SWIFT = 'DISNGE22' AND DEB_ACC_ID IS NULL) THEN
      DEB_ACC_ID := '10520000GEL';
      --CRED_ACC_ID:='25030003GEL';
    END IF;
    IF (SENDER_SWIFT = 'DISNGE22' AND CRED_ACC_ID IS NULL) THEN
      CRED_ACC_ID := '10520000GEL';
      --DEB_ACC_ID:='25030003GEL';
    END IF;
    
    
      VIP_NO := RTGS.INSERT_RKC_HEADER('MT_204');
      IF (VIP_NO = 0) THEN
        ERR_MSG := 'Procedure: CREATEMT204DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
        SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
      END IF;
      
          IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
     
      RTGS.INSERT_RKC_ENTRY(VIP_NO,
                            DOC_ID,
                            SENDER_MFO,
                            DEB_ACC_ID,
                            '',
                            '',
                            AMOUNT,
                            RECEIVER_MFO,
                            CRED_ACC_ID,
                            '',
                            '',
                            VALUE_DT,
                            REL_REF,
                            nvl(PURP,'გარიგების თანახმად'),
                            VALUE_DT,
                            VALUE_DT);
                            
                  
      COMMIT;
    
      /*BEGIN
        AUTH_INC_MT(VIP_NO);
      
      EXCEPTION
        WHEN OTHERS THEN
          ERR_MSG := 'PROC: CREATEMT204DOC; ERROR: cannot authorize document, vip_no: ' ||
                     VIP_NO || '
      ' || SQLERRM;
          RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
      END;*/
    
      I := I + 1;
    END LOOP;
  
    /*    IF (P72=0) THEN
        T58A := TRIM(SUBSTR(MT204, P58A + 5, PEND - P58A - 6));
      ELSE
          T58A := TRIM(SUBSTR(MT204, P58A + 5, P72 - P58A - 6));
    T72  := TRIM(SUBSTR(MT204, P72 + 4, PEND - P72 - 5)); 
    END IF;
    
    
    CCY            := SUBSTR(T32A, 7, 3);
    AMOUNT         := TO_NUMBER(REPLACE(SUBSTR(T32A, 10), ',', '.'),
                                '999999999999999999.00');
    VALUE_DT       := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
    DEB_ACC_ID     := SUBSTR(T52A, 2, INSTR(T52A, chr(13), 1, 1) - 2);
    CRED_ACC_ID    := SUBSTR(T58A, 2, INSTR(T58A, chr(13), 1, 1) - 2) ;
    IF (CRED_ACC_ID IS NOT NULL) THEN
    CRED_ACC_ID:=CRED_ACC_ID  || CCY;
    END IF;
                SELECT COUNT(*)
            INTO ACC_COUNTER
            FROM ACCOUNTS_MAIN
           WHERE ID = CRED_ACC_ID;
          IF (ACC_COUNTER = 0) THEN
          
            ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
            IF (ACC_FROM_IBAN IS NOT NULL) THEN
              SELECT COUNT(*)
                INTO ACC_COUNTER
                FROM ACCOUNTS_MAIN
               WHERE ID = ACC_FROM_IBAN;
              IF (ACC_COUNTER = 1) THEN
                CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
              END IF;
            END IF;
          
          END IF;
    
    
    
    
    SENDER_SWIFT   := TRIM(SUBSTR(T52A, INSTR(T52A, chr(13), 1, 1) + 1));
    RECEIVER_SWIFT := TRIM(SUBSTR(T58A, INSTR(T58A, chr(13), 1, 1) + 1));
    rel_ref:=T21;
    SELECT MIN(NEWNUM)
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT;
    SELECT MIN(NEWNUM)
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT;
    THIRD_PERS_TAX := SUBSTR(T72,
                             INSTR(T72, '/TIN', 1, 1) + 5,
                             INSTR(T72, '/TPN', 1, 1) -
                             INSTR(T72, '/TIN', 1, 1) - 5);
    THIRD_PERS_NM  := SUBSTR(T72,
                             INSTR(T72, '/TPN', 1, 1) + 5,
                             INSTR(T72, '/PON', 1, 1) -
                             INSTR(T72, '/TPN', 1, 1) - 5);
                             BEGIN
    INS_RES        := INSERTDOC(DEB_ACC_ID,
                                CRED_ACC_ID,
                                '',
                                '',
                                SENDER_MFO,
                                RECEIVER_MFO,
                                '',
                                '',
                                VB_CURRENCIES_S.GET_NUMERIC_CCY(CCY),
                                AMOUNT,
                                VALUE_DT,
                                'MT202',
                                '',
                                '',
                                rel_ref,
                                THIRD_PERS_TAX,
                                THIRD_PERS_NM,
                                '',
                                '');
                                EXCEPTION
                                  WHEN OTHERS THEN
     err_msg:='PROC: CREATEMT202DOC; ERROR: cannot insert document'||'
     '||SQLERRM;
     raise_application_error(-20000,err_msg);
                                END;*/
  
  EXCEPTION
        WHEN dubl_exc THEN
      ERR_MSG := 'MT_204 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32B, 10), ',', '.')||' '||T30||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
      
        ERR_MSG := 'PROC: CREATEMT204DOC; ERROR: cannot insert document';
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
  END;

  PROCEDURE CREATEMT205DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS
    P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
    P58A NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  
    T20            VARCHAR2(200);
    T21            VARCHAR2(200);
    T32A           VARCHAR2(200);
    T52A           VARCHAR2(200);
    T58A           VARCHAR2(200);
    T72            VARCHAR2(1200);
    MT205          VARCHAR2(32767);
    ERR_MSG        VARCHAR2(1500);
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    CCY            VARCHAR2(50);
    AMOUNT         NUMBER;
    VALUE_DT       DATE;
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
    THIRD_PERS_TAX VARCHAR2(50);
    THIRD_PERS_NM  VARCHAR2(500);
    INS_RES        NUMBER;
    REL_REF        VARCHAR2(500);
    ACC_COUNTER    NUMBER;
    ACC_FROM_IBAN  VARCHAR2(50);
    VIP_NO         NUMBER;
    START_POS      NUMBER;
  
    END_POS NUMBER;
    AM_CHAR VARCHAR2(50);
    DOC_ID  VARCHAR2(50);
    PURP    VARCHAR2(500);
    i NUMBER;
    chars_count NUMBER;
    
        dublicate NUMBER;
    dubl_exc EXCEPTION;
  BEGIN
    MT205 := P_MSG;
    MT205 := REPLACE(MT205, CHR(10) || CHR(13), CHR(13));
    MT205 := REPLACE(MT205, CHR(13) || CHR(10), CHR(13));
    P20   := INSTR(MT205, ':20:');
    P21   := INSTR(MT205, ':21:');
    P32A  := INSTR(MT205, ':32A:');
    P52A  := INSTR(MT205, ':52A:');
    P58A  := INSTR(MT205, ':58A:');
    P72   := INSTR(MT205, ':72:');
    PEND  := INSTR(MT205, '-}');
  
    T20  := TRIM(SUBSTR(MT205, P20 + 4, P21 - P20 - 5));
    T21  := TRIM(SUBSTR(MT205, P21 + 4, P32A - P21 - 5));
    T32A := TRIM(SUBSTR(MT205, P32A + 5, P52A - P32A - 6));
  
    T52A := TRIM(SUBSTR(MT205, P52A + 5, P58A - P52A - 6));
    IF (P72 = 0) THEN
      T58A := TRIM(SUBSTR(MT205, P58A + 5, PEND - P58A - 6));
    ELSE
      T58A := TRIM(SUBSTR(MT205, P58A + 5, P72 - P58A - 6));
      T72  := TRIM(SUBSTR(MT205, P72 + 4, PEND - P72 - 5));
    END IF;
  
    CCY        := SUBSTR(T32A, 7, 3);
    CCY        := REPLACE(CCY, CHR(13), '');
    AM_CHAR    := REPLACE(SUBSTR(T32A, 10), ',', '.');
    AMOUNT     := TO_NUMBER(AM_CHAR, '999999999999999999.00');
    VALUE_DT   := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
    DEB_ACC_ID := SUBSTR(T52A, 2, INSTR(T52A, CHR(13), 1, 1) - 2);
  
    CRED_ACC_ID := SUBSTR(T58A, 2, INSTR(T58A, CHR(13), 1, 1) - 2);
    CRED_ACC_ID := REPLACE(CRED_ACC_ID, CHR(13), '');
  
    /* SELECT COUNT(*)
      INTO ACC_COUNTER
      FROM ACCOUNTS_MAIN
     WHERE ID = CRED_ACC_ID;
    IF (ACC_COUNTER = 0) THEN
    
      ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
      IF (ACC_FROM_IBAN IS NOT NULL) THEN
        SELECT COUNT(*)
          INTO ACC_COUNTER
          FROM ACCOUNTS_MAIN
         WHERE ID = ACC_FROM_IBAN;
        IF (ACC_COUNTER = 1) THEN
          CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
        END IF;
      END IF;
    
    END IF;*/
  
    SENDER_SWIFT   := TRIM(SUBSTR(T52A, INSTR(T52A, CHR(13), 1, 1) + 1));
    SENDER_SWIFT   := REPLACE(SENDER_SWIFT, CHR(13), '');
    RECEIVER_SWIFT := TRIM(SUBSTR(T58A, INSTR(T58A, CHR(13), 1, 1) + 1));
    RECEIVER_SWIFT := REPLACE(RECEIVER_SWIFT, CHR(13), '');
    REL_REF        := T21;
    REL_REF        := REPLACE(REL_REF, CHR(13), '');
    SELECT NEWNUM
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT
       AND IS_HEAD = 1;
    SELECT NEWNUM
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT
       AND IS_HEAD = 1;
  
  
  
              dublicate :=is_dublicate_msg(T20,REPLACE(SUBSTR(T32A, 10), ',', '.'),SUBSTR(T32A, 1, 6),SENDER_SWIFT,'MT205');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
  
    /*START_POS := INSTR(T72, '/PON', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      DOC_ID := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    END IF;*/
  DOC_ID:=  rtgs.get_struct_field_value(T72,'PON');
    
   /* START_POS := INSTR(T72, '/TPN', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      THIRD_PERS_TAX := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    END IF;*/
      THIRD_PERS_TAX:=  rtgs.get_struct_field_value(T72,'TIN');
    
   /* START_POS := INSTR(T72, '/TIN', 1, 1);
    END_POS   := INSTR(T72, '/', START_POS + 5, 1);
    IF (END_POS = 0 AND START_POS != 0) THEN
      END_POS := LENGTH(T72) + 1;
    END IF;
    IF (START_POS != 0) THEN
      THIRD_PERS_NM := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
    
    END IF;*/
    
          THIRD_PERS_NM:= rtgs.get_struct_field_value(T72,'TPN');
          
          
          PURP:=  rtgs.get_struct_field_value(T72,'');
  
   /* START_POS := INSTR(T72, '//', 1, 1);
    END_POS   := PEND;
  
    IF (START_POS != 0) THEN
      PURP := SUBSTR(T72, START_POS + 2, END_POS - START_POS - 2);
    END IF;*/
    
  

    
    /* START_POS := INSTR(T72, '/ADI',1,1);
    END_POS   := PEND;
  
    IF (START_POS != 0) THEN
      PURP := SUBSTR(T72, START_POS + 5, END_POS - START_POS - 5);
      PURP:= REPLACE(PURP,'/ADI/','');
    END IF;*/
--PURP:=  rtgs.get_struct_field_value(T72,'ADI');

    IF (SENDER_SWIFT = 'DISNGE22' AND DEB_ACC_ID IS NOT NULL) THEN
      DEB_ACC_ID := SUBSTR(DEB_ACC_ID, 1, 22);
      DEB_ACC_ID := DEB_ACC_ID || CCY;
    
      SELECT COUNT(*)
        INTO ACC_COUNTER
        FROM ACCOUNTS_MAIN
       WHERE ID = DEB_ACC_ID;
      IF (ACC_COUNTER = 0) THEN
      
        ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(DEB_ACC_ID);
        IF (ACC_FROM_IBAN IS NOT NULL) THEN
          SELECT COUNT(*)
            INTO ACC_COUNTER
            FROM ACCOUNTS_MAIN
           WHERE ID = ACC_FROM_IBAN;
          IF (ACC_COUNTER = 1) THEN
            DEB_ACC_ID := IBAN.GET_ACC_FROM_IBAN(DEB_ACC_ID);
          END IF;
        END IF;
      
      END IF;
    ELSE
      IF (CRED_ACC_ID IS NOT NULL) THEN
        CRED_ACC_ID := CRED_ACC_ID || CCY;
        CRED_ACC_ID := SUBSTR(CRED_ACC_ID, 1, 22);
        SELECT COUNT(*)
          INTO ACC_COUNTER
          FROM ACCOUNTS_MAIN
         WHERE ID = CRED_ACC_ID;
        IF (ACC_COUNTER = 0) THEN
        
          ACC_FROM_IBAN := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
          IF (ACC_FROM_IBAN IS NOT NULL) THEN
            SELECT COUNT(*)
              INTO ACC_COUNTER
              FROM ACCOUNTS_MAIN
             WHERE ID = ACC_FROM_IBAN;
            IF (ACC_COUNTER = 1) THEN
              CRED_ACC_ID := IBAN.GET_ACC_FROM_IBAN(CRED_ACC_ID);
            END IF;
          END IF;
        
        END IF;
      END IF;
    END IF;
  
    IF (RECEIVER_SWIFT = 'DISNGE22' AND DEB_ACC_ID IS NULL) THEN
      DEB_ACC_ID := '10520000GEL';
      --CRED_ACC_ID:='25030003GEL';
    END IF;
    IF (SENDER_SWIFT = 'DISNGE22' AND CRED_ACC_ID IS NULL) THEN
      CRED_ACC_ID := '10520000GEL';
      --DEB_ACC_ID:='25030003GEL';
    END IF;
  
    VIP_NO := RTGS.INSERT_RKC_HEADER('MT_205');
    IF (VIP_NO = 0) THEN
      ERR_MSG := 'Procedure: CREATEMT205DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END IF;
    
        IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
     
     
    RTGS.INSERT_RKC_ENTRY(VIP_NO,
                          DOC_ID,
                          SENDER_MFO,
                          DEB_ACC_ID,
                          '',
                          '',
                          AMOUNT,
                          RECEIVER_MFO,
                          CRED_ACC_ID,
                          '',
                          '',
                          VALUE_DT,
                          REL_REF,
                          nvl(PURP,'გარიგების თანახმად'),
                          VALUE_DT,
                          VALUE_DT);
    COMMIT;
  
   /* BEGIN
      AUTH_INC_MT(VIP_NO);
    
    EXCEPTION
      WHEN OTHERS THEN
        ERR_MSG := 'PROC: CREATEMT205DOC; ERROR: cannot authorize document, vip_no: ' ||
                   VIP_NO || '
      ' || SQLERRM;
        RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END;*/
  
  EXCEPTION
  WHEN dubl_exc THEN
      ERR_MSG := 'MT_205 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32A, 10), ',', '.')||' '||SUBSTR(T32A, 1, 6)||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
        ERR_MSG := 'PROC: CREATEMT205DOC; ERROR: cannot insert document' ||
                   SQLERRM;
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    
  END;

  
    PROCEDURE CREATEMT900DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS

  P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
 P25 NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  
    T20            VARCHAR2(200);
    T21            VARCHAR2(200);
    T32A           VARCHAR2(200);
    T52A           VARCHAR2(200);
   T58A VARCHAR2(200);
  T25 VARCHAR2(200);
    T72            VARCHAR2(200);
    MT900          VARCHAR2(32767);
    ERR_MSG        VARCHAR2(1500);
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    CCY            VARCHAR2(50);
    AMOUNT         NUMBER;
    AM_CHAR  VARCHAR2(50);
    VALUE_DT       DATE;
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
   
    INS_RES        NUMBER;
    REL_REF        VARCHAR2(500);
   
    VIP_NO         NUMBER;
    START_POS      NUMBER;
        TTC        VARCHAR2(50);
  
    END_POS NUMBER;
    
   
        payment_dt DATE;
    signed DATE;
    payment_purp VARCHAR2(500);
    
      dublicate NUMBER;
    dubl_exc EXCEPTION;
    ttc_exc EXCEPTION;
  BEGIN
    MT900 := P_MSG;
    MT900 := REPLACE(MT900, CHR(10) || CHR(13), CHR(13));
    MT900 := REPLACE(MT900, CHR(13) || CHR(10), CHR(13));
    P20   := INSTR(MT900, ':20:');
    P21   := INSTR(MT900, ':21:');
    P25   := INSTR(MT900, ':25:');
    P32A  := INSTR(MT900, ':32A:');
    P52A  := INSTR(MT900, ':52A:');
    P72   := INSTR(MT900, ':72:');
    PEND  := INSTR(MT900, '-}');
  
    T20  := TRIM(SUBSTR(MT900, P20 + 4, P21 - P20 - 5));
    T21  := TRIM(SUBSTR(MT900, P21 + 4, P25 - P21 - 5));
     T25  := TRIM(SUBSTR(MT900, P25 + 4, P32A - P25 - 5));
    T32A := TRIM(SUBSTR(MT900, P32A + 5, P52A - P32A - 6));
  
    T52A := TRIM(SUBSTR(MT900, P52A + 5, P72 - P52A - 6));
   
     
      T72  := TRIM(SUBSTR(MT900, P72 + 4, PEND - P72 - 5));
   
  
  TTC:= rtgs.get_struct_field_value(T72,'TTC');
  
  IF (TTC IN ('0024','0103','0202','0205','1103','2202','3001','3002','3003','3004','8008','9008')) THEN
    RAISE ttc_exc;
  
  END IF;

  
    CCY         := SUBSTR(T32A, 7, 3);
    CCY         := REPLACE(CCY, CHR(13), '');
    AM_CHAR     := REPLACE(SUBSTR(T32A, 10), ',', '.');
    AMOUNT      := TO_NUMBER(AM_CHAR, '999999999999999999.00');
    VALUE_DT    := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
   
  SENDER_SWIFT:=rtgs.get_struct_field_value(T72,'DBP');
    RECEIVER_SWIFT:=rtgs.get_struct_field_value(T72,'CRP');
   

    IF (SENDER_SWIFT = 'DISNGE22') THEN
      CRED_ACC_ID:='25010002GEL';
      DEB_ACC_ID:='10520000GEL';
      ELSE
        CRED_ACC_ID:='10520000GEL';
      DEB_ACC_ID:='25010002GEL';
    END IF;
   
 SELECT NEWNUM
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT
       AND IS_HEAD = 1;
    SELECT NEWNUM
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT
       AND IS_HEAD = 1;


    REL_REF        := T21;
    REL_REF        := REPLACE(REL_REF, CHR(13), '');
    
    
  
  
      dublicate :=is_dublicate_msg(T20,REPLACE(SUBSTR(T32A, 10), ',', '.'),SUBSTR(T32A, 1, 6),SENDER_SWIFT,'MT900');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
  
 

    
    

    

    
   

    
  
    
            signed := trunc(SYSDATE);
    
    
        
            payment_dt := trunc(SYSDATE);
            
            
    
      
      payment_purp:=  T72;
            

    
    VIP_NO := RTGS.INSERT_RKC_HEADER('MT_900');
    IF (VIP_NO = 0) THEN
      ERR_MSG := 'Procedure: CREATEMT900DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END IF;
        IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
    RTGS.INSERT_RKC_ENTRY(VIP_NO,
                          '111',
                          SENDER_MFO,
                          DEB_ACC_ID,
                          '',
                          '',
                          AMOUNT,
                          RECEIVER_MFO,
                          CRED_ACC_ID,
                          '',
                          '',
                          VALUE_DT,
                          REL_REF,
                          payment_purp,
                          payment_dt,
                          signed);
    COMMIT;
  
 
  
  EXCEPTION
    WHEN dubl_exc THEN
      ERR_MSG := 'MT_900 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32A, 10), ',', '.')||' '||SUBSTR(T32A, 1, 6)||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN ttc_exc THEN
      ERR_MSG := 'TTC CODE '|| TTC ||' is not allowed in MT_900: '||T20||' MSG_ID:'||p_msg_id;
        RAISE_APPLICATION_ERROR(-20002, ERR_MSG);   
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
        ERR_MSG := 'PROC: CREATEMT900DOC; ERROR: cannot insert document' ||
                   SQLERRM;
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
  END;

  
    PROCEDURE CREATEMT910DOC(P_MSG VARCHAR2, p_msg_id VARCHAR2) AS

  P20  NUMBER;
    P21  NUMBER;
    P32A NUMBER;
    P52A NUMBER;
 P25 NUMBER;
    P72  NUMBER;
    PEND NUMBER;
  
    T20            VARCHAR2(200);
    T21            VARCHAR2(200);
    T32A           VARCHAR2(200);
    T52A           VARCHAR2(200);
   T58A VARCHAR2(200);
  T25 VARCHAR2(200);
    T72            VARCHAR2(200);
    MT910          VARCHAR2(32767);
    ERR_MSG        VARCHAR2(1500);
    DEB_ACC_ID     VARCHAR2(100);
    CRED_ACC_ID    VARCHAR2(100);
    CCY            VARCHAR2(50);
    AMOUNT         NUMBER;
    AM_CHAR  VARCHAR2(50);
    VALUE_DT       DATE;
    SENDER_SWIFT   VARCHAR2(50);
    RECEIVER_SWIFT VARCHAR2(50);
    SENDER_MFO     VARCHAR2(50);
    RECEIVER_MFO   VARCHAR2(50);
   
    INS_RES        NUMBER;
    REL_REF        VARCHAR2(500);
   
    VIP_NO         NUMBER;
    START_POS      NUMBER;
        TTC        VARCHAR2(50);
  
    END_POS NUMBER;
    
   
        payment_dt DATE;
    signed DATE;
    payment_purp VARCHAR2(500);
    
      dublicate NUMBER;
    dubl_exc EXCEPTION;
    ttc_exc EXCEPTION;
  BEGIN
    MT910 := P_MSG;
    MT910 := REPLACE(MT910, CHR(10) || CHR(13), CHR(13));
    MT910 := REPLACE(MT910, CHR(13) || CHR(10), CHR(13));
    P20   := INSTR(MT910, ':20:');
    P21   := INSTR(MT910, ':21:');
    P25   := INSTR(MT910, ':25:');
    P32A  := INSTR(MT910, ':32A:');
    P52A  := INSTR(MT910, ':52A:');
    P72   := INSTR(MT910, ':72:');
    PEND  := INSTR(MT910, '-}');
  
    T20  := TRIM(SUBSTR(MT910, P20 + 4, P21 - P20 - 5));
    T21  := TRIM(SUBSTR(MT910, P21 + 4, P25 - P21 - 5));
     T25  := TRIM(SUBSTR(MT910, P25 + 4, P32A - P25 - 5));
    T32A := TRIM(SUBSTR(MT910, P32A + 5, P52A - P32A - 6));
  
    T52A := TRIM(SUBSTR(MT910, P52A + 5, P72 - P52A - 6));
   
     
      T72  := TRIM(SUBSTR(MT910, P72 + 4, PEND - P72 - 5));
   
  
  TTC:= rtgs.get_struct_field_value(T72,'TTC');
  
  IF (TTC IN ('0024','0103','0202','0205','1103','2202','3001','3002','3003','3004','8008','9008')) THEN
    RAISE ttc_exc;
  
  END IF;

  
    CCY         := SUBSTR(T32A, 7, 3);
    CCY         := REPLACE(CCY, CHR(13), '');
    AM_CHAR     := REPLACE(SUBSTR(T32A, 10), ',', '.');
    AMOUNT      := TO_NUMBER(AM_CHAR, '999999999999999999.00');
    VALUE_DT    := TO_DATE(SUBSTR(T32A, 1, 6), 'YYMMDD');
   
  SENDER_SWIFT:=rtgs.get_struct_field_value(T72,'DBP');

    RECEIVER_SWIFT:=rtgs.get_struct_field_value(T72,'CRP');
    IF (RECEIVER_SWIFT IS NULL) THEN
        RECEIVER_SWIFT:='DISNGE22';
    END IF;
   
--RECEIVER_SWIFT:='DISNGE22';
    IF (SENDER_SWIFT = 'DISNGE22') THEN
      CRED_ACC_ID:='25010002GEL';
      DEB_ACC_ID:='10520000GEL';
      ELSE
        CRED_ACC_ID:='10520000GEL';
      DEB_ACC_ID:='25010002GEL';
    END IF;
   
 SELECT NEWNUM
      INTO SENDER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = SENDER_SWIFT
       AND IS_HEAD = 1;
    SELECT NEWNUM
      INTO RECEIVER_MFO
      FROM BNKSEEK K
     WHERE SWIFT_CODE = RECEIVER_SWIFT
       AND IS_HEAD = 1;


    REL_REF        := T21;
    REL_REF        := REPLACE(REL_REF, CHR(13), '');
    
    
  
  
      dublicate :=is_dublicate_msg(T20,REPLACE(SUBSTR(T32A, 10), ',', '.'),SUBSTR(T32A, 1, 6),SENDER_SWIFT,'MT910');
    IF (dublicate=1) THEN
      RAISE dubl_exc;
    END IF;
  
 

    
    

    

    
   

    
  
    
            signed := trunc(SYSDATE);
    
    
        
            payment_dt := trunc(SYSDATE);
            
            
    
      
      payment_purp:=  T72;
            

    
    VIP_NO := RTGS.INSERT_RKC_HEADER('MT_910');
    IF (VIP_NO = 0) THEN
      ERR_MSG := 'Procedure: CREATEMT910DOC;
         ERROR TEXT: Cannot insert entry in table RKC_VIP_H';
      SEND_MAIL('rtgs@bta.ge', 'error_log@bta.ge', 'RTGS_ERROR', ERR_MSG);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
    END IF;
        IF (p_msg_id!=0 AND VIP_NO>0)THEN
     UPDATE rtgs_received SET refer=to_char(VIP_NO) WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
    RTGS.INSERT_RKC_ENTRY(VIP_NO,
                          '777',
                          SENDER_MFO,
                          DEB_ACC_ID,
                          '',
                          '',
                          AMOUNT,
                          RECEIVER_MFO,
                          CRED_ACC_ID,
                          '',
                          '',
                          VALUE_DT,
                          REL_REF,
                          payment_purp,
                          payment_dt,
                          signed);
    COMMIT;
  
 
  
  EXCEPTION
    WHEN dubl_exc THEN
      ERR_MSG := 'MT_910 is DUBLICATED: '||T20||' '||REPLACE(SUBSTR(T32A, 10), ',', '.')||' '||SUBSTR(T32A, 1, 6)||' '||SENDER_SWIFT;
        RAISE_APPLICATION_ERROR(-20001, ERR_MSG);
    WHEN ttc_exc THEN
      ERR_MSG := 'TTC CODE '|| TTC ||' is not allowed in MT_910: '||T20||' MSG_ID:'||p_msg_id;
        RAISE_APPLICATION_ERROR(-20002, ERR_MSG);   
    WHEN OTHERS THEN
      IF (ERR_MSG IS NULL) THEN
        ERR_MSG := 'PROC: CREATEMT910DOC; ERROR: cannot insert document' ||
                   SQLERRM;
      END IF;
      RAISE_APPLICATION_ERROR(-20000, ERR_MSG);
  END;

  
  
  
  PROCEDURE PROCEEDMT198(P_MSG CLOB, p_msg_id VARCHAR2) AS
    T20       VARCHAR2(100);
    T12       VARCHAR2(100);
    T77E      VARCHAR2(100);
    T21       VARCHAR2(100);
    T11S      VARCHAR2(100);
    ERROR_TXT CLOB;
    STATUS    VARCHAR2(50);
    DOC_ID    NUMBER;
    MT198     CLOB;
    
    reference VARCHAR2(100);
    actual_reference VARCHAR2(100);
    found_slesh NUMBER;
    num_after_slash VARCHAR2(100);
  BEGIN

    MT198 := REPLACE(MT198, CHR(10) || CHR(13), CHR(13));
    MT198 := REPLACE(MT198, CHR(13) || CHR(10), CHR(13));
    BTA_MT.PARSEMT198(P_MSG, T20, T12, T77E, T21, T11S, ERROR_TXT);
/*  
    SELECT NO
      INTO DOC_ID
      FROM DOCUMENTS_ID_CODE
     WHERE ID_CODE = 'MT_ID'
       AND TO_NUMBER(ID_VALUE) = TO_NUMBER(T21);*/
         
    SELECT NO
      INTO DOC_ID
      FROM DOCUMENTS_ID_CODE
     WHERE ID_CODE = 'MT_ID'
       AND ID_VALUE = T21;
       
       
       IF (p_msg_id!=0)THEN
     UPDATE rtgs_received SET refer=DOC_ID WHERE msg_id=p_msg_id;
     COMMIT;
     END IF;
    --IF (ERROR_TXT IS NULL) THEN
    IF(T12 = '550') THEN
      STATUS := 'ACCP';
      BEGIN
        RTGS.FIN_DOC(DOC_ID);
      EXCEPTION
        WHEN OTHERS THEN
          ERROR_TXT := 'Cannot Finalize doc_no: ' || DOC_ID || ' ERROR: ' ||
                       SQLERRM;
          WRITEMTLOG(DOC_ID, TO_NUMBER(T20), 'ACCP/AUTH ERR', ERROR_TXT);
          COMMIT;
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT AUTH ERROR',
                    ERROR_TXT);
      END;
    
    --ELSE
    ELSIF(T12 = '557') THEN
      STATUS := 'RJCT';
      BEGIN
        RTGS.S00_TO_E01(DOC_ID); --to E01
        RTGS.S00_TO_E01(DOC_ID);--to E00
        
        -- aq moxdes shemdegi referensis gamotvla da id codebshi damaxsovreba       
         SELECT id_value INTO actual_reference FROM  DOCUMENTS_ID_CODE
         WHERE NO = DOC_ID AND ID_CODE = 'MT_ID';

         found_slesh:=INSTR(actual_reference,'/',1,1);
         
         IF (found_slesh=0) THEN
           reference:=actual_reference||'/1';           
         ELSE
           num_after_slash:=substr(actual_reference,found_slesh+1);
           reference:=to_char(DOC_ID)||'/'||to_char(num_after_slash+1);
         end if;
         CREATE_REFERENCE(DOC_ID, reference);
        
      EXCEPTION
        WHEN OTHERS THEN
          ERROR_TXT := 'Cannot unauthorize doc_no: ' || DOC_ID ||
                       ' ERROR: ' || SQLERRM;
          WRITEMTLOG(DOC_ID, TO_NUMBER(T20), 'RJCT/AUTH ERR', ERROR_TXT);
          COMMIT;
          SEND_MAIL('RTGS@bta.ge',
                    'error_log@bta.ge',
                    'MT AUTH ERROR',
                    ERROR_TXT);
      END;
      -- doc rcheba E01-ze
      SEND_MAIL('RTGS@bta.ge',
                'error_log@bta.ge',
                'MT ANSWER BAD',
                'ERROR RECEIVED ON DOC_NO:' || TO_CHAR(DOC_ID) || '
        ' || ERROR_TXT);
    END IF;
    WRITEMTLOG(DOC_ID, TO_NUMBER(T20), STATUS, ERROR_TXT);
    COMMIT;
  END;

  PROCEDURE WRITEMTLOG(P_DOC_ID NUMBER,
                       P_REF_ID NUMBER,
                       P_STATUS VARCHAR2,
                       P_ERROR  CLOB) AS
  BEGIN
    INSERT INTO RTGS_MT_SEND_LOG
    VALUES
      (P_DOC_ID, SYSDATE, P_STATUS, P_ERROR, P_REF_ID);
  END;

  PROCEDURE CREATE_REFERENCE(P_DOC_NO NUMBER, P_REF_ID VARCHAR2) AS
    COUNTER NUMBER;
  BEGIN
  
    SELECT COUNT(*)
      INTO COUNTER
      FROM DOCUMENTS_ID_CODE
     WHERE NO = P_DOC_NO
       AND ID_CODE = 'MT_ID';
  
    IF (COUNTER = 0) THEN
      INSERT INTO DOCUMENTS_ID_CODE
      VALUES
        ('SRB',
         P_DOC_NO,
         'MT_ID',
         P_REF_ID,
         SYSDATE,
         USER,
         NULL,
         NULL,
         NULL);
    ELSE
      UPDATE DOCUMENTS_ID_CODE
         SET ID_VALUE = P_REF_ID
       WHERE NO = P_DOC_NO
         AND ID_CODE = 'MT_ID';
    END IF;
  
    COMMIT;
  END;

  PROCEDURE AUTH_INC_MT(P_VIP_NO NUMBER) AS
    CURSOR VIPS IS
      SELECT * FROM RKC_VIP_E WHERE VIP_NO = P_VIP_NO;
    V_LIST        VARCHAR2(4000);
    V_INC_CORR_ID VARCHAR2(100);
    V_NO_RKC      VARCHAR2(100);
    V_NO_CORR     VARCHAR2(100);
    CS_ACC_ID     VARCHAR2(100);
    UND_C         VARCHAR2(100);
    UND_D         VARCHAR2(100);
    V_OBJECT_KEY  NUMBER;
    V_SCNNAME     VARCHAR2(32);
    N             NUMBER;
    V_SCHEMA      VARCHAR2(100);
    MT_TYPE       VARCHAR2(100);
    OP_TYPE       VARCHAR2(100);
    V_DOC_NO      NUMBER;
  BEGIN
    FOR A IN VIPS LOOP
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'PARENT_MDL', 'DT');
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'ID', A.NO_DOC);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'DOC_TYPE', A.C_OP);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Debit_Acc_Id', A.ID);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'MFO_Rem', A.COD_BN_PR);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rem_Acc_No', A.PAYER_COR_ID);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST,
                                   'Rem_Tax_Number',
                                   A.PAY_TAX_NUMBER);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rem_Rsn_Code', A.PAY_RSN_CODE);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Remittant_Name', A.PAYER_NAME);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Credit_Acc_Id', A.ID_CLN);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'MFO_Rec', A.RECIPIENT_MFO);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rec_Acc_No', A.RECIPIENT_COR_ID);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST,
                                   'Rec_Tax_Number',
                                   A.REC_TAX_NUMBER);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rec_Rsn_Code', A.REC_RSN_CODE);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST,
                                   'Receipient_Name',
                                   A.RECIPIENT_NAME);
    
      V_LIST := SM_SCT_S.DATA2LIST_D(V_LIST, 'Value_Date', A.CREATED);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'REPLIED_TYPE', A.REPLIED_TYPE);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Remarks', NVL(A.REMARKS, ''));
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST,
                                   'Payment_Purpose',
                                   A.PAYMENT_PURPOSE);
    
      V_LIST := SM_SCT_S.DATA2LIST_D(V_LIST, 'Payment_Date', A.TERM_PAYMENT);
    
      V_LIST := SM_SCT_S.DATA2LIST_D(V_LIST, 'Signed', A.DOC_ENTERING_DATE);
      V_LIST := SM_SCT_S.DATA2LIST_N(V_LIST, 'Amount_Cur_1', A.S_DB_CR);
      V_LIST := SM_SCT_S.DATA2LIST_N(V_LIST, 'Amount_rub_1', A.S_DB_CR);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Currency_No_1', '981');
    
      SELECT RKC_OUR INTO V_INC_CORR_ID FROM RKC_COUNT WHERE RKC_CORR = 1;
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'INC_CORR_ID', V_INC_CORR_ID);
    
      SELECT NO_RKC, NO_CORR, REMARKS
        INTO V_NO_RKC, V_NO_CORR, MT_TYPE
        FROM RKC_VIP_H
       WHERE VIP_NO = P_VIP_NO;
    
      SELECT RKC_OUR, RKC_UND_C, RKC_UND_D
        INTO CS_ACC_ID, UND_C, UND_D
        FROM RKC_COUNT
       WHERE BRANCH = 'SRB'
         AND RKC_NO = V_NO_RKC
         AND RKC_CORR = V_NO_CORR;
    
      /* IF (mt_type='MT_103') THEN
      op_type:='БНР_103';
      ELSIF (mt_type='MT_202') THEN
       op_type:='БНР_202';
        ELSIF (mt_type='MT_204') THEN
       op_type:='БНР';
       ELSIF (mt_type='MT_205') THEN
       op_type:='БНР';
       ELSE
          op_type:='БНР';
        END IF;*/
    
      /*  v_List := SM_SCT_S.Data2List  (v_List, 'Class_op'        , op_type);*/
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'BIC_Rkc', V_NO_RKC);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Corr_Rkc_Id', V_NO_CORR);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Corr_Bank_Id', CS_ACC_ID);
    
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Cod_Db_Cr', A.COD_DB_CR);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rkc_Und_C', UND_C);
      V_LIST := SM_SCT_S.DATA2LIST(V_LIST, 'Rkc_Und_D', UND_D);
    
      IF (A.RECIPIENT_MFO = '220101827') THEN
        V_SCHEMA := 'РКЦ_НК';
      ELSE
        V_SCHEMA := 'РКЦ_ДП';
      END IF;
    
      BEGIN
        V_OBJECT_KEY := SM_SCT_U.EXECUTE_OPERATION(V_SCHEMA,
                                                   V_LIST,
                                                   NULL,
                                                   NULL);
      
        COMMIT;
      
        SELECT D.NO
          INTO V_DOC_NO
          FROM SM_SCT_DOCUMENT D, SM_SCT_ACTION A
         WHERE D.PARENT IS NULL
           AND D.BRANCH = 'SRB'
           AND D.INTERNAL_KEY = V_OBJECT_KEY
           AND A.PROD = V_SCHEMA
           AND A.INTERNAL_KEY = D.ACTION
           AND D.SOURCE = A.SOURCE;
      
        UPDATE RKC_VIP_E E
           SET E.TRANS_NO = V_DOC_NO
         WHERE E.VIP_NO = P_VIP_NO;
        COMMIT;
      
        SM_SCT_MSG.CREATE_MESSAGE(V_OBJECT_KEY, 'DT');
        COMMIT;
        --
        -- Выполнить действие('ФУД');
        N := SM_SCT_U.EXECUTE_OPERATION(V_SCHEMA, NULL, V_OBJECT_KEY, NULL);
      
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          IF V_DOC_NO IS NOT NULL AND N IS NULL THEN
            SM_SCT_DCM.DELETE_DCM_TOTAL('SRB', V_DOC_NO, NULL);
            COMMIT;
            UPDATE RKC_VIP_E E
               SET E.TRANS_NO = NULL
             WHERE E.VIP_NO = P_VIP_NO;
            COMMIT;
          END IF;
          V_DOC_NO := NULL;
          RAISE_APPLICATION_ERROR(-20000, SQLERRM);
        
      END;
    
      UPDATE RKC_VIP_E E
         SET E.OWN_TRANS = '*', E.CLASS_OP = V_SCHEMA
       WHERE E.VIP_NO = P_VIP_NO;
      COMMIT;
    END LOOP;
  END;


  FUNCTION tokenize_string(p_text VARCHAR2, p_line_len NUMBER, p_max_line NUMBER, p_new_line_char VARCHAR2 DEFAULT '') RETURN VARCHAR2 AS
  
 RES VARCHAR2(1000);
 init_pos NUMBER;
 token VARCHAR(1000);
 line_num NUMBER;
    BEGIN
      
    RES:='';
  init_pos:=1;
  line_num:=1;
    WHILE (init_pos<=length(p_text) AND line_num<=p_max_line)
  LOOP
token:=  substr(p_text,init_pos,p_line_len);
    IF (init_pos=1) THEN
      RES:=RES||ltrim(repl_char(token,1,':',' '));
    ELSE
      
      RES:=RES||CHR(13) || CHR(10)|| p_new_line_char || ltrim(repl_char(token,1,':',' '));
    END IF;

  init_pos:=init_pos+p_line_len;
  line_num:=line_num+1;
  END LOOP;
  RETURN RES;
      END;

  FUNCTION check_receiver(p_acc VARCHAR2, p_tax VARCHAR2) RETURN NUMBER AS
    cust_no  NUMBER;
    tax VARCHAR2(50);
    BEGIN
      
    BEGIN
    SELECT customer_no  INTO cust_no  FROM accounts_main WHERE id=p_acc AND closed IS NULL;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 0;
    END;
    
    BEGIN
    SELECT tax_number INTO tax FROM customers WHERE no=cust_no;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 0;
    END;
    
    IF (nvl(p_tax,'NA')!=tax) THEN
      RETURN 0;
      END IF;
    
        
  
    
    
    
      RETURN 1;
      END;
      
      
          FUNCTION repl_char(p_text VARCHAR2, p_index NUMBER, p_old_char VARCHAR2,p_new_char VARCHAR2)RETURN VARCHAR2 AS
            ch VARCHAR2(20);
            res VARCHAR2(2000);
          BEGIN
          
          IF (p_index>length(p_text)) THEN
            RETURN p_text;
          END IF;
          
            ch:=SUBSTR(p_text,p_index,1);
          
          IF (ch=p_old_char) THEN
            res:=substr(p_text,1,p_index-1)||p_new_char||substr(p_text,p_index+1);
            RETURN res;
          END IF;
          
            RETURN p_text;
          
          
            END ;
            
            
            
            
          FUNCTION is_iban(p_acc VARCHAR2) RETURN NUMBER AS
            Is_our_acc NUMBER;
              BEGIN
                  
              IF (length(p_acc)!=22) THEN
                RETURN 0;
              END IF;
              
              IF (SUBSTR(p_acc,1,2) != 'GE') THEN
                    RETURN 0;
              END IF;
              
              SELECT COUNT(*) INTO Is_our_acc FROM accounts_main WHERE id=p_acc||'GEL' AND closed IS NULL;
              
              IF (Is_our_acc=0) THEN
                
              RETURN 0;
              
              END IF;
              
              RETURN 1;
              
              END;
              
              
              
        FUNCTION is_dublicate_msg(p_refer VARCHAR2, p_amount VARCHAR2, p_value_date VARCHAR2, p_sending_bank VARCHAR2,p_msg_type VARCHAR2) RETURN NUMBER AS
          counter NUMBER;
            BEGIN
                SELECT COUNT(*) INTO counter FROM rtgs_rec_dubl_log r 
                WHERE r.refer=p_refer AND r.amount=p_amount AND r.val_date=p_value_date AND r.sending_bank=p_sending_bank AND r.msg_type=p_msg_type;
                
                IF (counter>0) THEN
                  RETURN 1;
                
                ELSE
                  INSERT INTO rtgs_rec_dubl_log r VALUES(p_refer,p_amount,p_value_date,p_sending_bank,p_msg_type);
                  COMMIT;
                RETURN 0;
                END IF;
          
            
            END ;    
      
        
  PROCEDURE notify(p_ip VARCHAR2, p_msg VARCHAR2) AS
       RES VARCHAR2(50);
       PARAMS WEB_SERVICE.PARAMETERS_TABLE;
    BEGIN
    
  
  

   PARAMS(1).PARAM := 'p_ip';
    PARAMS(1).VALUE := p_ip;
     PARAMS(2).PARAM := 'p_msg';
    PARAMS(2).VALUE := p_msg;
  
   RES := WEB_SERVICE.EXECUTE_WEB_SERVICE(HTTP_NETSEND, 'SEND', PARAMS);
  
  
    
    END;

END;
/
