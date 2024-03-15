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

    public class timesheetWrapper{
        public string recordid;
        public string ApprovalStatus;
    }

    @AuraEnabled
    public static string updateApprovalStatus(String Timesheets){
        try {

            List<Timesheet__c> obj_timesheets = new List<Timesheet__c>();
            List<timesheetWrapper> listTimesheet = (List<timesheetWrapper>)JSON.deserialize(Timesheets,List<timesheetWrapper>.class);

            for (timesheetWrapper singleTimesheet : listTimesheet) {
                obj_timesheets.add(new Timesheet__c(
                    Id = singleTimesheet.recordid, 
                    Approval_Status__c = singleTimesheet.ApprovalStatus
                    ));
            }

            Database.update(obj_timesheets);

            return ''+obj_timesheets;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    

}