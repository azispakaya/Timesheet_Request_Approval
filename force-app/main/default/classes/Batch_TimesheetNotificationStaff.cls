/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-04-04 13:32:31
 * @modify date 2024-04-04 13:32:31
 * @desc [Notification sending Summary Report Timesheet for each employee]
 */
 global class Batch_TimesheetNotificationStaff implements Database.Batchable<sObject>{
    
    public Batch_TimesheetNotificationStaff() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id, Employee_ID__c, Name, Email__c
            FROM Employee__c
            WHERE Active__c = true AND Timesheet_User__c = true
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Employee__c> scope){
        for(Employee__c singleEmployee : scope){
            
            Integer sumApproved = [
                SELECT COUNT() FROM Timesheet__c
                WHERE Action_Date__c =: Date.today() AND Approval_Status__c = 'Fully Approved'
            ];

            Integer sumReject = [
                SELECT COUNT() FROM Timesheet__c
                WHERE Action_Date__c =: Date.today() AND Approval_Status__c = 'Rejected'
            ];

            Integer sumRevise = [
                SELECT COUNT() FROM Timesheet__c
                WHERE Approval_Status__c = 'Need to Revise'
            ];

            String subject = 'Timesheet - '+String.valueOf(Date.today())+ ' : '+String.valueOf(sumApproved)+'/'+String.valueOf(sumReject)+'/'+String.valueOf(sumRevise)+' Timesheets Approved/Rejected/Revised';
            String Body = 'Dear ' + singleEmployee.Name + ',\n\n' +
            'I trust this email finds you well. I am writing to inform you of the status of timesheets. As of today, ' + String.valueOf(Date.today()) + ', we have processed the following timesheets:\n' +
            String.valueOf(sumApproved) + ' timesheets have been approved.\n' +
            String.valueOf(sumReject) + ' timesheets have been rejected.\n' +
            String.valueOf(sumRevise) + ' timesheets have been revised.\n' +
            'Please review the details of the approved, rejected, and revised timesheets accordingly. If you have any questions or require further clarification regarding these actions, please don\'t hesitate to reach out to us.\n' +
            'Thank you for your attention to this matter.\n\n' +
            'Best regards,\n' +
            'MSInfokom Support';
            

            SendEmailNotification.SendEmailNotificationUtils(
                singleEmployee.Email__c, 
                subject, Body
            );

        }
    }

    public void finish(Database.BatchableContext bc){

    }
}