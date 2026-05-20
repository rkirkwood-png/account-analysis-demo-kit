import { LightningElement, track } from 'lwc';

export default class FundReview extends LightningElement {
    @track selectedFundId;

    handleFundSelect(event) {
        this.selectedFundId = event.detail.recordId;
    }
}
