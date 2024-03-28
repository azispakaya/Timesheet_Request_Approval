/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:42:28
 * @modify date 2024-03-24 15:42:28
 * @desc [Schedule Controller for Timesheet batch]
 */
global class Schedule_TimesheetRequest implements Schedulable {
    
    public void execute(SchedulableContext sc){

        if(Date.today().day() == 25){
            updateApprovalStatus(25);
        }
        

        Batch_TimesheetRequest batch = new Batch_TimesheetRequest();
        ID batchprocessid = Database.executeBatch(batch, 200);

    }

    public static List<Database.SaveResult> updateApprovalStatus(Integer days){

        List<Timesheet__c> listTimesheet = [
            SELECT 
                Id, Approval_Status__c, Auto_Approve__c
            FROM Timesheet__c
            WHERE 
                Day_of_Creation__c =: days AND Approval_Status__c = 'Waiting for Approval'
        ];

        if(listTimesheet.size() == 0 ){
            return null;
        }

        for(Timesheet__c ts : listTimesheet){
            ts.Approval_Status__c = 'Fully Approved';
            ts.Auto_Approve__c = true;
        }

        Database.SaveResult[] listResult = Database.update(listTimesheet, false);

        return listResult;
    }

}