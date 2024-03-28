@isTest
private class Schedule_TimesheetRequestTest {

    @isTest
    static void testSchedule_TimesheetRequest() {

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

        Schedule_TimesheetRequest st = new Schedule_TimesheetRequest();

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new Mock_Timesheetv2());
        st.execute(null);

        Test.stopTest();

        // System.assertEquals(1, [SELECT count() FROM AsyncApexJob WHERE ApexClass.Name = 'Batch_TimesheetRequest']);
    }

    @isTest
    public static void testUpdateApprovalStatus() {

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

        Timesheet__c ts = new Timesheet__c(
            Project__c = project.Id,
            Approval_Status__c = 'Waiting for Approval',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today(),
            Remarks__c = 'Test Timesheet Approval',
            Timesheet_Approver__c = approver.Id,
            Timesheet_Approver_Optional__c = PM_Admin.Id,
            Employee__c = staff.Id,
            Time__c = '8'
        );
        Insert ts;

        List<Database.SaveResult> listResult = Schedule_TimesheetRequest.updateApprovalStatus(Date.today().day());

        System.assertEquals(1, listResult.size(), 'Timesheet record should be updated');

        for(Database.SaveResult result : listResult) {
            System.assert(result.isSuccess(), 'The update operation should be successful');
        }
    }
}