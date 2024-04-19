/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-04-04 14:27:56
 * @modify date 2024-04-18 18:10:35
 * @desc [Schedule for Timesheet Notification for Staff]
 */
global class Schedule_TimesheetNotificationStaff implements Schedulable{
    
    public void execute(SchedulableContext sc){
        Batch_TimesheetNotificationStaff batch = new Batch_TimesheetNotificationStaff();
        ID batchprocessid = Database.executeBatch(batch, 8);
    }

}