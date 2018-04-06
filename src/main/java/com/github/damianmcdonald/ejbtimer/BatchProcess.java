package com.github.damianmcdonald.ejbtimer;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import javax.ejb.*;
import java.util.Date;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;

@Startup
@Singleton
public class BatchProcess {

    private static final Logger LOGGER = Logger.getLogger(BatchProcess.class.getName());

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

    @Timeout
    public void execute() {
        LOGGER.log(Level.INFO, "Batch process EXECUTING on node %s and %s", new Object[]{HostName.getNodeName(), new Date().toString()});
        LOGGER.log(Level.INFO, "Batch process says: %s", generateRandomString());
        LOGGER.log(Level.INFO, "Batch process COMPLETED on node %s and %s", new Object[]{HostName.getNodeName(), new Date().toString()});
    }

    private String generateRandomString() {
        final int leftLimit = 97; // letter 'a'
        final int rightLimit = 122; // letter 'z'
        final int targetStringLength = 10;
        final Random random = new Random();
        final StringBuilder buffer = new StringBuilder(targetStringLength);
        for (int i = 0; i < targetStringLength; i++) {
            final int randomLimitedInt = leftLimit + (int)
                    (random.nextFloat() * (rightLimit - leftLimit + 1));
            buffer.append((char) randomLimitedInt);
        }
        return buffer.toString();
    }

}
