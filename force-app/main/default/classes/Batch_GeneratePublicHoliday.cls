/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-05-20 10:02:29
 * @modify date 2024-05-20 10:02:29
 * @desc [Generate Timesheet Public Holiday for All Timesheet Users]
 * @test class [Schedule_GeneratePublicHolidayTest]
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

        Employee__c AutomatedUser = [
            SELECT Id, Name, Employee_ID__c FROM Employee__c WHERE Employee_ID__c = 'ADM101'
        ];

        List<Timesheet__c> CreateTimesheet = new List<Timesheet__c>();

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
                        Project__c = Pro_holiday.Id,
                        Approval_Status__c = 'Fully Approved',
                        Action_By__c = AutomatedUser.Id,
                        Action_Date__c = listHoliday[0].ActivityDate
                    )
                );
            }
            Database.insert(CreateTimesheet);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

}