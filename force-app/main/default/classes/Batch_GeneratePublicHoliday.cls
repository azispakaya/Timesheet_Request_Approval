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
            WHERE ActivityDate = :System.today()
        ];

        Project__c Pro_holiday = [
            SELECT Id, SPK__c FROM Project__c WHERE SPK__c ='MSI006' LIMIT 1
        ];
        List<Timesheet__c> CreateTimesheet;

        if(listHoliday.size() > 0){
            for(Employee__c singleEmployee : scope){
                CreateTimesheet.add(
                    new Timesheet__c(
                        Employee__c = singleEmployee.Id,
                        Email__c = singleEmployee.Email__c,
                        Start_Date__c = listHoliday[0].ActivityDate,
                        End_Date__c = listHoliday[0].ActivityDate,
                        Time__c = '8',
                        Remarks__c = 'Public Holiday - '+listHoliday[0].Name,
                        Project__c = Pro_holiday.Id
                    )
                );
            }
            Database.insert(CreateTimesheet);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

}