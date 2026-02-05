/* eslint-disable no-confusing-arrow */
import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";

// Apex (wrapper-based)
import convertEmployeeID from "@salesforce/apex/lwc_RequestTimesheetController.convertEmployeeID";
import generateTimesheetRemark from "@salesforce/apex/TimesheetAIController.generateTimesheetRemark";

import { CloseActionScreenEvent } from "lightning/actions";

import createMultiTimesheet from "@salesforce/apex/lwc_ApprovalTimesheetController.createMultiTimesheet";

export default class RequestTimesheet extends LightningElement {
  @api recordId; // Employee__c Id

  // ========= UI flags =========
  @track uiState = {
    isLoadingEmployee: false,
    isConvertingRow: false,
    isSaving: false,
    isSubmitting: false
  };

  // ========= Header / Role =========
  employeName = "Timesheet";
  employeeRole = true; // same behavior with your existing HTML
  selectedPicklist = "Project";

  // used by your HTML
  PicklistObject = [];

  // ========= Lists =========
  @track listProjects = [];
  @track listCases = [];
  @track listPOCs = [];
  @track listOpportunities = [];
  @track listCampaigns = [];

  // ========= employee context (from wrapper) =========
  @track employeeContext = {
    employeeRecordId: null,
    employeeName: "",
    employeeNumber: "",
    email: "",
    role: ""
  };

  @track uiMessage = {
    visible: false,
    variant: "info", // error | warning | info
    title: "",
    message: ""
  };

  get uiMessageClass() {
    return `ts-msg ts-msg--${this.uiMessage.variant || "info"}`;
  }

  showMessage(variant, title, message) {
    this.uiMessage = {
      visible: true,
      variant: variant || "info",
      title: title || "Notice",
      message: message || ""
    };
  }

  clearMessage() {
    this.uiMessage = {
      visible: false,
      variant: "info",
      title: "",
      message: ""
    };
  }

  // ========= Computed =========
  get desktopSupport() {
    return FORM_FACTOR !== "Small";
  }

  get mobileSupport() {
    return FORM_FACTOR === "Small";
  }

  // keep this for your HTML binding
  get isLoading() {
    return (
      this.uiState.isLoadingEmployee ||
      this.uiState.isSaving ||
      this.uiState.isSubmitting
    );
  }

  // empty state flag used by HTML (your "isVisible")
  get isVisible() {
    const totalRows =
      this.listProjects.length +
      this.listCases.length +
      this.listPOCs.length +
      this.listOpportunities.length +
      this.listCampaigns.length;
    return totalRows === 0;
  }

  get formFactorClass() {
    return "slds-grid slds-gutters_small";
  }

  // Count hours for header
  get countHours() {
    const allRows = this.getAllRows();
    let total = 0;

    allRows.forEach((rowItem) => {
      const value = Number(rowItem.stime);
      if (!Number.isNaN(value)) total += value;
    });

    return total;
  }

  // ========= Wire employee context =========
  @wire(convertEmployeeID, { RecordID: "$recordId", render: "loaddata" })
  wiredEmployeeContext(wireResult) {
    const { data, error } = wireResult;

    this.uiState.isLoadingEmployee = true;

    if (error) {
      const normalizedError = this.normalizeApexError(error);
      this.showMessage("error", "Employee", normalizedError.message);
      this.uiState.isLoadingEmployee = false;
      return;
    }

    if (data) {
      const responseWrapper = this.normalizeResponse(data);

      if (!responseWrapper.success) {
        this.showMessage(
          "error",
          "Employee",
          responseWrapper.message || "Failed to load employee context."
        );
        this.uiState.isLoadingEmployee = false;
        return;
      }

      const payload = responseWrapper.payload || {};
      this.employeeContext = {
        employeeRecordId: payload.employeeRecordId || this.recordId,
        employeeName: payload.employeeName || "",
        employeeNumber: payload.employeeNumber || "",
        email: payload.email || "",
        role: payload.role || ""
      };

      this.employeName = this.employeeContext.employeeName || "Timesheet";
      this.applyRoleRules(this.employeeContext.role);

      this.uiState.isLoadingEmployee = false;
    }
  }

  applyRoleRules(roleValue) {
    const role = roleValue || "";

    if (role === "Presales") {
      this.employeeRole = false;
      this.selectedPicklist = "Opportunity";
      this.PicklistObject = [
        { label: "Opportunity", value: "Opportunity" },
        { label: "Project", value: "Project" },
        { label: "POC", value: "POC" }
      ];
      return;
    }

    if (role === "Marketing") {
      this.employeeRole = true;
      this.selectedPicklist = "Campaign";
      this.PicklistObject = [
        { label: "Campaign", value: "Campaign" },
        { label: "Project", value: "Project" }
      ];
      return;
    }

    // default
    this.employeeRole = true;
    this.selectedPicklist = "Project";
    this.PicklistObject = [
      { label: "Project", value: "Project" },
      { label: "Case", value: "Case" },
      { label: "POC", value: "POC" }
    ];
  }

  // ========= Header handlers (menu) =========
  setProjectHandler() {
    this.selectedPicklist = "Project";
  }
  setCaseHandler() {
    this.selectedPicklist = "Case";
  }
  setPOCHandler() {
    this.selectedPicklist = "POC";
  }
  setOptyHandler() {
    this.selectedPicklist = "Opportunity";
  }
  setCampaignHandler() {
    this.selectedPicklist = "Campaign";
  }

  // ========= Add row =========
  addNewHandler() {
    const typeLabel = this.selectedPicklist;
    this.addRowByTypeLabel(typeLabel);
  }

  addRowByTypeLabel(typeLabel) {
    const tempId = this.generateTempId();

    const newRow = {
      tempId,

      // lookup record selected by user
      objectRecordId: null,

      // resolved from Apex convert payload
      objectLabel: "",
      projectId: null,
      projectName: "",
      projectSpk: "",

      // approver info (optional, if you return them)
      approverId: null,
      approverOptionalId: null,

      // user fields
      date: null,
      stime: null,
      temp_remark: ""
    };

    if (typeLabel === "Project")
      this.listProjects = [...this.listProjects, newRow];
    if (typeLabel === "Case") this.listCases = [...this.listCases, newRow];
    if (typeLabel === "POC") this.listPOCs = [...this.listPOCs, newRow];
    if (typeLabel === "Opportunity")
      this.listOpportunities = [...this.listOpportunities, newRow];
    if (typeLabel === "Campaign")
      this.listCampaigns = [...this.listCampaigns, newRow];
  }

  // ========= Child events =========
  handleRowRemove(event) {
    try {
      const { tempId, entityType } = event.detail || {};
      if (!tempId || !entityType) return;

      // IMPORTANT: blur active element to prevent base-component focusing/validation crash
      const activeElement = this.template.activeElement;
      if (activeElement && typeof activeElement.blur === "function") {
        activeElement.blur();
      }

      if (entityType === "opty") {
        this.listOpportunities = (this.listOpportunities || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "project") {
        this.listProjects = (this.listProjects || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "case") {
        this.listCases = (this.listCases || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "poc") {
        this.listPOCs = (this.listPOCs || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "campaign") {
        this.listCampaigns = (this.listCampaigns || []).filter(
          (row) => row.tempId !== tempId
        );
      }

      // optional:
      // this.recalculateHours();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("handleRowRemove crashed:", error);
    }
  }

  async handleRowFieldChange(event) {
    const { tempId, entityType, fieldName, value } = event.detail || {};
    if (!tempId || !entityType || !fieldName) return;

    // ---- get previous value (before we patch) ----
    const prevRow = this.getRowByTempId(entityType, tempId);
    const prevValue = prevRow ? prevRow[fieldName] : null;

    // ---- VALIDATION: stime (hours) ----
    if (fieldName === "stime") {
      const num = Number(value);

      // allow empty/null (user clearing input)
      if (
        value !== null &&
        value !== undefined &&
        value !== "" &&
        Number.isFinite(num)
      ) {
        if (num > 24) {
          const msg = "Hours cannot be more than 24 hours (1 day).";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "stime", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        if (num < 0) {
          const msg = "Hours cannot be less than 0.";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "stime", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        this.clearMessage();
      }
    }

    // ---- VALIDATION: date ----
    if (fieldName === "date") {
      // value biasanya "YYYY-MM-DD"
      if (value) {
        const selected = this.toLocalDate(value); // midnight local
        const today = this.getTodayLocal(); // midnight local
        const earliest = this.addDays(today, -7); // today - 7 days

        if (selected > today || selected < earliest) {
          const msg = "Date must be within the last 7 days (including today).";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "date", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        this.clearMessage();
      }
    }
    const rowCmp = this.getChildRowComponent(tempId);
    if (rowCmp && typeof rowCmp.clearFieldError === "function") {
      rowCmp.clearFieldError(fieldName);
    }
    // 1) always update local state first (ONLY if valid)
    const patch = { [fieldName]: value };
    if (entityType === "project") {
      this.listProjects = this.updateRow(this.listProjects, tempId, patch);
    } else if (entityType === "case") {
      this.listCases = this.updateRow(this.listCases, tempId, patch);
    } else if (entityType === "poc") {
      this.listPOCs = this.updateRow(this.listPOCs, tempId, patch);
    } else if (entityType === "opty") {
      this.listOpportunities = this.updateRow(
        this.listOpportunities,
        tempId,
        patch
      );
    } else if (entityType === "campaign") {
      this.listCampaigns = this.updateRow(this.listCampaigns, tempId, patch);
    }
  }

  handleRowLookupResolved(event) {
    const { tempId, entityType, payload } = event.detail || {};
    if (!tempId || !entityType) return;

    const safePayload = payload || {};

    // enforce objectRecordId exists
    const patch = {
      ...safePayload,
      objectRecordId:
        safePayload.objectRecordId ||
        this.getRowByTempId(entityType, tempId)?.objectRecordId ||
        null
    };

    this.applyResolvedPayloadToRow(entityType, tempId, patch);
  }

  updateRow(list = [], tempId, patch = {}) {
    const rowIndex = list.findIndex((row) => row.tempId === tempId);
    if (rowIndex === -1) return list;

    const updatedRow = { ...list[rowIndex], ...patch };
    const clonedList = [...list];
    clonedList[rowIndex] = updatedRow;
    return clonedList;
  }

  recalculateHours() {
    const allRows = [
      ...(this.listOpportunities || []),
      ...(this.listProjects || []),
      ...(this.listCases || []),
      ...(this.listPOCs || []),
      ...(this.listCampaigns || [])
    ];

    const totalHours = allRows.reduce((sum, rowItem) => {
      const hoursValue = Number(rowItem.stime || 0);
      return sum + (Number.isFinite(hoursValue) ? hoursValue : 0);
    }, 0);

    this.countHours = totalHours;
  }

  // ========= Row update helpers =========
  updateRowValue(entityType, tempId, fieldName, value) {
    const updater = (rows) =>
      rows.map((rowItem) =>
        rowItem.tempId === tempId ? { ...rowItem, [fieldName]: value } : rowItem
      );

    if (entityType === "project")
      this.listProjects = updater(this.listProjects);
    if (entityType === "case") this.listCases = updater(this.listCases);
    if (entityType === "poc") this.listPOCs = updater(this.listPOCs);
    if (entityType === "opty")
      this.listOpportunities = updater(this.listOpportunities);
    if (entityType === "campaign")
      this.listCampaigns = updater(this.listCampaigns);
  }

  applyResolvedPayloadToRow(entityType, tempId, payload) {
    // payload shape recommended from Apex:
    // {
    //   objectRecordId,
    //   objectLabel,
    //   projectId,
    //   projectName,
    //   projectSpk,
    //   approverId,
    //   approverOptionalId
    // }

    const safePayload = payload || {};

    const patch = {
      objectLabel: safePayload.objectLabel || "",
      projectId: safePayload.projectId || null,
      projectName: safePayload.projectName || "",
      projectSpk: safePayload.spk || "",
      approverId: safePayload.approverId || null,
      approverOptionalId: safePayload.approverOptionalId || null,

      // always keep selected objectRecordId if payload returns it
      objectRecordId: safePayload.objectRecordId || null
    };

    Object.keys(patch).forEach((fieldName) => {
      this.updateRowValue(entityType, tempId, fieldName, patch[fieldName]);
    });
  }

  // ========= Save / Submit =========
  async saveTimesheet() {
    await this.persistTimesheet("Draft");
  }

  async submitTimesheet() {
    await this.persistTimesheet("Waiting for Approval");
  }

  async persistTimesheet(statusValue) {
    const payloadList = this.buildCreateTimesheetPayload();
    // console.log("payloadList>>", JSON.stringify(payloadList, null, 2));
    // console.log("isValid", this.uiMessage.visible);
    // console.log("uiMessage", JSON.stringify(this.uiMessage, null, 2));

    const result = this.validatePayloadList(payloadList);
    if (!result.isValid) {
      const first = result.errors[0];

      this.uiMessage = {
        visible: true,
        variant: "error",
        title: "Incomplete entry",
        message:
          first.rowIndex === null
            ? first.message
            : `Row ${first.rowIndex + 1}: ${first.message}`
      };

      console.table(result.errors);

      return;
    }

    this.clearMessage();
    // return;

    const isSubmit = statusValue === "Submitted";
    this.uiState.isSubmitting = isSubmit;
    this.uiState.isSaving = !isSubmit;

    try {
      const rawResponse = await createMultiTimesheet({
        Timesheet: JSON.stringify(payloadList),
        ApprovalStatus: statusValue
      });

      const responseWrapper = this.normalizeResponse(rawResponse);

      if (!responseWrapper.success) {
        this.showMessage(
          "error",
          "Timesheet",
          responseWrapper.message || "Failed to save."
        );
        this.uiState.isSubmitting = false;
        this.uiState.isSaving = false;
        return;
      }
      this.clearMessage();

      this.toast(
        "Success",
        responseWrapper.message || "Timesheet saved.",
        "success"
      );

      this.uiState.isSubmitting = false;
      this.uiState.isSaving = false;
      this.cancelHandler();
      this.resetAllRows();
    } catch (caughtError) {
      const normalizedError = this.normalizeApexError(caughtError);
      this.toast("Timesheet", normalizedError.message, "error");
      this.uiState.isSubmitting = false;
      this.uiState.isSaving = false;
    }
  }

  cancelHandler() {
    // up to you: close quick action / modal / navigate back

    this.dispatchEvent(
      new CloseActionScreenEvent({ bubbles: true, composed: true })
    );
  }

  // ========= Validation =========
  validateAllInputs() {
    let isValid = true;

    // 1) Validate child rows (desktop)
    const rowComponents = this.template.querySelectorAll("c-timesheet-row");
    rowComponents.forEach((rowComponent) => {
      const childValid = rowComponent.reportValidity();
      if (!childValid) isValid = false;
    });

    // 2) Validate inline mobile inputs (mobile section uses direct inputs)
    // This will only find elements in parent template (mobile markup)
    const mobileInputs = this.template.querySelectorAll(
      "lightning-input.validated, lightning-textarea.validated, lightning-input-field.validated"
    );

    mobileInputs.forEach((inputElement) => {
      if (typeof inputElement.reportValidity === "function") {
        const ok = inputElement.reportValidity();
        if (!ok) isValid = false;
      }
    });

    return isValid;
  }

  // ========= Payload builder =========
  buildCreateTimesheetPayload() {
    const employeeId = this.employeeContext.employeeRecordId || this.recordId;

    const mapRowToRecord = (rowItem, entityType) => ({
      ProjectId: rowItem.projectId,
      Approver: rowItem.approverId,
      Approver_Optional: rowItem.approverOptionalId,
      start_date: rowItem.date,
      end_date: rowItem.date,
      stime: rowItem.stime,
      EmployeeID: employeeId,
      //   remark: rowItem.temp_remark,
      remark: this.buildCombinedRemark(rowItem, entityType),
      Email: this.employeeContext.email,
      type: entityType,
      ObjectRecordId: rowItem.objectRecordId
    });

    const records = []
      .concat(
        this.listProjects.map((rowItem) => mapRowToRecord(rowItem, "project"))
      )
      .concat(this.listCases.map((rowItem) => mapRowToRecord(rowItem, "case")))
      .concat(this.listPOCs.map((rowItem) => mapRowToRecord(rowItem, "poc")))
      .concat(
        this.listOpportunities.map((rowItem) => mapRowToRecord(rowItem, "opty"))
      )
      .concat(
        this.listCampaigns.map((rowItem) => mapRowToRecord(rowItem, "campaign"))
      );

    return records;
  }

  buildCombinedRemark(rowItem, entityType) {
    const r = rowItem || {};

    // console.log(
    //   "buildCombinedRemark rowItem",
    //   JSON.stringify(rowItem, null, 2)
    // );

    // prefix rule:
    // - project => SPK (fallback projectName)
    // - others  => objectLabel (fallback objectRecordId)
    let prefix = "";

    if (entityType === "project") {
      prefix = (r.projectSpk || r.projectName || "").trim();
    } else {
      prefix = (r.objectLabel || r.objectRecordId || "").trim();
    }

    const note = (r.temp_remark || "").trim();

    // if both empty, return empty string
    if (!prefix && !note) return "";

    // if only one exists
    if (!prefix) return note;
    if (!note) return prefix;

    // both exist
    return `${prefix} - ${note}`;
  }

  // ========= Utility =========
  getAllRows() {
    return []
      .concat(this.listProjects)
      .concat(this.listCases)
      .concat(this.listPOCs)
      .concat(this.listOpportunities)
      .concat(this.listCampaigns);
  }

  resetAllRows() {
    this.listProjects = [];
    this.listCases = [];
    this.listPOCs = [];
    this.listOpportunities = [];
    this.listCampaigns = [];
  }

  generateTempId() {
    return `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  }

  toast(title, message, variant) {
    // Only allow SUCCESS toast per requirement
    if (variant !== "success") {
      this.showMessage(variant || "info", title, message);
      return;
    }
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  normalizeResponse(apexData) {
    let responseObject = apexData;

    try {
      if (typeof apexData === "string") {
        responseObject = JSON.parse(apexData);
      }
    } catch (parseError) {
      return {
        success: false,
        code: "INVALID_RESPONSE",
        message: "Response is not valid JSON.",
        payload: null
      };
    }

    return {
      success: responseObject?.success === true,
      code: responseObject?.code,
      message: responseObject?.message,
      payload: responseObject?.payload
    };
  }

  normalizeApexError(apexError) {
    let message = "Unknown error.";
    let code = "APEX_ERROR";

    if (apexError?.body) {
      if (Array.isArray(apexError.body)) {
        message = apexError.body.map((item) => item.message).join(", ");
      } else if (typeof apexError.body.message === "string") {
        message = apexError.body.message;
      }
      code = apexError.body.errorCode || code;
    } else if (apexError?.message) {
      message = apexError.message;
    }

    return { code, message };
  }

  getListNameByEntityType(entityType) {
    const mapEntityToList = {
      opty: "listOpportunities",
      project: "listProjects",
      case: "listCases",
      poc: "listPOCs",
      campaign: "listCampaigns"
    };
    return mapEntityToList[entityType];
  }

  getRowByTempId(entityType, tempId) {
    const list = this.getListByEntityType(entityType);
    return (list || []).find((r) => r.tempId === tempId) || null;
  }

  getListByEntityType(entityType) {
    if (entityType === "project") return this.listProjects;
    if (entityType === "case") return this.listCases;
    if (entityType === "poc") return this.listPOCs;
    if (entityType === "opty") return this.listOpportunities;
    if (entityType === "campaign") return this.listCampaigns;
    return [];
  }

  revertRowField(entityType, tempId, fieldName, prevValue) {
    // revert state ke value sebelumnya (atau null kalau gak ada)
    const patch = { [fieldName]: prevValue ?? null };

    if (entityType === "project") {
      this.listProjects = this.updateRow(this.listProjects, tempId, patch);
    } else if (entityType === "case") {
      this.listCases = this.updateRow(this.listCases, tempId, patch);
    } else if (entityType === "poc") {
      this.listPOCs = this.updateRow(this.listPOCs, tempId, patch);
    } else if (entityType === "opty") {
      this.listOpportunities = this.updateRow(
        this.listOpportunities,
        tempId,
        patch
      );
    } else if (entityType === "campaign") {
      this.listCampaigns = this.updateRow(this.listCampaigns, tempId, patch);
    }
  }

  /** Convert "YYYY-MM-DD" to a local Date at 00:00:00 */
  toLocalDate(yyyyMmDd) {
    // safer parsing: split not relying on Date(string) quirks
    const [y, m, d] = (yyyyMmDd || "").split("-").map((x) => Number(x));
    if (!y || !m || !d) return null;
    return new Date(y, m - 1, d, 0, 0, 0, 0);
  }

  getTodayLocal() {
    const now = new Date();
    return new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0,
      0
    );
  }

  addDays(dateObj, deltaDays) {
    const d = new Date(dateObj);
    d.setDate(d.getDate() + deltaDays);
    return d;
  }
  getChildRowComponent(tempId) {
    const nodes = this.template.querySelectorAll("c-timesheet-row");

    // console.log("nodes", JSON.stringify(nodes));
    return (
      Array.from(nodes).find((n) => String(n.tempid) === String(tempId)) || null
    );
  }

  notifyChildFieldError(tempId, fieldName, message, prevValue) {
    const rowCmp = this.getChildRowComponent(tempId);
    if (!rowCmp) return;

    rowCmp.setFieldError(fieldName, message);
    rowCmp.revertFieldValue(fieldName, prevValue);
  }

  validatePayloadList(payloadList = []) {
    const errors = [];

    // 1) empty payload
    if (!Array.isArray(payloadList) || payloadList.length === 0) {
      return {
        isValid: false,
        errors: [
          {
            rowIndex: null,
            field: "payloadList",
            message: "No timesheet entries to save or submit."
          }
        ]
      };
    }

    // helpers
    const parseYMD = (ymd) => {
      // ymd: "YYYY-MM-DD"
      if (!ymd || typeof ymd !== "string") return null;
      const d = new Date(`${ymd}T00:00:00`);
      return Number.isNaN(d.getTime()) ? null : d;
    };

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const minDate = new Date(today);
    minDate.setDate(minDate.getDate() - 7);

    payloadList.forEach((row, idx) => {
      // 2) required fields
      this.validateRequiredFields(row, idx, errors);
      // 3) stime validation
      const hours = Number(row?.stime);
      if (
        row?.stime !== undefined &&
        row?.stime !== null &&
        row?.stime !== ""
      ) {
        if (Number.isNaN(hours)) {
          errors.push({
            rowIndex: idx,
            field: "stime",
            message: "Time must be a valid number."
          });
        } else if (hours <= 0) {
          errors.push({
            rowIndex: idx,
            field: "stime",
            message: "Time must be greater than 0."
          });
        } else if (hours > 24) {
          errors.push({
            rowIndex: idx,
            field: "stime",
            message: "Hours cannot be more than 24 hours (1 day)."
          });
        }
      }

      // 4) date range validation (start & end)
      const start = parseYMD(row?.start_date);
      const end = parseYMD(row?.end_date);

      if (!start) {
        errors.push({
          rowIndex: idx,
          field: "start_date",
          message: "Start date must be a valid date."
        });
      } else if (start > today || start < minDate) {
        errors.push({
          rowIndex: idx,
          field: "start_date",
          message:
            "Date must be within the last 7 days and cannot be in the future."
        });
      }

      if (!end) {
        errors.push({
          rowIndex: idx,
          field: "end_date",
          message: "End date must be a valid date."
        });
      } else if (end > today || end < minDate) {
        errors.push({
          rowIndex: idx,
          field: "end_date",
          message:
            "Date must be within the last 7 days and cannot be in the future."
        });
      }

      // 5) OPTIONAL: kalau lu anggep entry harus 1 hari aja
      // (kalau lu memang daily timesheet, ini recommended)
      if (start && end && start.getTime() !== end.getTime()) {
        errors.push({
          rowIndex: idx,
          field: "end_date",
          message: "Start date and end date must be the same day."
        });
      }

      if (!this.isEmptyValue(row?.remark)) {
        const remark = String(row.remark).trim();
        if (remark.length < 15) {
          errors.push({
            rowIndex: idx,
            field: "remark",
            message:
              "Please add more details. Remarks must be at least 15 characters long."
          });
        }
      }
    });

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // helper: friendly label per field + per type
  getFieldLabel(field, rowType) {
    const type = (rowType || "").toLowerCase();

    // Lookup label depends on type
    const lookupLabelByType = {
      project: "Project SPK",
      case: "Case Number",
      poc: "POC Number",
      opty: "Opportunity",
      opportunity: "Opportunity",
      campaign: "Campaign"
    };

    const base = {
      EmployeeID: "Employee",
      stime: "Hours",
      start_date: "Date",
      end_date: "Date",
      remark: "Remarks",
      type: "Type"
    };

    if (field === "ObjectRecordId") {
      return lookupLabelByType[type] || "Record";
    }

    return base[field] || field;
  }

  isEmptyValue(val) {
    return (
      val === null ||
      val === undefined ||
      (typeof val === "string" && val.trim() === "")
    );
  }

  // ✅ this one validates required fields with better messages
  validateRequiredFields(row, idx, errors) {
    const requiredFields = [
      "type",
      "EmployeeID",
      "ObjectRecordId",
      "stime",
      "start_date",
      "end_date",
      "remark"
    ];

    const rowType = row?.type;

    for (const f of requiredFields) {
      const val = row?.[f];

      if (this.isEmptyValue(val)) {
        // Special: start_date & end_date -> "Date is required." (only once)
        if (f === "start_date" || f === "end_date") {
          const alreadyHasDateError = errors.some(
            (e) => e.rowIndex === idx && e.field === "Date_required"
          );
          if (!alreadyHasDateError) {
            errors.push({
              rowIndex: idx,
              field: "Date_required",
              message: "Date is required."
            });
          }
          continue;
        }

        errors.push({
          rowIndex: idx,
          field: f,
          message: `${this.getFieldLabel(f, rowType)} is required.`
        });
      }
    }
  }
  // =============================
  // AI REMARK - HELPERS
  // =============================
  getListRefByType(type) {
    switch (type) {
      case "project":
        return "listProjects";
      case "case":
        return "listCases";
      case "poc":
        return "listPOCs";
      case "opty":
        return "listOpportunities";
      case "campaign":
        return "listCampaigns";
      default:
        return null;
    }
  }

  findRow(type, tempId) {
    const listRef = this.getListRefByType(type);
    if (!listRef || !Array.isArray(this[listRef])) return null;
    return (
      this[listRef].find((r) => String(r.tempId) === String(tempId)) || null
    );
  }

  patchRow(type, tempId, patch) {
    const listRef = this.getListRefByType(type);
    if (!listRef || !Array.isArray(this[listRef])) return;

    this[listRef] = this[listRef].map((r) => {
      if (String(r.tempId) !== String(tempId)) return r;
      return { ...r, ...patch };
    });
  }

  buildAiPayload(row) {
    // payload minimal yang kamu mau: ObjectRecordId sebagai primary + beberapa context row
    // (ProjectId/ApproverId gak dipakai)
    return {
      ObjectRecordId: row?.objectRecordId || row?.ObjectRecordId || "",
      type: row?.type || "",
      EmployeeID:
        this.employeeContext?.employeeRecordId || row?.EmployeeID || "",
      Email: this.employeeContext?.employeeEmail || row?.Email || "",

      // date range (kalau kamu simpan start/end, pakai itu; kalau single date, set keduanya sama)
      start_date: row?.start_date || row?.date || "",
      end_date: row?.end_date || row?.date || "",

      stime: row?.stime || "",

      // remark existing bisa bantu AI ngerti prefix
      remark: row?.temp_remark || row?.remark || ""
    };
  }

  // prefix helper: keep “SPK - ” / “CASE# - ” kalau udah ada
  extractPrefix(remark) {
    if (!remark) return "";
    const s = String(remark).trim();

    // ambil prefix sebelum " - " kalau ada
    const idx = s.indexOf(" - ");
    if (idx > 0) return s.slice(0, idx).trim();

    // fallback: kalau user udah isi manual tanpa separator, prefix kosong biar gak maksa
    return "";
  }

  clamp255(text) {
    if (!text) return "";
    const s = String(text);
    return s.length > 255 ? s.slice(0, 255) : s;
  }

  // =============================
  // AI REMARK - EVENTS
  // =============================
  async handleRowRemarkGenerate(event) {
    const { tempId, entityType } = event.detail || {};
    const row = this.findRow(entityType, tempId);

    if (!row) return;

    // minimal gate: harus ada recordId biar AI bisa baca record
    const objectId = row?.objectRecordId || row?.ObjectRecordId;
    if (!objectId) {
      this.patchRow(entityType, tempId, {
        aiError:
          "Please select a record first. AI remark generation needs a valid record.",
        aiPreviewText: null,
        isGeneratingRemark: false
      });
      return;
    }

    // set loading
    this.patchRow(entityType, tempId, {
      isGeneratingRemark: true,
      aiError: null
    });

    try {
      const payload = this.buildAiPayload({
        ...row,
        type: entityType
      });

      console.log("AI payload:", JSON.stringify(payload, null, 2));
      // call Apex
      const result = await generateTimesheetRemark({
        payloadJson: JSON.stringify(payload)
      });

      // result asumsi: string remark suggestion
      console.log("AI result:", JSON.stringify(result, null, 2));
      const suggestion = (result?.suggestedRemark || "").trim();

      if (!suggestion) {
        this.patchRow(entityType, tempId, {
          aiError: "No suggestion was generated. Please try again.",
          aiPreviewText: null,
          isGeneratingRemark: false
        });
        return;
      }

      this.patchRow(entityType, tempId, {
        aiPreviewText: suggestion,
        isGeneratingRemark: false,
        aiError: null
      });
    } catch (e) {
      const msg =
        e?.body?.message ||
        e?.message ||
        "Something went wrong while generating the remark.";

      this.patchRow(entityType, tempId, {
        aiError: msg,
        aiPreviewText: null,
        isGeneratingRemark: false
      });
    }
  }

  handleRowRemarkDiscard(event) {
    const { tempId, entityType } = event.detail || {};
    this.patchRow(entityType, tempId, {
      aiPreviewText: null,
      aiError: null,
      isGeneratingRemark: false
    });
  }

  handleRowRemarkApply(event) {
    const { tempId, entityType, previewText } = event.detail || {};
    const row = this.findRow(entityType, tempId);
    if (!row) return;

    const existingRemark = row?.temp_remark || "";
    const prefix = this.extractPrefix(existingRemark);

    // apply: keep prefix kalau ada, lalu tempel preview text
    const finalRemark = prefix
      ? `${prefix} - ${String(previewText || "").trim()}`
      : String(previewText || "").trim();

    this.patchRow(entityType, tempId, {
      temp_remark: this.clamp255(finalRemark),
      aiPreviewText: null,
      aiError: null,
      isGeneratingRemark: false
    });

    // optional: kalau kamu butuh parent logic yg sama kaya blur change,
    // kamu bisa panggil handleRowFieldChange manual di sini.
    // tapi biasanya patchRow udah cukup karena row state tersimpan.
  }
}
