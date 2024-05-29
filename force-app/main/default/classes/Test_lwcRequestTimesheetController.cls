/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-26 18:00:47
 * @modify date 2024-05-29 09:13:34
 * @LastModify [Adding test Method for ConvertOpportunity]
 */
@isTest
private class Test_lwcRequestTimesheetController {

    @IsTest
    static void positiveUnitTest(){

        Employee__c employee = new Employee__c(
            Employee_ID__c = '12345',
            Name = 'Test Acek Employee',
            Email__c = 'test@gmail.com',
            Role__c = 'Project Manager',
            Active__c = true,
            Department__c = 'Operation',
            Grade__c = 'TL8',
            Unit__c = 'Project - Wireless'
        );
        Insert employee;

        Employee__c engineerRole = new Employee__c(
            Employee_ID__c = '12346',
            Name = 'Test Acek Engineer',
            Email__c = 'test@gmail.com',
            Role__c = 'Engineer',
            Active__c = true,
            Department__c = 'Operation',
            Grade__c = 'TL8',
            Unit__c = 'Project - Wireless'
        );
        Insert engineerRole;

        Employee__c PM_Admin = new Employee__c(
            Employee_ID__c = '952300',
            Name = 'Test Admin',
            Email__c = 'test@gmail.com',
            Role__c = 'Project Admin',
            Active__c = true,
            Department__c = 'Operation',
            Grade__c = 'STF4',
            Unit__c = 'Project - Wireless'
        ) ;
        Insert PM_Admin;

        Account account = new Account(
            Name = 'Test Account'
        );
        Insert account;

        Contact contact = new Contact(
            LastName = 'Contact Name',
            AccountId = account.Id,
            Email = 'contact.name@example.com',
            MobilePhone = '0876712931'
        );
        Insert contact;

        Project__c project = new Project__c(
            Name = 'Test Project',
            SPK__c = '098722',
            Project_Manager__c = employee.Id,
            Product_Category__c = 'Application',
            Status__c = 'Planned'
        );
        Insert project;

        Project__c projectPOC = new Project__c(
            Name = 'MSInfokom - Business Development',
            SPK__c = 'MSI001',
            Project_Manager__c = employee.Id,
            Product_Category__c = 'Application',
            Status__c = 'Planned'
        );
        Insert projectPOC;

        Project__c projectOverhead = new Project__c(
            Name = 'MSInfokom - Overhead',
            SPK__c = 'MSI002',
            Project_Manager__c = employee.Id,
            Product_Category__c = 'Application',
            Status__c = 'Planned'
        );
        Insert projectOverhead;

        Project_Member__c projectMember = new Project_Member__c(
            Project_Member__c = engineerRole.Id,
            Project__c = project.Id,
            Email__c = 'test@sample.co'
        );
        Insert projectMember;

        Case caseObject_withProject = new Case(
            Subject = 'Case for Project Sample',
            Description = 'Test Case Description',
            AccountId = account.Id,
            ContactId = contact.Id,
            Origin = 'Web',
            Assigned_To__c = PM_Admin.Id,
            Project__c = project.Id
        );
        Insert caseObject_withProject;

        Case caseObject_withoutProject = new Case(
            Subject = 'Case not Using Test Project',
            Description = 'Test Case Description',
            AccountId = account.Id,
            ContactId = contact.Id,
            Origin = 'Web',
            Assigned_To__c = PM_Admin.Id
        );
        Insert caseObject_withoutProject;

        POC__c poc = new POC__c(
            POC_Name__c = 'Test POC Name',
            Account__c = account.Id,
            POC_Status__c = 'Planned',
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Project_Manager__c = employee.Id
        );
        Insert poc;

        POC_Member__c pocMember = new POC_Member__c(
            Employee__c = engineerRole.Id,
            POC__c = poc.Id
        );
        Insert pocMember;

        Opportunity opty = new Opportunity(
            Name = 'Test Opportunty',
            CloseDate = System.today(),
            StageName = 'Gathering Requirements',
            AccountId = account.Id
        );
        Insert opty;

        Employee__c presales = new Employee__c(
            Employee_ID__c = '12346',
            Name = 'Test Acek Prsales',
            Email__c = 'test@gmail.com',
            Role__c = 'Presales',
            Active__c = true,
            Department__c = 'Presales',
            Grade__c = 'TL8',
            Unit__c = 'Project - Wireless'
        );
        Insert presales;

        Opportunity_Divide__c optyDivide = new Opportunity_Divide__c(
            Role__c = 'Presales',
            Name__c = presales.Id,
            Opportunity__c = opty.Id
        );
        Insert optyDivide;
        
        //! Define Test Data
        Project__c projectObject = [
            SELECT Id, SPK__c FROM Project__c WHERE SPK__c != 'MSI001' LIMIT 1
        ];

        Case caseObject = [
            SELECT Id, CaseNumber, Assigned_To__c FROM Case WHERE Project__c != null LIMIT 1
        ];

        Case caseObject_noProject = [
            SELECT Id, CaseNumber, Assigned_To__c FROM Case WHERE Project__c = null LIMIT 1
        ];

        POC__c pocObject = [
            SELECT Id FROM POC__c LIMIT 1
        ];

        Employee__c pm = [
            SELECT Id FROM Employee__c WHERE Role__c ='Project Manager' LIMIT 1
        ];

        Employee__c engineer = [
            SELECT Id FROM Employee__c WHERE Role__c ='Engineer' LIMIT 1
        ];

        Employee__c presalesEmp = [
            SELECT Id FROM Employee__c WHERE Role__c = 'Presales' LIMIT 1
        ];

        Opportunity optyList = [
            SELECT Id FROM Opportunity LIMIT 1
        ];

        String listTimesheet = '[{"tempId":1707657464743,"project_name":"Test Project","spk":"MSI-LKS","type":"project","start_date":"2024-02-09","end_date":"2024-02-09","stime":"8","temp_remark":"Test","pic_name":"981901","billable":"1","remark":"MSI-LKS - Test"}]';

        Test.startTest();

        //! Test Get Data
        // * convert Employee SFID to EmployeeId
        lwc_RequestTimesheetController.convertEmployeeID(pm.Id, 'loadData');
        lwc_RequestTimesheetController.convertEmployeeID(pm.Id, 'submit');

        // * Checking Project Member based on Employee 
        lwc_RequestTimesheetController.convertProjectName(projectObject.Id, pm.Id);
        lwc_RequestTimesheetController.convertProjectName(projectObject.Id, engineer.Id);
        lwc_RequestTimesheetController.convertProjectName('', pm.Id);
        lwc_RequestTimesheetController.convertProjectName(projectObject.Id, '');

        // * checking Case Assigned based on Employee
        lwc_RequestTimesheetController.convertCaseNumber(caseObject.Id, caseObject.Assigned_To__c);
        lwc_RequestTimesheetController.convertCaseNumber(caseObject.Id, '');
        lwc_RequestTimesheetController.convertCaseNumber(caseObject_noProject.Id, caseObject_noProject.Assigned_To__c);

        // * checking POC Members Based on Employee
        lwc_RequestTimesheetController.convertPOCNumber(pocObject.Id, engineer.Id);
        lwc_RequestTimesheetController.convertPOCNumber(pocObject.Id, pm.Id);

        // * Checking Opportunity Based on Opportunity
        lwc_RequestTimesheetController.convertOpportuniyId(optyList.Id, presalesEmp.Id);


        Test.setMock(HttpCalloutMock.class, new Mock_Timesheetv2());
        lwc_RequestTimesheetController.submitTimesheet(listTimesheet);

        Test.stopTest();
        
    }

}