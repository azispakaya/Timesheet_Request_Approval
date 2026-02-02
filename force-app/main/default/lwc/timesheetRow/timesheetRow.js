import { LightningElement, api } from "lwc";

export default class TimesheetRow extends LightningElement {
  @api tempid; // string/number
  @api entityType; // 'project' | 'case' | 'poc' | 'opty' | 'campaign'
  @api badgeLabel;
  @api badgeClass;

  // layout helper
  @api formFactorClass;

  // lookup config
  @api lookupFieldApiName; // ex: 'Project__c'
  @api lookupName; // ex: 'project_name'

  // =============================
  // REMOVE
  // =============================
  handleRemoveClick() {
    this.dispatchEvent(
      new CustomEvent("rowremove", {
        detail: {
          tempId: this.tempid,
          entityType: this.entityType
        },
        bubbles: true,
        composed: true
      })
    );
  }

  // =============================
  // FIELD CHANGES
  // =============================
  handleLookupChange(event) {
    // lightning-input-field -> event.detail.value
    const selectedValue = event.target?.value;
    // console.log("selectedValue", selectedValue);
    this.dispatchRowFieldChange({
      fieldName: "objectRecordId", // keep same as your old "name" usage
      value: selectedValue
    });
  }

  handleInputChange(event) {
    // lightning-input / lightning-textarea -> event.target.value
    const fieldName = event.target?.name;
    const value = event.target?.value;

    this.dispatchRowFieldChange({ fieldName, value });
  }

  dispatchRowFieldChange({ fieldName, value }) {
    this.dispatchEvent(
      new CustomEvent("rowfieldchange", {
        detail: {
          tempId: this.tempid,
          entityType: this.entityType,
          fieldName,
          value
        },
        bubbles: true,
        composed: true
      })
    );
  }
}
