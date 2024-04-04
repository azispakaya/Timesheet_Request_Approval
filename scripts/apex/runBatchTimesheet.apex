Batch_TimesheetRequest batch = new Batch_TimesheetRequest();
ID batchprocessid = Database.executeBatch(batch, 200);

Batch_TimesheetNotificationStaff batch = new Batch_TimesheetNotificationStaff();
ID batchprocessid = Database.executeBatch(batch, 50);