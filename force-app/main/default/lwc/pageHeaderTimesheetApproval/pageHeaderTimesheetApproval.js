/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:46:12
 * @modify date 2026-02-06 14:51:40
 * @desc [Controller for Header Information]
 */

import { LightningElement, api, wire } from "lwc";
import { gql, graphql } from "lightning/uiGraphQLApi";
import getApproverInfo from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName";
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class PageHeaderTimesheetApproval extends LightningElement {
  resultEmployees;
  totalTimesheets = 0;
  errors;

  @api recordId;

  employeId;
  desktopSupport;
  mobileSupport;

  get AvatarProfile() {
    return "standard:people_score";
  }

  @wire(graphql, {
    query: gql`
      query approver(
        $ApproverId: ID
        $employeID: ID
        $approvalStatus: Picklist
      ) {
        uiapi {
          query {
            Timesheet_Approval__c(where: { Id: { eq: $ApproverId } }) {
              edges {
                node {
                  Id
                  Name {
                    value
                  }
                  Approver__r {
                    Id
                    Name {
                      value
                    }
                    Employee_ID__c {
                      value
                    }
                    Role__c {
                      value
                    }
                    Department__c {
                      value
                    }
                    Email__c {
                      value
                    }
                    Mobile_Phone__c {
                      value
                    }
                  }
                }
              }
            }

            Timesheet__c(
              where: {
                and: [
                  {
                    or: [
                      { Timesheet_Approver__c: { eq: $employeID } }
                      { Timesheet_Approver_Optional__c: { eq: $employeID } }
                    ]
                  }
                  { Approval_Status__c: { eq: $approvalStatus } }
                ]
              }
            ) {
              totalCount
            }
          }
        }
      }
    `,
    variables: "$variables"
  })
  graphqlResult(result) {
    const { data, errors } = result;

    if (data) {
      const edges = data?.uiapi?.query?.Timesheet_Approval__c?.edges || [];
      this.resultEmployees = edges.map((edge) => edge.node);

      this.totalTimesheets = data?.uiapi?.query?.Timesheet__c?.totalCount || 0;
      this.errors = undefined;
      return;
    }

    if (errors) {
      this.errors = errors;
    }
  }

  async connectedCallback() {
    // form factor
    if (FORM_FACTOR === "Large") {
      this.desktopSupport = true;
      this.mobileSupport = false;
    } else {
      this.mobileSupport = true;
      this.desktopSupport = false;
    }

    // resolve employee id from wrapper-based Apex
    try {
      const res = await getApproverInfo({ recordPageId: this.recordId });

      if (!res || res.success !== true) {
        this.errors = res?.message || "Failed to load approver info.";
        return;
      }

      // wrapper.data = { name, id }
      this.employeId = res?.data?.id;
    } catch (e) {
      this.errors = e?.body?.message || e?.message || "Server error.";
    }
  }

  get variables() {
    return {
      ApproverId: this.recordId,
      employeID: this.employeId,
      approvalStatus: "Waiting for Approval"
    };
  }
}
