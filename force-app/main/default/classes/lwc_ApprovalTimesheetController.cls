global with sharing class lwc_ApprovalTimesheetController {
   
    @AuraEnabled
    public static string ApproverName(Id recordPageId){
        try {
            List<Timesheet_Approval__c>  timesheetApprovals = [
                SELECT Id, Approver__r.Name 
                FROM Timesheet_Approval__c 
                WHERE Id = : recordPageId limit 1
                ];
            
            return timesheetApprovals[0].Approver__r.Name;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}