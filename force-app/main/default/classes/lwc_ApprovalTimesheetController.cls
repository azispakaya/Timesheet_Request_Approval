/**
 * @author [AcekBecek]
 * @desc Controller for Approval + Create Timesheets (Wrapper-based)
 */
global with sharing class lwc_ApprovalTimesheetController {
  // =========================
  // ApproverName (now wrapper)
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper ApproverName(
    Id recordPageId
  ) {
    try {
      if (recordPageId == null) {
        return TimesheetResponseModels.ResponseWrapper.fail(
          'INVALID_INPUT',
          'Record Id is required.'
        );
      }

      List<Timesheet_Approval__c> approvals = [
        SELECT Id, Approver__c, Approver__r.Name
        FROM Timesheet_Approval__c
        WHERE Id = :recordPageId
        LIMIT 1
      ];

      TimesheetResponseModels.ApproverInfo approverInfo = new TimesheetResponseModels.ApproverInfo();

      if (!approvals.isEmpty()) {
        approverInfo.name = approvals[0].Approver__r.Name;
        approverInfo.id = approvals[0].Approver__c;
        return TimesheetResponseModels.ResponseWrapper.ok(
          approverInfo,
          'Approver loaded.'
        );
      }

      List<Employee__c> employees = [
        SELECT Id, Name
        FROM Employee__c
        WHERE Id = :recordPageId
        LIMIT 1
      ];

      if (employees.isEmpty()) {
        return TimesheetResponseModels.ResponseWrapper.fail(
          'NOT_FOUND',
          'Employee not found.'
        );
      }

      approverInfo.name = employees[0].Name;
      approverInfo.id = employees[0].Id;
      return TimesheetResponseModels.ResponseWrapper.ok(
        approverInfo,
        'Employee loaded.'
      );
    } catch (Exception exceptionmsg) {
      return TimesheetResponseModels.ResponseWrapper.fail(
        'SERVER_ERROR',
        exceptionmsg.getMessage()
      );
    }
  }

  // =========================
  // Update Approval Status (now wrapper)
  // =========================
  public class TimesheetApprovalUpdateRow {
    public String recordid;
    public String ApprovalStatus;
    public String Comment;
    public String ApproveBy;
  }

  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper updateApprovalStatus(
    String Timesheets
  ) {
    try {
      if (String.isBlank(Timesheets)) {
        return TimesheetResponseModels.ResponseWrapper.fail(
          'INVALID_INPUT',
          'Timesheets payload is empty.'
        );
      }

      List<TimesheetApprovalUpdateRow> updateRows = (List<TimesheetApprovalUpdateRow>) JSON.deserialize(
        Timesheets,
        List<TimesheetApprovalUpdateRow>.class
      );

      List<Timesheet__c> timesheetsToUpdate = new List<Timesheet__c>();

      for (TimesheetApprovalUpdateRow row : updateRows) {
        timesheetsToUpdate.add(
          new Timesheet__c(
            Id = row.recordid,
            Approval_Status__c = row.ApprovalStatus,
            Comment__c = row.Comment,
            Action_By__c = row.ApproveBy,
            Action_Date__c = Date.today()
          )
        );
      }

      Database.update(timesheetsToUpdate);

      Map<String, Object> payload = new Map<String, Object>{
        'updatedCount' => timesheetsToUpdate.size()
      };

      return TimesheetResponseModels.ResponseWrapper.ok(
        payload,
        'Approval statuses updated.'
      );
    } catch (Exception exceptionmsg) {
      return TimesheetResponseModels.ResponseWrapper.fail(
        'SERVER_ERROR',
        exceptionmsg.getMessage()
      );
    }
  }

  // =========================
  // Public: Get Project Manager (now wrapper)
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper getProjectManager(
    Id ProjectId,
    Id EmployeeID
  ) {
    try {
      TimesheetResponseModels.ApproverPair pair = resolveApproverIds(
        ProjectId,
        EmployeeID
      );
      return TimesheetResponseModels.ResponseWrapper.ok(
        pair,
        'Approver resolved.'
      );
    } catch (Exception exceptionmsg) {
      return TimesheetResponseModels.ResponseWrapper.fail(
        'SERVER_ERROR',
        exceptionmsg.getMessage()
      );
    }
  }

  // =========================
  // Helper: Resolve Approvers (Option A core)
  // =========================
  public static TimesheetResponseModels.ApproverPair resolveApproverIds(
    Id projectId,
    Id employeeId
  ) {
    if (projectId == null || employeeId == null) {
      TimesheetResponseModels.ApproverPair emptyPair = new TimesheetResponseModels.ApproverPair();
      emptyPair.approverId = null;
      emptyPair.approverOptionalId = null;
      return emptyPair;
    }

    List<Project__c> projects = [
      SELECT Id, Project_Manager__c, Project_Admin__c
      FROM Project__c
      WHERE Id = :projectId
      LIMIT 1
    ];

    List<Employee__c> employees = [
      SELECT Id, Supervisorr__c, Manager__c, Timesheet_Approver__c
      FROM Employee__c
      WHERE Id = :employeeId
      LIMIT 1
    ];

    TimesheetResponseModels.ApproverPair approverPair = new TimesheetResponseModels.ApproverPair();

    if (projects.isEmpty() || employees.isEmpty()) {
      approverPair.approverId = null;
      approverPair.approverOptionalId = null;
      return approverPair;
    }

    Project__c projectRecord = projects[0];
    Employee__c employeeRecord = employees[0];

    // Original logic preserved:
    // If project manager null OR employee is special timesheet approver => use employee manager/supervisor
    if (
      projectRecord.Project_Manager__c == null ||
      employeeRecord.Timesheet_Approver__c
    ) {
      approverPair.approverId = employeeRecord.Manager__c;
      approverPair.approverOptionalId = employeeRecord.Supervisorr__c;
      return approverPair;
    }

    approverPair.approverId = projectRecord.Project_Manager__c;
    approverPair.approverOptionalId = projectRecord.Project_Admin__c;
    return approverPair;
  }

  // =========================
  // Create Timesheet (now wrapper)
  // =========================
  public class TimesheetCreateRowIncoming {
    public String ProjectId;
    public String Approver;
    public String start_date;
    public String end_date;
    public String stime;
    public String EmployeeID;
    public String remark;
    public String Approver_Optional;
    public String Email;
    public String type;
    public String ObjectRecordId;
  }

  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper createMultiTimesheet(
    String Timesheet,
    String ApprovalStatus
  ) {
    try {
      if (String.isBlank(Timesheet)) {
        return TimesheetResponseModels.ResponseWrapper.fail(
          'INVALID_INPUT',
          'Timesheet payload is empty.'
        );
      }
      if (String.isBlank(ApprovalStatus)) {
        return TimesheetResponseModels.ResponseWrapper.fail(
          'INVALID_INPUT',
          'ApprovalStatus is required.'
        );
      }

      List<TimesheetCreateRowIncoming> incomingRows = (List<TimesheetCreateRowIncoming>) JSON.deserialize(
        Timesheet,
        List<TimesheetCreateRowIncoming>.class
      );

      List<Timesheet__c> timesheetsToInsert = new List<Timesheet__c>();
      TimesheetResponseModels.CreateTimesheetResult createResult = new TimesheetResponseModels.CreateTimesheetResult();

      Id resolvedEmployeeId;

      for (TimesheetCreateRowIncoming incomingRow : incomingRows) {
        resolvedEmployeeId = (Id) incomingRow.EmployeeID;

        Timesheet__c timesheetRecord = new Timesheet__c(
          Project__c = (Id) incomingRow.ProjectId,
          Timesheet_Approver__c = (Id) incomingRow.Approver,
          Employee__c = (Id) incomingRow.EmployeeID,
          Start_Date__c = Date.valueOf(incomingRow.start_date),
          End_Date__c = Date.valueOf(incomingRow.end_date),
          Time__c = incomingRow.stime,
          Remarks__c = incomingRow.remark,
          Approval_Status__c = ApprovalStatus,
          Timesheet_Approver_Optional__c = (Id) incomingRow.Approver_Optional,
          Email__c = incomingRow.Email
        );

        // Map object record id by type
        if (incomingRow.type == 'opty') {
          timesheetRecord.Opportunity__c = (Id) incomingRow.ObjectRecordId;
        } else if (incomingRow.type == 'case') {
          timesheetRecord.Case__c = (Id) incomingRow.ObjectRecordId;
        } else if (incomingRow.type == 'poc') {
          timesheetRecord.POC__c = (Id) incomingRow.ObjectRecordId;
        } else if (incomingRow.type == 'campaign') {
          timesheetRecord.Campaign__c = (Id) incomingRow.ObjectRecordId;
        }

        timesheetsToInsert.add(timesheetRecord);
      }

      // Keep original behavior (update employee record without changes – likely to trigger automation)
      if (resolvedEmployeeId != null) {
        Employee__c employeeToTouch = new Employee__c(Id = resolvedEmployeeId);
        Database.update(employeeToTouch);
      }

      Database.insert(timesheetsToInsert);

      for (Timesheet__c insertedRecord : timesheetsToInsert) {
        createResult.createdIds.add(insertedRecord.Id);
      }
      createResult.createdCount = timesheetsToInsert.size();

      return TimesheetResponseModels.ResponseWrapper.ok(
        createResult,
        'Successfully Create Timesheet'
      );
    } catch (Exception exceptionMsg) {
      return TimesheetResponseModels.ResponseWrapper.fail(
        'SERVER_ERROR',
        exceptionMsg.getMessage()
      );
    }
  }
}
