public without sharing class lwc_RequestTimesheetController {
    @AuraEnabled
    public static string submitTimesheet(String listTimesheet) {

        String RSAKey = 'MIIC6DCCAdACAQAwgaIxCzAJBgNVBAYTAklEMRQwEgYDVQQIDAtES2kgSmFrYXJ0YTEUMBIGA1UEBwwLREtJIEpha2FydGExHTAbBgNVBAoMFE1pdHJhIFNvbHVzaSBJbmZva29tMQ4wDAYDVQQLDAVzZmFwaTESMBAGA1UEAwwJbXNpbmZva29tMSQwIgYJKoZIhvcNAQkBFhVtZXJpLnlhbnRpQGRhdGFvbi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQClytZtdVQ4LO8H5uzSRGMrDsuha0tM3rTUn/IaLNgxItiGb8U1tYHN9oOF2WqmmVhaQZQHdlDTt+YUYqI4lSFJfcwHSVhYpAvzyMeK+dYbSamsj7++E7FsmPltveLRoIWjPWQqb4/jZxXqblX6HKtbypyx/xgGtjvgOF+J7dm2FMSAp9TJdhXpiJUlSYtB3CDeW0XPAoMtZtr8NBrcy0p+LfNvMZc3tx2YL1qOyS1M4bdEQ7Ln6WfRXOiuo9icCVQwoJviZmOsqqYtnOYiAik1CfphvcWwPlY5LOANPsZCUXH7pbWCqy1mq4TlFHeph8AyHLBDc6x2MEVntNXXorbtAgMBAAGgADANBgkqhkiG9w0BAQsFAAOCAQEAAJYWKnYuadkOegUupUm1hf96pHlkMCb+83joBuxDR9IU2XsnK2YE5YX8k27CGAMmDZy93QrOaViaoWa0kSmiai43rwoHIDM6mZJV7dD1kowJFDzwDn2zX3/TKIfW34J/LK5wvAGVSwsMJ0pbwadQyYhAL/6oPQZOjow6eBjMWzvdjY8CN2U20nyPbMI1isq0sayPDq8AXQohUQqzUz/ed7P2k3+gCQFlAjrXVWNUM6mtwNc88Nt0HFNZgfl0kqe+qhSv2U6nAvLJZ9XEd+rUGeJY6K9m7TTTHIWoAXF4glp5NNU6KZ07V8cYDOld2kYWYiq1zAFAmgA1eq++suwvZA==';
        String jsonBody = '{"timesheet" : ' + listTimesheet + '}';
        TimesheetModel parse = TimesheetModel.parse(jsonBody.replace('pic_name', 'pic'));

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setBody(JSON.serializePretty(parse).replace('stime', 'time'));
        request.setMethod('POST');
        request.setEndpoint('' + System.label.sunfishURL_Timesheet);
        request.setHeader('content-type', 'application/json');
        request.setHeader('X-SFAPI-AppName', 'msinfokom');
        request.setHeader('X-SFAPI-Account', 'sfapi');
        request.setHeader('X-SFAPI-RSAKey', RSAKey);

        System.debug('JSON Stringfy' + jsonBody);
        System.debug('JSON Parse');
        System.debug(request.getBody());

        HttpResponse response = http.send(request);
        System.debug('Response => ' + response.getBody());
        // return '{"error_msg":"Successfully Create Timesheet", "error_code":"001" }';
        // return ''+request.getBody();
        return String.valueOf(response.getBody());

    }

    @AuraEnabled
    public static string convertEmployeeID(String RecordID, String render) {

        System.debug('Employee SFID ' + RecordID);

        try {
            list<Employee__c> employee = [
                SELECT Id, Name, Employee_ID__c FROM Employee__c WHERE Id =: RecordID LIMIT 1
            ];
            if (employee.size() > 0) {
                
                if (render == 'loadData') {
                    return String.valueOf(employee[0].Name) + ' - ' + String.valueOf(employee[0].Employee_ID__c);
                }else{
                    return String.valueOf(employee[0].Employee_ID__c);
                }

            }
        } catch (Exception e) {
            System.debug(e);
            
        }

        return 'null';

    }

    @AuraEnabled
    public static string convertProjectName(String ProjectID, String memberId) {

        String responData = 'null';

        if (ProjectID.equals('')) {
            responData = 'No Data';
        } else {
            List < Project_Member__c > projectMember = [
                SELECT Id, Name, Project__r.Name, Project__r.SPK__c
                FROM Project_Member__c
                WHERE
                Project__c =: ProjectID
                AND Project_Member__c =: memberId
                AND Project__r.Status__c != 'Completed'
                LIMIT 1
            ];

            if (projectMember.size() > 0) {

                responData = String.valueOf(projectMember[0].Project__r.Name) + ',' + String.valueOf(projectMember[0].Project__r.SPK__c);

            }else{
                List<Project__c> project = [
                    SELECT Id, Name, SPK__c
                    FROM Project__c
                    WHERE 
                    Id =: ProjectID
                    AND Status__c != 'Completed'
                    AND  (Project_Manager__c =: memberId OR Project_Admin__c =: memberId) 
                    LIMIT 1
                ];
                if(project.size() > 0){

                    responData = String.valueOf(project[0].Name) + ',' + String.valueOf(project[0].SPK__c);

                }
            }

        }
        return responData;

    }

    @AuraEnabled
    public static string convertCaseNumber(String caseId, String memberId) {

        String responseData = '400;null';

        String employeeid = convertEmployeeID(memberId, 'Apex');
        
        if(employeeid == 'null')return 'No Employee';

        if (!caseId.equals('')) {

            String queries = 'SELECT Id, CaseNumber, Project__c, Project__r.Name, Project__r.SPK__c FROM Case WHERE Id =:caseId ';

            if (employeeid != '952300') {
                queries += 'AND Assigned_To__r.Employee_ID__c =:employeeid ';
            }

            queries += 'LIMIT 1';

            List < Case > listCase = Database.query(queries);
            // Assigned_To__r.Employee_ID__c = '952300'

            if (listCase.size() > 0) {

                if (listCase[0].Project__c == null) {

                    List < Project__c > listProject = [
                        SELECT Id, SPK__c, Name
                        FROM Project__c
                        WHERE Name = 'MSInfokom - Overhead'
                        LIMIT 1
                    ];

                    responseData = '200;' + listCase[0].CaseNumber + ',' + listProject[0].Name + ',' + listProject[0].SPK__c;

                } else {

                    responseData = '200;' + listCase[0].CaseNumber + ',' + listCase[0].Project__r.Name + ',' + listCase[0].Project__r.SPK__c;

                }
            }else{
                responseData = '401;Not Assign';
            }

        }
        return responseData;

    }

    @AuraEnabled
    public static string convertPOCNumber(String pocId, String memberId) {

        String responseData = '400;null';

        if (!pocId.equals('')) {
            List < POC_Member__c > listPOCMember = [
                SELECT Id, Name, POC__r.Name
                FROM POC_Member__c
                WHERE
                POC__c =: pocId
                AND Employee__c =: memberId
                LIMIT 1
            ];

            List < Project__c > pocProject = [
                SELECT Id, Name, SPK__c FROM Project__c WHERE SPK__c = 'MSI001'
                LIMIT 1
            ];

            if (listPOCMember.size() > 0) {
                responseData = '200;' + listPOCMember[0].POC__r.Name + ',' + pocProject[0].Name + ',' + pocProject[0].SPK__c;
            }else{

                List<POC__c> listPoc = [
                    SELECT Id, Name
                    FROM POC__c
                    WHERE 
                    Id =: pocId
                    AND Project_Manager__c =: memberId
                    LIMIT 1
                ];
                if(listPoc.size() > 0){
                    responseData = '200;' + listPoc[0].Name + ',' + pocProject[0].Name + ',' + pocProject[0].SPK__c;
                }else{
                    responseData = '401; not Assign to POC';
                }
            }
        }

        return responseData;

    }
}