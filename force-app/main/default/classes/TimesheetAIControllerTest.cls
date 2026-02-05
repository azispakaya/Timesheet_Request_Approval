@IsTest
private class TimesheetAIControllerTest {
  // ====== Mock HTTP Callout Classes ======

  // Success mock - returns JSON with suggestedRemark
  private class MockN8NSuccessJSON implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setStatus('OK');
      res.setBody('{"suggestedRemark": "AI generated remark for timesheet"}');
      return res;
    }
  }

  // Success mock - returns plain text
  private class MockN8NSuccessPlainText implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setStatus('OK');
      res.setBody('Plain text AI generated remark');
      return res;
    }
  }

  // HTTP 500 error mock
  private class MockN8NError500 implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setStatus('Internal Server Error');
      res.setBody('{"error": "AI service failure"}');
      return res;
    }
  }

  // HTTP 400 error mock
  private class MockN8NError400 implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(400);
      res.setStatus('Bad Request');
      res.setBody('{"error": "Invalid request"}');
      return res;
    }
  }

  // Null response mock
  private class MockN8NNull implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      return null;
    }
  }

  // Empty body mock
  private class MockN8NEmptyBody implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setStatus('OK');
      res.setBody('');
      return res;
    }
  }

  // ====== Test Data Setup ======

  @TestSetup
  static void setupTestData() {
    // Create Case
    Case testCase = new Case(
      Subject = 'Test Case for Timesheet',
      Status = 'New',
      Description = 'Test case description',
      Summary__c = 'Test summary'
    );
    insert testCase;

    // Create Project (if Project__c exists in your org)
    // Uncomment if Project__c is available
    /*
    Project__c testProject = new Project__c(
      Name = 'Test Project',
      SPK__c = 'SPK-001',
      Status__c = 'Active',
      Overview__c = 'Test overview',
      Assumptions__c = 'Test assumptions'
    );
    insert testProject;
    */

    // Create POC (if POC__c exists in your org)
    // Uncomment if POC__c is available
    /*
    POC__c testPOC = new POC__c(
      Name = 'Test POC',
      POC_Number__c = 'POC-001',
      Status__c = 'Active',
      Description__c = 'Test POC description',
      Objective__c = 'Test objective',
      Scope_of_POC__c = 'Test scope'
    );
    insert testPOC;
    */

    // Create Opportunity
    Opportunity testOpty = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      Amount = 100000,
      CloseDate = Date.today().addDays(30)
    );
    insert testOpty;

    // Create Campaign
    Campaign testCampaign = new Campaign(
      Name = 'Test Campaign',
      Status = 'Planned',
      StartDate = Date.today(),
      EndDate = Date.today().addDays(30)
    );
    insert testCampaign;
  }

  // ====== Happy Path Tests ======

  @IsTest
  static void testGenerateRemarkForCase_Success_JSON() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'Initial remark';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(true, res.success, 'Request should succeed');
    System.assertEquals(200, res.httpStatus, 'HTTP status should be 200');
    System.assertEquals('OK', res.message, 'Message should be OK');
    System.assertEquals(
      'AI generated remark for timesheet',
      res.suggestedRemark,
      'Should extract suggestedRemark from JSON'
    );
    System.assertNotEquals(null, res.raw, 'Raw response should not be null');
  }

  @IsTest
  static void testGenerateRemarkForCase_Success_PlainText() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'Initial remark';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.5';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessPlainText());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(true, res.success, 'Request should succeed');
    System.assertEquals(200, res.httpStatus, 'HTTP status should be 200');
    System.assertEquals(
      'Plain text AI generated remark',
      res.suggestedRemark,
      'Should use plain text as suggestedRemark'
    );
  }

  @IsTest
  static void testGenerateRemarkForOpportunity_Success() {
    // Arrange
    Opportunity testOpty = [SELECT Id FROM Opportunity LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testOpty.Id;
    req.type = 'opty';
    req.remark = 'Opty work';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '5.0';
    req.EmployeeID = 'EMP002';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      true,
      res.success,
      'Request should succeed for Opportunity'
    );
    System.assertEquals(200, res.httpStatus, 'HTTP status should be 200');
  }

  @IsTest
  static void testGenerateRemarkForCampaign_Success() {
    // Arrange
    Campaign testCampaign = [SELECT Id FROM Campaign LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCampaign.Id;
    req.type = 'campaign';
    req.remark = 'Campaign work';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '3.0';
    req.EmployeeID = 'EMP003';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      true,
      res.success,
      'Request should succeed for Campaign'
    );
    System.assertEquals(200, res.httpStatus, 'HTTP status should be 200');
  }

  // ====== Bulk Test ======

  @IsTest
  static void testBulkRequests() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    List<TimesheetAIController.GenerateRemarkResponse> responses = new List<TimesheetAIController.GenerateRemarkResponse>();

    for (Integer i = 0; i < 5; i++) {
      TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
      req.ObjectRecordId = testCase.Id;
      req.type = 'case';
      req.remark = 'Bulk test ' + i;
      req.start_date = '2024-01-01';
      req.end_date = '2024-01-31';
      req.stime = '1.0';
      req.EmployeeID = 'EMP' + i;

      responses.add(
        TimesheetAIController.generateTimesheetRemark(JSON.serialize(req))
      );
    }
    Test.stopTest();

    // Assert
    System.assertEquals(5, responses.size(), 'Should handle 5 requests');
    for (TimesheetAIController.GenerateRemarkResponse res : responses) {
      System.assertEquals(true, res.success, 'Each request should succeed');
    }
  }

  // ====== Validation Tests ======

  @IsTest
  static void testMissingObjectRecordId() {
    // Arrange
    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.type = 'case';
    req.remark = 'Test';
    // ObjectRecordId is null

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      false,
      res.success,
      'Should fail for missing ObjectRecordId'
    );
    System.assertEquals(400, res.httpStatus, 'Should return 400');
    System.assert(
      res.message.containsIgnoreCase('missing'),
      'Should mention missing fields'
    );
  }

  @IsTest
  static void testMissingType() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    // type is null
    req.remark = 'Test';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(false, res.success, 'Should fail for missing type');
    System.assertEquals(400, res.httpStatus, 'Should return 400');
  }

  @IsTest
  static void testUnsupportedType() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'unsupported_type';
    req.remark = 'Test';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(false, res.success, 'Should fail for unsupported type');
    System.assertEquals(400, res.httpStatus, 'Should return 400');
    System.assert(
      res.message.containsIgnoreCase('unsupported'),
      'Should mention unsupported type'
    );
  }

  @IsTest
  static void testInvalidRecordIdFormat() {
    // Arrange
    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = 'INVALID_ID';
    req.type = 'case';
    req.remark = 'Test';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      false,
      res.success,
      'Should fail for invalid ID format'
    );
    System.assertEquals(400, res.httpStatus, 'Should return 400');
    System.assert(
      res.message.containsIgnoreCase('invalid'),
      'Should mention invalid ID'
    );
  }

  @IsTest
  static void testRecordNotFound() {
    // Arrange - use a valid format but non-existent Case ID
    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = '500000000000000'; // Valid format but doesn't exist
    req.type = 'case';
    req.remark = 'Test';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      false,
      res.success,
      'Should fail for non-existent record'
    );
    System.assertEquals(500, res.httpStatus, 'Should return 500 for exception');
  }

  @IsTest
  static void testWrongObjectType() {
    // Arrange - use Opportunity ID with type='case'
    Opportunity testOpty = [SELECT Id FROM Opportunity LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testOpty.Id;
    req.type = 'case'; // Wrong type
    req.remark = 'Test';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(
      false,
      res.success,
      'Should fail for mismatched object type'
    );
    System.assertEquals(500, res.httpStatus, 'Should return 500');
  }

  // ====== HTTP Error Tests ======

  @IsTest
  static void testHTTPError500() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NError500());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(false, res.success, 'Should fail on HTTP 500');
    System.assertEquals(500, res.httpStatus, 'Should return 500');
    System.assert(
      res.message.containsIgnoreCase('failed'),
      'Should mention service failure'
    );
  }

  @IsTest
  static void testHTTPError400() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NError400());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(false, res.success, 'Should fail on HTTP 400');
    System.assertEquals(400, res.httpStatus, 'Should return 400');
  }

  @IsTest
  static void testEmptyResponseBody() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = ' 8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NEmptyBody());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert
    System.assertEquals(false, res.success, 'Should fail on empty body');
    System.assertEquals(
      200,
      res.httpStatus,
      'HTTP status is 200 but content empty'
    );
    System.assert(
      res.message.containsIgnoreCase('empty'),
      'Should mention empty remark'
    );
  }

  // ====== Security Tests ======

  @IsTest
  static void testFLSEnforcement() {
    // Arrange
    Case testCase = new Case(
      Subject = 'FLS Test Case',
      Status = 'New',
      Description = 'Test Description'
    );
    insert testCase;

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'case';
    req.remark = 'FLS Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act - Run as current user (should enforce FLS)
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert - Should succeed (assuming current user has access)
    // Real FLS testing requires profile setup with limited permissions
    System.assertNotEquals(null, res, 'Response should not be null');
  }

  @IsTest
  static void testCaseSensitiveTypeHandling() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = 'CASE'; // Uppercase
    req.remark = 'Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert - Should handle case-insensitive type
    System.assertEquals(true, res.success, 'Should handle uppercase type');
  }

  @IsTest
  static void testWhitespaceInType() {
    // Arrange
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    TimesheetAIController.GenerateRemarkRequest req = new TimesheetAIController.GenerateRemarkRequest();
    req.ObjectRecordId = testCase.Id;
    req.type = '  case  '; // Whitespace
    req.remark = 'Test';
    req.start_date = '2024-01-01';
    req.end_date = '2024-01-31';
    req.stime = '8.0';
    req.EmployeeID = 'EMP001';

    Test.setMock(HttpCalloutMock.class, new MockN8NSuccessJSON());

    // Act
    Test.startTest();
    TimesheetAIController.GenerateRemarkResponse res = TimesheetAIController.generateTimesheetRemark(
      JSON.serialize(req)
    );
    Test.stopTest();

    // Assert - Should trim whitespace
    System.assertEquals(true, res.success, 'Should handle whitespace in type');
  }
}
