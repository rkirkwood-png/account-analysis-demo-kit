import { LightningElement, api, track } from 'lwc';
import getInteractionSummary from '@salesforce/apex/MeetingPrepController.getInteractionSummary';

export default class AccountSummary extends LightningElement {
    _accountId;
    @track result;
    @track isLoading = false;
    @track error;
    _isConnected = false;

    @api
    get accountId() {
        return this._accountId;
    }

    set accountId(value) {
        const hasChanged = value !== this._accountId;
        this._accountId = value;
        if (this._isConnected && hasChanged && value) {
            this.load();
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._accountId) {
            this.load();
        }
    }

    async load() {
        this.isLoading = true;
        this.error = null;
        this.result = null;
        try {
            this.result = await getInteractionSummary({ accountId: this._accountId });
        } catch (e) {
            this.error = 'Unable to load interaction summary.';
        } finally {
            this.isLoading = false;
        }
    }
}
