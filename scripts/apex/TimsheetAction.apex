List<Timesheet__c> listTimesheets = [
    SELECT 
        Remarks__c, Employee__r.Name, response__c, Start_Date__c, End_Date__c
    FROM Timesheet__c
    Order By CreatedDate ASC LIMIT 770
];

Database.delete(listTimesheets);