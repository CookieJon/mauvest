CREATE OR REPLACE PACKAGE BODY Pkg_Vip_Report_Sql AS

	PROCEDURE P_REPORT_SQL(
	  a_criterias                IN   	 	 T_CRITERIAS,
	  a_report_id   		   IN     		NUMBER,
	  a_criteria_size		   IN       NUMBER,
  	  a_where_clause     IN  VARCHAR2,
	  a_out_result_list		OUT 	Pkg_Global_Objects_Admin.cur_reference_cursor
	) AS
	/*********************************************************************
	Purpose             : Get report query list

	Author                 : Vijaya Shetty
	Date Created   : November 2004
	Modifications
	Date        Author   Description
 Aug 09      VF       PPP: Added more reports
 Jun 11      LvW      Fix report 3160, 3161
	*********************************************************************/
	a_sql VARCHAR2(10000);
	a_bus_unit   VARCHAR2(1000);
	a_cust_type VARCHAR2(10);
	a_identity_type VARCHAR2(10);
	a_date_recieved_from VARCHAR2(10);
	a_date_recieved_to VARCHAR2(10);
	a_contact_nature VARCHAR2(10);
	a_CRITERIA  t_criteria;
	a_date_approved_from VARCHAR2(10);
	a_date_approved_to VARCHAR2(10);
	a_appl_status_id VARCHAR2(1000);
  a_date_refused_from varchar2(10);
  a_date_refused_to varchar2(10);
  a_use_mgmt_rep_date_range_yn varchar2(10) := 'N';
  a_legal_org_id varchar2(10);
  a_cricos_only_yn varchar2(10) := 'N';
	a_date_from VARCHAR2(10);
	a_date_to VARCHAR2(10);
  v_user_name user_security.dud_username%TYPE;
  a_processing_days_range_id  number  := 0;
  a_processing_days_from      number  := 0;
  a_processing_days_to        number  := 10000;

  n_activity_period_id        number;
  n_stream_group_id           number;
  n_legal_org_id              number;
  n_det_centre_id             varchar2(200);
  n_role_id                   number;
  n_change_type_id            number;
  --dt_to                       date;
  --dt_from                     date;
  n_person_id                 number := 0;

	BEGIN
	   v_user_name := pkg_ivets_web_audit.get_current_username();
	   FOR i IN 1..a_criteria_size LOOP
	   	    IF a_criterias(i) IS NOT NULL THEN
			   a_criteria :=a_criterias(i);
			   IF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_BUSINESS_UNIT)THEN
			   		a_bus_unit:=a_criteria.VALUE;
				ELSIF (a_criteria.NAME = Pkg_Vip_Report_Constants.CN_CUSTOMER_TYPE) THEN
				  	a_cust_type:= a_criteria.VALUE;
				ELSIF (a_criteria.NAME =Pkg_Vip_Report_Constants.CN_DATE_REC_FROM) THEN
				  	a_date_recieved_from:= a_criteria.VALUE;
				ELSIF (a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_REC_TO) THEN
				  	a_date_recieved_to:= a_criteria.VALUE;
	            ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_CONTACT_NATURE) THEN
		  	        a_contact_nature:= a_criteria.VALUE;
                ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_APR_FROM) THEN
		  	        a_date_approved_from:= a_criteria.VALUE;
                ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_APR_TO) THEN
  	                a_date_approved_to:= a_criteria.VALUE;
				ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_STATUS_ID) THEN
  	                a_appl_status_id := a_criteria.VALUE;
				ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_REFUSED_FROM) THEN
				  	a_date_refused_from:= a_criteria.VALUE;
  			ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_REFUSED_TO) THEN
				  	a_date_refused_to:= a_criteria.VALUE;
  			ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_USE_MGMT_REP_DATE_RANGE_YN) THEN
            a_use_mgmt_rep_date_range_yn:= NVL(TRIM(a_criteria.VALUE),'N');
  			ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_LEGAL_ORG_ID) THEN
            a_legal_org_id:= a_criteria.VALUE;
            n_legal_org_id := to_number(a_criteria.VALUE);
  			ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_CRICOS_ONLY_YN) THEN
            a_cricos_only_yn:= NVL(TRIM(a_criteria.VALUE),'N');
				ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_FROM) THEN
				  	a_date_from:= a_criteria.VALUE;
  			ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_DATE_TO) THEN
				  	a_date_to:= a_criteria.VALUE;
        ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_PROCESSING_DAYS) THEN
            a_processing_days_range_id := a_criteria.VALUE;
        ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_ACTIVITY_PERIOD_ID) THEN
            n_activity_period_id := to_number(a_criteria.VALUE);
        ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_STREAM_GROUP_ID) THEN
            n_stream_group_id := to_number(a_criteria.VALUE);
        ELSIF(a_criteria.name = Pkg_Vip_Report_Constants.CN_DET_CENTRE_ID) THEN
            n_det_centre_id := a_criteria.value;
        ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_ROLE_ID) THEN
            n_role_id := to_number(a_criteria.VALUE);
        ELSIF(a_criteria.NAME = Pkg_Vip_Report_Constants.CN_CHANGE_TYPE_ID) THEN
            n_change_type_id := to_number(a_criteria.VALUE);
	   END IF;
			END IF;
	   END LOOP;

	/****************************************************
	This has to be moved to different package for CUSTMGMT
	*****************************************************/
	IF (a_report_id=Pkg_Vip_Report_Constants.CN_COMPLAINT_ABOUT)THEN
	   --complaint about
	   a_sql:='	SELECT   NVL(identity.REF_NAME,''Related identity not specified'')IDENTITY, ref_context1.description context1  , '||
	   ' ref_context2.description context2  ,ref_context3.description context3, report.complaint    FROM  ( SELECT  COUNT(contact.contact_ref_id) complaint  ,'||
	   ' contact.classification_rule_id classification_rule_id, contact.RELATED_IDENTITY_TYPE_ID related_identity_type FROM  CM_CONTACT contact , '||
	   ' CM_CLASSIFICATION_RULE rule,WORK_ALLOCATION wa  WHERE ''cm_contact''=srce_tablename(+) AND contact.contact_ref_id=srce_id(+) AND '||
	   ' contact.classification_rule_id = rule.classification_rule_id '||a_where_clause||
	   '  AND contact.contact_nature_id=2  GROUP BY contact.RELATED_IDENTITY_TYPE_ID,contact.classification_rule_id  ) report , '||
	   ' CM_CLASSIFICATION_RULE rule1 , ref_cm_contact_context ref_context1 , ref_cm_contact_context ref_context2 , '||
	   ' ref_cm_contact_context ref_context3,REF_CM_CONTACT_ABOUT identity  WHERE  report.classification_rule_id = rule1.classification_rule_id  AND '||
	   '  rule1.about_context1_id = ref_context1.contact_context_id  AND   rule1.about_context2_id = ref_context2.contact_context_id(+)  AND '||
	   '  rule1.about_context3_id = ref_context3.contact_context_id(+) AND  report.related_identity_type =identity.CONTACT_ABOUT_ID(+) '||
	   ' ORDER BY  identity,context1, context2, context3';
	ELSIF (a_report_id=Pkg_Vip_Report_Constants.CN_CONTACT_OVERDUE)THEN
	   --contact overdue
       a_sql:='  SELECT  contact.CONTACT_REF_ID, NVL(ref_business_unit.description,''Business Unit not specified'')BUSINESS_UNIT, ref_cm_contact_nature.description CONTACT_NATURE ,'||
	   	'Pkg_Vip_Report_Sql .convert_date_to_string(wa.date_target) DEADLINE_DATE  , ref_status.description status  , contact.description description ,'||
		' NVL(per.FIRSTNAME||'' ''||per.SURNAME, '' '') officer   , Pkg_Vip_Report_Sql .convert_date_to_string(contact.date_received) RECEIVED_DATE ,'||
		' Pkg_Vip_Custmgmt_Report.f_vip_get_customer_info(contact.contact_ref_id) customer  , ref_cm_contact_about.description identity  ,'||
		'ref_context1.description context1  ,ref_context2.description context2  ,ref_context3.description context3 FROM '||
        ' CM_CONTACT contact , ref_business_unit , ref_status , ref_cm_contact_about , ref_cm_contact_nature ,  CM_CLASSIFICATION_RULE rule , '||
		'ref_cm_contact_context ref_context1 , ref_cm_contact_context ref_context2 ,  ref_cm_contact_context ref_context3 , ref_cm_classification,'||
		'WORK_ALLOCATION wa, PERSON per  WHERE   wa.business_unit_id = ref_business_unit.business_unit_id(+) AND '||
		'contact.status_id = ref_status.status_id AND  contact.related_identity_type_id = ref_cm_contact_about.contact_about_id(+) AND '||
		'  contact.classification_rule_id = rule.classification_rule_id  AND   rule.about_context1_id = ref_context1.contact_context_id  AND '||
		'   rule.about_context2_id = ref_context2.contact_context_id(+)  AND   rule.about_context3_id = ref_context3.contact_context_id(+)  AND '||
		'   rule.classification_id = ref_cm_classification.classification_id  AND   contact.contact_nature_id = ref_cm_contact_nature.contact_nature_id  AND '||
       '   contact.contact_ref_id=wa.SRCE_ID(+) AND ''cm_contact''=wa.SRCE_TABLENAME(+)   AND contact.status_id<>Pkg_Vip_Custmgmt_Report.f_vip_get_contact_status(7060) '||
	   ' AND wa.PERSON_ID_OWNER=per.PERSON_ID(+)  and  NVL(wa.date_target,sysdate) <=sysdate  '||a_where_clause ||' ORDER BY  BUSINESS_UNIT, ref_cm_contact_nature.description,DEADLINE_DATE';

	ELSIF (a_report_id=Pkg_Vip_Report_Constants.CN_COMPLAINT_RESOLUTION ) THEN
		  --complaints resolution
		 a_sql:=' SELECT   NVL(identity.REF_NAME,''Related identity not specified'') identity, ref_context1.description context1  , '||
		 ' ref_context2.description context2  , ref_context3.description context3,  report.complaints_lodged "COMPLAINTS_LODGED" , report.complaints_resolved "COMPLAINTS_RESOLVED" , '||
		 ' report.complaints_lodged - report.complaints_resolved  "COMPLAINTS_OUTSTANDING",  report.avg_resolution_time  "AVG_RESOLUTION_TIME"  '||
		 ' FROM	( SELECT  COUNT (contact.contact_ref_id) complaints_lodged ,'||
		 ' contact.classification_rule_id  ,contact.RELATED_IDENTITY_TYPE_ID identity_id ,'||
 		 ' Pkg_Vip_Custmgmt_Report.f_vip_get_complaints_resolved('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''', contact.classification_rule_id,2,contact.RELATED_IDENTITY_TYPE_ID) '||
		 ' complaints_resolved , Pkg_Vip_Custmgmt_Report.f_vip_avg_resolution_time('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''', contact.classification_rule_id,2,0,contact.RELATED_IDENTITY_TYPE_ID) '||
		 ' avg_resolution_time FROM  CM_CONTACT contact , CM_CLASSIFICATION_RULE rule ,WORK_ALLOCATION wa WHERE   contact.contact_nature_id = 2 AND '||
	   ' contact.classification_rule_id = rule.classification_rule_id   AND contact.CONTACT_REF_ID=wa.SRCE_ID(+) AND ''cm_contact''= wa.SRCE_TABLENAME(+)'||
	   a_where_clause||'  GROUP BY contact.classification_rule_id,contact.RELATED_IDENTITY_TYPE_ID  ) report ,  CM_CLASSIFICATION_RULE rule1 ,'||
	   ' ref_cm_contact_context ref_context1 , ref_cm_contact_context ref_context2 ,  ref_cm_contact_context ref_context3,REF_CM_CONTACT_ABOUT identity '||
	   ' WHERE	  report.classification_rule_id = rule1.classification_rule_id	  AND rule1.about_context1_id = ref_context1.contact_context_id  AND '||
	   '  rule1.about_context2_id = ref_context2.contact_context_id(+)  AND	  rule1.about_context3_id = ref_context3.contact_context_id(+) AND '||
	   '  report.identity_id =identity.CONTACT_ABOUT_ID(+)  ORDER BY  identity,context1, context2, context3 ';

	ELSIF (a_report_id=Pkg_Vip_Report_Constants.CN_CONTACT_CHAN_WKLD)THEN
	--Channel Workload
		 a_sql:='SELECT   NVL(per.firstname||'' ''||per.surname,''System'') officer  ,'||
		 ' Pkg_Vip_Custmgmt_Report.f_vip_get_contact_channel('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_contact_nature ||''','''||a_bus_unit ||''',contact.person_id_creator,3) phone   ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_get_contact_channel('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_contact_nature ||''','''||a_bus_unit ||''',contact.person_id_creator,4) email   ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_get_contact_channel('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_contact_nature ||''','''||a_bus_unit ||''',contact.person_id_creator,2) fax   ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_get_contact_channel('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_contact_nature ||''','''||a_bus_unit ||''',contact.person_id_creator,1) post   ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_get_contact_channel('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_contact_nature ||''','''||a_bus_unit ||''',contact.person_id_creator,5) "INPERSON" '||
       ' FROM  CM_CONTACT contact , CM_CLASSIFICATION_RULE rule, WORK_ALLOCATION wa, PERSON per  WHERE contact.classification_rule_id = rule.classification_rule_id '||
	   ' AND contact.CONTACT_REF_ID=wa.SRCE_ID(+) AND ''cm_contact''=wa.SRCE_TABLENAME(+)	AND contact.PERSON_ID_CREATOR =per.person_id(+) '||
	   a_where_clause||' GROUP BY (per.firstname,per.surname, contact.person_id_creator )  ORDER BY officer ';

	ELSIF (a_report_id=Pkg_Vip_Report_Constants.CN_COMPLAINT_ASSIGN)THEN
	--Complaint Assignment
		a_sql:=' SELECT NVL(per.FIRSTNAME||'' ''||per.SURNAME, ''Not Assigned '' ) officer, Pkg_Vip_Report_Sql .convert_date_to_string(contact.date_received) "DATE_RECEIVED" , Pkg_Vip_Report_Sql .convert_date_to_string(wa.DATE_TARGET) "DEADLINE_DATE" ,'||
		' Pkg_Vip_Report_Sql .convert_date_to_string(wa.date_completed) "RESOLVED_DATE" ,Pkg_Vip_Report_Sql .convert_num_to_string(NVL(wa.date_completed,SYSDATE) - contact.date_received) "DAYS_OPEN" ,'||
		' ref_status.description status ,ref_nature.description "CONTACT_NATURE",ref_context1.description context1  FROM  CM_CONTACT contact,'||
		'WORK_ALLOCATION wa, ref_status ,PERSON per , ref_cm_contact_context ref_context1,CM_CLASSIFICATION_RULE rule, ref_cm_classification ref_class,'||
		'ref_cm_contact_nature ref_nature  WHERE contact.status_id = ref_status.status_id  AND  contact.CONTACT_REF_ID=wa.SRCE_ID(+)'||
		'  AND  ''cm_contact''= wa.SRCE_TABLENAME(+)  AND  wa.PERSON_ID_OWNER = per.PERSON_ID(+)  AND  contact.classification_rule_id = rule.classification_rule_id '||
  		'  AND  rule.CLASSIFICATION_ID=ref_class.CLASSIFICATION_ID  AND  contact.CONTACT_NATURE_ID =ref_nature.CONTACT_NATURE_ID '||
		'  AND  ref_nature.CONTACT_NATURE_ID = 2  AND  rule.about_context1_id = ref_context1.contact_context_id(+) '||a_where_clause||
		'  ORDER BY   officer,date_received,date_completed ';

	ELSIF (a_report_id=Pkg_Vip_Report_Constants.CN_CONTACT_WORKFLOW)THEN
	--Contact Workflow
	   a_sql:='	SELECT NVL(identity.REF_NAME,''Related identity not specified'') identity, ref_context1.description context1  , ref_context2.description context2  , ref_context3.description context3,ref_status.description status,'||
	   ' report.contact_referred "CONTACT_LOGGED" , report.contact_assign_internal "CONTACT_ASSIGNED_INTERNAL", report.contact_assign_external "CONTACT_ASSIGNED_EXTERNAL" ,report.avg_resolution_time "AVG_RESOLUTION_TIME"   FROM (SELECT   contact.classification_rule_id  ,contact.status_id, '||
	   'Pkg_Vip_Custmgmt_Report.f_vip_contact_logged('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''', contact.classification_rule_id,'''||a_contact_nature ||''',contact.status_id,contact.RELATED_IDENTITY_TYPE_ID) contact_referred ,'||
 	   'Pkg_Vip_Custmgmt_Report.f_vip_contact_assigned_report('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''', contact.classification_rule_id, 1,'''||a_contact_nature ||''',contact.status_id,contact.RELATED_IDENTITY_TYPE_ID) contact_assign_internal ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_contact_assigned_report('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''',contact.classification_rule_id, 2,'''||a_contact_nature ||''',contact.status_id,contact.RELATED_IDENTITY_TYPE_ID) contact_assign_external ,'||
	   ' Pkg_Vip_Custmgmt_Report.f_vip_avg_res_time_report('''||a_date_recieved_from ||''','''||a_date_recieved_to ||''','''||a_cust_type ||''','''||a_bus_unit ||''', contact.classification_rule_id,'''||a_contact_nature ||''',contact.status_id,contact.RELATED_IDENTITY_TYPE_ID) avg_resolution_time ,'||
	   '  contact.RELATED_IDENTITY_TYPE_ID related_identity_type  FROM	CM_CONTACT contact , CM_CLASSIFICATION_RULE rule ,'||
	   ' ref_cm_classification ref_rule, WORK_ALLOCATION wa ,ref_status  WHERE  	contact.classification_rule_id = rule.classification_rule_id '||
	   ' AND rule.classification_rule_id =ref_rule.classification_id(+)	AND contact.CONTACT_REF_ID=wa.SRCE_ID(+) AND ''cm_contact''= wa.SRCE_TABLENAME(+) '||
       ' AND contact.status_id = ref_status.status_id '|| a_where_clause||'GROUP BY 	contact.RELATED_IDENTITY_TYPE_ID,contact.classification_rule_id,contact.status_id ) report ,'||
	   ' CM_CLASSIFICATION_RULE rule1 ,   ref_cm_contact_context ref_context1 , ref_cm_contact_context ref_context2 ,ref_cm_contact_context ref_context3,'||
	   ' REF_CM_CONTACT_ABOUT identity,ref_status WHERE	report.classification_rule_id =rule1.classification_rule_id AND '||
	   ' report.status_id=ref_status.status_id AND	rule1.about_context1_id = ref_context1.contact_context_id  AND '||
	   'rule1.about_context2_id = ref_context2.contact_context_id(+)  AND	rule1.about_context3_id = ref_context3.contact_context_id(+) AND '||
       'report.related_identity_type =identity.CONTACT_ABOUT_ID(+)	ORDER BY  identity, context1, context2, context3 ';

	  ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_CONTACT_HISTORY)THEN
	  --Contact History
	  a_sql:='SELECT * FROM(SELECT DESCRIPTION, Pkg_Vip_Report_Sql .convert_date_to_string(DATE_HISTORY)DATE_HISTORY,(PERSON.FIRSTNAME||'' ''|| PERSON.SURNAME) ChangedBy FROM '||
	  'CM_CONTACT_HISTORY ,PERSON WHERE  person_id_creator =person_ID  '||a_where_clause||
	  'UNION SELECT DESCRIPTION, Pkg_Vip_Report_Sql .convert_date_to_string(DATE_HISTORY)DATE_HISTORY,(PERSON.FIRSTNAME||'' ''|| PERSON.SURNAME) ChangedBy FROM WORK_ALLOCATION_HISTORY WA,PERSON '||
	  ' WHERE WA.PERSON_ID =PERSON.person_ID AND WA.SRCE_TABLENAME=''cm_contact'' '||a_where_clause||
	  ' UNION SELECT (''Assigned from ''|| NVL(assc1.firstname,''None'')||'' ''|| NVL(assc1.surname,'''') ||'' TO ''||NVL(assc2.firstname,'' None '')||'' ''||NVL(assc2.surname,'''') )DESCRIPTION,'||
	  'Pkg_Vip_Report_Sql .convert_date_to_string(DATE_HISTORY)DATE_HISTORY, (PERSON.FIRSTNAME||'' ''|| PERSON.SURNAME) ChangedBy FROM PERSON, CM_HISTORY_NOTE NOTE ,PERSON assc1,'||
	  'PERSON assc2 WHERE person_id_creator =PERSON.person_ID  AND NOTE.ASSOC_ID1=assc1.person_id(+) AND NOTE.ASSOC_ID2=assc2.person_id(+) AND '||
	  '  history_type_id = 4  '||a_where_clause||
	  ' UNION SELECT (''Status Changed from ''|| assc1.description||'' to ''||assc2.description)DESCRIPTION,Pkg_Vip_Report_Sql .convert_date_to_string(DATE_HISTORY)DATE_HISTORY, (PERSON.FIRSTNAME||'' ''|| PERSON.SURNAME) ChangedBy '||
	  ' FROM PERSON, CM_HISTORY_NOTE NOTE ,ref_status assc1,ref_status assc2 WHERE person_id_creator =PERSON.person_ID'||
	  '  AND NOTE.ASSOC_ID1=assc1.STATUS_ID(+) AND NOTE.ASSOC_ID2=assc2.STATUS_ID(+) AND  history_type_id = 3 '||a_where_clause||
	  ')ORDER BY 2 DESC ';
	/****************************************************
	This has to be moved to different package for RTOMGMT
	*****************************************************/
	  ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_RTO_REG)THEN
	  --RTO Registered
	  a_sql:='SELECT DISTINCT   LEGAL_ORG.LEGAL_ORG_NAME,LEGAL_ORG.LEGAL_ORG_ID,ADDRESS.ADDR_ST_LINE1, ADDRESS.ADDR_ST_LINE2,'||
         'ADDRESS.ADDR_ST_LINE3,ADDRESS.ADDR_ST_LINE4,ADDRESS.AM_PCODE_ID, ADDRESS.STATE,  ADDRESS.AM_SUBURB_NAME,  '||
         'ADDRESS.PHONE_AH,  ADDRESS.PHONE_BUS,  ADDRESS.FAX,    ADDRESS.EMAIL, '||
		 'Pkg_Vip_Report_Sql .convert_date_to_string(TO_APPLICATION.EXPIRY_DATE)EXPIRY_DATE,Pkg_Vip_Report_Sql .convert_date_to_string(TO_APPLICATION.DATE_APPROVED)DATE_APPROVED'||
         ' FROM    TO_APPLICATION,      LEGAL_ORG,         RTO,         ORGANISATION,         ADDRESS,			ADDRESS_ROLE '||
		 '  WHERE ( LEGAL_ORG.LEGAL_ORG_ID = RTO.LEGAL_ORG_ID ) AND        ( RTO.PRIMARY_ORG_ID = ORGANISATION.ORG_ID ) AND '||
        ' ( ORGANISATION.ORG_ID = ADDRESS.ORG_ID ) AND        ( TO_APPLICATION.LEGAL_ORG_ID = LEGAL_ORG.LEGAL_ORG_ID ) AND '||
        ' ( ADDRESS.ADDR_ID = ADDRESS_ROLE.ADDR_ID ) AND         ( ADDRESS_ROLE.ADDR_TYPE_ID = 1 ) AND '||
        ' ( TO_APPLICATION.APPL_VOL_ID = 0 ) AND       ( TO_APPLICATION.APPL_CATEG_ID = 100 ) AND '||
		' ( TO_APPLICATION.STATUS_ID = 5045 OR TO_APPLICATION.STATUS_ID = 5050 ) AND '||
        '  ( TO_APPLICATION.DATE_APPROVED IS NOT NULL )'	||a_where_clause ||
		 'ORDER BY LEGAL_ORG.LEGAL_ORG_NAME';

	   ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_RTO_REG_EXPIRING)THEN
	   --Expiring RTOs
	   	a_sql:=' SELECT DISTINCT	ORGANISATION.ORG_NAME,	LEGAL_ORG.LEGAL_ORG_NAME,	LEGAL_ORG.LEGAL_ORG_ID,REF_SALUTATION_TYPE.DESCRIPTION SALUTATION,'||
		' PERSON.SURNAME,	PERSON.FIRSTNAME,	ADDRESS.ADDR_ST_LINE1,	ADDRESS.ADDR_ST_LINE2,	ADDRESS.ADDR_ST_LINE3,'||
		' ADDRESS.ADDR_ST_LINE4,	ADDRESS.AM_SUBURB_NAME,	ADDRESS.STATE,	ADDRESS.AM_PCODE_ID,	Pkg_Vip_Report_Sql .convert_date_to_string(RTO.EXPIRY_DATE)EXPIRY_DATE'||
		'  FROM 	RTO,	ORGANISATION,	LEGAL_ORG,	ADDRESS_ROLE,	ADDRESS,	PERSON_ROLE,	PERSON,'||
		' REF_SALUTATION_TYPE WHERE RTO.LEGAL_ORG_ID = LEGAL_ORG.LEGAL_ORG_ID AND RTO.PRIMARY_ORG_ID = ORGANISATION.ORG_ID'||
		' AND RTO.STATE_OF_ORIGIN_ID = 1 AND RTO.PRIMARY_ORG_ID = ADDRESS.ORG_ID AND ADDRESS.ADDR_ID = ADDRESS_ROLE.ADDR_ID'||
		' AND ADDRESS_ROLE.ADDR_TYPE_ID = 2 AND RTO.PRIMARY_ORG_ID = PERSON_ROLE.ORG_ID AND PERSON_ROLE.FUNCTION_ID = 5 '||
		' AND PERSON_ROLE.CONTACT_ID = PERSON.PERSON_ID AND PERSON.SALUTATION_ID = REF_SALUTATION_TYPE.SALUTATION_ID '||
		a_where_clause ||' ORDER BY EXPIRY_DATE';

     /* 19/11/2007 PT: CR588 This query is not used. The query is embedded within the jasper report.
		 ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_BY_RECEIVED_DT) THEN
		 -- RTOVETAB monthly statistics by Approved date
					  Pkg_Vip_General_Reports.p_vip_rto_app_by_status_dt_rpt(TO_DATE(a_date_recieved_from,'DD/MM/YYYY'),TO_DATE(a_date_recieved_to,'DD/MM/YYYY'),a_out_result_list);
     */
		 ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_UNDER_PROCESSING) THEN
		 -- VETAB Management Report, Report of (Under processing)Application
					  Pkg_Vip_General_Reports.p_vip_mgmt_under_processing(TO_DATE(a_date_recieved_from,'DD/MM/YYYY'),TO_DATE(a_date_recieved_to,'DD/MM/YYYY'),a_out_result_list);
		 ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_REGISTERED) THEN
		 --Report 3127
		 -- VETAB Management Report, Report of Registered Application
					  Pkg_Vip_General_Reports.p_vip_mgmt_appl_registered(TO_DATE(a_date_approved_from,'DD/MM/YYYY'),TO_DATE(a_date_approved_to,'DD/MM/YYYY'),a_out_result_list);
		 ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_AS_OF_TODAY) THEN
		 -- VETAB Management Report, Report of (Under processing)Application
					  Pkg_Vip_General_Reports.p_vip_mgmt_under_processing(NULL,TO_DATE(TO_CHAR(SYSDATE,'DD/MM/YYYY'),'DD/MM/YYYY'),a_out_result_list);
		 ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_YEARLY_REGISTERED) THEN
		 -- VETAB Management Report, Report of (Under processing)Application
					  Pkg_Vip_General_Reports.p_vip_mgmt_appl_yealy_regsd(TO_DATE('01/01/2003','DD/MM/YYYY'),TO_DATE(TO_CHAR(SYSDATE,'DD/MM/YYYY'),'DD/MM/YYYY'),a_out_result_list);

		-- Report of Applications and scope
		ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_SCOPE_BY_STATUS) then
		                Pkg_Vip_General_Reports.p_vip_rto_app_scope_status_rpt(TO_DATE(a_date_recieved_from,'DD/MM/YYYY'),TO_DATE(a_date_recieved_to,'DD/MM/YYYY'), a_appl_status_id, a_out_result_list);

   --ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_RTOVETAB_ORG_BY_APPROVAL_DT)THEN
		 -- RTOVETAB monthly statistics by Approved date , Moved to RTOMgmt package
	  --pkg_vip_general_reports.p_vip_vetab_approvaldt_rpt(to_date(a_date_approved_from,'DD/MM/YYYY'),to_date(a_date_approved_to,'DD/MM/YYYY'),a_out_result_list);

  -- RRM reports (criteria handled in there)
  ELSIF a_report_id in (PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_SUMMARY,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_PYMT_SUMM,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_PYMT_DETAIL,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_REJ_SUMM,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_REJ_BY_STATUS,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LODGE_REJ_BY_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_RTO_FEE_EXEMPT_SUMM,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_RTO_EQUITY_SUMM,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_INDUSTRY_SUMM,
                        PKG_VIP_REPORT_CONSTANTS.CN_RRM_LEARNER_UPDATE_LOG) THEN
    PKG_VIP_RRM_REPORT_SQL.P_REPORT_SQL(a_criterias, a_report_id, a_criteria_size, a_where_clause, a_out_result_list);



  -- Tender reports (criteria handled in there)


  ELSIF a_report_id in (PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_SUMM_AQF_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_SUMM_AQF,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_SUMM_PKG_AQF,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_DET_AQF_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_DET_RTO_QUAL,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_DET_QUAL_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CAP_SUMM_AQF_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CAP_SUMM_RTO_AQF,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CAP_DET_RTO_AQF,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CAP_DET_AQF_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CAP_SITE_DETAIL,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CP_ACT_PY_SUM_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CP_ACT_PY_SUM_PKG,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CP_ACT_PY_DTL_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_CP_ACT_PY_DTL_QUAL,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_CP_PY_SUM_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_CP_PY_SUM_PKG,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_CP_PY_DTL_RTO,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_ACT_CP_PY_DTL_QUAL,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_TP_REV_ACT_MIS,
                        PKG_VIP_REPORT_CONSTANTS.CN_TNDR_RTO_SCOPE,
						PKG_VIP_REPORT_CONSTANTS.CN_TNDR_RTO_PERMISSIONS,
						PKG_VIP_REPORT_CONSTANTS.CN_TNDR_RTO_STATUS
                        ) THEN
    PKG_VIP_TENDER_RPT_SQL.P_REPORT_SQL(a_criterias, a_report_id, a_criteria_size, a_where_clause, a_out_result_list);


		-- 3150 RTO Details - Expiring Registered Training Organisations (excluding Reciprocals)
		-- Handed by Pkg_Vip_rtomgmt_Report_sql package because report 3150 is the same report as 3103 but 3150 is in the manamgement reports menu and 3103 is in the operational reports menu. They use the same SQL.
		ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_RTO_REG_EXPIRING) then
		                Pkg_Vip_rtomgmt_Report_sql.P_REPORT_SQL(a_criterias, a_report_id, a_criteria_size, a_where_clause, a_out_result_list);

    ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_REFUSED) then

      -- REPORT 3151 Refused Applications

      -- Determine dates to use, depending on whether using management report dates, or user entered dates
      select
        case
          when a_use_mgmt_rep_date_range_yn = 'Y' then
            to_char(trunc(add_months(to_date(p1.parameter_value, 'dd/mm/yyyy'), - (to_number(p2.parameter_value))), 'MONTH'),'dd/mm/yyyy')
          else
            a_date_refused_from
        end from_date,
        case
          when a_use_mgmt_rep_date_range_yn = 'Y' then
            to_char(to_date(p1.parameter_value, 'dd/mm/yyyy') - 1,'dd/mm/yyyy')
          else
            a_date_refused_to
          end to_date
        into a_date_refused_from, a_date_refused_to
        from
        ref_ivets_parameter p1,
        ref_ivets_parameter p2
        where p1.parameter_id = 107 -- Processing Days Report Date
        and p2.parameter_id = 108; -- Processing Days Report interval in months

      if (a_date_refused_from is null) then
        select to_char(min(date_status_changed), 'dd/mm/yyyy')
          into a_date_refused_from
          from to_application
          where status_id = pkg_global_objects_recog.cn_refused; /* pkg_global_objects_recog.cn_refused = 5065 */
      end if;

      if (a_date_refused_to is null) then
        select to_char(sysdate, 'dd/mm/yyyy') into a_date_refused_to from dual;
      end if;

      open a_out_result_list for
        select
          to_char(legal_org.legal_org_id) legal_org_id,
          legal_org.legal_org_name,
          to_char(to_application.appl_year) appl_year,
          to_char(to_application.appl_seq_id) appl_seq_id,
          to_char(to_application.appl_vol_id) appl_vol_id,
          ref_appl_type.description appl_type,
          appl_status.description application_status,
          legal_org.ntis_id legal_org_ntis_id,
          to_char(to_application.date_received, 'dd/mm/yyyy') date_application_received,
          to_char(to_application.date_status_changed, 'dd/mm/yyyy') date_status_changed,
          to_char(to_application.auditor_person_id) auditor_person_id,
          to_char(to_application.ext_auditor_person_id) ext_auditor_person_id,
          nvl2(person.person_id, person.firstname, person_external.firstname) firstname,
          nvl2(person.person_id, person.surname, person_external.surname) surname,
          to_application_scope.scope_type_ind,
          training_object.ntis_id c_or_q_ntis_id,
          training_object.name,
          unit_of_competency.ntis_id uoc_ntis_id,
          unit_of_competency.competency_name,
          scope_status.description scope_status,
          to_char(to_application_scope.date_status_changed, 'dd/mm/yyyy') date_scope_status_changed,
          to_char(to_date(a_date_refused_from, 'dd/mm/yyyy'), 'fmdd Month yyyy') || ' - ' || to_char(to_date(a_date_refused_to, 'dd/mm/yyyy'), 'fmdd Month yyyy') report_date_range,
          (select to_char(count(*)) from to_application where
						/* filters */
						to_application.status_id = pkg_global_objects_recog.cn_refused /* pkg_global_objects_recog.cn_refused = 5065 */
						/* user criteria */
            and (a_date_refused_from is null or to_application.date_status_changed >= to_date(a_date_refused_from, 'dd/mm/yyyy'))
	          and (a_date_refused_to is null or to_application.date_status_changed <= to_date(a_date_refused_to, 'dd/mm/yyyy')+1)
            ) count_refused_applications
          from
          legal_org,
          to_application,
          to_application_scope,
          training_object,
          unit_of_competency,
          ref_status appl_status,
          ref_status scope_status,
          ref_appl_type,
          person,
          person person_external
          where
          /* joins */
          legal_org.legal_org_id = to_application.legal_org_id
          and to_application.to_appl_id = to_application_scope.to_appl_id
          and to_application_scope.training_object_id = training_object.training_object_id (+)
          and to_application_scope.unit_of_competency_id = unit_of_competency.unit_of_competency_id (+)
          and to_application.status_id = appl_status.status_id
          and to_application_scope.status_id = scope_status.status_id
          and to_application.auditor_person_id = person.person_id (+)
          and to_application.ext_auditor_person_id = person_external.person_id (+)
          and to_application.appl_type_id = ref_appl_type.appl_type_id
          /* filters */
          and to_application.status_id = pkg_global_objects_recog.cn_refused /* pkg_global_objects_recog.cn_refused = 5065 */
          /* user criteria */
          and (a_date_refused_from is null or to_application.date_status_changed >= to_date(a_date_refused_from, 'dd/mm/yyyy'))
          and (a_date_refused_to is null or to_application.date_status_changed <= to_date(a_date_refused_to, 'dd/mm/yyyy')+1)
          /* ordering */
          order by
          legal_org.legal_org_name,
          to_application.appl_year,
          to_application.appl_seq_id,
          to_application.appl_vol_id,
          training_object.name,
          unit_of_competency.competency_name;

  ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_HIGH_RISK_UPDATES) then

      -- REPORT 3154 RTO Details High Risk Updates History

      if (a_date_to is null and a_date_from is null and a_legal_org_id is null and a_cricos_only_yn = 'N') then
        -- No criteria entered, so must be running the VIP_J2EE_SCHEDULER which is the email for cricos high risk.
        a_date_to := to_char(sysdate-1, 'dd/mm/yyyy');
        a_date_from := to_char(sysdate-1, 'dd/mm/yyyy');
        a_cricos_only_yn := 'Y';
      end if;

      -- Default date parameters.
      if (a_date_to is null) then
        a_date_to := to_char(sysdate, 'dd/mm/yyyy');
      end if;

      -- Default date parameters.
      if (a_date_from is null) then
        a_date_from := to_char(to_date(a_date_to, 'dd/mm/yyyy')-14, 'dd/mm/yyyy');
      end if;

      open a_out_result_list for
				select
					to_char(lo.legal_org_id) legal_org_id,
					lo.legal_org_name,
					lo.NTIS_ID,
					vip_provider.CRICOS_ID,
					to_char(h.date_history, 'dd/mm/yyyy hh24:mi') date_change,
					h.description change,
					h.USER_ID username,
					to_char(to_date(a_date_from, 'dd/mm/yyyy'), 'fmdd Month yyyy') || ' - ' || to_char(to_date(a_date_to, 'dd/mm/yyyy'), 'fmdd Month yyyy') param_report_date_range,
					a_cricos_only_yn param_cricos_only_yn,
					a_legal_org_id param_rto_id
					from history h, organisation o, legal_org lo, rto, vip_provider
					where
					-- joins
					h.srce_id = o.org_id
					and o.legal_org_id = lo.legal_org_id
					and o.org_id = rto.PRIMARY_ORG_ID
          and o.legal_org_id = vip_provider.legal_org_id
					-- filters
					and h.srce_tablename = 'ORGANISATION'
					-- user filters
					and (h.high_risk_cricos_yn = 'Y' or (a_cricos_only_yn = 'N' and h.high_risk_vetab_yn = 'Y'))
					and (a_date_from is null or h.date_history >= to_date(a_date_from, 'dd/mm/yyyy'))
					and (a_date_to is null or h.date_history <= to_date(a_date_to, 'dd/mm/yyyy')+1)
					and (a_legal_org_id is null or lo.legal_org_id = to_number(a_legal_org_id))
					order by lo.legal_org_name, h.date_history;

  ELSIF(a_report_id=Pkg_Vip_Report_Constants.CN_MGMT_APPL_COMPLETE_AWAITING) then

      -- REPORT 3155 RTO Applications in status Complete, Awaiting Auditor
      open a_out_result_list for
				select
					-- new fields
					ref_business_unit.ref_name business_unit,
					ref_appl_type.ref_name application_type,
					to_char(rto.expiry_date, 'dd/mm/yyyy') rto_expiry_date,
					to_char(decode(to_application_scope.scope_type_ind, 'C', scope_qual.expiry_date, null), 'dd/mm/yyyy') course_expiry_date,
					vip_provider.CRICOS_ID ,
					to_application_scope.scope_type_ind,
					-- old fields
					to_char(legal_org.legal_org_id) legal_org_id,
					legal_org.ntis_id rto_ntis_id,
					legal_org.legal_org_name legal_org_name ,
					organisation.org_name org_name,
					to_application.appl_year||'/'||to_application.appl_seq_id||'.'||to_application.appl_vol_id appl_seq,
					to_char(to_application.date_received,'dd/mm/yyyy')  date_received,
					appl_status.description appl_status_desc,
					to_char(to_application.date_status_changed,'dd/mm/yyyy') status_eff_date,
					ref_recog_risk_ranking.description appl_risk_ranking,
					scope_pkg.ntis_id pkg_ntis,
					scope_pkg.name  pkg_name,
					scope_qual.ntis_id qual_ntis,
					scope_qual.name qual_name,
					scope_unit.ntis_id unit_ntis,
					scope_unit.name unit_name,
					scope_status.description scope_status_desc,
					decode(to_application_scope.scope_type_ind, 'U', scope_unit.recog_high_risk_yn, scope_qual.recog_high_risk_yn) recog_high_risk_yn
					from
					legal_org, rto, to_application, organisation,
          vip_provider,
					ref_status appl_status, ref_status scope_status,
					to_application_scope, training_object scope_pkg, training_object scope_qual,
					training_object scope_unit, ref_recog_risk_ranking,
					ref_appl_type, ref_business_unit
					where
					-- joins
					legal_org.legal_org_id = rto.legal_org_id
          and legal_org.legal_org_id = vip_provider.legal_org_id
					and rto.primary_org_id = organisation.org_id
					and rto.legal_org_id = to_application.legal_org_id
					and to_application.to_appl_id = to_application_scope.to_appl_id
					and to_application_scope.training_package_id   = scope_pkg.training_object_id(+)
					and to_application_scope.training_object_id    = scope_qual.training_object_id(+)
					and to_application_scope.unit_of_competency_id = scope_unit.training_object_id(+)
					and to_application.status_id = appl_status.status_id
					and to_application.appl_type_id = ref_appl_type.appl_type_id
					-- filters
					and rto.state_of_origin_id = 1
					and to_application.appl_seq_id > 0
					and to_application_scope.status_id = scope_status.status_id
					and to_application.recog_risk_ranking_id = ref_recog_risk_ranking.recog_risk_ranking_id (+)
					and to_application.status_id = pkg_global_objects_recog.cn_complete_awaiting_auditor -- complete awaiting auditor (5014)
					and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
					-- user filters
					and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
					and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
					and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
					order by
					business_unit,
					application_type,
					legal_org.legal_org_id,
					to_application.appl_year||'/'||to_application.appl_seq_id||'.'||to_application.appl_vol_id,
					scope_pkg.ntis_id,
					scope_qual.ntis_id,
					scope_unit.ntis_id;

  elsif a_report_id=pkg_vip_report_constants.CN_RTO_APPL_PROCESSING_DAYS then

    case
      when a_processing_days_range_id = 1 then
        a_processing_days_from  := 0;
        a_processing_days_to    := 30;
      when a_processing_days_range_id = 2 then
        a_processing_days_from  := 31;
        a_processing_days_to    := 60;
      when a_processing_days_range_id = 3 then
        a_processing_days_from  := 61;
        a_processing_days_to    := 90;
      when a_processing_days_range_id = 4 then
        a_processing_days_from  := 91;
        a_processing_days_to    := 120;
      when a_processing_days_range_id = 5 then
        a_processing_days_from  := 121;
        a_processing_days_to    := 150;
      when a_processing_days_range_id = 6 then
        a_processing_days_from  := 151;
        a_processing_days_to    := 180;
      when a_processing_days_range_id = 7 then
        a_processing_days_from  := 181;
        a_processing_days_to    := 10000;
      else
        a_processing_days_from  := 0;
        a_processing_days_to    := 10000;
    end case;

    open a_out_result_list for
				select legal_org.legal_org_id,
               legal_org.legal_org_name,
               (
                 processing_days_report.appl_year ||'\'||
                 processing_days_report.appl_seq_id ||'.'||
                 processing_days_report.appl_vol_id
               ) registration_id,
               ref_status.ref_name status,
               processing_days_report.cricos_yn,
               processing_days_report.processing_days,
               to_application.owning_business_unit_id,
               ref_business_unit.ref_name business_unit,
               report_date_range.report_start_date,
               report_date_range.report_end_date
        from   legal_org, processing_days_report, to_application, ref_business_unit, ref_status,
               ( /* A rather ugly way to pass two more parameters to the report (SM) */
                 select to_char(
                          trunc(
                            add_months(
                              to_date(last_report_date.parameter_value, 'dd/mm/yyyy'),
                              - (to_number(months_between_reports.parameter_value))
                            ),
                            'MONTH'
                          ),
                          'fmdd Month yyyy'
                        ) report_start_date,
                        to_char(
                          to_date(last_report_date.parameter_value, 'dd/mm/yyyy') - 1,
                          'fmdd Month yyyy'
                        ) report_end_date
                 from   ref_ivets_parameter last_report_date,
                        ref_ivets_parameter months_between_reports
                 where  last_report_date.parameter_id = 107
                 and    months_between_reports.parameter_id = 108
               ) report_date_range
        where  processing_days_report.legal_org_id = legal_org.legal_org_id
        and    processing_days_report.appl_categ_id = 100 -- exclude interstate
        and    processing_days_report.appl_type_id in (1,2,4) -- exclude tp revision
        and    (processing_days_report.task_id is not null and task_id <> 11) -- except cricos entry
        and    processing_days_report.to_appl_id = to_application.to_appl_id
        and    to_application.status_id = ref_status.status_id(+)
        and    to_application.owning_business_unit_id = ref_business_unit.business_unit_id(+)
        and    to_application.owning_business_unit_id = nvl(nullif(to_number(a_bus_unit),0), to_application.owning_business_unit_id)
        and    processing_days_report.processing_days between a_processing_days_from and a_processing_days_to
        order by ref_business_unit.ref_name asc, processing_days_report.processing_days desc;


  elsif a_report_id = pkg_vip_report_constants.CN_MGMT_PROVIDER_APPLICATIONS then

    -- REPORT 3158 Provider Applications with Scope and Processing Days

    if a_appl_status_id = 'ALL_RECEIVED' then

      select f_join_strings(
               cursor(
                 select status_id
                 from   ref_status
                 where  status_id > pkg_global_objects_recog.cn_pending_submission
                 and    status_id < pkg_global_objects_recog.cn_complete_awaiting_auditor
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    elsif a_appl_status_id = 'ALL_UNDER_PROCESSING' then

      select f_join_strings(
             cursor(
               select status_id
               from   ref_status
               where  status_id in (
                        select status_id
                        from   to_application_status_xref
                        where  processing_yn = 'Y'
                      )
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    end if;

    a_appl_status_id := replace(a_appl_status_id, 'ALL_RECEIVED', '0');
    a_appl_status_id := replace(a_appl_status_id, 'ALL_UNDER_PROCESSING', '0');

    open a_out_result_list for
      select
      most_details.*,
      -- Get Organisation
      case
        when most_details.appl_sector_id = 2 then
         (select o.org_name from organisation o, vip_cricos_provider vcp where o.org_id = vcp.primary_org_id and vcp.legal_org_id = most_details.legal_org_id and vcp.sector_id = 2 ) -- schools
        else
          (select o.org_name from organisation o, rto r where o.org_id = r.primary_org_id and r.legal_org_id = most_details.legal_org_id)
        end org_name,
      -- Get Expriy (user RTO expiry for VET sector (either cricos or aqtf, or school expiry)
      case
        when most_details.appl_sector_id = 2 then
         (select to_char(vcp.registration_expiry_date,'dd/mm/yyyy') from vip_cricos_provider vcp where vcp.legal_org_id = most_details.legal_org_id and vcp.sector_id = 2 ) -- schools
        else
          (select to_char(r.expiry_date,'dd/mm/yyyy') from rto r where r.legal_org_id = most_details.legal_org_id)
        end sector_expiry_date,
      -- Get sector description
      (select rvs.description from ref_vetab_sector rvs where rvs.vetab_sector_id = most_details.appl_sector_id) appl_sector_description
      from
      -- Most Details Subquery (most details exception for trading name and sector expiry date
      (
      select
        'AQTF' scope_type,
        ref_business_unit.ref_name  business_unit,
        (
          select f_join_strings(
            cursor(
              select ref_appl_component_type.ref_name ||' (' || to_application_component.component_count ||')'
              from   to_application_component, ref_appl_component_type
              where  to_application_component.to_appl_id = to_application.to_appl_id
              and    to_application_component.component_type_id = ref_appl_component_type.component_type_id
            ), ', '
          ) from dual
        ) components,
        to_char(decode(to_application_scope.scope_type_ind, 'C', scope_qual.expiry_date, null), 'dd/mm/yyyy')  course_expiry_date,
        vip_provider.cricos_id,
        to_application_scope.scope_type_ind     scope_type_ind,
        to_char(legal_org.legal_org_id)         legal_org_id,
        legal_org.ntis_id                       rto_ntis_id,
        legal_org.legal_org_name                legal_org_name ,
        to_application.appl_year||'/'||to_application.appl_seq_id||'.'||to_application.appl_vol_id||pkg_vip_cricos.f_get_application_indicator(to_application.to_appl_id)  appl_seq,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_received,
        appl_status.description                 appl_status_desc,
        to_application_status_xref.sort_order   appl_status_sort_order,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_lodged,
        ref_recog_risk_ranking.description      appl_risk_ranking,
        scope_pkg.ntis_id                       pkg_ntis,
        scope_pkg.name                          pkg_name,
        scope_qual.ntis_id                      qual_ntis,
        scope_qual.name                         qual_name,
        scope_unit.ntis_id                      unit_ntis,
        scope_unit.name                         unit_name,
        scope_status.description                scope_status_desc,
        decode(to_application_scope.scope_type_ind, 'U', scope_unit.recog_high_risk_yn, scope_qual.recog_high_risk_yn)  recog_high_risk_yn,
        nvl(mv_processing_days.processing_days, 0)  processing_days,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name)  bu_appl_count,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name,to_application.status_id)  status_appl_count,
--        count(distinct to_application.to_appl_id) over ()  total_appl_count,
        null site_full_name, -- for delivery sites only
        null capacity_increase_yn, -- for delivery sites only
        to_char(to_application.appl_sector_id) appl_sector_id,
        to_char(to_application.to_appl_id) to_appl_id
      from
        legal_org, rto,  to_application,
        vip_provider,
        ref_status appl_status, ref_status scope_status,
        to_application_status_xref,
        to_application_scope, training_object scope_pkg, training_object scope_qual,
        training_object scope_unit, ref_recog_risk_ranking,
        ref_appl_type, ref_business_unit, mv_processing_days
      where rto.legal_org_id = legal_org.legal_org_id
        and legal_org.tafe_yn = 'N'
        and legal_org.legal_org_id = vip_provider.legal_org_id
        and legal_org.legal_org_id = to_application.legal_org_id
        and to_application.to_appl_id = to_application_scope.to_appl_id
        and to_application_scope.training_package_id   = scope_pkg.training_object_id(+)
        and to_application_scope.training_object_id    = scope_qual.training_object_id(+)
        and to_application_scope.unit_of_competency_id = scope_unit.training_object_id(+)
        and to_application.status_id = appl_status.status_id
        and appl_status.status_id = to_application_status_xref.status_id
        and to_application.appl_type_id = ref_appl_type.appl_type_id
        and rto.state_of_origin_id = 1
        and to_application.appl_seq_id > 0
        and to_application_scope.status_id = scope_status.status_id
        and to_application.recog_risk_ranking_id = ref_recog_risk_ranking.recog_risk_ranking_id (+)
        and (
              (nullif(a_appl_status_id,'0') is null) or
              to_application.status_id in (
                select column_value from table(
                  f_split_strings(a_appl_status_id)
                )
              )
            )
        and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
        and ((a_date_recieved_from is null) or (to_application.date_received >= to_date(a_date_recieved_from, 'dd/mm/yyyy')))
        and ((a_date_recieved_to is null) or (trunc(to_application.date_received)  <= to_date(a_date_recieved_to, 'dd/mm/yyyy')))
        and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
        and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
        and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
        and to_application.to_appl_id = mv_processing_days.to_appl_id(+)
      union all
      select
        'CRICOS' scope_type,
        ref_business_unit.ref_name  business_unit,
        (
          select f_join_strings(
            cursor(
              select ref_appl_component_type.ref_name ||' (' || to_application_component.component_count ||')'
              from   to_application_component, ref_appl_component_type
              where  to_application_component.to_appl_id = to_application.to_appl_id
              and    to_application_component.component_type_id = ref_appl_component_type.component_type_id
            ), ', '
          ) from dual
        ) components,
        to_char(decode(to_appl_cricos_scope.cricos_scope_type_ind, 'C', scope_qual.expiry_date, null), 'dd/mm/yyyy')  course_expiry_date,
        vip_provider.cricos_id,
        to_appl_cricos_scope.cricos_scope_type_ind  scope_type_ind,
        to_char(legal_org.legal_org_id)         legal_org_id,
        legal_org.ntis_id                       rto_ntis_id,
        legal_org.legal_org_name                legal_org_name ,
        to_application.appl_year||'/'||to_application.appl_seq_id||'.'||to_application.appl_vol_id||pkg_vip_cricos.f_get_application_indicator(to_application.to_appl_id)  appl_seq,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_received,
        appl_status.description                 appl_status_desc,
        to_application_status_xref.sort_order   appl_status_sort_order,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_lodged,
        ref_recog_risk_ranking.description      appl_risk_ranking,
        null                                    pkg_ntis,
        null                                    pkg_name,
        nvl(scope_qual.ntis_id, cricos_course.ntis_code) qual_ntis,
        nvl(scope_qual.name, cricos_course.course_name) qual_name,
        null                                    unit_ntis,
        null                                    unit_name,
        scope_status.description                scope_status_desc,
        scope_qual.recog_high_risk_yn           recog_high_risk_yn,
        nvl(mv_processing_days.processing_days, 0)  processing_days,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name)  bu_appl_count,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name,to_application.status_id)  status_appl_count,
--        count(distinct to_application.to_appl_id) over ()  total_appl_count,
        null site_full_name, -- for delivery sites only
        null capacity_increase_yn, -- for delivery sites only
        to_char(to_application.appl_sector_id) appl_sector_id,
        to_char(to_application.to_appl_id) to_appl_id
      from
        legal_org, to_application,
        vip_provider,
        ref_status appl_status, ref_status scope_status,
        to_application_status_xref,
        to_appl_cricos_scope, training_object scope_qual,
        ref_recog_risk_ranking,
        ref_appl_type, ref_business_unit, mv_processing_days,
        cricos_course
      where legal_org.tafe_yn = 'N'
        and legal_org.legal_org_id = vip_provider.legal_org_id
        and legal_org.legal_org_id = to_application.legal_org_id
        and to_application.to_appl_id = to_appl_cricos_scope.to_appl_id
        and to_appl_cricos_scope.training_object_id = scope_qual.training_object_id(+)
        and to_appl_cricos_scope.cricos_course_id = cricos_course.cricos_course_id(+)
        and to_application.status_id = appl_status.status_id
        and appl_status.status_id = to_application_status_xref.status_id
        and to_application.appl_type_id = ref_appl_type.appl_type_id
        and to_application.appl_seq_id > 0
        and to_appl_cricos_scope.status_id = scope_status.status_id
        and to_application.recog_risk_ranking_id = ref_recog_risk_ranking.recog_risk_ranking_id(+)
        and (
              (nullif(a_appl_status_id,'0') is null) or
              to_application.status_id in (
                select column_value from table(
                  f_split_strings(a_appl_status_id)
                )
              )
            )
        and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
        and ((a_date_recieved_from is null) or (to_application.date_received  >= to_date(a_date_recieved_from, 'dd/mm/yyyy')))
        and ((a_date_recieved_to is null) or (trunc(to_application.date_received)  <= to_date(a_date_recieved_to, 'dd/mm/yyyy')))
        and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
        and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
        and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
        and to_application.to_appl_id = mv_processing_days.to_appl_id(+)
        and to_appl_cricos_scope.component_type_id in (4,5,6,7) -- cricos initial, cricos scope renewal, cricos new scope amendment, cricos course update
      union all
      select
        'CRICOS Delivery Site' scope_type,
        ref_business_unit.ref_name  business_unit,
        (
          select f_join_strings(
            cursor(
              select ref_appl_component_type.ref_name ||' (' || to_application_component.component_count ||')'
              from   to_application_component, ref_appl_component_type
              where  to_application_component.to_appl_id = to_application.to_appl_id
              and    to_application_component.component_type_id = ref_appl_component_type.component_type_id
            ), ', '
          ) from dual
        ) components,
        null                                    course_expiry_date,
        vip_provider.cricos_id,
        to_appl_cricos_scope.cricos_scope_type_ind  scope_type_ind,
        to_char(legal_org.legal_org_id)         legal_org_id,
        legal_org.ntis_id                       rto_ntis_id,
        legal_org.legal_org_name                legal_org_name,
        to_application.appl_year||'/'||to_application.appl_seq_id||'.'||to_application.appl_vol_id||pkg_vip_cricos.f_get_application_indicator(to_application.to_appl_id)  appl_seq,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_received,
        appl_status.description                 appl_status_desc,
        to_application_status_xref.sort_order   appl_status_sort_order,
        to_char(to_application.date_received,'dd/mm/yyyy')  date_lodged,
        null                                    appl_risk_ranking,
        null                                    pkg_ntis,
        null                                    pkg_name,
        null                                    qual_ntis,
        null                                    qual_name,
        null                                    unit_ntis,
        null                                    unit_name,
        scope_status.description                scope_status_desc,
        null                                    recog_high_risk_yn,
        nvl(mv_processing_days.processing_days, 0)  processing_days,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name)  bu_appl_count,
--        count(distinct to_application.to_appl_id) over (partition by ref_business_unit.ref_name,to_application.status_id)  status_appl_count,
--        count(distinct to_application.to_appl_id) over ()  total_appl_count,
        decode(
          address.addr_st_line1 || decode(address.addr_st_line2,null,null,' '||address.addr_st_line2),
          null,null,
          address.addr_st_line1||decode(address.addr_st_line2,null,null,' '||address.addr_st_line2) || ', '
        ) || address.am_suburb_name||' '||address.state||' '|| address.am_pcode_id site_full_name,
        to_appl_cricos_scope.student_increase_fee_yn capacity_increase_yn,
        to_char(to_application.appl_sector_id) appl_sector_id,
        to_char(to_application.to_appl_id) to_appl_id
      from
        legal_org,
        to_application,
        vip_provider,
        ref_status appl_status,
        ref_status scope_status,
        to_application_status_xref,
        to_appl_cricos_scope,
        ref_appl_type,
        ref_business_unit,
        mv_processing_days,
        cricos_location, address
      where legal_org.tafe_yn = 'N'
        and legal_org.legal_org_id = vip_provider.legal_org_id
        and legal_org.legal_org_id = to_application.legal_org_id
        and to_application.to_appl_id = to_appl_cricos_scope.to_appl_id
        and to_application.status_id = appl_status.status_id
        and appl_status.status_id = to_application_status_xref.status_id
        and to_application.appl_type_id = ref_appl_type.appl_type_id
        and to_application.appl_seq_id > 0
        and to_appl_cricos_scope.status_id = scope_status.status_id
        and (
              (nullif(a_appl_status_id,'0') is null) or
              to_application.status_id in (
                select column_value from table(
                  f_split_strings(a_appl_status_id)
                )
              )
            )
        and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
        and ((a_date_recieved_from is null) or (to_application.date_received  >= to_date(a_date_recieved_from, 'dd/mm/yyyy')))
        and ((a_date_recieved_to is null) or (trunc(to_application.date_received)  <= to_date(a_date_recieved_to, 'dd/mm/yyyy')))
        and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
        and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
        and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
        and to_application.to_appl_id = mv_processing_days.to_appl_id(+)
        and to_appl_cricos_scope.component_type_id in (8,9,10,11) -- cricos new additional site, cricos site update, cricos capacity change, cricos relocation
        and to_appl_cricos_scope.cricos_site_id = cricos_location.cricos_location_id
        and cricos_location.addr_id = address.addr_id
      ) most_details
      order by
        business_unit,
        appl_status_sort_order,
        legal_org_id,
        appl_seq,
        scope_type,  -- cricos, aqtf, cricos delivery site
        processing_days,
        scope_type_ind; -- qual, course, uoc, site

    -- end of report 3158

  elsif a_report_id = pkg_vip_report_constants.CN_MGMT_PROVIDER_APPS_BY_ORG then

    -- REPORT 3160 Provider Applications Sorted by Provider Legal Name

    if a_appl_status_id = 'ALL_RECEIVED' then

      select f_join_strings(
               cursor(
                 select status_id
                 from   ref_status
                 where  status_id > pkg_global_objects_recog.cn_pending_submission
                 and    status_id < pkg_global_objects_recog.cn_complete_awaiting_auditor
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    elsif a_appl_status_id = 'ALL_UNDER_PROCESSING' then

      select f_join_strings(
             cursor(
               select status_id
               from   ref_status
               where  status_id in (
                        select status_id
                        from   to_application_status_xref
                        where  processing_yn = 'Y'
                      )
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    end if;

    a_appl_status_id := replace(a_appl_status_id, 'ALL_RECEIVED', '0');
    a_appl_status_id := replace(a_appl_status_id, 'ALL_UNDER_PROCESSING', '0');

    open a_out_result_list for
      select
        legal_org.legal_org_name                  legal_org_name,
        to_char(legal_org.legal_org_id)           legal_org_id,
        legal_org.ntis_id                         ntis_id,
        vip_provider.cricos_id                    cricos_id,
        ref_vetab_sector.description              application_sector,
        -- wasn't picking up a date if had no vip_cricos_provider record - Lynda 2nd June 2011 VIp-1919
--        (
--          select case
--                   when vip_cricos_provider.sector_id = 3 /*VET*/ and rto.state_of_origin_id = 1 /*NSW*/ then
--                     to_char(nvl(rto.expiry_date, vip_cricos_provider.registration_expiry_date), 'dd/mm/yyyy')
--                   else
--                     to_char(vip_cricos_provider.registration_expiry_date, 'dd/mm/yyyy')
--                 end
--          from   vip_cricos_provider
--          where  vip_cricos_provider.legal_org_id = to_application.legal_org_id
--          and    vip_cricos_provider.sector_id = to_application.appl_sector_id
--        )                                         sector_expiry_date,
        (
        case when to_application.appl_sector_id = 3 /*VET*/  then
                 to_char(rto.expiry_date, 'dd/mm/yyyy')
             when to_application.appl_sector_id = 2 /*school*/ then
                 (select to_char(vip_cricos_provider.registration_expiry_date, 'dd/mm/yyyy')
                 from  vip_cricos_provider
                 where to_application.legal_org_id   = vip_cricos_provider.legal_org_id
                 and   vip_cricos_provider.sector_id = 2)
             else
                 to_char(rto.expiry_date, 'dd/mm/yyyy')
        end
        )                                        sector_expiry_date,
        (
          to_application.appl_year ||'/'||
          to_application.appl_seq_id ||'.'||
          to_application.appl_vol_id ||
          pkg_vip_cricos.f_get_application_indicator(to_application.to_appl_id)
        )                                         appl_id,
        (
          select f_join_strings(
            cursor(
              select ref_appl_component_type.ref_name ||' (' || to_application_component.component_count ||')'
              from   to_application_component, ref_appl_component_type
              where  to_application_component.to_appl_id = to_application.to_appl_id
              and    to_application_component.component_type_id = ref_appl_component_type.component_type_id
            ), ', '
          ) from dual
        )                                          components,
        to_char(nvl(mv_processing_days.processing_days, 0)) processing_days,
        to_char(to_application.date_received, 'dd/mm/yyyy') evidence_received,
        appl_status.description                    appl_status,
        to_application_status_xref.sort_order      appl_status_sort_order,
        auditor.firstname ||' '|| auditor.surname  auditor_name,
        ref_business_unit.acronym                  business_unit
      from
        to_application,
        legal_org,
        vip_provider,
        ref_vetab_sector,
        mv_processing_days,
        ref_status appl_status,
        to_application_status_xref,
        person auditor,
        ref_business_unit,
        rto
      where to_application.legal_org_id = legal_org.legal_org_id
        and legal_org.tafe_yn = 'N'
        and legal_org.legal_org_id = vip_provider.legal_org_id(+)
        and to_application.appl_sector_id = ref_vetab_sector.vetab_sector_id
        and to_application.appl_sector_id in (2,3) -- School and VET
        and to_application.to_appl_id = mv_processing_days.to_appl_id(+)
        and to_application.status_id = appl_status.status_id
        and appl_status.status_id = to_application_status_xref.status_id
        and auditor.person_id(+) = nvl(to_application.auditor_person_id, to_application.ext_auditor_person_id)
        and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
        and legal_org.legal_org_id = rto.legal_org_id(+)
        and (
              (nullif(a_appl_status_id,'0') is null) or
              to_application.status_id in (
                select column_value from table(
                  f_split_strings(a_appl_status_id)
                )
              )
            )
        and ((a_date_recieved_from is null) or (to_application.date_received  >= to_date(a_date_recieved_from, 'dd/mm/yyyy')))
        and ((a_date_recieved_to is null) or (trunc(to_application.date_received)  <= to_date(a_date_recieved_to, 'dd/mm/yyyy')))
        and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
        and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
        and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
      order by
        legal_org.legal_org_name asc,
        appl_status_sort_order asc,
        nvl(mv_processing_days.processing_days, 0) desc;


  elsif a_report_id = pkg_vip_report_constants.CN_MGMT_PROVIDER_APPS_BY_STAT then

    -- REPORT 3161 Provider Applications Sorted by Status and Processing Days

    if a_appl_status_id = 'ALL_RECEIVED' then

      select f_join_strings(
               cursor(
                 select status_id
                 from   ref_status
                 where  status_id > pkg_global_objects_recog.cn_pending_submission
                 and    status_id < pkg_global_objects_recog.cn_complete_awaiting_auditor
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    elsif a_appl_status_id = 'ALL_UNDER_PROCESSING' then

      select f_join_strings(
             cursor(
               select status_id
               from   ref_status
               where  status_id in (
                        select status_id
                        from   to_application_status_xref
                        where  processing_yn = 'Y'
                      )
               ), ','
             )
      into   a_appl_status_id
      from   dual;

    end if;

    a_appl_status_id := replace(a_appl_status_id, 'ALL_RECEIVED', '0');
    a_appl_status_id := replace(a_appl_status_id, 'ALL_UNDER_PROCESSING', '0');

    open a_out_result_list for
      select
        legal_org.legal_org_name                  legal_org_name,
        to_char(legal_org.legal_org_id)           legal_org_id,
        legal_org.ntis_id                         ntis_id,
        vip_provider.cricos_id                    cricos_id,
        ref_vetab_sector.description              application_sector,
        -- wasn't picking up a date if had no vip_cricos_provider record - Lynda 2nd June 2011 VIp-1919
--        (
--          select case
--                   when vip_cricos_provider.sector_id = 3 /*VET*/ and rto.state_of_origin_id = 1 /*NSW*/ then
--                     to_char(nvl(rto.expiry_date, vip_cricos_provider.registration_expiry_date), 'dd/mm/yyyy')
--                   else
--                     to_char(vip_cricos_provider.registration_expiry_date, 'dd/mm/yyyy')
--                 end
--          from   vip_cricos_provider
--          where  vip_cricos_provider.legal_org_id = to_application.legal_org_id
--          and    vip_cricos_provider.sector_id = to_application.appl_sector_id
--        )                                         sector_expiry_date,
        (
        case when to_application.appl_sector_id = 3 /*VET*/  then
                 to_char(rto.expiry_date, 'dd/mm/yyyy')
             when to_application.appl_sector_id = 2 /*school*/ then
                 (select to_char(vip_cricos_provider.registration_expiry_date, 'dd/mm/yyyy')
                 from  vip_cricos_provider
                 where to_application.legal_org_id   = vip_cricos_provider.legal_org_id
                 and   vip_cricos_provider.sector_id = 2)
             else
                 to_char(rto.expiry_date, 'dd/mm/yyyy')
        end
        )                                        sector_expiry_date,
        (
          to_application.appl_year ||'/'||
          to_application.appl_seq_id ||'.'||
          to_application.appl_vol_id ||
          pkg_vip_cricos.f_get_application_indicator(to_application.to_appl_id)
        )                                         appl_id,
        (
          select f_join_strings(
            cursor(
              select ref_appl_component_type.ref_name ||' (' || to_application_component.component_count ||')'
              from   to_application_component, ref_appl_component_type
              where  to_application_component.to_appl_id = to_application.to_appl_id
              and    to_application_component.component_type_id = ref_appl_component_type.component_type_id
            ), ', '
          ) from dual
        )                                          components,
        to_char(nvl(mv_processing_days.processing_days, 0)) processing_days,
        to_char(to_application.date_received, 'dd/mm/yyyy') evidence_received,
        appl_status.description                    appl_status,
        auditor.firstname ||' '|| auditor.surname  auditor_name,
        ref_business_unit.acronym                  business_unit,
        to_application_status_xref.sort_order      appl_status_sort_order
      from
        to_application,
        legal_org,
        vip_provider,
        ref_vetab_sector,
        mv_processing_days,
        ref_status appl_status,
        person auditor,
        ref_business_unit,
        rto,
        to_application_status_xref
      where to_application.legal_org_id = legal_org.legal_org_id
        and legal_org.tafe_yn = 'N'
        and legal_org.legal_org_id = vip_provider.legal_org_id(+)
        and to_application.appl_sector_id = ref_vetab_sector.vetab_sector_id
        and to_application.appl_sector_id in (2,3) -- School and VET
        and to_application.to_appl_id = mv_processing_days.to_appl_id(+)
        and to_application.status_id = appl_status.status_id
        and appl_status.status_id = to_application_status_xref.status_id
        and auditor.person_id(+) = nvl(to_application.auditor_person_id, to_application.ext_auditor_person_id)
        and to_application.owning_business_unit_id = ref_business_unit.business_unit_id
        and legal_org.legal_org_id = rto.legal_org_id(+)
        and (
              (nullif(a_appl_status_id,'0') is null) or
              to_application.status_id in (
                select column_value from table(
                  f_split_strings(a_appl_status_id)
                )
              )
            )
        and ((a_date_recieved_from is null) or (to_application.date_received  >= to_date(a_date_recieved_from, 'dd/mm/yyyy')))
        and ((a_date_recieved_to is null) or (trunc(to_application.date_received)  <= to_date(a_date_recieved_to, 'dd/mm/yyyy')))
        and ((a_date_from is null) or (to_application.date_status_changed  >= to_date(a_date_from, 'dd/mm/yyyy')))
        and ((a_date_to is null) or (to_application.date_status_changed  <= to_date(a_date_to, 'dd/mm/yyyy')+1))
        and ((nullif(a_bus_unit,'0') is null) or (ref_business_unit.business_unit_id in (select column_value from table(f_split_strings(a_bus_unit)))))
      order by
        to_application_status_xref.sort_order asc,
        nvl(mv_processing_days.processing_days, 0) desc;

  elsif a_report_id = pkg_vip_report_constants.CN_PCM_RTO_FINANTIAL_CAPS then

    open a_out_result_list for
    select
      /*csv*/
      distinct rto_as_cap_id "UNIQUE KEY",
      "LEGAL ORG ID",
      "LEGAL ORG NAME",
      "PROGRAM",
      "REGION",
      "QUALIFICATION",
      "NEW ENROLMENTS NOTIFIED",
      "NEW ENROLMENTS EXP/CANCELLED",
      "NEW ENROLMENTS SUBMITTED",
      "NEW ENROLMENTS FINALISED",
      "NEW ENROLMENTS COMPLETED",
      ltrim(round(("NEW ENROLMENTS COMPLETED" * 100) / nullif("NEW ENROLMENTS FINALISED", 0), 2) || '%', '%') as "NEW ENROLMENTS COMPLETION %",
      to_char("NEW ENROLMENTS CAP", '$999,999,990.99') as "NEW ENROLMENTS CAP",
      to_char("NEW ENROLMENTS ESTIMATE", '$999,999,990.99') as "NEW ENROLMENTS CAP USAGE EST",
      to_char("NEW ENROLMENTS CAPS USED", '$999,999,990.99') as "NEW ENROLMENTS CAP USAGE",
      "ONGOING ENROLMENTS NOTIFIED" ,
      "ONGOING ENROLMENTS SUBMITTED",
      "ONGOING ENROLMENTS FINALISED",
      "ONGOING ENROLMENTS COMPLETED",
      to_char("ONGOING ENROLMENTS CAP", '$999,999,990.99') as "ONGOING ENROLMENTS CAP",
      to_char("ONGOING ENROLMENTS ESTIMATE", '$999,999,990.99') as "ONGOING ENROLMT CAP USAGE EST",
      to_char("ONGOING ENROLMENTS CAP USED", '$999,999,990.99') as "ONGOING ENROLMENTS CAP USAGE",
      to_char((nvl("NEW ENROLMENTS CAP", 0) + nvl("ONGOING ENROLMENTS CAP", 0)), '$999,999,990.99') as "TOTAL CAP",
      to_char((nvl("NEW ENROLMENTS ESTIMATE", 0) + nvl("ONGOING ENROLMENTS ESTIMATE", 0)), '$999,999,990.99') as "TOTAL CAP ESTIMATE",
      to_char ((nvl("NEW ENROLMENTS CAPS USED", 0) + nvl("ONGOING ENROLMENTS CAP USED", 0)), '$999,999,990.99') as "TOTAL CAP USAGE",
      ltrim(
        round(
          ((nvl("ONGOING ENROLMENTS ESTIMATE", 0) + nvl("NEW ENROLMENTS ESTIMATE", 0)) * 100 )
          / nullif(nvl("ONGOING ENROLMENTS CAP", 0) + nvl("NEW ENROLMENTS CAP", 0), 0),
          2
        ) || '%',
        '%'
      ) as "CAP USAGE ESTIMATE %",
      ltrim(
        round(
          ((nvl("ONGOING ENROLMENTS CAP USED", 0) + nvl("NEW ENROLMENTS CAPS USED", 0)) * 100 )
          / nullif(nvl("ONGOING ENROLMENTS CAP", 0) + nvl("NEW ENROLMENTS CAP", 0), 0),
          2
        ) || '%',
        '%'
      ) as "CAP USAGE %",
      ltrim(
        round(
          ((nvl("ONGOING ENROLMENTS CAP USED", 0) + nvl("NEW ENROLMENTS CAPS USED", 0)) * 100 )
          / nullif((nvl("ONGOING ENROLMENTS ESTIMATE", 0) + nvl("NEW ENROLMENTS ESTIMATE", 0)), 0),
          2
        ) || '%',
        '%'
      ) as "USAGE/ESTIMATE %",
      ltrim(
        round(
          ((nvl("ONGOING ENROLMENTS ESTIMATE", 0) + nvl("NEW ENROLMENTS ESTIMATE", 0)) * 100 )
          / nvl(prog_cap_estimated, 1),
          2
        ) || '%',
        '%'
      ) as "PROGRAM ESTIMATE %",
      ltrim(
        round(
          ((nvl("ONGOING ENROLMENTS CAP USED", 0) + nvl("NEW ENROLMENTS CAPS USED", 0)) * 100)
          / nvl( prog_cap_used, 1),
          2
        ) || '%',
        '%'
      ) as "PROGRAM USAGE %"
    from (
      select
        l.legal_org_id as "LEGAL ORG ID",
        l.legal_org_name as "LEGAL ORG NAME",
        s.abbr as "PROGRAM",
        sr.ref_name as "REGION",
        (
          select training_object.name
          from training_object, rto_as_cap_to
          where rto_as_cap_to.rto_as_cap_id = r.rto_as_cap_id
          and rto_as_cap_to.training_object_id = training_object.training_object_id
          -- Exclude superseded quals
          and rto_as_cap_to.training_object_id = (
            select max(rt.training_object_id)
            from rto_as_cap_to rt
            where rt.rto_as_cap_id = rto_as_cap_to.rto_as_cap_id
          )
        ) "QUALIFICATION",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.enrolled
          and c.ongoing_yn = 'N'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS NOTIFIED",
        (
          select count(p.enrolment_reference_id)
          from pcec_enrolment p
          join rto_as_course_site_allo ao on p.rto_as_course_site_allo_id = ao.rto_as_course_site_allo_id
          where p.enrolment_status_id in (pkg_constant_types.enrolment_status.withdrawn, pkg_constant_types.enrolment_status.expired)
          and ao.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS EXP/CANCELLED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.received
          and c.ongoing_yn = 'N'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS SUBMITTED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.finalised
          and c.ongoing_yn = 'N'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS FINALISED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.finalised
          and p.completion_flag = 'C'
          and c.ongoing_yn = 'N'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS COMPLETED",
        r.new_commencement_cap as "NEW ENROLMENTS CAP",
        (
          select sum(nvl(c.paid_standard_subsidy, c.estimated_standard_subsidy))
          from caps_track_payment c
          where c.ongoing_yn = 'N'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "NEW ENROLMENTS ESTIMATE",
        r.current_caps_used as "NEW ENROLMENTS CAPS USED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.enrolled
          and c.ongoing_yn = 'Y'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "ONGOING ENROLMENTS NOTIFIED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.received
          and c.ongoing_yn = 'Y'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "ONGOING ENROLMENTS SUBMITTED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.finalised
          and c.ongoing_yn = 'Y'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) "ONGOING ENROLMENTS FINALISED",
        (
          select count(distinct p.enrolment_reference_id)
          from pcec_enrolment p
          join caps_track_payment c on p.enrolment_reference_id = c.commitment_id
          where p.enrolment_status_id = pkg_constant_types.enrolment_status.finalised
          and p.completion_flag = 'C'
          and c.ongoing_yn = 'Y'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "ONGOING ENROLMENTS COMPLETED",
        r.ongoing_student_cap as "ONGOING ENROLMENTS CAP",
        (
          select sum(nvl(c.paid_standard_subsidy, c.estimated_standard_subsidy))
          from caps_track_payment c
          where c.ongoing_yn = 'Y'
          and c.rto_as_cap_id = r.rto_as_cap_id
        ) as "ONGOING ENROLMENTS ESTIMATE",
        r.ongoing_cap_used as "ONGOING ENROLMENTS CAP USED",
        (
          select sum ((RC.CURRENT_CAPS_USED )+ ( rc.ongoing_cap_used) )
          from rto_as_cap rc
          where RC.STREAM_GROUP_ID =r.stream_group_id and RC.ACTIVITY_PERIOD_ID = R.ACTIVITY_PERIOD_ID
        ) as prog_cap_used,
        (
          select sum (RC.CURRENT_CAPS_ESTIMATED + RC.ONGOING_CAP_ESTIMATED)
          from  rto_as_cap rc
          where  RC.STREAM_GROUP_ID =r.stream_group_id and RC.ACTIVITY_PERIOD_ID = R.ACTIVITY_PERIOD_ID
        ) as prog_cap_estimated,
        r.rto_as_cap_id
      from rto_as_cap r
        join legal_org l on l.legal_org_id = r.legal_org_id
        join ref.ref_stream_group s on r.stream_group_id = s.stream_group_id
        left join ref.ref_sr_region sr on sr.abs_code = r.region_code
      where
        (nvl(n_activity_period_id,0) = 0 or r.activity_period_id = n_activity_period_id)
        and ((nvl(n_stream_group_id,0) = 0 and r.stream_group_id in (1, 2, 5, 7, 8, 10)) or (r.stream_group_id = n_stream_group_id))
        and (l.tafe_yn = 'N' or r.stream_group_id in (1, 2, 7, 8, 10)) -- all except 5
        and (nvl(n_legal_org_id,0) = 0 or l.legal_org_id = n_legal_org_id)
        and (exists (select 1 FROM user_security us
          JOIN sts_staff_location urc
          ON us.person_id    = urc.person_id
          where urc.det_centre_id = 12
          and us.dud_username = v_user_name
          ) or
          exists ( SELECT 1
          FROM
            (SELECT us.dud_username,
              urc.det_centre_id,
              ubu.business_unit_id
            FROM user_security us
            JOIN sts_staff_location urc
            ON us.person_id = urc.person_id
            LEFT JOIN sts_staff_bu ubu
            ON us.person_id    = ubu.person_id
            ) users
          JOIN
            (SELECT prc.legal_org_id,
              prc.dtec_centre_id,
              pbu.business_unit_id
            FROM legal_org_dtec_centre_map prc
            LEFT JOIN legal_org_bu_map pbu
            ON pbu.legal_org_id                = prc.legal_org_id
            ) providers ON users.det_centre_id = providers.dtec_centre_id
          AND (providers.business_unit_id     IS NULL
          OR providers.business_unit_id        = users.business_unit_id)
        where legal_org_id = r.legal_org_id  and users.dud_username = v_user_name
           )
        )
    )
    order by "PROGRAM", "LEGAL ORG ID", "REGION";

    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_SANDS_COURSE_RPT ) THEN
        pkg_sands_report.p_get_courses(a_out_result_list);
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_SANDS_RTO_RPT ) THEN
        pkg_sands_report.p_get_rtos(a_out_result_list);
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_CAPS_RPT ) THEN
        pkg_vip_mm_reports.p_caps_adjustment_report(a_criterias,a_out_result_list);
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_QR_ADJ_RPT ) THEN
        pkg_vip_mm_reports.p_quals_regions_adj_report(a_criterias,a_out_result_list);
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_PROG_RPT ) THEN
        pkg_vip_mm_reports.p_program_adj_report(a_criterias,a_out_result_list);
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_CLM_RTO_ACT_SCH_RPT ) THEN
     open a_out_result_list for
      select to_char(sysdate, 'ddmmYYYY') || '-' || lo.legal_org_id || '-' || rst.short_desc || '-' || rsr.abs_code || '-' || tobj.ntis_id "UNIQUE KEY",
         to_char(sysdate, 'dd/mm/yyyy') "DATA DATE",
         lo.legal_org_name "PROVIDER NAME",
         lo.ntis_id "NTIS ID",
         lo.legal_org_id "LEGAL ORG ID",
         rsr.description "REGION",
         tobj.name "QUALIFICATION NAME",
         tobj.ntis_id "QUALIFICATION CODE",
         rst.description "PROGRAM",
         rs.description "STATUS",
         to_char(racv.date_commencement_from, 'dd/mm/yyyy') "START DATE",
         to_char(racv.date_commencement_to, 'dd/mm/yyyy') "END DATE"
         from rto_as_cs_view racv
         join legal_org lo on lo.legal_org_id = racv.legal_org_id
         join training_object tobj on tobj.training_object_id = racv.training_object_id
         left join ref_sr_region rsr on rsr.abs_code = racv.region_code
         join ref_stream rst on rst.stream_id = racv.stream_id
         join ref_status rs on rs.status_id = racv.status_id
         where (nvl(n_activity_period_id,0) = 0 or racv.activity_period_id = n_activity_period_id)
         order by "LEGAL ORG ID";
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_CLM_PAST_PER_RPT ) THEN
     open a_out_result_list for
        select rpt.legal_org_id || '-' || rpt.start_year "UNIQUE KEY",
             to_char(sysdate, 'dd/mm/yyyy') "DATA DATE",
             ap.description "ACTIVITY_PERIOD",
             lo.legal_org_id "PROVIDER LEGAL ORG ID",
             lo.legal_org_name "PROVIDER LEGAL NAME",
             lo.ntis_id "NATIONAL ID",
             lo.abn "AUSTRALIAN BUSINESS NUMBER",
             lo.acn "AUSTRALIAN COMPANY NUMBER",
             rpt.start_year "CONTRACT START YEAR",
             rpt.end_year "CONTRACT END YEAR",
             decode(rpt.attp_declaration_recvd, '0', null, rpt.attp_declaration_recvd) "ATTP CONTRACT DECLARATION",
             decode(rpt.ssp_declaration_recvd, '0', null, rpt.ssp_declaration_recvd) "SSP CONTRACT DECLARATION",
             (case when rpt.activity_period_id > 0 then rs.description else rrcs.description end) "CONTRACT STATUS",
             rpt.reason_for_status "REASON FOR CONTRACT STATUS",
             to_char(rpt.status_change_start_date, 'dd/mm/yyyy') "CONTRACT STATUS CHNG START DT",
             to_char(rpt.status_change_end_date, 'dd/mm/yyyy') "CONTRACT STATUS CHNG END DT",
             decode(rpt.impl_for_payments, null, null, 'Y') "IMPLICATION FOR PYMT INDICATOR",
             rpt.impl_for_payments "IMPLICATION FOR PAYMENT",
             rpt.stop_new_enrolment_yn "STOP NEW ENROLMENT INDICATOR"
             from rto_performance_tender rpt
             join legal_org lo on lo.legal_org_id = rpt.legal_org_id
             left join activity_period ap on ap.activity_period_id = rpt.activity_period_id
             left join ref_rto_contract_status rrcs on rrcs.status_id = rpt.contract_status
             left join ref_status rs on rs.status_id = rpt.contract_status
             order by "PROVIDER LEGAL ORG ID";
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_PCM_CLM_PROV_DETAILS_RPT ) THEN
     open a_out_result_list for
       select distinct lo.legal_org_name "LEGAL NAME",
        trim(addr_st_line1 || rtrim(' '||addr_st_line2) || rtrim(' '||addr_st_line3) || rtrim(' '||addr_st_line4)) "HEAD OFFICE ADDRESS STREET",
        upper(am_suburb_name) "SUBURB",
        upper(state) "STATE",
        am_pcode_id "POSTCODE",
        lo.acn "ACN",
        lo.abn "ABN",
        lo.ntis_id "NATIONAL ID",
        rca.legal_org_id "LEGAL ORG ID",
        org.ORG_NAME "TRADING NAME",
        ceo_p.firstname "CEO FIRST NAME",
        ceo_p.surname "CEO LAST NAME",
        ceo_p.email "CEO EMAIL",
        ceo_p.mobile "CEO MOBILE",
        ceo_p.phone_bus "CEO PHONE",
        pr_p.firstname "REP FIRST NAME",
        pr_p.surname "REP LAST NAME",
        pr_p.email "REP EMAIL",
        pr_p.mobile "REP MOBILE",
        pr_p.phone_bus "REP PHONE",
        rca.finalised_by "CONTRACT ACCEPTED BY",
        upper(to_char(rca.date_finalised, 'dd/mm/yyyy HH:MI:SS am')) "CONTRACT DATE ACCEPTED",
        decode(rs1.description, null, rs.description, rs1.description) "RTO SNS CONTRACT STATUS",
        rars.description "ASQA REGISTRATION STATUS", -- (from Past Peformance)
        (select decode(count(distinct ctp.commitment_id), 0, null, count(distinct ctp.commitment_id))
          from rto_as_cap ras
          join caps_track_payment ctp on ctp.rto_as_cap_id = ras.rto_as_cap_id
          join rto_as_cs_view racv on racv.legal_org_id = ras.legal_org_id and racv.rto_as_cap_id = ras.rto_as_cap_id and racv.activity_period_id = ras.activity_period_id
          join pcec_enrolment pe on pe.rto_as_course_site_allo_id = racv.rto_as_course_site_allo_id and pe.enrolment_reference_id = ctp.commitment_id
          join ref_stream_group rsg on rsg.stream_group_id = ras.stream_group_id
          where ras.activity_period_id = rca.activity_period_id
          and ras.legal_org_id = rca.legal_org_id
          and rsg.caps_yn = 'Y'
          and rsg.active_yn = 'Y') "TOTAL NUMBER OF COMMITMENTS",
        (select decode(count(distinct ctp.commitment_id), 0, null, count(distinct ctp.commitment_id))
          from rto_as_cap ras
          join caps_track_payment ctp on ctp.rto_as_cap_id = ras.rto_as_cap_id
          join rto_as_cs_view racv on racv.legal_org_id = ras.legal_org_id and racv.rto_as_cap_id = ras.rto_as_cap_id and racv.activity_period_id = ras.activity_period_id
          join pcec_enrolment pe on pe.rto_as_course_site_allo_id = racv.rto_as_course_site_allo_id and pe.enrolment_reference_id = ctp.commitment_id
          join ref_stream_group rsg on rsg.stream_group_id = ras.stream_group_id
          where ras.activity_period_id = rca.activity_period_id
          and ras.legal_org_id = rca.legal_org_id
          and ctp.ongoing_yn = 'N'
          and rsg.caps_yn = 'Y'
          and rsg.active_yn = 'Y'
          and paid_standard_subsidy is not null) "TOTAL NUMBER OF COMMENCEMENTS",
        (select trim(to_char(sum(paid_standard_subsidy), '$999,999,990.99'))
          from rto_as_cap ras
          join caps_track_payment ctp on ctp.rto_as_cap_id = ras.rto_as_cap_id
          join ref_stream_group rsg on rsg.stream_group_id = ras.stream_group_id
          where ras.activity_period_id = rca.activity_period_id
          and ras.legal_org_id = rca.legal_org_id
          and rsg.caps_yn = 'Y'
          and rsg.active_yn = 'Y'
          and paid_standard_subsidy is not null) "TOTAL PAYMENTS (without GST)",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_AandT
           group by ras.legal_org_id) "EAT Y/N",
        (select decode(nvl(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), 0), 0, null, trim(to_char(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_AandT
           group by ras.legal_org_id) "EAT FINANCIAL CAP",
        (select decode(nvl(sum(nvl(ras.new_commencement_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.new_commencement_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_AandT) "EAT NEW COMMENCEMENT CAP",
        (select decode(nvl(sum(nvl(ras.ongoing_student_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.ongoing_student_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_AandT) "EAT CONTINUING CAP",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_full_qual
           group by ras.legal_org_id) "EFQ Y/N",
        (select decode(nvl(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), 0), 0, null, trim(to_char(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_full_qual
           group by ras.legal_org_id) "EFQ FINANCIAL CAP",
        (select decode(nvl(sum(nvl(ras.new_commencement_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.new_commencement_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_full_qual) "EFQ NEW COMMENCEMENT CAP",
        (select decode(nvl(sum(nvl(ras.ongoing_student_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.ongoing_student_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_full_qual) "EFQ CONTINUING CAP",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_foundation
           group by ras.legal_org_id) "EFS Y/N",
        (select decode(nvl(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), 0), 0, null, trim(to_char(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_foundation
           group by ras.legal_org_id) "EFS FINANCIAL CAP",
        (select decode(nvl(sum(nvl(ras.new_commencement_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.new_commencement_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_foundation) "EFS NEW COMMENCEMENT CAP",
        (select decode(nvl(sum(nvl(ras.ongoing_student_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.ongoing_student_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_ent_foundation) "EFS CONTINUING CAP",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_sbat
           group by ras.legal_org_id) "SBAT Y/N",
        (select decode(nvl(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), 0), 0, null, trim(to_char(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_sbat
           group by ras.legal_org_id) "SBAT FINANCIAL CAP",
        (select decode(nvl(sum(nvl(ras.new_commencement_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.new_commencement_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_sbat) "SBAT NEW COMMENCEMENT CAP",
        (select decode(nvl(sum(nvl(ras.ongoing_student_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.ongoing_student_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_sbat) "SBAT CONTINUING CAP",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_tar_full_qual
           group by ras.legal_org_id) "TPFQ Y/N",
        (select decode(nvl(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), 0), 0, null, trim(to_char(sum(sum(nvl(ras.new_commencement_cap, 0)) + sum(nvl(ras.ongoing_student_cap, 0))), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_tar_full_qual
           group by ras.legal_org_id) "TPFQ FINANCIAL CAP",
        (select decode(nvl(sum(nvl(ras.new_commencement_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.new_commencement_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_tar_full_qual) "TPFQ NEW COMMENCEMENT CAP",
        (select decode(nvl(sum(nvl(ras.ongoing_student_cap, 0)), 0), 0, null, trim(to_char(sum(nvl(ras.ongoing_student_cap, 0)), '$999,999,990.99')))
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_tar_full_qual) "TPFQ CONTINUING CAP",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cap ras
           where ras.activity_period_id = rca.activity_period_id
           and ras.legal_org_id = rca.legal_org_id
           and ras.stream_group_id = pkg_global_objects_prog.cn_str_group_tar_part_qual
           group by ras.legal_org_id) "TPPPQ Y/N",
        (select decode(nvl(count(1), 0), 0, 'No', 'Yes')
           from rto_as_cs_view racv
           where legal_org_id = rca.legal_org_id
           and activity_period_id = rca.activity_period_id
           and pas_id > 0
           and racv.status_id in (pkg_rtow_activity_schedule.cn_cs_status_current, pkg_rtow_activity_schedule.cn_cs_status_pending,
                                  pkg_rtow_activity_schedule.cn_cs_status_pending_accept, pkg_rtow_activity_schedule.cn_cs_status_declined,
                                  pkg_rtow_activity_schedule.cn_cs_status_withdrawn)) "PAS Y/N"
          from rto_contract_acceptance rca
          join legal_org lo on lo.legal_org_id = rca.legal_org_id
          join rto r on r.legal_org_id = lo.legal_org_id
          join organisation org on org.org_id = r.primary_org_id
          join ref_status rs on rs.status_id = rca.status_id
          join address a on a.legal_org_id = rca.legal_org_id
          join address_role ar on ar.addr_id = a.addr_id
          join ref_address_type rat on rat.addr_type_id = ar.addr_type_id
          left join (select distinct pr.legal_org_id, p.firstname, p.surname, p.email, p.mobile, p.phone_bus
                      from person_role pr
                      join person p on p.person_id = pr.contact_id
                      where pr.function_id = pkg_global_objects_prog.cn_func_role_peo -- CEO (Chief Executive Officer) Person ID
                      and p.current_use = 1
                    ) ceo_p on ceo_p.legal_org_id = lo.legal_org_id
          left join (select distinct pr.legal_org_id, p.firstname, p.surname, p.email, p.mobile, p.phone_bus
                      from person_role pr
                      join person p on p.person_id = pr.contact_id
                      where pr.function_id = pkg_post_application.cn_providers_representative -- Provider Representative Person ID
                      and pr.function_group_id = 1 -- S&S Provider Representative functional group
                    ) pr_p on pr_p.legal_org_id = lo.legal_org_id
          left join rto_performance_tender rpt on rpt.legal_org_id = rca.legal_org_id and rpt.activity_period_id = rca.activity_period_id
          left join ref_status rs1 on rs1.status_id = rpt.contract_status
          left join rto_performance rp on rp.legal_org_id = rca.legal_org_id
          left join ref_asqa_registration_status rars on rars.status_id = rp.asqa_reg_status
          where (nvl(n_activity_period_id,0) = 0 or rca.activity_period_id = n_activity_period_id)
          and nvl(a.current_use,1) = 1
          and rat.addr_type_id = pkg_global_objects_ivets.CN_ADDR_TYPE_REGSTRD -- (1 - Head Office Address Type)
          and rat.active = 'Y'
          and rca.type_ind in (pkg_global_objects_prog.cn_contract_type_initial, pkg_global_objects_prog.cn_contract_type_review) -- Smart and Skilled Contract with Intial and Review status only
          and (rpt.contract_status is null or rpt.contract_status <> pkg_global_objects_prog.cn_contract_status_full_term) -- All Smart and Skilled Providers with exception of contract status 9111 (Terminated - Full)
          order by "LEGAL ORG ID", "RTO SNS CONTRACT STATUS";
    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_ADMIN_SM_AUDIT_SECURITY_RPT ) THEN
    /*dt_from := TO_DATE(TO_CHAR(a_date_from, 'DD-MON-YYYY') || ' 23:59:59', 'DD-MON-YYYY HH24:MI:SS');
    -- make the to date
    IF a_date_to IS NULL THEN
    dt_to := NULL;
    ELSE
    dt_to := TO_DATE(TO_CHAR(a_date_to, 'DD-MON-YYYY') || ' 23:59:59', 'DD-MON-YYYY HH24:MI:SS');
    END IF;*/
    open a_out_result_list for
    SELECT TO_CHAR(AUDIT_SECURITY.change_date, 'DD/MM/YYYY HH:MM:SS') as "Date Changed",
        AUDIT_SECURITY.CHANGE_TYPE as "Type",
        AUDIT_SECURITY.CHANGE_BY_USERNAME as "User Name",
        RBU.DESCRIPTION as "Business Unit",
        DTEC.ADDR_ID as "Address ID",
        ADDRESS.ADDR_ST_LINE1 as "Address Line 1",
        ADDRESS.ADDR_ST_LINE2 as "Line 2",
        ADDRESS.ADDR_ST_LINE3 as "Line 3",
        ADDRESS.ADDR_ST_LINE4 as "Line 4",
        ADDRESS.AM_SUBURB_NAME as "Suburb",
        USER_SECURITY.FIRSTNAME as "First Name",
        USER_SECURITY.SURNAME as "Surname",
        USER_SECURITY.USER_NAME as "User Name",
        MAX( DECODE( ROL.STAFF_ROLE_ID,0,1,0)) as "Current User",
        MAX( DECODE( ROL.STAFF_ROLE_ID,1,1,0)) as "Assessment Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,2,1,0)) as "Inspection Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,3,1,0)) as "Purchase Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,4,1,0)) as "Data Entry Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,5,1,0)) as "Chief Exceutive Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,6,1,0)) as "Purchase Order Approving Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,7,1,0)) as "Scheduling Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,8,1,0)) as "Write Director's Folder",
        MAX( DECODE( ROL.STAFF_ROLE_ID,9,1,0)) as "Training Contract Admin",
        MAX( DECODE( ROL.STAFF_ROLE_ID,13,1,0)) as "Send Batch Privilege",
        MAX( DECODE( ROL.STAFF_ROLE_ID,14,1,0)) as "Training Contract Delete",
        MAX( DECODE( ROL.STAFF_ROLE_ID,15,1,0)) as "Training Contract Approve",
        MAX( DECODE( ROL.STAFF_ROLE_ID,16,1,0)) as "VT5 Data entry Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,17,1,0)) as "VT7 Data Entry Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,18,1,0)) as "Sensitive Data Security Cleared",
        MAX( DECODE( ROL.STAFF_ROLE_ID,19,1,0)) as "Reception/Switch",
        MAX( DECODE( ROL.STAFF_ROLE_ID,20,1,0)) as "Clerical Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,21,1,0)) as "Auditor",
        MAX( DECODE( ROL.STAFF_ROLE_ID,22,1,0)) as "Lead Auditor",
        MAX( DECODE( ROL.STAFF_ROLE_ID,23,1,0)) as "Co-Auditor",
        MAX( DECODE( ROL.STAFF_ROLE_ID,24,1,0)) as "Director VETAB",
        MAX( DECODE( ROL.STAFF_ROLE_ID,25,1,0)) as "Generate Certificate",
        MAX( DECODE( ROL.STAFF_ROLE_ID,26,1,0)) as "CRICOS",
        MAX( DECODE( ROL.STAFF_ROLE_ID,27,1,0)) as "Update Org'n Details",
        MAX( DECODE( ROL.STAFF_ROLE_ID,28,1,0)) as "Reassign Task/Reassign CM",
        MAX( DECODE( ROL.STAFF_ROLE_ID,29,1,0)) as "Deregister/Withdraw RTO",
        MAX( DECODE( ROL.STAFF_ROLE_ID,30,1,0)) as "Rollover Tender Data",
        MAX( DECODE( ROL.STAFF_ROLE_ID,31,1,0)) as "Course Site Activator",
        MAX( DECODE( ROL.STAFF_ROLE_ID,32,1,0)) as "NTIS Contact",
        MAX( DECODE( ROL.STAFF_ROLE_ID,33,1,0)) as "National Recognition",
        MAX( DECODE( ROL.STAFF_ROLE_ID,34,1,0)) as "TAFE Payments",
        MAX( DECODE( ROL.STAFF_ROLE_ID,35,1,0)) as "Advisor",
        MAX( DECODE( ROL.STAFF_ROLE_ID,36,1,0)) as "Registration Contact",
        MAX( DECODE( ROL.STAFF_ROLE_ID,37,1,0)) as "Work Allocation Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,38,1,0)) as "TC Admin User",
        MAX( DECODE( ROL.STAFF_ROLE_ID,39,1,0)) as "Approval Low Risk TC",
        MAX( DECODE( ROL.STAFF_ROLE_ID,40,1,0)) as "Authorise PV upto $20,000",
        MAX( DECODE( ROL.STAFF_ROLE_ID,41,1,0)) as "Authorise PV upto $35,000",
        MAX( DECODE( ROL.STAFF_ROLE_ID,42,1,0)) as "Authorise PV upto $75,000",
        MAX( DECODE( ROL.STAFF_ROLE_ID,43,1,0)) as "Authorise PV upto $200,000",
        MAX( DECODE( ROL.STAFF_ROLE_ID,44,1,0)) as "Alter Other STS Centre Claim",
        MAX( DECODE( ROL.STAFF_ROLE_ID,45,1,0)) as "Resend to Finance System",
        MAX( DECODE( ROL.STAFF_ROLE_ID,46,1,0)) as "Raise Credit Note",
        MAX( DECODE( ROL.STAFF_ROLE_ID,47,1,0)) as "Receipt of RCTI(pdf)",
        MAX( DECODE( ROL.STAFF_ROLE_ID,48,1,0)) as "External Auditor",
        MAX( DECODE( ROL.STAFF_ROLE_ID,49,1,0)) as "Industry Training Coordinator",
        MAX( DECODE( ROL.STAFF_ROLE_ID,50,1,0)) as "Complaint Manager",
        -- There is no related function role "51" in table ref_function_role
        MAX( DECODE( ROL.STAFF_ROLE_ID,52,1,0)) as "TP Revision",
        MAX( DECODE( ROL.STAFF_ROLE_ID,53,1,0)) as "PSD Override",
        MAX( DECODE( ROL.STAFF_ROLE_ID,54,1,0)) as "Issue Pre-payments",
        MAX( DECODE( ROL.STAFF_ROLE_ID,55,1,0)) as "Claim Representative",
        MAX( DECODE( ROL.STAFF_ROLE_ID,100,1,0)) as "VETAB Administrator",
        MAX( DECODE( ROL.STAFF_ROLE_ID,101,1,0)) as "Finance Officer",
        MAX( DECODE( ROL.STAFF_ROLE_ID,102,1,0)) as "System Administrator",
        MAX( DECODE( LEAST(55,ROL.STAFF_ROLE_ID),56,1,0)) as "Unknown",
        AUDIT_SECURITY.comments as "Comments",
        USER_SECURITY.PERSON_ID as "Person ID"
    FROM AUDIT_SECURITY,
        ADDRESS,
        USER_SECURITY,
      STS_STAFF_LOCATION LOC,
      STS_STAFF_BU BU,
      STS_STAFF_ROLE ROL,
      REF_DTEC_CENTRE DTEC,
      REF_BUSINESS_UNIT RBU
      WHERE ( USER_SECURITY.PERSON_ID = LOC.PERSON_ID) AND
      ( USER_SECURITY.PERSON_ID = BU.PERSON_ID(+)) AND
      ( USER_SECURITY.PERSON_ID = ROL.PERSON_ID(+)) AND
      ( DTEC.DTEC_CENTRE_ID = LOC.DET_CENTRE_ID) AND
            ( AUDIT_SECURITY.person_id = USER_SECURITY.person_id ) AND
            ( DTEC.addr_id = ADDRESS.addr_id ) AND
      (USER_SECURITY.DEFAULT_BUSINESS_UNIT_ID = RBU.BUSINESS_UNIT_ID(+)) AND
      (a_date_from is null or AUDIT_SECURITY.change_date >= to_date(a_date_from, 'dd/mm/yyyy')) AND
      (a_date_to is null or AUDIT_SECURITY.change_date <= to_date(a_date_to, 'dd/mm/yyyy')+1) AND
            (( AUDIT_SECURITY.change_type = n_change_type_id ) OR (n_change_type_id = 0) ) AND
      (( trim(n_det_centre_id) IS NULL OR n_det_centre_id = '0' OR loc.det_centre_id IN (select column_value from table(f_split_strings(cast(n_det_centre_id as VARCHAR2(200)) ))))) AND
            (( ROL.STAFF_ROLE_ID = n_role_id ) OR (n_role_id = '0') OR (n_role_id IS NULL) OR (n_role_id = -1)) AND
            (( BU.BUSINESS_UNIT_ID = a_bus_unit ) OR (a_bus_unit IS NULL) OR (a_bus_unit = 0)) AND
      (( USER_SECURITY.PERSON_ID = n_person_id ) OR (n_person_id IS NULL) OR (n_person_id = 0))
        GROUP BY AUDIT_SECURITY.change_date,
            AUDIT_SECURITY.change_type,
            AUDIT_SECURITY.change_by_username,
      RBU.DESCRIPTION,
            DTEC.addr_id,
            ADDRESS.addr_st_line1,
            ADDRESS.addr_st_line2,
            ADDRESS.addr_st_line3,
            ADDRESS.addr_st_line4,
            ADDRESS.am_suburb_name,
            USER_SECURITY.person_id,
            USER_SECURITY.firstname,
            USER_SECURITY.surname,
            USER_SECURITY.user_name,
            AUDIT_SECURITY.comments
      ORDER BY AUDIT_SECURITY.change_date DESC;


    ELSIF ( a_report_id = Pkg_Vip_Report_Constants.CN_ADMIN_SM_USER_PROFILES_RPT ) THEN

        open a_out_result_list for
        SELECT up.SYSTEM_USERNAME username, up.SECURITY_PROFILE profileid, sp.PROFILE_NM profilename, up.SECURITY_PROFILE_TYPE profiletype, sp.APPLICATION_CODE applicationcode
        FROM SIMDBA.USER_PROFILES up
            LEFT OUTER JOIN SIMDBA.SECURITY_PROFILES sp
            ON (sp.SECURITY_PROFILE = up.SECURITY_PROFILE);

    END IF;

  IF a_sql IS NOT NULL THEN
    OPEN a_out_result_list	FOR a_sql;
  END IF;

  END P_REPORT_SQL;

	/************************************************************************************************************************************/
	FUNCTION convert_date_to_string(
			 a_date							IN				DATE
	)RETURN VARCHAR2
	AS
	/*********************************************************************
    Purpose             : Convert the date to dd/mm/yyyy format
    Author              : Vijaya Shetty
    Date Created        : Nov 2004
    Modifications
    Date        Author   Description
  *********************************************************************/
		a_string 				 VARCHAR2(10);
	BEGIN
		 IF a_date IS NOT NULL THEN
		 	   a_string :=TO_CHAR(a_date,'dd/mm/yyyy');
		ELSE
			a_string :='';
		END IF;
	RETURN a_string;
	END convert_date_to_string;

	/************************************************************************************************************************************/
	FUNCTION convert_string_to_date(
			 a_date_string							IN				varchar2
	)RETURN date
	AS
	/*********************************************************************
    Purpose             : Convert the string containnig a date in dd/mm/yyyy format to a date object
    Author              : Peter Thiem
    Date Created        : June 2008
    Modifications
    Date        Author   Description
  *********************************************************************/
		a_date 				 date;
	BEGIN
		IF a_date_string IS NOT NULL THEN
		 	a_date :=TO_DATE(a_date_string,'dd/mm/yyyy');
		ELSE
			a_date := null;
		END IF;
	RETURN a_date;
	END convert_string_to_date;


/************************************************************************************************************************************/
	 FUNCTION convert_num_to_string(
	a_num							IN				NUMBER
	)RETURN VARCHAR2
	AS
	/*********************************************************************
    Purpose             : Convert the num to long
    Author                 : Vijaya Shetty
    Date Created   : Nov 2004
    Modifications
    Date        Author   Description
  *********************************************************************/

		a_string 				 VARCHAR2(100);
	BEGIN
		 IF a_num IS NOT NULL THEN
		 	   a_string :=TO_CHAR( a_num ,'9999999999');
		ELSE
			a_string :='';
		END IF;
	RETURN a_string;
	END convert_num_to_string;
/************************************************************************************************************************************/

END Pkg_Vip_Report_Sql;
