import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql,refreshGraphQL } from "lightning/uiGraphQLApi";
import ConvertApproverName from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"
import updateStatus from "@salesforce/apex/lwc_ApprovalTimesheetController.updateApprovalStatus"

export default class ViewActiveTimesheetApproval extends LightningElement {

    results
    errors
    @api recordId
    ApproverName
    ApprovalStatus

    @track draftTimesheet = []

    connectedCallback(){
        ConvertApproverName({ recordPageId : this.recordId})
        .then((res)=>{
            this.ApproverName = res;
            this.ApprovalStatus = 'Waiting for Approval'
        })
    }

    @wire(graphql, {
        query: gql`
            query timesheets($ApproverName : String, $ApprovalStatus : Picklist){
                uiapi{
                    query{
                        Timesheet__c(
                            where : {
                                and : [
                                    {Timesheet_Approver__r :{Name :{eq : $ApproverName}}},
                                    {Approval_Status__c : {eq : $ApprovalStatus}}
                                ]
                            }
                        ){
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
    graphqlQueryResult(result) {
        const { data, errors } = result

        if (data) {
          this.results = data.uiapi.query.Timesheet__c.edges.map((edge) => edge.node);
        }
        this.errors = errors;
        this.graphQlData = result
    }

    handleChecked(event){
        const timesheetId = event.target.dataset.id

        const duplicate = this.draftTimesheet.some((timesheet) => timesheet.recordid === timesheetId)
        if(!duplicate) {
            this.draftTimesheet.push({
                recordid : timesheetId
            })
        }else{
            this.draftTimesheet = this.draftTimesheet.filter(item => item.recordid !== timesheetId)
        }
        
        console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleApprove(event){
        this.draftTimesheet.forEach(item => {
            item.ApprovalStatus = 'Fully Approved'
        })

        await updateStatus({
            Timesheets : JSON.stringify(this.draftTimesheet)
        }).then((res)=>{
            console.log(res)
            
        }).then(()=>{
            refreshGraphQL(this.graphQlData)
        })
        

        console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleReject(event){
        this.draftTimesheet.forEach(item =>{
            item.ApprovalStatus = 'Rejected'
        })
        await updateStatus({
            Timesheets : JSON.stringify(this.draftTimesheet)
        }).then((res)=>{
            console.log(res)
            
        }).then(()=>{
            refreshGraphQL(this.graphQlData)
        })

        // await refreshGraphQL(this.graphQlData)

        console.log(JSON.stringify(this.draftTimesheet))
    }

    get variables() {
        return {
          ApproverName: this.ApproverName,
          ApprovalStatus: this.ApprovalStatus,
        };
      }
    
    @api
    async refreshData(){
        return refreshGraphQL(this.results)
    }
    

}