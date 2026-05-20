import { LightningElement, api, track } from 'lwc';
import getRelationshipHealth from
'@salesforce/apex/RelationshipHealthController.getRelationshipHealth';

export default class RelationshipHealth extends LightningElement {
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
        if (this._isConnected && hasChanged) {
            this.analyze();
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._accountId) {
            this.analyze();
        }
    }

    async analyze() {
        this.isLoading = true;
        this.error = null;
        this.result = null;
        try {
            const response = await getRelationshipHealth({ accountId: this._accountId });
            this.result = JSON.parse(response);
        } catch (e) {
            this.error = 'Unable to analyze deal execution risk. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    get statusClass() {
        if (!this.result) return '';
        const s = this.result.status?.toLowerCase();
        if (s === 'at risk') return 'slds-theme_error';
        if (s === 'healthy') return 'slds-theme_success';
        return 'slds-theme_warning';
    }
}