@isTest
private class Schedule_TimesheetNotificationStaffTest {
    
    @TestSetup
    static void makeTestData() {
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
    }

    @IsTest
    static void positiveTest() {
        
        Schedule_TimesheetNotificationStaff st = new Schedule_TimesheetNotificationStaff();

        Test.startTest();

        st.execute(null);
        Test.stopTest();
    }
}