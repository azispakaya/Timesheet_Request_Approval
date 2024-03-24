/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:46:50
 * @modify date 2024-03-24 15:46:50
 * @desc [Controller for List Approval and Action]
 */


global with sharing class lwc_ApprovalTimesheetController {
   
    @AuraEnabled
    public static string ApproverName(Id recordPageId){
        try {
            List<Timesheet_Approval__c>  timesheetApprovals = [
                SELECT Id, Approver__r.Name 
                FROM Timesheet_Approval__c 
                WHERE Id = : recordPageId limit 1
                ];
            
            return timesheetApprovals[0].Approver__r.Name+';'+timesheetApprovals[0].Approver__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class timesheetWrapper{
        public string recordid;
        public string ApprovalStatus;
        public string Comment;
        public string ApproveBy;
    }

    @AuraEnabled
    public static string updateApprovalStatus(String Timesheets){
        try {

            List<Timesheet__c> obj_timesheets = new List<Timesheet__c>();
            List<timesheetWrapper> listTimesheet = (List<timesheetWrapper>)JSON.deserialize(Timesheets,List<timesheetWrapper>.class);

            for (timesheetWrapper singleTimesheet : listTimesheet) {
                obj_timesheets.add(new Timesheet__c(
                    Id = singleTimesheet.recordid, 
                    Approval_Status__c = singleTimesheet.ApprovalStatus,
                    Comment__c = singleTimesheet.Comment,
                    Action_By__c = singleTimesheet.ApproveBy,
                    Action_Date__c = Date.today()

                    ));
            }

            Database.update(obj_timesheets);

            return '200';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getProjectManager(Id ProjectId, Id EmployeeID){
        try {
            
            List<Project__c> listProject = [
                SELECT Id, Project_Manager__c, Project_Admin__c
                FROM Project__c
                WHERE Id = : ProjectId limit 1
                
            ];

            List<Employee__c> listEmployee = [
                    SELECT Id, Name, Supervisor__c, Manager__c, Timesheet_User__c
                    FROM Employee__c
                    WHERE Id =:EmployeeID
                    LIMIT 1
            ];
                
            if (listProject[0].Project_Manager__c == null || listEmployee[0].Timesheet_Approver__c) {

                return listEmployee[0].Manager__c+';'+listEmployee[0].Supervisorr__c;

            }
            return listProject[0].Project_Manager__c+';'+listProject[0].Project_Admin__c;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class mapTimesheetRecord{
        public string ProjectId;
        public string Approver;
        public string start_date;
        public string end_date;
        public string stime;
        public string EmployeeID;
        public string remark;
        public string Approver_Optional;
        public string Email;
    }

    @AuraEnabled
    public static string createMultiTimesheet(String Timesheet, String ApprovalStatus){
        try {
            List<Timesheet__c> createTimesheet = new List<Timesheet__c>();

            List<mapTimesheetRecord> timesheetList = (List<mapTimesheetRecord>)JSON.deserialize(Timesheet,List<mapTimesheetRecord>.class);

            for(mapTimesheetRecord singleTimesheet : timesheetList){

                createTimesheet.add(new Timesheet__c(
                    Project__c = singleTimesheet.ProjectId,
                    Timesheet_Approver__c = singleTimesheet.Approver,
                    Employee__c = singleTimesheet.EmployeeID,
                    Start_Date__c = Date.valueOf(singleTimesheet.start_date),
                    End_Date__c = Date.valueOf(singleTimesheet.end_date),
                    Time__c = singleTimesheet.stime,
                    Remarks__c = singleTimesheet.remark,
                    Approval_Status__c = ApprovalStatus,
                    Timesheet_Approver_Optional__c = singleTimesheet.Approver_Optional,
                    Email__c = singleTimesheet.Email
                ));
            }

            Database.insert(createTimesheet);

            return '{"error_msg":"Successfully Create Timesheet", "error_code":"000" }';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    

}