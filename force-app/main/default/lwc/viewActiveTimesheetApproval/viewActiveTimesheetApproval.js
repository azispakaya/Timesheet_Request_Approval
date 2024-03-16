import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql,refreshGraphQL } from "lightning/uiGraphQLApi";
import ConvertApproverName from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"
import updateStatus from "@salesforce/apex/lwc_ApprovalTimesheetController.updateApprovalStatus"
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import modalEditLine from 'c/modalCommentTimesheet';

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
        
        // console.log(JSON.stringify(this.draftTimesheet))
    }

    handleRefresh(event){

        refreshGraphQL(this.graphQlData)
        this.toast('Successfully Refresh', 'success', 'Info')
    }

    async handleApprove(event){
        this.draftTimesheet.forEach(item => {
            item.ApprovalStatus = 'Fully Approved',
            item.Comment = 'This Timesheet Successfully Approved'
        })

        await updateStatus({
            Timesheets : JSON.stringify(this.draftTimesheet)
        }).then((res)=>{

            refreshGraphQL(this.graphQlData)
            this.toast('Successfully Approved', 'success', 'Info')

        }).catch((error)=>{
            console.log(error)
        })
        

        // console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleReject(event){
        this.draftTimesheet.forEach(item =>{
            item.ApprovalStatus = 'Rejected',
            item.Comment = 'This Timesheet has been Rejected, Please Re-Submit'
        })
        await updateStatus({
            
            Timesheets : JSON.stringify(this.draftTimesheet)

        }).then((res)=>{

            refreshGraphQL(this.graphQlData)
            this.toast('Successfully Rejected', 'warning', 'Info')

        }).catch((error)=>{
            console.log(error)
        })


        // console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleEditLine(event){

        let singleTimesheet = []
        const timesheetId = event.target.dataset.id

        
        const resultComment = await modalEditLine.open({
            headerLabel: 'Add Comment',
            // timesheets: this.draftTimesheet
        })

        singleTimesheet.push({
            recordid : timesheetId,
            Comment : resultComment.split(';')[0],
            ApprovalStatus : resultComment.split(';')[1]
        })

        if(resultComment != 'cancel'){
            await updateStatus({

                Timesheets : JSON.stringify(singleTimesheet)

            }).then((res)=>{
                refreshGraphQL(this.graphQlData)
                this.toast('Updated Successfully','success','Success') 
            }).catch((e)=>{
                console.log(e)
            })
        }
       

        // console.log(JSON.stringify(singleTimesheet));

        
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

    toast(message, variant, title) {
        const callToast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
        this.dispatchEvent(callToast);
    }
    

}