public without sharing class lwc_RequestTimesheetController {
  // =========================
  // Employee Context (replacement for split convertEmployeeID)
  // Keep name convertEmployeeID to avoid breaking LWC imports
  // =========================
  @AuraEnabled(cacheable=true)
  public static TimesheetResponseModels.ResponseWrapper convertEmployeeID(
    String RecordID,
    String render
  ) {
    try {
      if (String.isBlank(RecordID)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'Employee RecordID is required.'
        );
      }

      List<Employee__c> employees = [
        SELECT Id, Name, Employee_ID__c, Email__c, Role__c
        FROM Employee__c
        WHERE Id = :RecordID
        LIMIT 1
      ];

      if (employees.isEmpty()) {
        return TimesheetResponseModels.fail('NOT_FOUND', 'Employee not found.');
      }

      Employee__c employeeRecord = employees[0];

      TimesheetResponseModels.EmployeeContext employeeContext = new TimesheetResponseModels.EmployeeContext();
      employeeContext.employeeRecordId = employeeRecord.Id;
      employeeContext.employeeName = employeeRecord.Name;
      employeeContext.employeeNumber = employeeRecord.Employee_ID__c;
      employeeContext.email = employeeRecord.Email__c;
      employeeContext.role = employeeRecord.Role__c;

      // "render" parameter retained for compatibility, but we no longer split strings.
      // LWC can use payload.role/payload.employeeName etc.
      return TimesheetResponseModels.ok(
        employeeContext,
        'Employee context loaded.'
      );
    } catch (Exception caughtException) {
      return TimesheetResponseModels.fail(
        'SERVER_ERROR',
        caughtException.getMessage()
      );
    }
  }

  // =========================
  // Convert Project
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper convertProjectName(
    String ProjectID,
    String memberId
  ) {
    try {
      if (String.isBlank(ProjectID)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'ProjectID is required.'
        );
      }
      if (String.isBlank(memberId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'memberId is required.'
        );
      }

      String responseProjectName;
      String responseSpk;
      Id responseProjectId;

      List<Project_Member__c> projectMembers = [
        SELECT Id, Project__r.Name, Project__r.SPK__c, Project__c
        FROM Project_Member__c
        WHERE
          Project__c = :ProjectID
          AND Project_Member__c = :memberId
          AND Project__r.Status__c != 'Completed'
        LIMIT 1
      ];

      if (!projectMembers.isEmpty()) {
        responseProjectName = String.valueOf(projectMembers[0].Project__r.Name)
          .replace(',', '');
        responseSpk = String.valueOf(projectMembers[0].Project__r.SPK__c);
        responseProjectId = projectMembers[0].Project__c;
      } else {
        List<Project__c> projects = [
          SELECT Id, Name, SPK__c
          FROM Project__c
          WHERE
            Id = :ProjectID
            AND Status__c != 'Completed'
            AND (Project_Manager__c = :memberId
            OR Project_Admin__c = :memberId)
          LIMIT 1
        ];

        if (projects.isEmpty()) {
          return TimesheetResponseModels.fail(
            'NOT_ASSIGNED',
            'You are not assigned to this project, or the project has been closed.'
          );
        }

        responseProjectName = String.valueOf(projects[0].Name).replace(',', '');
        responseSpk = String.valueOf(projects[0].SPK__c);
        responseProjectId = projects[0].Id;
      }

      TimesheetResponseModels.TimesheetLookupResult lookupResult = new TimesheetResponseModels.TimesheetLookupResult();
      lookupResult.entryType = 'project';
      lookupResult.objectRecordId = (Id) ProjectID;
      lookupResult.objectLabel = responseProjectName;
      lookupResult.projectId = responseProjectId;
      lookupResult.projectName = responseProjectName;
      lookupResult.spk = responseSpk;

      TimesheetResponseModels.ApproverPair approverPair = lwc_ApprovalTimesheetController.resolveApproverIds(
        responseProjectId,
        (Id) memberId,
        'project'
      );

      lookupResult.approverId = approverPair.approverId;
      lookupResult.approverOptionalId = approverPair.approverOptionalId;

      return TimesheetResponseModels.ok(lookupResult, 'Project resolved.');
    } catch (Exception caughtException) {
      return TimesheetResponseModels.fail(
        'SERVER_ERROR',
        caughtException.getMessage()
      );
    }
  }

  // =========================
  // Convert Case
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper convertCaseNumber(
    String caseId,
    String memberId
  ) {
    try {
      if (String.isBlank(caseId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'caseId is required.'
        );
      }
      if (String.isBlank(memberId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'memberId is required.'
        );
      }

      Employee__c employeeRecord = [
        SELECT Id, Employee_ID__c
        FROM Employee__c
        WHERE Id = :memberId
        LIMIT 1
      ];

      if (
        employeeRecord == null || String.isBlank(employeeRecord.Employee_ID__c)
      ) {
        return TimesheetResponseModels.fail('NOT_FOUND', 'Employee not found.');
      }

      String employeeNumber = employeeRecord.Employee_ID__c;

      List<Case_Escalation_History__c> caseEscalations = [
        SELECT Id, Case__c
        FROM Case_Escalation_History__c
        WHERE
          Case__c = :caseId
          AND From_Engineer__r.Employee_ID__c = :employeeNumber
        LIMIT 1
      ];

      String dynamicQuery =
        'SELECT Id, CaseNumber, Project__c, Project__r.Name, Project__r.SPK__c ' +
        'FROM Case WHERE Id = :caseId ';

      if (caseEscalations.isEmpty()) {
        dynamicQuery += 'AND Assigned_To__r.Employee_ID__c = :employeeNumber ';
      }

      dynamicQuery += 'LIMIT 1';

      List<Case> cases = Database.query(dynamicQuery);
      if (cases.isEmpty()) {
        return TimesheetResponseModels.fail(
          'NOT_ASSIGNED',
          'You are not assigned to this Case.'
        );
      }

      Case caseRecord = cases[0];

      Id resolvedProjectId;
      String resolvedProjectName;
      String resolvedSpk;

      if (caseRecord.Project__c == null) {
        List<Project__c> overheadProjects = [
          SELECT Id, SPK__c, Name
          FROM Project__c
          WHERE Name = 'MSInfokom - Overhead'
          LIMIT 1
        ];
        if (overheadProjects.isEmpty()) {
          return TimesheetResponseModels.fail(
            'NOT_FOUND',
            'Overhead project not found.'
          );
        }
        resolvedProjectId = overheadProjects[0].Id;
        resolvedProjectName = overheadProjects[0].Name;
        resolvedSpk = overheadProjects[0].SPK__c;
      } else {
        resolvedProjectId = caseRecord.Project__c;
        resolvedProjectName = caseRecord.Project__r.Name;
        resolvedSpk = caseRecord.Project__r.SPK__c;
      }

      TimesheetResponseModels.TimesheetLookupResult lookupResult = new TimesheetResponseModels.TimesheetLookupResult();
      lookupResult.entryType = 'case';
      lookupResult.objectRecordId = (Id) caseId;
      lookupResult.objectLabel = caseRecord.CaseNumber;
      lookupResult.projectId = resolvedProjectId;
      lookupResult.projectName = resolvedProjectName;
      lookupResult.spk = resolvedSpk;

      TimesheetResponseModels.ApproverPair approverPair = lwc_ApprovalTimesheetController.resolveApproverIds(
        resolvedProjectId,
        (Id) memberId,
        'case'
      );

      lookupResult.approverId = approverPair.approverId;
      lookupResult.approverOptionalId = approverPair.approverOptionalId;

      return TimesheetResponseModels.ok(lookupResult, 'Case resolved.');
    } catch (Exception caughtException) {
      return TimesheetResponseModels.fail(
        'SERVER_ERROR',
        caughtException.getMessage()
      );
    }
  }

  // =========================
  // Convert POC
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper convertPOCNumber(
    String pocId,
    String memberId
  ) {
    try {
      if (String.isBlank(pocId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'pocId is required.'
        );
      }
      if (String.isBlank(memberId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'memberId is required.'
        );
      }

      List<Project__c> pocProjects = [
        SELECT Id, Name, SPK__c
        FROM Project__c
        WHERE SPK__c = 'MSI001'
        LIMIT 1
      ];
      if (pocProjects.isEmpty()) {
        return TimesheetResponseModels.fail(
          'NOT_FOUND',
          'POC default project (MSI001) not found.'
        );
      }

      Project__c pocProject = pocProjects[0];

      List<POC_Member__c> pocMembers = [
        SELECT Id, POC__r.Name
        FROM POC_Member__c
        WHERE POC__c = :pocId AND Employee__c = :memberId
        LIMIT 1
      ];

      String pocName;

      if (!pocMembers.isEmpty()) {
        pocName = pocMembers[0].POC__r.Name;
      } else {
        List<POC__c> pocRecords = [
          SELECT Id, Name
          FROM POC__c
          WHERE
            Id = :pocId
            AND (Project_Manager__c = :memberId
            OR Presales__c = :memberId)
          LIMIT 1
        ];
        if (pocRecords.isEmpty()) {
          return TimesheetResponseModels.fail(
            'NOT_ASSIGNED',
            'You are not assigned to this POC.'
          );
        }
        pocName = pocRecords[0].Name;
      }

      TimesheetResponseModels.TimesheetLookupResult lookupResult = new TimesheetResponseModels.TimesheetLookupResult();
      lookupResult.entryType = 'poc';
      lookupResult.objectRecordId = (Id) pocId;
      lookupResult.objectLabel = pocName;
      lookupResult.projectId = pocProject.Id;
      lookupResult.projectName = pocProject.Name;
      lookupResult.spk = pocProject.SPK__c;

      TimesheetResponseModels.ApproverPair approverPair = lwc_ApprovalTimesheetController.resolveApproverIds(
        pocProject.Id,
        (Id) memberId,
        'poc'
      );

      lookupResult.approverId = approverPair.approverId;
      lookupResult.approverOptionalId = approverPair.approverOptionalId;

      return TimesheetResponseModels.ok(lookupResult, 'POC resolved.');
    } catch (Exception caughtException) {
      return TimesheetResponseModels.fail(
        'SERVER_ERROR',
        caughtException.getMessage()
      );
    }
  }

  // =========================
  // Convert Opportunity
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper convertOpportuniyId(
    String OptyID,
    String memberId
  ) {
    try {
      if (String.isBlank(OptyID)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'OptyID is required.'
        );
      }

      List<Opportunity> opportunities = [
        SELECT Id, Name, SPK__c
        FROM Opportunity
        WHERE Id = :OptyID
        LIMIT 1
      ];

      if (opportunities.isEmpty()) {
        return TimesheetResponseModels.fail(
          'NOT_FOUND',
          'Opportunity not found.'
        );
      }

      List<Project__c> businessDevelopmentProjects = [
        SELECT Id, Name, SPK__c
        FROM Project__c
        WHERE SPK__c = 'MSI001'
        LIMIT 1
      ];
      if (businessDevelopmentProjects.isEmpty()) {
        return TimesheetResponseModels.fail(
          'NOT_FOUND',
          'Default project (MSI001) not found.'
        );
      }

      Opportunity opportunityRecord = opportunities[0];
      Project__c businessDevelopmentProject = businessDevelopmentProjects[0];

      TimesheetResponseModels.TimesheetLookupResult lookupResult = new TimesheetResponseModels.TimesheetLookupResult();
      lookupResult.entryType = 'opty';
      lookupResult.objectRecordId = (Id) OptyID;
      lookupResult.objectLabel = opportunityRecord.Name;
      lookupResult.projectId = businessDevelopmentProject.Id;
      lookupResult.projectName = businessDevelopmentProject.Name;
      lookupResult.spk = opportunityRecord.SPK__c;

      TimesheetResponseModels.ApproverPair approverPair = lwc_ApprovalTimesheetController.resolveApproverIds(
        businessDevelopmentProject.Id,
        (Id) memberId,
        'opty'
      );

      lookupResult.approverId = approverPair.approverId;
      lookupResult.approverOptionalId = approverPair.approverOptionalId;

      return TimesheetResponseModels.ok(lookupResult, 'Opportunity resolved.');
    } catch (Exception caughtException) {
      return TimesheetResponseModels.fail(
        'SERVER_ERROR',
        caughtException.getMessage()
      );
    }
  }

  // =========================
  // Convert Campaign
  // =========================
  @AuraEnabled
  public static TimesheetResponseModels.ResponseWrapper convertCampaign(
    String campaignId,
    String memberId
  ) {
    try {
      if (String.isBlank(campaignId)) {
        return TimesheetResponseModels.fail(
          'INVALID_INPUT',
          'campaignId is required.'
        );
      }

      Project__c projectRecord = [
        SELECT Id, SPK__c, Name
        FROM Project__c
        WHERE SPK__c = 'MSI009'
        LIMIT 1
      ];

      Campaign campaignRecord = [
        SELECT Id, Name
        FROM Campaign
        WHERE Id = :campaignId
        LIMIT 1
      ];

      TimesheetResponseModels.TimesheetLookupResult lookupResult = new TimesheetResponseModels.TimesheetLookupResult();
      lookupResult.entryType = 'campaign';
      lookupResult.objectRecordId = (Id) campaignId;
      lookupResult.objectLabel = campaignRecord.Name;
      lookupResult.projectId = projectRecord.Id;
      lookupResult.projectName = projectRecord.Name;
      lookupResult.spk = projectRecord.SPK__c;

      TimesheetResponseModels.ApproverPair approverPair = lwc_ApprovalTimesheetController.resolveApproverIds(
        projectRecord.Id,
        (Id) memberId,
        'campaign'
      );

      lookupResult.approverId = approverPair.approverId;
      lookupResult.approverOptionalId = approverPair.approverOptionalId;

      return TimesheetResponseModels.ok(lookupResult, 'Campaign resolved.');
    } catch (Exception caughtException) {
      throw new AuraHandledException(caughtException.getMessage());
    }
  }
}
