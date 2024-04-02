/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 22:28:07
 * @modify date 2024-03-30 16:34:28
 * @desc [add Assert ]
 */
@isTest
private class Test_lwc_ApprovalTimesheetController {
    
    @TestSetup
    static void setup() {
        
        Employee__c approver = new Employee__c(
            Name = 'Project Manager',
            Email__c = 'approver@test.com',
            Active__c = true,
            Role__c = 'Project Manager',
            Employee_ID__c = 'E001',
            Mobile_Phone__c = '087217313',
            Timesheet_Approver__c = true
        );
        Insert approver;

        Employee__c staff = new Employee__c(
            Name = 'Employee Name',
            Email__c = 'approver@test.com',
            Employee_ID__c = 'E002',
            Active__c = true,
            Role__c = 'Engineer',
            Mobile_Phone__c = '087217313',
            Timesheet_User__c = true
        );
        Insert staff;

        Employee__c PM_Admin = new Employee__c(
            Name = 'Project Admin',
            Email__c = 'approver@test.com',
            Employee_ID__c = 'E003',
            Active__c = true,
            Role__c = 'Project Admin',
            Mobile_Phone__c = '087217313',
            Timesheet_User__c = true
        );
        Insert PM_Admin;

        Project__c project = new Project__c(
            Name = 'Test Project',
            SPK__c = '12345',
            Status__c = 'Planned',
            Project_Manager__c = approver.Id,
            Project_Admin__c = PM_Admin.Id
        );
        Insert Project;

        Timesheet_Approval__c timeshetApproval = new Timesheet_Approval__c(
             Approver__c = approver.Id
        );
        Insert timeshetApproval;

       
    }

    @IsTest
    static void positiveTestUnit() {
        
        Employee__c approver = [
            SELECT Id FROM  Employee__c WHERE Role__c = 'Project Manager' LIMIT 1
        ];

        Employee__c approverOptional = [
            SELECT Id FROM Employee__c WHERE Role__c = 'Project Admin' LIMIT 1
        ];

        Employee__c staff = [
             SELECT Id FROM Employee__c WHERE Role__c = 'Engineer' LIMIT 1
        ];

        Timesheet_Approval__c timesheetApprover = [
            SELECT Id, Name, Approver__c
            FROM Timesheet_Approval__c
            WHERE Approver__c =: approver.Id
            LIMIT 1
        ];

        Project__c project = [
            SELECT Id FROM Project__c LIMIT 1
        ];

        String timesheets = '[{"tempId":1711287241598,"project_name":"MSInfokom - Business Development","spk":"MSI001","ProjectId":"'+project.Id+'",'+
        '"type":"project","Approver":"'+approver.Id+'","Approver_Optional":"'+approverOptional.Id+'","start_date":"2024-03-24","end_date":"2024-03-24",'+
        '"stime":"8","temp_remark":"Test","pic_name":"960982","Email":"azis@langitkreasi.com","EmployeeID":"'+staff.Id+'","billable":"1","remark":"Project MSI001 - Test"}]';

        Test.startTest();

        lwc_ApprovalTimesheetController.ApproverName(timesheetApprover.Id);
        lwc_ApprovalTimesheetController.getProjectManager(project.Id, approver.Id);
        lwc_ApprovalTimesheetController.getProjectManager(project.Id, staff.Id);
        lwc_ApprovalTimesheetController.createMultiTimesheet(timesheets, 'waiting for Approval');

        List<Timesheet__c> countTimesheet_Waiting = [
            SELECT Id FROM Timesheet__c WHERE Approval_Status__c = 'Waiting for Approval'
        ];

        System.assert(countTimesheet_Waiting.size() > 0);

        Timesheet__c listApproval = [
            SELECT Id FROM Timesheet__c WHERE Approval_Status__c = 'Waiting for Approval'
        ];

        String updateTimesheets = '[{"recordid":"'+listApproval.Id+'","ApprovalStatus":"Fully Approved","Comment":"","ApproveBy":"'+approver.Id+'"}]';

        lwc_ApprovalTimesheetController.updateApprovalStatus(updateTimesheets);

        List<Timesheet__c> countTimesheet_Approved = [
            SELECT Id FROM Timesheet__c WHERE Approval_Status__c = 'Fully Approved'
        ];

        System.assert(countTimesheet_Approved.size() > 0);

        Test.stopTest();
    }

    @IsTest
    static void negativeTestUnit(){
        
        
        Test.startTest();
       
        Test.stopTest();
        
    }
}