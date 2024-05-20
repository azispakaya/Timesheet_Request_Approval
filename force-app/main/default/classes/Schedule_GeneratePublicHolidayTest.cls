/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-05-20 20:55:30
 * @modify date 2024-05-20 20:55:30
 * @desc [Test Class for Schedule Public Holiday]
 */

@isTest
private class Schedule_GeneratePublicHolidayTest {

    @isTest
    static void testGeneratePublicHoliday() {

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

        Employee__c AutomatedUser = new Employee__c(
            Name = 'Automated Process',
            Email__c = 'approver@test.com',
            Employee_ID__c = 'ADM101',
            Active__c = true,
            Role__c = 'Management',
            Mobile_Phone__c = '087217313',
            Timesheet_Approver__c = true
        );
        Insert AutomatedUser;

        Project__c project = new Project__c(
            Name = 'Test Project',
            SPK__c = 'MSI006',
            Status__c = 'Planned',
            Project_Manager__c = approver.Id,
            Project_Admin__c = PM_Admin.Id
        );
        Insert Project;

        Timesheet__c ts = new Timesheet__c(
            Project__c = project.Id,
            Approval_Status__c = 'Fully Approved',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today(),
            Remarks__c = 'Test Remarks',
            Timesheet_Approver__c = approver.Id,
            Timesheet_Approver_Optional__c = PM_Admin.Id,
            Employee__c = staff.Id,
            Time__c = '8'
        );
        
        Insert ts;

        Integer countHoliday = [
            SELECT COUNT() FROM Holiday WHERE ActivityDate = TODAY
        ];
        System.debug('Check Holiday '+countHoliday);

        Schedule_GeneratePublicHoliday st = new Schedule_GeneratePublicHoliday();

        Test.startTest();

        st.execute(null);

        Test.stopTest();
    }
}