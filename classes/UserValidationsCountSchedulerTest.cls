@isTest
private class UserValidationsCountSchedulerTest {

    @isTest static void testScheduler() {
       
        Test.startTest();
        String jobId = System.schedule('Schedule Count', UserValidationsCountScheduler.CRON_EXP, new UserValidationsCountScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(UserValidationsCountScheduler.CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT count() FROM CronTrigger WHERE id = :jobId],
        'The job should have beeen scheduled');
        
       
    }
}