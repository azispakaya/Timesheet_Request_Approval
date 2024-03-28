/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:45:08
 * @modify date 2024-03-24 15:45:31
 * @desc [Layout for Confirmation modal for Approve or Reject]
 */

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