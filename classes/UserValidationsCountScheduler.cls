global class UserValidationsCountScheduler implements Schedulable {

    public static String CRON_EXP = '0 0 0 * * ?';
    global void execute(SchedulableContext SC) {
        BatchUserValidationsCount validationCount = new BatchUserValidationsCount();
        database.executeBatch(validationCount);
    }
 
}