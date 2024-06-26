/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:44:17
 * @modify date 2024-04-18 17:02:38
 * @desc [Batch Method for Timesheet Request and Sync to sunfish ]
 */

global class Batch_TimesheetRequest implements Database.Batchable<sObject>,Database.AllowsCallouts{
    public Batch_TimesheetRequest() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT 
                Id, Start_Date__c, End_Date__c, Approval_Status__c, 
                Time__c, Project__r.SPK__c, Project__r.Name, 
                Employee__r.Name, Employee__r.Employee_ID__c, Remarks__c
            FROM Timesheet__c
            WHERE Approval_Status__c = 'Fully Approved' AND response__c != '000'
        ]);
     }
  
    public void execute(Database.BatchableContext bc, List<Timesheet__c> scope){
        
        String RSAKey = 'MIIC6DCCAdACAQAwgaIxCzAJBgNVBAYTAklEMRQwEgYDVQQIDAtES2kgSmFrYXJ0YTEUMBIGA1UEBwwLREtJIEpha2FydGExHTAbBgNVBAoMFE1pdHJhIFNvbHVzaSBJbmZva29tMQ4wDAYDVQQLDAVzZmFwaTESMBAGA1UEAwwJbXNpbmZva29tMSQwIgYJKoZIhvcNAQkBFhVtZXJpLnlhbnRpQGRhdGFvbi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQClytZtdVQ4LO8H5uzSRGMrDsuha0tM3rTUn/IaLNgxItiGb8U1tYHN9oOF2WqmmVhaQZQHdlDTt+YUYqI4lSFJfcwHSVhYpAvzyMeK+dYbSamsj7++E7FsmPltveLRoIWjPWQqb4/jZxXqblX6HKtbypyx/xgGtjvgOF+J7dm2FMSAp9TJdhXpiJUlSYtB3CDeW0XPAoMtZtr8NBrcy0p+LfNvMZc3tx2YL1qOyS1M4bdEQ7Ln6WfRXOiuo9icCVQwoJviZmOsqqYtnOYiAik1CfphvcWwPlY5LOANPsZCUXH7pbWCqy1mq4TlFHeph8AyHLBDc6x2MEVntNXXorbtAgMBAAGgADANBgkqhkiG9w0BAQsFAAOCAQEAAJYWKnYuadkOegUupUm1hf96pHlkMCb+83joBuxDR9IU2XsnK2YE5YX8k27CGAMmDZy93QrOaViaoWa0kSmiai43rwoHIDM6mZJV7dD1kowJFDzwDn2zX3/TKIfW34J/LK5wvAGVSwsMJ0pbwadQyYhAL/6oPQZOjow6eBjMWzvdjY8CN2U20nyPbMI1isq0sayPDq8AXQohUQqzUz/ed7P2k3+gCQFlAjrXVWNUM6mtwNc88Nt0HFNZgfl0kqe+qhSv2U6nAvLJZ9XEd+rUGeJY6K9m7TTTHIWoAXF4glp5NNU6KZ07V8cYDOld2kYWYiq1zAFAmgA1eq++suwvZA==';
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setMethod('POST');
        request.setEndpoint('' + System.label.sunfishURL_Timesheet);
        request.setHeader('content-type', 'application/json');
        request.setHeader('X-SFAPI-AppName', 'msinfokom');
        request.setHeader('X-SFAPI-Account', 'sfapi');
        request.setHeader('X-SFAPI-RSAKey', RSAKey);

        List<Timesheet__c> newTimesheet = new List<Timesheet__c>();

        for (Timesheet__c singleTimesheet : scope) {

            TimesheetModel timesheetModel = new TimesheetModel();
            TimesheetModel.cls_timesheet timesheetField = new TimesheetModel.cls_timesheet();
            List<TimesheetModel.cls_timesheet> listTimesheet = new List<TimesheetModel.cls_timesheet>();
            
            timesheetField.billable = '1';
            timesheetField.end_date = String.valueOf(singleTimesheet.End_Date__c);
            timesheetField.pic = singleTimesheet.Employee__r.Employee_ID__c;
            timesheetField.project_name = singleTimesheet.Project__r.Name;
            timesheetField.start_date = String.valueOf(singleTimesheet.Start_Date__c);
            timesheetField.remark = singleTimesheet.Remarks__c;
            timesheetField.stime = String.valueOf(singleTimesheet.Time__c);
            timesheetField.spk = singleTimesheet.Project__r.SPK__c;

            listTimesheet.add(timesheetField);            
            timesheetModel.timesheet = listTimesheet;

            request.setBody(JSON.serialize(timesheetModel).replace('stime', 'time'));
            try {
                HttpResponse res = http.send(request);
                String responseBody;

                if(res.getStatusCode() == 200){
                    Map<String, Object> mapObject = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

                    if ((String)mapObject.get('error_code') == '000') {
                        responseBody = (String)mapObject.get('error_code');
                        
                    }else{
                        responseBody = (String)mapObject.get('error_msg');
                    }
                }

                newTimesheet.add(new Timesheet__c(
                    Id = singleTimesheet.Id,
                    response__c = responseBody
                ));
            } catch(Exception e) {
                System.debug(e.getMessage());
            }
                
        }

        Database.update(newTimesheet);

        System.debug(''+request.getBody());
        
    }
  
    public void finish(Database.BatchableContext bc){

    }
}