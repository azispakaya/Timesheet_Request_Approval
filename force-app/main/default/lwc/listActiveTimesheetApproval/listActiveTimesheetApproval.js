import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class ListActiveTimesheetApproval extends NavigationMixin(LightningElement) {

    @api field
    @api selectTimesheetId

    handleSelectTimesheet(event) {
        event.preventDefault();
        const selectTimesheetEvent = new CustomEvent('selecttimesheet',{
            detail : {
                timesheetId : event.target?.dataset.Id,
                objectApiName : event.target?.dataset.objectName
            }
        })
        this.dispatchEvent(selectTimesheetEvent);
    }
}