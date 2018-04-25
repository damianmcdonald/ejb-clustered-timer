# EJB3 Clustered Database Timers

This project demonstrates the use of a database to persist EJB3 Timers so that:

* Timer schedule executes only *once* per Wildfly domain
* Domain contains only a single registration per Timer
* Timers are highly available and will continue execution even if domain nodes fail

## Overview

The project follows the guidelines provided by the Wildfly team for creating [EJB3 Clustered Database Timers](https://docs.jboss.org/author/display/WFLY10/EJB3+Clustered+Database+Timers).

The implementation is based on the [Creating clustered EJB 3 Timers](http://www.mastertheboss.com/jboss-server/wildfly-8/creating-clustered-ejb-3-timers) guide.

## Domain Configuration

The Wildfly node designated as the `master`, defines itself as a domain controller within the [host-master.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/host-master.xml) file.

```XML
 <domain-controller>
     <local/>
 </domain-controller>
```
In this demo project, we are:

* using the `<profile name="full">`
* defining a single server group `<server-group name="main-server-group" profile="full">`

In the [domain.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/domain.xml) file we define the datasource and persistence approach for the Timer within the `<profile name="full">`.

**Datasource definition**

```SQL
<subsystem xmlns="urn:jboss:domain:datasources:4.0">
    <datasources>
        <datasource jndi-name="java:jboss/datasources/ExampleDS" pool-name="ExampleDS" enabled="true" use-java-context="true">
            <connection-url>jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE</connection-url>
            <driver>h2</driver>
            <security>
                <user-name>sa</user-name>
                <password>sa</password>
            </security>
        </datasource>
        <xa-datasource jndi-name="java:jboss/datasources/SpXaDsMysql" pool-name="SpXaDsMysql" enabled="true" use-java-context="true">
           <xa-datasource-property name="ServerName">
                ${database.host}
            </xa-datasource-property>
            <xa-datasource-property name="DatabaseName">
                ${database.name}
            </xa-datasource-property>
            <xa-datasource-property name="PortNumber">
                ${database.port}
            </xa-datasource-property>
            <xa-datasource-property name="User">
                ${database.username}
            </xa-datasource-property>
            <xa-datasource-property name="Password">
                ${database.password}
            </xa-datasource-property>
            <driver>mysql</driver>
        </xa-datasource>
        <drivers>
            <driver name="h2" module="com.h2database.h2">
                <xa-datasource-class>org.h2.jdbcx.JdbcDataSource</xa-datasource-class>
            </driver>
            <driver name="mysql" module="com.mysql.jdbc">
                <xa-datasource-class>com.mysql.jdbc.jdbc2.optional.MysqlXADataSource</xa-datasource-class>
            </driver>
        </drivers>
    </datasources>
</subsystem>
```

*NOTE*: 

The [MySQL JDBC Driver](https://dev.mysql.com/downloads/connector/j/5.1.html) must be installed in **all** of the Wildfly nodes that will participate in the domain. The  `mysql-connector-java-5.1.XX-bin.jar` must be copied to `$WILDFLY_HOME/modules/system/layers/base/com/mysql/jdbc/main/mysql-connector-java-5.1.XX-bin.jar.`

Additionally, in the `$WILDFLY_HOME/modules/system/layers/base/com/mysql/jdbc/main/`folder a `module.xml` file must be created with the content below:

```XML
<module xmlns="urn:jboss:module:1.0" name="com.mysql.jdbc">
  <resources>
    <resource-root path="mysql-connector-java-5.1.XX-bin.jar"/>
  </resources>
  <dependencies>
    <module name="javax.api"/>
    <module name="javax.transaction.api"/>
  </dependencies>
</module>
```
**Timer definition**

```XML
<timer-service thread-pool-name="default" default-data-store="clustered-store">
    <data-stores>
        <database-data-store name="clustered-store" datasource-jndi-name="java:jboss/datasources/SpXaDsMysql" database="mysql" partition="timer"/>
    </data-stores>
</timer-service>
```

## Host Configuration

The key point for the host configuration ([host-master.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/host-master.xml) and [host-slave.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/host-slave.xml) respectively) is that the hosts are members of *main-server-group*: `<server name="server-one" group="main-server-group"/>`.

## Timer Creation

The Timer is defined in the [BatchProcess](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/src/main/java/com/github/damianmcdonald/ejbtimer/BatchProcess.java) class (shown below).

```Java
@Startup
@Singleton
public class BatchProcess {

    @Resource
    TimerService timerService;

    @PostConstruct
    public void init() {
        final ScheduleExpression exp = new ScheduleExpression();
        exp.dayOfMonth("*").dayOfWeek("*").hour("*").minute("*").second("20,40");
        final TimerConfig timerConfig = new TimerConfig();
        timerConfig.setPersistent(true);
        timerService.createCalendarTimer(exp, timerConfig);
    }
```

The Timer is being created programmatically and it is *persisted* every time that the application starts.

The number of registered Timers can be calculated as:

`number of Timers registered = (number of domain nodes) + (number of times each node has been restarted)`

For the purposes of this demo, the requirements are:

* Timer schedule must execute only *once* per Wildfly domain
* Domain must contain only a single registration per Timer
* Timers are highly available and will continue execution even if domain nodes fail

These requirements can be achieved by modifiying the Timer database configuration.


## Timer Database Configuration

By default, the SQL statements that define the Timer persistence behaviour is defined in `$WILDFLY_HOME/modules/system/layers/base/org/jboss/as/ejb3/main/timers/timer-sql.properties`.

The default SQL syntax to create timers is shown below:

```SQL
INSERT INTO JBOSS_EJB_TIMER 
(ID, TIMED_OBJECT_ID, INITIAL_DATE, REPEAT_INTERVAL, NEXT_DATE, PREVIOUS_RUN, PRIMARY_KEY, 
INFO, TIMER_STATE, SCHEDULE_EXPR_SECOND, SCHEDULE_EXPR_MINUTE, SCHEDULE_EXPR_HOUR, 
SCHEDULE_EXPR_DAY_OF_WEEK, SCHEDULE_EXPR_DAY_OF_MONTH, SCHEDULE_EXPR_MONTH, SCHEDULE_EXPR_YEAR, 
SCHEDULE_EXPR_START_DATE, SCHEDULE_EXPR_END_DATE, SCHEDULE_EXPR_TIMEZONE, AUTO_TIMER, 
TIMEOUT_METHOD_DECLARING_CLASS, TIMEOUT_METHOD_NAME, TIMEOUT_METHOD_DESCRIPTOR, CALENDAR_TIMER,
PARTITION_NAME, NODE_NAME) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
```
This default SQL does not contain any controls for timer creation. Every time a node requests the creation of a Timer, a new Timer will be created. 

The [DatabaseTimerPersistence](https://github.com/wildfly/wildfly/blob/master/ejb3/src/main/java/org/jboss/as/ejb3/timerservice/persistence/database/DatabaseTimerPersistence.java) class provided by Wildfly uses a [PreparedStatement](https://docs.oracle.com/javase/8/docs/api/java/sql/PreparedStatement.html) that does not support named paramaters. For this reason, it is not possibile to use the provided parameters (the `?`entries in the SQL) multiple times.

In order to achieve the level of control that we require, within the constraints of not modifying the Wildfly source code, it is necessary to create a Stored Procedure ([create_ejb_timer_proc.sql](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/sql/create-timer-proc.sql)).

```SQL
DROP PROCEDURE IF EXISTS create_ejb_timer_proc;

DELIMITER //
CREATE PROCEDURE create_ejb_timer_proc
(
IN v_ID  VARCHAR(255),
IN v_TIMED_OBJECT_ID VARCHAR(255), 
IN v_INITIAL_DATE DATETIME, 
IN v_REPEAT_INTERVAL BIGINT, 
IN v_NEXT_DATE DATETIME, 
IN v_PREVIOUS_RUN DATETIME, 
IN v_PRIMARY_KEY VARCHAR(255), 
IN v_INFO TEXT, 
IN v_TIMER_STATE VARCHAR(32), 
IN v_SCHEDULE_EXPR_SECOND VARCHAR(100), 
IN v_SCHEDULE_EXPR_MINUTE VARCHAR(100), 
IN v_SCHEDULE_EXPR_HOUR VARCHAR(100),
IN v_SCHEDULE_EXPR_DAY_OF_WEEK VARCHAR(100), 
IN v_SCHEDULE_EXPR_DAY_OF_MONTH VARCHAR(100), 
IN v_SCHEDULE_EXPR_MONTH VARCHAR(100), 
IN v_SCHEDULE_EXPR_YEAR VARCHAR(100), 
IN v_SCHEDULE_EXPR_START_DATE VARCHAR(100), 
IN v_SCHEDULE_EXPR_END_DATE VARCHAR(100), 
IN v_SCHEDULE_EXPR_TIMEZONE VARCHAR(100), 
IN v_AUTO_TIMER BOOLEAN,
IN v_TIMEOUT_METHOD_DECLARING_CLASS VARCHAR(255),
IN v_TIMEOUT_METHOD_NAME VARCHAR(100),
IN v_TIMEOUT_METHOD_DESCRIPTOR VARCHAR(255), 
IN v_CALENDAR_TIMER BOOLEAN, 
IN v_PARTITION_NAME VARCHAR(100), 
IN v_NODE_NAME VARCHAR(255)
)
BEGIN

	INSERT INTO JBOSS_EJB_TIMER 
	(ID, TIMED_OBJECT_ID, INITIAL_DATE, REPEAT_INTERVAL, NEXT_DATE, PREVIOUS_RUN, PRIMARY_KEY, INFO, TIMER_STATE, SCHEDULE_EXPR_SECOND, SCHEDULE_EXPR_MINUTE, 
	SCHEDULE_EXPR_HOUR, SCHEDULE_EXPR_DAY_OF_WEEK, SCHEDULE_EXPR_DAY_OF_MONTH, SCHEDULE_EXPR_MONTH, SCHEDULE_EXPR_YEAR, SCHEDULE_EXPR_START_DATE, SCHEDULE_EXPR_END_DATE, 
	SCHEDULE_EXPR_TIMEZONE, AUTO_TIMER, TIMEOUT_METHOD_DECLARING_CLASS, TIMEOUT_METHOD_NAME, TIMEOUT_METHOD_DESCRIPTOR, CALENDAR_TIMER, PARTITION_NAME, NODE_NAME) 
	SELECT v_ID, v_TIMED_OBJECT_ID, v_INITIAL_DATE, v_REPEAT_INTERVAL, v_NEXT_DATE, v_PREVIOUS_RUN, v_PRIMARY_KEY, v_INFO, v_TIMER_STATE, v_SCHEDULE_EXPR_SECOND, v_SCHEDULE_EXPR_MINUTE, 
	v_SCHEDULE_EXPR_HOUR, v_SCHEDULE_EXPR_DAY_OF_WEEK, v_SCHEDULE_EXPR_DAY_OF_MONTH, v_SCHEDULE_EXPR_MONTH, v_SCHEDULE_EXPR_YEAR, v_SCHEDULE_EXPR_START_DATE, v_SCHEDULE_EXPR_END_DATE, 
	v_SCHEDULE_EXPR_TIMEZONE, v_AUTO_TIMER, v_TIMEOUT_METHOD_DECLARING_CLASS, v_TIMEOUT_METHOD_NAME, v_TIMEOUT_METHOD_DESCRIPTOR, v_CALENDAR_TIMER, v_PARTITION_NAME, v_NODE_NAME
	FROM dual
	WHERE NOT EXISTS (SELECT ID FROM JBOSS_EJB_TIMER
						WHERE TIMED_OBJECT_ID = v_TIMED_OBJECT_ID
							AND PARTITION_NAME = v_PARTITION_NAME
					);

END //
DELIMITER ;
```
Once [create_ejb_timer_proc.sql](create_ejb_timer_proc.sql) has been created, the `$WILDFLY_HOME/modules/system/layers/base/org/jboss/as/ejb3/main/timers/timer-sql.properties` file on **all** Wildfly nodes must be updated (as shown below):

```SQL
create-timer={call create_ejb_timer_proc(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}
```

## Start the domain

**Domain Controller**

The [host-master.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/host-master.xml) file should be copied to `$WILDFLY_HOME/domain/configuration/host-master.xml` on the node deignated as the Domian Controller.

The Domain Controller can be started with: `$WILDFLY_HOME/bin/domain.sh --host-config=host-master.xml`

**Domain Nodes**

The [host-slave.xml](https://github.com/damianmcdonald/ejb-clustered-timer/blob/master/configuration/host-slave.xml) file should be copied to `$WILDFLY_HOME/domain/configuration/host-slave.xml` on the domain nodes.

The Domain Nodes can be started with: `$WILDFLY_HOME/bin/domain.sh --host-config=host-slave.xml`

## Build ejb-clustered-timer


The library was built using the following toolchain:

* [Java Oracle JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
* [Maven 3.2.3](https://maven.apache.org/download.cgi)
* [Wildfly 10.1.0-Final](http://download.jboss.org/wildfly/10.1.0.Final/wildfly-10.1.0.Final.zip)

Your mileage may vary with versions different than the ones specified above.

Follow these steps to get started:

1) Git-clone this repository.

```
git clone git://github.com/damianmcdonald/ejb-clustered-timer.git my-project

```

2) Change directory into your clone:

```
cd my-project
```

3) Use Maven to compile everything:

```
mvn clean install
```

## Deploy ejb-clustered-timer

The `ejb-clustered-timer` is packaged as a Web Application (WAR file).

Deploy `ejb-clustered-timer` to the *main-server-group*.

`[domain@localhost:9990 /] deploy ~/opt/my-project/ejb-clustered-timer.war --server-groups=main-server-group`

See [Wildfly Application Deployment](https://docs.jboss.org/author/display/WFLY10/Application+deployment) for more details.
 

