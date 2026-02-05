/**
 * @author [AcekBecek]
 * @desc Test class for TimesheetResponseModels - validates all DTOs and factory methods
 */
@IsTest
private class Test_TimesheetResponseModels {
  // =============================
  // FACTORY METHOD TESTS: ok()
  // =============================
  @IsTest
  static void test_FactoryOk_WithPayloadAndMessage_Success() {
    Map<String, Object> testPayload = new Map<String, Object>{
      'field1' => 'value1',
      'field2' => 123
    };
    String testMessage = 'Operation successful';

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      testPayload,
      testMessage
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Success should be true');
    System.assertEquals('OK', response.statusCode, 'Status code should be OK');
    System.assertEquals(testMessage, response.message, 'Message should match');
    System.assertEquals(testPayload, response.payload, 'Payload should match');
    System.assertNotEquals(
      null,
      response.fieldIssues,
      'Field issues should be initialized'
    );
    System.assertEquals(
      0,
      response.fieldIssues.size(),
      'Field issues should be empty'
    );
  }

  @IsTest
  static void test_FactoryOk_WithNullPayload_Success() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      null,
      'Success with null payload'
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Success should be true');
    System.assertEquals('OK', response.statusCode, 'Status code should be OK');
    System.assertEquals(null, response.payload, 'Payload should be null');
  }

  @IsTest
  static void test_FactoryOk_WithBlankMessage_UsesDefault() {
    Map<String, Object> testPayload = new Map<String, Object>{
      'test' => 'data'
    };

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      testPayload,
      ''
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Success should be true');
    System.assertEquals(
      'OK',
      response.message,
      'Should use default OK message'
    );
  }

  @IsTest
  static void test_FactoryOk_WithNullMessage_UsesDefault() {
    Map<String, Object> testPayload = new Map<String, Object>{
      'test' => 'data'
    };

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      testPayload,
      null
    );
    Test.stopTest();

    System.assertEquals(
      'OK',
      response.message,
      'Should use default OK message when null'
    );
  }

  @IsTest
  static void test_FactoryOk_WithComplexPayload_Success() {
    TimesheetResponseModels.EmployeeContext employeeContext = new TimesheetResponseModels.EmployeeContext();
    employeeContext.employeeRecordId = '001000000000000AAA';
    employeeContext.employeeName = 'Test Employee';
    employeeContext.employeeNumber = 'EMP001';
    employeeContext.email = 'test@test.com';
    employeeContext.role = 'Engineer';

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      employeeContext,
      'Employee loaded'
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Success should be true');
    System.assertNotEquals(
      null,
      response.payload,
      'Payload should not be null'
    );

    // Verify payload can be deserialized back
    TimesheetResponseModels.EmployeeContext retrievedContext = (TimesheetResponseModels.EmployeeContext) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.EmployeeContext.class
    );
    System.assertEquals(
      'Test Employee',
      retrievedContext.employeeName,
      'Employee name should match'
    );
  }

  // =============================
  // FACTORY METHOD TESTS: fail()
  // =============================
  @IsTest
  static void test_FactoryFail_WithStatusCodeAndMessage_Success() {
    String testStatusCode = 'INVALID_INPUT';
    String testMessage = 'Field X is required';

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      testStatusCode,
      testMessage
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Success should be false');
    System.assertEquals(
      testStatusCode,
      response.statusCode,
      'Status code should match'
    );
    System.assertEquals(testMessage, response.message, 'Message should match');
    System.assertEquals(null, response.payload, 'Payload should be null');
  }

  @IsTest
  static void test_FactoryFail_WithBlankStatusCode_UsesDefault() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      '',
      'Error occurred'
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Success should be false');
    System.assertEquals(
      'SERVER_ERROR',
      response.statusCode,
      'Should use default SERVER_ERROR'
    );
  }

  @IsTest
  static void test_FactoryFail_WithNullStatusCode_UsesDefault() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      null,
      'Error occurred'
    );
    Test.stopTest();

    System.assertEquals(
      'SERVER_ERROR',
      response.statusCode,
      'Should use default SERVER_ERROR when null'
    );
  }

  @IsTest
  static void test_FactoryFail_WithBlankMessage_UsesDefault() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      'NOT_FOUND',
      ''
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Success should be false');
    System.assertEquals(
      'Request failed',
      response.message,
      'Should use default failure message'
    );
  }

  @IsTest
  static void test_FactoryFail_WithNullMessage_UsesDefault() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      'NOT_FOUND',
      null
    );
    Test.stopTest();

    System.assertEquals(
      'Request failed',
      response.message,
      'Should use default failure message when null'
    );
  }

  @IsTest
  static void test_FactoryFail_AllStatusCodes() {
    List<String> statusCodes = new List<String>{
      'INVALID_INPUT',
      'NOT_ASSIGNED',
      'NOT_FOUND',
      'SERVER_ERROR'
    };

    Test.startTest();
    for (String statusCode : statusCodes) {
      TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
        statusCode,
        'Test error for ' + statusCode
      );

      System.assertEquals(
        false,
        response.success,
        'Success should be false for ' + statusCode
      );
      System.assertEquals(
        statusCode,
        response.statusCode,
        'Status code should match: ' + statusCode
      );
    }
    Test.stopTest();
  }

  // =============================
  // RESPONSE WRAPPER TESTS
  // =============================
  @IsTest
  static void test_ResponseWrapper_DefaultConstructor() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = new TimesheetResponseModels.ResponseWrapper();
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Default success should be false'
    );
    System.assertEquals(
      'SERVER_ERROR',
      response.statusCode,
      'Default status code should be SERVER_ERROR'
    );
    System.assertEquals(
      'Unexpected error',
      response.message,
      'Default message should be Unexpected error'
    );
    System.assertEquals(
      null,
      response.payload,
      'Default payload should be null'
    );
    System.assertNotEquals(
      null,
      response.fieldIssues,
      'Field issues should be initialized'
    );
    System.assertEquals(
      0,
      response.fieldIssues.size(),
      'Field issues should be empty by default'
    );
  }

  @IsTest
  static void test_ResponseWrapper_AddFieldIssue_Single() {
    TimesheetResponseModels.ResponseWrapper response = new TimesheetResponseModels.ResponseWrapper();

    Test.startTest();
    response.addFieldIssue('Project__c', 'Project is required', 'row1');
    Test.stopTest();

    System.assertEquals(
      1,
      response.fieldIssues.size(),
      'Should have 1 field issue'
    );
    System.assertEquals(
      'Project__c',
      response.fieldIssues[0].fieldApiName,
      'Field name should match'
    );
    System.assertEquals(
      'Project is required',
      response.fieldIssues[0].issueMessage,
      'Issue message should match'
    );
    System.assertEquals(
      'row1',
      response.fieldIssues[0].rowTempId,
      'Row temp ID should match'
    );
  }

  @IsTest
  static void test_ResponseWrapper_AddFieldIssue_Multiple() {
    TimesheetResponseModels.ResponseWrapper response = new TimesheetResponseModels.ResponseWrapper();

    Test.startTest();
    response.addFieldIssue('Start_Date__c', 'Start date is required', 'row1');
    response.addFieldIssue(
      'End_Date__c',
      'End date must be after start date',
      'row1'
    );
    response.addFieldIssue('Time__c', 'Time is required', 'row2');
    Test.stopTest();

    System.assertEquals(
      3,
      response.fieldIssues.size(),
      'Should have 3 field issues'
    );
    System.assertEquals(
      'Start_Date__c',
      response.fieldIssues[0].fieldApiName,
      'First field should match'
    );
    System.assertEquals(
      'End_Date__c',
      response.fieldIssues[1].fieldApiName,
      'Second field should match'
    );
    System.assertEquals(
      'Time__c',
      response.fieldIssues[2].fieldApiName,
      'Third field should match'
    );
  }

  @IsTest
  static void test_ResponseWrapper_AddFieldIssue_Chaining() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = new TimesheetResponseModels.ResponseWrapper()
      .addFieldIssue('Field1', 'Error 1', 'row1')
      .addFieldIssue('Field2', 'Error 2', 'row1')
      .addFieldIssue('Field3', 'Error 3', 'row2');
    Test.stopTest();

    System.assertEquals(
      3,
      response.fieldIssues.size(),
      'Should have 3 field issues from chaining'
    );
  }

  @IsTest
  static void test_ResponseWrapper_AuraEnabled_Serialization() {
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      new Map<String, Object>{ 'test' => 'value' },
      'Test message'
    );
    response.addFieldIssue('TestField', 'Test issue', 'row1');

    Test.startTest();
    String serialized = JSON.serialize(response);
    Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped(
      serialized
    );
    Test.stopTest();

    System.assert(
      deserialized.containsKey('success'),
      'Should contain success'
    );
    System.assert(
      deserialized.containsKey('statusCode'),
      'Should contain statusCode'
    );
    System.assert(
      deserialized.containsKey('message'),
      'Should contain message'
    );
    System.assert(
      deserialized.containsKey('payload'),
      'Should contain payload'
    );
    System.assert(
      deserialized.containsKey('fieldIssues'),
      'Should contain fieldIssues'
    );
  }

  // =============================
  // FIELD ISSUE DTO TESTS
  // =============================
  @IsTest
  static void test_FieldIssue_Properties() {
    Test.startTest();
    TimesheetResponseModels.FieldIssue issue = new TimesheetResponseModels.FieldIssue();
    issue.fieldApiName = 'Employee__c';
    issue.issueMessage = 'Employee is required';
    issue.rowTempId = 'temp123';
    Test.stopTest();

    System.assertEquals(
      'Employee__c',
      issue.fieldApiName,
      'Field API name should match'
    );
    System.assertEquals(
      'Employee is required',
      issue.issueMessage,
      'Issue message should match'
    );
    System.assertEquals('temp123', issue.rowTempId, 'Row temp ID should match');
  }

  @IsTest
  static void test_FieldIssue_Serialization() {
    TimesheetResponseModels.FieldIssue issue = new TimesheetResponseModels.FieldIssue();
    issue.fieldApiName = 'Project__c';
    issue.issueMessage = 'Project not found';
    issue.rowTempId = 'row5';

    Test.startTest();
    String serialized = JSON.serialize(issue);
    TimesheetResponseModels.FieldIssue deserialized = (TimesheetResponseModels.FieldIssue) JSON.deserialize(
      serialized,
      TimesheetResponseModels.FieldIssue.class
    );
    Test.stopTest();

    System.assertEquals(
      issue.fieldApiName,
      deserialized.fieldApiName,
      'Field name should match after serialization'
    );
    System.assertEquals(
      issue.issueMessage,
      deserialized.issueMessage,
      'Message should match after serialization'
    );
    System.assertEquals(
      issue.rowTempId,
      deserialized.rowTempId,
      'Row ID should match after serialization'
    );
  }

  // =============================
  // EMPLOYEE CONTEXT DTO TESTS
  // =============================
  @IsTest
  static void test_EmployeeContext_AllProperties() {
    Test.startTest();
    TimesheetResponseModels.EmployeeContext ctx = new TimesheetResponseModels.EmployeeContext();
    ctx.employeeRecordId = '001000000000001AAA';
    ctx.employeeName = 'John Doe';
    ctx.employeeNumber = 'EMP123';
    ctx.email = 'john.doe@test.com';
    ctx.role = 'Engineer';
    Test.stopTest();

    System.assertEquals(
      '001000000000001AAA',
      ctx.employeeRecordId,
      'Employee record ID should match'
    );
    System.assertEquals(
      'John Doe',
      ctx.employeeName,
      'Employee name should match'
    );
    System.assertEquals(
      'EMP123',
      ctx.employeeNumber,
      'Employee number should match'
    );
    System.assertEquals('john.doe@test.com', ctx.email, 'Email should match');
    System.assertEquals('Engineer', ctx.role, 'Role should match');
  }

  @IsTest
  static void test_EmployeeContext_Serialization() {
    TimesheetResponseModels.EmployeeContext ctx = new TimesheetResponseModels.EmployeeContext();
    ctx.employeeRecordId = '001000000000002AAA';
    ctx.employeeName = 'Jane Smith';
    ctx.employeeNumber = 'EMP456';
    ctx.email = 'jane@test.com';
    ctx.role = 'Manager';

    Test.startTest();
    String serialized = JSON.serialize(ctx);
    TimesheetResponseModels.EmployeeContext deserialized = (TimesheetResponseModels.EmployeeContext) JSON.deserialize(
      serialized,
      TimesheetResponseModels.EmployeeContext.class
    );
    Test.stopTest();

    System.assertEquals(
      ctx.employeeRecordId,
      deserialized.employeeRecordId,
      'ID should match'
    );
    System.assertEquals(
      ctx.employeeName,
      deserialized.employeeName,
      'Name should match'
    );
    System.assertEquals(
      ctx.employeeNumber,
      deserialized.employeeNumber,
      'Number should match'
    );
    System.assertEquals(ctx.email, deserialized.email, 'Email should match');
    System.assertEquals(ctx.role, deserialized.role, 'Role should match');
  }

  // =============================
  // APPROVER PAIR DTO TESTS
  // =============================
  @IsTest
  static void test_ApproverPair_Properties() {
    Test.startTest();
    TimesheetResponseModels.ApproverPair pair = new TimesheetResponseModels.ApproverPair();
    pair.approverId = '005000000000001AAA';
    pair.approverOptionalId = '005000000000002AAA';
    Test.stopTest();

    System.assertEquals(
      '005000000000001AAA',
      pair.approverId,
      'Approver ID should match'
    );
    System.assertEquals(
      '005000000000002AAA',
      pair.approverOptionalId,
      'Optional approver ID should match'
    );
  }

  @IsTest
  static void test_ApproverPair_NullValues() {
    Test.startTest();
    TimesheetResponseModels.ApproverPair pair = new TimesheetResponseModels.ApproverPair();
    Test.stopTest();

    System.assertEquals(
      null,
      pair.approverId,
      'Approver ID should be null by default'
    );
    System.assertEquals(
      null,
      pair.approverOptionalId,
      'Optional approver ID should be null by default'
    );
  }

  @IsTest
  static void test_ApproverPair_Serialization() {
    TimesheetResponseModels.ApproverPair pair = new TimesheetResponseModels.ApproverPair();
    pair.approverId = '005000000000003AAA';
    pair.approverOptionalId = '005000000000004AAA';

    Test.startTest();
    String serialized = JSON.serialize(pair);
    TimesheetResponseModels.ApproverPair deserialized = (TimesheetResponseModels.ApproverPair) JSON.deserialize(
      serialized,
      TimesheetResponseModels.ApproverPair.class
    );
    Test.stopTest();

    System.assertEquals(
      pair.approverId,
      deserialized.approverId,
      'Approver ID should match'
    );
    System.assertEquals(
      pair.approverOptionalId,
      deserialized.approverOptionalId,
      'Optional ID should match'
    );
  }

  // =============================
  // TIMESHEET LOOKUP RESULT DTO TESTS
  // =============================
  @IsTest
  static void test_TimesheetLookupResult_AllProperties() {
    Test.startTest();
    TimesheetResponseModels.TimesheetLookupResult result = new TimesheetResponseModels.TimesheetLookupResult();
    result.entryType = 'project';
    result.objectRecordId = 'a00000000000001AAA';
    result.objectLabel = 'Test Project';
    result.projectId = 'a01000000000001AAA';
    result.projectName = 'MSInfokom - Test';
    result.spk = 'SPK001';
    result.approverId = '005000000000001AAA';
    result.approverOptionalId = '005000000000002AAA';
    Test.stopTest();

    System.assertEquals('project', result.entryType, 'Entry type should match');
    System.assertEquals(
      'a00000000000001AAA',
      result.objectRecordId,
      'Object record ID should match'
    );
    System.assertEquals(
      'Test Project',
      result.objectLabel,
      'Object label should match'
    );
    System.assertEquals(
      'a01000000000001AAA',
      result.projectId,
      'Project ID should match'
    );
    System.assertEquals(
      'MSInfokom - Test',
      result.projectName,
      'Project name should match'
    );
    System.assertEquals('SPK001', result.spk, 'SPK should match');
    System.assertEquals(
      '005000000000001AAA',
      result.approverId,
      'Approver ID should match'
    );
    System.assertEquals(
      '005000000000002AAA',
      result.approverOptionalId,
      'Optional approver should match'
    );
  }

  @IsTest
  static void test_TimesheetLookupResult_AllEntryTypes() {
    List<String> entryTypes = new List<String>{
      'project',
      'case',
      'poc',
      'opty',
      'campaign'
    };

    Test.startTest();
    for (String entryType : entryTypes) {
      TimesheetResponseModels.TimesheetLookupResult result = new TimesheetResponseModels.TimesheetLookupResult();
      result.entryType = entryType;

      System.assertEquals(
        entryType,
        result.entryType,
        'Entry type should match: ' + entryType
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void test_TimesheetLookupResult_Serialization() {
    TimesheetResponseModels.TimesheetLookupResult result = new TimesheetResponseModels.TimesheetLookupResult();
    result.entryType = 'case';
    result.objectRecordId = '500000000000001AAA';
    result.objectLabel = 'CASE-12345';
    result.projectId = 'a01000000000002AAA';
    result.projectName = 'Support Project';
    result.spk = 'SUP001';
    result.approverId = '005000000000005AAA';
    result.approverOptionalId = null;

    Test.startTest();
    String serialized = JSON.serialize(result);
    TimesheetResponseModels.TimesheetLookupResult deserialized = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      serialized,
      TimesheetResponseModels.TimesheetLookupResult.class
    );
    Test.stopTest();

    System.assertEquals(
      result.entryType,
      deserialized.entryType,
      'Entry type should match'
    );
    System.assertEquals(
      result.objectRecordId,
      deserialized.objectRecordId,
      'Object ID should match'
    );
    System.assertEquals(
      result.objectLabel,
      deserialized.objectLabel,
      'Label should match'
    );
    System.assertEquals(
      result.projectId,
      deserialized.projectId,
      'Project ID should match'
    );
    System.assertEquals(
      result.projectName,
      deserialized.projectName,
      'Project name should match'
    );
    System.assertEquals(result.spk, deserialized.spk, 'SPK should match');
    System.assertEquals(
      result.approverId,
      deserialized.approverId,
      'Approver ID should match'
    );
    System.assertEquals(
      result.approverOptionalId,
      deserialized.approverOptionalId,
      'Optional should be null'
    );
  }

  // =============================
  // CREATE TIMESHEET RESULT DTO TESTS
  // =============================
  @IsTest
  static void test_CreateTimesheetResult_DefaultConstructor() {
    Test.startTest();
    TimesheetResponseModels.CreateTimesheetResult result = new TimesheetResponseModels.CreateTimesheetResult();
    Test.stopTest();

    System.assertEquals(
      0,
      result.createdCount,
      'Default created count should be 0'
    );
    System.assertNotEquals(
      null,
      result.createdIds,
      'Created IDs should be initialized'
    );
    System.assertEquals(
      0,
      result.createdIds.size(),
      'Created IDs should be empty'
    );
  }

  @IsTest
  static void test_CreateTimesheetResult_WithData() {
    Test.startTest();
    TimesheetResponseModels.CreateTimesheetResult result = new TimesheetResponseModels.CreateTimesheetResult();
    result.createdCount = 5;
    result.createdIds.add('a02000000000001AAA');
    result.createdIds.add('a02000000000002AAA');
    result.createdIds.add('a02000000000003AAA');
    result.createdIds.add('a02000000000004AAA');
    result.createdIds.add('a02000000000005AAA');
    Test.stopTest();

    System.assertEquals(5, result.createdCount, 'Created count should be 5');
    System.assertEquals(5, result.createdIds.size(), 'Should have 5 IDs');
    System.assertEquals(
      'a02000000000001AAA',
      result.createdIds[0],
      'First ID should match'
    );
    System.assertEquals(
      'a02000000000005AAA',
      result.createdIds[4],
      'Last ID should match'
    );
  }

  @IsTest
  static void test_CreateTimesheetResult_Serialization() {
    TimesheetResponseModels.CreateTimesheetResult result = new TimesheetResponseModels.CreateTimesheetResult();
    result.createdCount = 3;
    result.createdIds.add('a02000000000006AAA');
    result.createdIds.add('a02000000000007AAA');
    result.createdIds.add('a02000000000008AAA');

    Test.startTest();
    String serialized = JSON.serialize(result);
    TimesheetResponseModels.CreateTimesheetResult deserialized = (TimesheetResponseModels.CreateTimesheetResult) JSON.deserialize(
      serialized,
      TimesheetResponseModels.CreateTimesheetResult.class
    );
    Test.stopTest();

    System.assertEquals(
      result.createdCount,
      deserialized.createdCount,
      'Created count should match'
    );
    System.assertEquals(
      result.createdIds.size(),
      deserialized.createdIds.size(),
      'List size should match'
    );
    System.assertEquals(
      result.createdIds[0],
      deserialized.createdIds[0],
      'First ID should match'
    );
  }

  // =============================
  // APPROVER INFO DTO TESTS
  // =============================
  @IsTest
  static void test_ApproverInfo_Properties() {
    Test.startTest();
    TimesheetResponseModels.ApproverInfo info = new TimesheetResponseModels.ApproverInfo();
    info.name = 'Project Manager';
    info.id = '005000000000009AAA';
    Test.stopTest();

    System.assertEquals('Project Manager', info.name, 'Name should match');
    System.assertEquals('005000000000009AAA', info.id, 'ID should match');
  }

  @IsTest
  static void test_ApproverInfo_NullValues() {
    Test.startTest();
    TimesheetResponseModels.ApproverInfo info = new TimesheetResponseModels.ApproverInfo();
    Test.stopTest();

    System.assertEquals(null, info.name, 'Name should be null by default');
    System.assertEquals(null, info.id, 'ID should be null by default');
  }

  @IsTest
  static void test_ApproverInfo_Serialization() {
    TimesheetResponseModels.ApproverInfo info = new TimesheetResponseModels.ApproverInfo();
    info.name = 'Supervisor';
    info.id = '005000000000010AAA';

    Test.startTest();
    String serialized = JSON.serialize(info);
    TimesheetResponseModels.ApproverInfo deserialized = (TimesheetResponseModels.ApproverInfo) JSON.deserialize(
      serialized,
      TimesheetResponseModels.ApproverInfo.class
    );
    Test.stopTest();

    System.assertEquals(info.name, deserialized.name, 'Name should match');
    System.assertEquals(info.id, deserialized.id, 'ID should match');
  }

  // =============================
  // INTEGRATION TESTS
  // =============================
  @IsTest
  static void test_Integration_CompleteSuccessWorkflow() {
    // Simulate complete success workflow with all DTOs
    TimesheetResponseModels.CreateTimesheetResult createResult = new TimesheetResponseModels.CreateTimesheetResult();
    createResult.createdCount = 2;
    createResult.createdIds.add('a02000000000011AAA');
    createResult.createdIds.add('a02000000000012AAA');

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.ok(
      createResult,
      'Timesheets created successfully'
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Should be successful');
    System.assertEquals('OK', response.statusCode, 'Status should be OK');

    TimesheetResponseModels.CreateTimesheetResult retrievedResult = (TimesheetResponseModels.CreateTimesheetResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.CreateTimesheetResult.class
    );
    System.assertEquals(
      2,
      retrievedResult.createdCount,
      'Created count should be preserved'
    );
  }

  @IsTest
  static void test_Integration_CompleteFailureWorkflow() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = TimesheetResponseModels.fail(
      'INVALID_INPUT',
      'Validation failed'
    );

    response.addFieldIssue('Start_Date__c', 'Start date is required', 'row1');
    response.addFieldIssue('Employee__c', 'Employee not found', 'row1');
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should be failure');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Status should be INVALID_INPUT'
    );
    System.assertEquals(
      2,
      response.fieldIssues.size(),
      'Should have 2 field issues'
    );
  }

  @IsTest
  static void test_Integration_AllDTOsSerialization() {
    // Test that all DTOs can be serialized and deserialized properly
    Map<String, Object> allDTOs = new Map<String, Object>();

    // Employee Context
    TimesheetResponseModels.EmployeeContext empCtx = new TimesheetResponseModels.EmployeeContext();
    empCtx.employeeName = 'Test';
    allDTOs.put('employeeContext', empCtx);

    // Approver Pair
    TimesheetResponseModels.ApproverPair pair = new TimesheetResponseModels.ApproverPair();
    pair.approverId = '005000000000013AAA';
    allDTOs.put('approverPair', pair);

    // Timesheet Lookup Result
    TimesheetResponseModels.TimesheetLookupResult lookup = new TimesheetResponseModels.TimesheetLookupResult();
    lookup.entryType = 'project';
    allDTOs.put('lookupResult', lookup);

    // Create Timesheet Result
    TimesheetResponseModels.CreateTimesheetResult createResult = new TimesheetResponseModels.CreateTimesheetResult();
    createResult.createdCount = 1;
    allDTOs.put('createResult', createResult);

    // Approver Info
    TimesheetResponseModels.ApproverInfo info = new TimesheetResponseModels.ApproverInfo();
    info.name = 'Manager';
    allDTOs.put('approverInfo', info);

    Test.startTest();
    String serialized = JSON.serialize(allDTOs);
    Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped(
      serialized
    );
    Test.stopTest();

    System.assertEquals(5, deserialized.size(), 'Should have all 5 DTOs');
    System.assert(
      deserialized.containsKey('employeeContext'),
      'Should contain employee context'
    );
    System.assert(
      deserialized.containsKey('approverPair'),
      'Should contain approver pair'
    );
    System.assert(
      deserialized.containsKey('lookupResult'),
      'Should contain lookup result'
    );
    System.assert(
      deserialized.containsKey('createResult'),
      'Should contain create result'
    );
    System.assert(
      deserialized.containsKey('approverInfo'),
      'Should contain approver info'
    );
  }

  @IsTest
  static void test_Integration_ResponseWithMultipleDTOTypes() {
    // Test ResponseWrapper can handle different payload types
    List<TimesheetResponseModels.ResponseWrapper> responses = new List<TimesheetResponseModels.ResponseWrapper>();

    // Response with EmployeeContext
    TimesheetResponseModels.EmployeeContext empCtx = new TimesheetResponseModels.EmployeeContext();
    empCtx.employeeName = 'John';
    responses.add(TimesheetResponseModels.ok(empCtx, 'Employee loaded'));

    // Response with ApproverPair
    TimesheetResponseModels.ApproverPair pair = new TimesheetResponseModels.ApproverPair();
    pair.approverId = '005000000000014AAA';
    responses.add(TimesheetResponseModels.ok(pair, 'Approver resolved'));

    // Response with CreateTimesheetResult
    TimesheetResponseModels.CreateTimesheetResult result = new TimesheetResponseModels.CreateTimesheetResult();
    result.createdCount = 5;
    responses.add(TimesheetResponseModels.ok(result, 'Created'));

    Test.startTest();
    for (TimesheetResponseModels.ResponseWrapper resp : responses) {
      System.assertEquals(
        true,
        resp.success,
        'All responses should be successful'
      );
      System.assertNotEquals(null, resp.payload, 'All should have payload');
    }
    Test.stopTest();
  }
}
