List<Employee__c> listEmployee = [
	SELECT Id, Name, Timesheet_User__c, Timesheet_Approver__c FROM Employee__c 
	WHERE 
    (Role__c = 'Project Manager' OR Role__c = 'Project Admin' OR Role__c = 'Engineer' OR Role__c = 'Management') 
    AND Active__c = true AND Grade__c !=  null
];

for(Employee__c singleEmployee : listEmployee){
    singleEmployee.Timesheet_Approver__c = true;
}
Database.update(listEmployee);