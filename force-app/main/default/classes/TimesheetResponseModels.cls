public without sharing class TimesheetResponseModels {
  // =========================
  // Factory methods (TOP LEVEL, boleh static)
  // =========================
  public static ResponseWrapper ok(Object payloadData, String messageText) {
    ResponseWrapper response = new ResponseWrapper();
    response.success = true;
    response.statusCode = 'OK';
    response.message = String.isBlank(messageText) ? 'OK' : messageText;
    response.payload = payloadData;
    return response;
  }

  public static ResponseWrapper fail(
    String statusCodeText,
    String messageText
  ) {
    ResponseWrapper response = new ResponseWrapper();
    response.success = false;
    response.statusCode = String.isBlank(statusCodeText)
      ? 'SERVER_ERROR'
      : statusCodeText;
    response.message = String.isBlank(messageText)
      ? 'Request failed'
      : messageText;
    response.payload = null;
    return response;
  }

  // =========================
  // Main Response Wrapper
  // =========================
  public class ResponseWrapper {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String statusCode; // OK | INVALID_INPUT | NOT_ASSIGNED | NOT_FOUND | SERVER_ERROR
    @AuraEnabled
    public String message; // user-friendly message
    @AuraEnabled
    public Object payload; // TimesheetLookupResult / EmployeeContext / CreateTimesheetResult / ApproverPair, etc
    @AuraEnabled
    public List<FieldIssue> fieldIssues;

    public ResponseWrapper() {
      success = false;
      statusCode = 'SERVER_ERROR';
      message = 'Unexpected error';
      payload = null;
      fieldIssues = new List<FieldIssue>();
    }

    public ResponseWrapper addFieldIssue(
      String fieldApiName,
      String issueMessage,
      String rowTempId
    ) {
      FieldIssue issue = new FieldIssue();
      issue.fieldApiName = fieldApiName;
      issue.issueMessage = issueMessage;
      issue.rowTempId = rowTempId;
      this.fieldIssues.add(issue);
      return this;
    }
  }

  public class FieldIssue {
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String issueMessage;
    @AuraEnabled
    public String rowTempId;
  }

  // =========================
  // Employee Context DTO
  // =========================
  public class EmployeeContext {
    @AuraEnabled
    public Id employeeRecordId;
    @AuraEnabled
    public String employeeName;
    @AuraEnabled
    public String employeeNumber; // Employee_ID__c
    @AuraEnabled
    public String email;
    @AuraEnabled
    public String role;
  }

  // =========================
  // Approver Pair DTO
  // =========================
  public class ApproverPair {
    @AuraEnabled
    public Id approverId;
    @AuraEnabled
    public Id approverOptionalId;
  }

  // =========================
  // Lookup Result DTO (Convert methods)
  // =========================
  public class TimesheetLookupResult {
    @AuraEnabled
    public String entryType; // project | case | poc | opty | campaign
    @AuraEnabled
    public Id objectRecordId;
    @AuraEnabled
    public String objectLabel;

    @AuraEnabled
    public Id projectId;
    @AuraEnabled
    public String projectName;
    @AuraEnabled
    public String spk;

    @AuraEnabled
    public Id approverId;
    @AuraEnabled
    public Id approverOptionalId;
  }

  // =========================
  // Create Result DTO
  // =========================
  public class CreateTimesheetResult {
    @AuraEnabled
    public Integer createdCount;
    @AuraEnabled
    public List<Id> createdIds;

    public CreateTimesheetResult() {
      createdCount = 0;
      createdIds = new List<Id>();
    }
  }

  // =========================
  // Approver Info DTO
  // =========================
  public class ApproverInfo {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Id id;
  }
}
