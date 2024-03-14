import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql } from "lightning/uiGraphQLApi";
import ConvertApproverName from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"

export default class ViewActiveTimesheetApproval extends LightningElement {

    results
    errors
    @api recordId
    ApproverName

    connectedCallback(){
        ConvertApproverName({ recordPageId : this.recordId})
        .then((res)=>{
            this.ApproverName = res;
        })
    }

    @wire(graphql, {
        query: gql`
            query timesheets($ApproverName : String){
                uiapi{
                    query{
                        Timesheet__c(where: {Timesheet_Approver__r :{Name : { eq: $ApproverName}}})
                        {
                            edges{
                                node{
                                    Id
                                    Name{
                                        value
                                    }
                                    Employee__r{
                                        Name{
                                            value
                                        }
                                        Employee_ID__c{
                                            value
                                        }
                                    }
                                    Project__r{
                                        Name{
                                            value
                                        }
                                        SPK__c{
                                            value
                                        }
                                    }
                                    Start_Date__c{
                                        value
                                    }
                                    End_Date__c{
                                        value
                                    }
                                    Time__c{
                                        value
                                    }
                                    Remarks__c{
                                        value
                                    }
                                    Approval_Status__c{
                                        value
                                    }
                                    Timesheet_Approver__r{
                                        Name{
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
        variables: "$variables",
    })
    graphqlQueryResult({ data, errors }) {
        if (data) {
          this.results = data.uiapi.query.Timesheet__c.edges.map((edge) => edge.node);
        }
        this.errors = errors;
    }

    get variables() {
        return {
          ApproverName: this.ApproverName,
        };
      }
    

}