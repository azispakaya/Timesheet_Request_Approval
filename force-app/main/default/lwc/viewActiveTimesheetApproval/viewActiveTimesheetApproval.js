/* eslint-disable no-unused-expressions */
/* eslint-disable no-sequences */
/* eslint-disable consistent-return */
/* eslint-disable array-callback-return */
/* eslint-disable eqeqeq */
/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:45:40
 * @modify date 2026-02-06 15:13:34
 * @desc [Controller for List Timesheet Approval Page]
 */

import { LightningElement, api, track, wire } from "lwc";
import { gql, graphql, refreshGraphQL } from "lightning/uiGraphQLApi";
import getApproverInfo from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName";
import updateApprovalStatus from "@salesforce/apex/lwc_ApprovalTimesheetController.updateApprovalStatus";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import modalEditLine from "c/modalCommentTimesheet";
import modalConfirmation from "c/modalConfirmationPage";
import { NavigationMixin } from "lightning/navigation";
import form_factor from "@salesforce/client/formFactor";

export default class ViewActiveTimesheetApproval extends NavigationMixin(
  LightningElement
) {
  @track results = [];
  @track draftTimesheet = [];

  totalCountRecord = 0;
  errors;

  @api recordId;
  @api objectApiName;

  @track ApproverName;
  @track ApproverId;

  selectedApprovalStatus = "Waiting for Approval";
  approvalStyle = "slds-truncate slds-badge slds-badge_inverse";
  isDisabled = false;

  isVisible;
  after = null;
  pageInfo;
  showRecord = 15;
  hasNext = true;
  hasPrev = true;
  setStartDate;
  setEndDate;

  sortName;
  mobileSupport;
  desktopSupport;

  timesheetApproverId; // Timesheet_Approval__c Id

  graphQlData;

  // ======================
  // GraphQL
  // ======================
  @wire(graphql, {
    query: gql`
      query timesheets(
        $ApproverName: ID
        $ApprovalStatus: Picklist
        $nextCursor: String
        $recordCount: Int
        $startDate: Date
        $endDate: Date
      ) {
        uiapi {
          query {
            Timesheet__c(
              first: $recordCount
              after: $nextCursor
              where: {
                and: [
                  {
                    or: [
                      { Timesheet_Approver__r: { Id: { eq: $ApproverName } } }
                      {
                        Timesheet_Approver_Optional__r: {
                          Id: { eq: $ApproverName }
                        }
                      }
                    ]
                  }
                  { Approval_Status__c: { eq: $ApprovalStatus } }
                  { Start_Date__c: { gte: { value: $startDate } } }
                  { End_Date__c: { lte: { value: $endDate } } }
                  { not: { Employee__c: { eq: "" } } }
                  { not: { Project__c: { eq: "" } } }
                ]
              }
              orderBy: { Start_Date__c: { order: DESC } }
            ) {
              edges {
                node {
                  Id
                  Name {
                    value
                  }
                  Employee__r {
                    Id
                    Name {
                      value
                    }
                    Employee_ID__c {
                      value
                    }
                  }
                  Project__r {
                    Id
                    Name {
                      value
                    }
                    SPK__c {
                      value
                    }
                  }
                  Start_Date__c {
                    value
                  }
                  End_Date__c {
                    value
                  }
                  Time__c {
                    value
                  }
                  Remarks__c {
                    value
                  }
                  Approval_Status__c {
                    value
                  }
                  Timesheet_Approver__r {
                    Name {
                      value
                    }
                  }
                  Timesheet_Approver_Optional__r {
                    Name {
                      value
                    }
                  }
                  Account_Name__c {
                    value
                  }
                  Account_Id__c {
                    value
                  }
                }
                cursor
              }
              totalCount
              pageInfo {
                startCursor
                endCursor
                hasNextPage
                hasPreviousPage
              }
            }

            Timesheet_Approval__c(
              where: { Approver__c: { eq: $ApproverName } }
            ) {
              edges {
                node {
                  Id
                  Name {
                    value
                  }
                  Approver__r {
                    Name {
                      value
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: "$variables"
  })
  graphqlQueryResult(result) {
    const { data, errors } = result;

    if (data) {
      const timesheetEdges = data?.uiapi?.query?.Timesheet__c?.edges || [];
      this.results = timesheetEdges.map((edge) => edge.node);

      this.totalCountRecord = data?.uiapi?.query?.Timesheet__c?.totalCount || 0;
      this.pageInfo = data?.uiapi?.query?.Timesheet__c?.pageInfo;

      this.hasNext = !!this.pageInfo?.hasNextPage;
      this.hasPrev = !!this.pageInfo?.hasPreviousPage;

      const approvalEdges =
        data?.uiapi?.query?.Timesheet_Approval__c?.edges || [];
      this.timesheetApproverId = approvalEdges?.[0]?.node?.Id;

      this.isVisible = !(this.totalCountRecord > 0);
    }

    this.errors = errors;
    this.graphQlData = result;
  }

  // ======================
  // Init
  // ======================
  async connectedCallback() {
    // Form factor
    if (form_factor === "Large") {
      this.desktopSupport = true;
      this.mobileSupport = false;
    } else {
      this.mobileSupport = true;
      this.desktopSupport = false;
    }

    // Default date range: last year Jan 01 -> today
    const today = new Date().toJSON().slice(0, 10);
    const d = new Date();
    const year = d.getFullYear() - 1;
    this.setStartDate = `${year}-01-01`;
    this.setEndDate = today;

    this.sortName = "StartDate";

    // Load approver info (Apex wrapper)
    await this.loadApproverInfo();
  }

  async loadApproverInfo() {
    try {
      const res = await getApproverInfo({ recordPageId: this.recordId });

      if (!res || res.success !== true) {
        this.toast(
          res?.message || "Failed to load approver.",
          "error",
          res?.code || "Error"
        );
        return;
      }

      // wrapper.data = { name, id }
      this.ApproverName = res?.payload?.name;
      this.ApproverId = res?.payload?.id;
      console.log("res:", JSON.stringify(res, null, 2));
      console.log("ApproverId:", this.ApproverId);
      console.log("Name:", this.ApproverName);
    } catch (e) {
      this.toast(
        e?.body?.message || e?.message || "Server error.",
        "error",
        "SERVER_ERROR"
      );
    }
  }

  // ======================
  // Sorting
  // ======================
  @track directSort = "ASC";

  sortByNo() {
    this.sortUtils("Name");
  }
  sortByDate() {
    this.sortUtils("Start_Date__c");
  }
  sortByName() {
    this.sortUtils("Employee__r.Name");
  }
  sortByProject() {
    this.sortUtils("Project__r.Name");
  }

  sortUtils(fieldName) {
    const getField = (obj, path) =>
      path.split(".").reduce((o, key) => (o ? o[key] : undefined), obj);

    const curSortDirect = this.directSort;

    this.results = [...this.results].sort((prev, cur) => {
      const a = getField(prev, fieldName);
      const b = getField(cur, fieldName);

      // Some fields may not have .value (safety)
      const fieldPrev = (a?.value ?? "").toString().toUpperCase();
      const fieldCur = (b?.value ?? "").toString().toUpperCase();

      if (curSortDirect === "DESC") {
        return fieldPrev.localeCompare(fieldCur);
      }
      return fieldCur.localeCompare(fieldPrev);
    });

    // toggle direction
    this.directSort = curSortDirect === "DESC" ? "ASC" : "DESC";
  }

  // ======================
  // Filters
  // ======================
  fieldChangeHandler(event) {
    const fieldName = event?.target?.name;
    const fieldValue = event?.target?.value;

    if (fieldName === "StartDate") {
      this.setStartDate = fieldValue;
    } else if (fieldName === "EndDate") {
      this.setEndDate = fieldValue;
    } else if (fieldName === "ApprovalStatus") {
      this.selectedApprovalStatus = fieldValue;

      switch (fieldValue) {
        case "Fully Approved":
          this.approvalStyle = "slds-truncate slds-badge slds-theme_success";
          this.isDisabled = true;
          break;
        case "Waiting for Approval":
          this.approvalStyle = "slds-truncate slds-badge slds-badge_inverse";
          this.isDisabled = false;
          break;
        default:
          this.approvalStyle = "slds-truncate slds-badge slds-theme_error";
          this.isDisabled = true;
          break;
      }
    }
  }

  // ======================
  // Select timesheets
  // ======================
  handleChecked(event) {
    const timesheetId = event?.target?.dataset?.id;
    if (!timesheetId) return;

    const exists = this.draftTimesheet.some((t) => t.recordid === timesheetId);

    if (!exists) {
      this.draftTimesheet = [...this.draftTimesheet, { recordid: timesheetId }];
    } else {
      this.draftTimesheet = this.draftTimesheet.filter(
        (item) => item.recordid !== timesheetId
      );
    }
  }

  // ======================
  // Refresh
  // ======================
  handleRefresh() {
    refreshGraphQL(this.graphQlData);
    this.toast("Successfully Refresh", "success", "Info");
    this.isVisible = !(this.totalCountRecord > 0);
  }

  // ======================
  // Bulk Approve / Reject
  // ======================
  async handleApprove() {
    if (!this.draftTimesheet?.length) {
      this.toast(
        "Nothing to Approve, Please Select at least 1 Timesheet",
        "error",
        "Approve Error!!"
      );
      return;
    }

    const payload = this.draftTimesheet.map((item) => ({
      ...item,
      ApprovalStatus: "Fully Approved",
      Comment: "This Timesheet Successfully Approved",
      ApproveBy: this.ApproverId
    }));

    const countTimesheet = payload.length;

    const confirm = await modalConfirmation.open({
      Content: `Are You sure to Approve (${countTimesheet}) Timesheets ?`,
      Header: "Approve Confirmation"
    });

    if (confirm !== "Save") return;

    await this.submitApprovalUpdate(
      payload,
      "Successfully Approved",
      "success"
    );
  }

  async handleReject() {
    if (!this.draftTimesheet?.length) {
      this.toast(
        "Nothing to Reject, Please Select at least 1 Timesheet",
        "error",
        "Reject Error!!"
      );
      return;
    }

    const payload = this.draftTimesheet.map((item) => ({
      ...item,
      ApprovalStatus: "Rejected",
      Comment: "This Timesheet has been Rejected, Please Re-Submit",
      ApproveBy: this.ApproverId
    }));

    const countTimesheet = payload.length;

    const confirm = await modalConfirmation.open({
      Content: `Are You sure to Reject (${countTimesheet}) Timesheets ?`,
      Header: "Reject Confirmation"
    });

    if (confirm !== "Save") return;

    await this.submitApprovalUpdate(
      payload,
      "Successfully Rejected",
      "warning"
    );
  }

  async submitApprovalUpdate(rows, successMessage, toastVariant) {
    try {
      const res = await updateApprovalStatus({
        Timesheets: JSON.stringify(rows)
      });

      if (!res || res.success !== true) {
        this.toast(
          res?.message || "Failed to update approval status.",
          "error",
          res?.code || "Error"
        );
        return;
      }

      // res.data.updatedCount exists (from Apex)
      this.toast(res?.message || successMessage, toastVariant, "Info");

      this.draftTimesheet = [];
      refreshGraphQL(this.graphQlData);
    } catch (e) {
      this.toast(
        e?.body?.message || e?.message || "Server error.",
        "error",
        "SERVER_ERROR"
      );
    }
  }

  // ======================
  // Row actions
  // ======================
  handleShowMore(event) {
    const timesheetId = event?.currentTarget?.dataset?.timesheetId;
    const remarks = event?.currentTarget?.dataset?.remarks;
    this.toast(`${remarks || "-"}`, "info", `Remarks : ${timesheetId || "-"}`);
  }

  async handleEditLine(event) {
    let singleTimesheet = [];
    const timesheetId = event?.target?.dataset?.id;
    const timesheetNumber = event?.target?.dataset?.label;

    const resultComment = await modalEditLine.open({
      headerLabel: "" + timesheetNumber
    });

    if (!resultComment || resultComment === "cancel") return;

    const parts = resultComment.split(";");
    const comment = parts?.[0] ?? "";
    const status = parts?.[1] ?? "";
    const verbLabel = parts?.[2] ?? "updated";

    singleTimesheet.push({
      recordid: timesheetId,
      Comment: comment,
      ApprovalStatus: status,
      ApproveBy: this.ApproverId
    });

    try {
      const res = await updateApprovalStatus({
        Timesheets: JSON.stringify(singleTimesheet)
      });

      if (!res || res.success !== true) {
        this.toast(
          res?.message || "Failed to update timesheet.",
          "error",
          res?.code || "Error"
        );
        return;
      }

      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          actionName: "view",
          recordId: timesheetId
        }
      }).then((url) => {
        const eventToast = new ShowToastEvent({
          title: "Success!",
          variant: "success",
          message: "Timesheet {0} Successfully {1}",
          messageData: [{ url, label: timesheetNumber }, verbLabel]
        });
        this.dispatchEvent(eventToast);
      });

      refreshGraphQL(this.graphQlData);
    } catch (e) {
      this.toast(
        e?.body?.message || e?.message || "Server error.",
        "error",
        "SERVER_ERROR"
      );
    } finally {
      singleTimesheet = [];
    }
  }

  // ======================
  // Navigation
  // ======================
  get menuItemLabel() {
    return this.objectApiName == "Employee__c" ? "View All" : "View Approver";
  }

  handleViewAll() {
    let objectName;
    let redirectId;

    if (this.objectApiName == "Employee__c") {
      objectName = "Timesheet_Approver__c";
      redirectId = this.timesheetApproverId;
    } else {
      objectName = "Employee__c";
      redirectId = this.ApproverId;
    }

    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        actionName: "view",
        objectApiName: objectName,
        recordId: redirectId
      }
    });
  }

  navToRecord(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        actionName: "view",
        objectApiName: event?.currentTarget?.dataset?.objectName,
        recordId: event?.currentTarget?.dataset?.id
      }
    });
  }

  // ======================
  // Pagination-ish (local recordCount)
  // ======================
  loadMore(event) {
    event.preventDefault();
    if (this.pageInfo?.hasNextPage) {
      this.showRecord = this.showRecord + 5;
    } else {
      this.after = null;
    }
  }

  loadLess(event) {
    event.preventDefault();
    if (this.totalCountRecord > 5) {
      this.showRecord = Math.max(5, this.showRecord - 5);
    } else {
      this.after = null;
    }
  }

  // ======================
  // GraphQL variables
  // ======================
  get variables() {
    return {
      ApproverName: this.ApproverId, // ID Approver
      ApprovalStatus: this.selectedApprovalStatus,
      nextCursor: this.after,
      recordCount: this.showRecord,
      startDate: this.setStartDate,
      endDate: this.setEndDate
    };
  }

  get picklistStatus() {
    return [
      { label: "Waiting for Approval", value: "Waiting for Approval" },
      { label: "Fully Approved", value: "Fully Approved" },
      { label: "Rejected", value: "Rejected" }
    ];
  }

  // FIX: refreshData should refresh GraphQL result, not this.results
  @api
  async refreshData() {
    return refreshGraphQL(this.graphQlData);
  }

  // ======================
  // Toast helper
  // ======================
  toast(message, variant, title) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
