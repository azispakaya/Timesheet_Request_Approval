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
            SELECT Id, Employee_ID__c, Name, Email__c
            FROM Employee__c
            WHERE Active__c = true AND Timesheet_User__c = true
            
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Employee__c> scope) {
        List<Holiday> listHoliday = [
            SELECT Id, Name, ActivityDate 
            FROM Holiday
            WHERE ActivityDate = :System.Date()
        ];
        
        if(listHoliday.size() > 0){
            for(Employee__c singleEmployee : scope){
                
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

}