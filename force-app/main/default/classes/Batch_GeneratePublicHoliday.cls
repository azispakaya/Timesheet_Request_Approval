/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-05-20 10:02:29
 * @modify date 2024-05-20 10:02:29
 * @desc [Generate Timesheet Public Holiday for All Timesheet Users]
 */

public class Batch_GeneratePublicHoliday implements Database.Batchable<sObject> {

    public Batch_GeneratePublicHoliday() {
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id From User
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
    }

    public void finish(Database.BatchableContext BC) {
    }

}