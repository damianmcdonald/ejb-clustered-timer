CREATE OR REPLACE PROCEDURE create_ejb_timer_proc
(
v_ID IN VARCHAR2(255),
v_TIMED_OBJECT_ID IN VARCHAR2(255), 
v_INITIAL_DATE IN TIMESTAMP, 
v_REPEAT_INTERVAL IN NUMBER(20), 
v_NEXT_DATE IN TIMESTAMP, 
v_PREVIOUS_RUN IN TIMESTAMP, 
v_PRIMARY_KEY IN VARCHAR2(255), 
v_INFO IN CLOB, 
v_TIMER_STATE IN VARCHAR2(32), 
v_SCHEDULE_EXPR_SECOND IN VARCHAR2(100), 
v_SCHEDULE_EXPR_MINUTE IN VARCHAR2(100), 
v_SCHEDULE_EXPR_HOUR IN VARCHAR2(100),
v_SCHEDULE_EXPR_DAY_OF_WEEK IN VARCHAR2(100), 
v_SCHEDULE_EXPR_DAY_OF_MONTH IN VARCHAR2(100), 
v_SCHEDULE_EXPR_MONTH IN VARCHAR2(100), 
v_SCHEDULE_EXPR_YEAR IN VARCHAR2(100), 
v_SCHEDULE_EXPR_START_DATE IN VARCHAR2(100), 
v_SCHEDULE_EXPR_END_DATE IN VARCHAR(100), 
v_SCHEDULE_EXPR_TIMEZONE IN VARCHAR2(100), 
v_AUTO_TIMER IN NUMBER(1),
v_TIMEOUT_METHOD_DECLARING_CLASS IN VARCHAR2(255),
v_TIMEOUT_METHOD_NAME IN VARCHAR2(100),
v_TIMEOUT_METHOD_DESCRIPTOR IN VARCHAR2(255), 
v_CALENDAR_TIMER IN NUMBER(1), 
v_PARTITION_NAME IN VARCHAR2(100), 
v_NODE_NAME IN VARCHAR2(255)
)
IS
BEGIN

	INSERT INTO JBOSS_EJB_TIMER 
	(ID, TIMED_OBJECT_ID, INITIAL_DATE, REPEAT_INTERVAL, NEXT_DATE, PREVIOUS_RUN, PRIMARY_KEY, INFO, TIMER_STATE, SCHEDULE_EXPR_SECOND, SCHEDULE_EXPR_MINUTE, 
	SCHEDULE_EXPR_HOUR, SCHEDULE_EXPR_DAY_OF_WEEK, SCHEDULE_EXPR_DAY_OF_MONTH, SCHEDULE_EXPR_MONTH, SCHEDULE_EXPR_YEAR, SCHEDULE_EXPR_START_DATE, SCHEDULE_EXPR_END_DATE, 
	SCHEDULE_EXPR_TIMEZONE, AUTO_TIMER, TIMEOUT_METHOD_DECLARING_CLASS, TIMEOUT_METHOD_NAME, TIMEOUT_METHOD_DESCRIPTOR, CALENDAR_TIMER, PARTITION_NAME, NODE_NAME) 
	SELECT v_ID, v_TIMED_OBJECT_ID, v_INITIAL_DATE, v_REPEAT_INTERVAL, v_NEXT_DATE, v_PREVIOUS_RUN, v_PRIMARY_KEY, v_INFO, v_TIMER_STATE, v_SCHEDULE_EXPR_SECOND, v_SCHEDULE_EXPR_MINUTE, 
	v_SCHEDULE_EXPR_HOUR, v_SCHEDULE_EXPR_DAY_OF_WEEK, v_SCHEDULE_EXPR_DAY_OF_MONTH, v_SCHEDULE_EXPR_MONTH, v_SCHEDULE_EXPR_YEAR, v_SCHEDULE_EXPR_START_DATE, v_SCHEDULE_EXPR_END_DATE, 
	v_SCHEDULE_EXPR_TIMEZONE, v_AUTO_TIMER, v_TIMEOUT_METHOD_DECLARING_CLASS, v_TIMEOUT_METHOD_NAME, v_TIMEOUT_METHOD_DESCRIPTOR, v_CALENDAR_TIMER, v_PARTITION_NAME, v_NODE_NAME
	FROM dual
	WHERE NOT EXISTS (SELECT 1 FROM JBOSS_EJB_TIMER
						WHERE TIMED_OBJECT_ID = v_TIMED_OBJECT_ID
							AND PARTITION_NAME = v_PARTITION_NAME
					);

END;
/

 