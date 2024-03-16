import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ModalCommentTimesheet extends LightningModal {
    @api headerLabel
    // @api timesheets = []
    textComment 

    HandlefieldChange(event){
        this.textComment = event.target.value
        console.log('comment: ',this.textComment)
    }

    handleRevise(){
        this.close(this.textComment+';Need to Revise')
    }

    handleReject(){
        this.close(this.textComment+';Rejected')
    }
    
    handleCancel(){
        this.close('cancel')
    }
}