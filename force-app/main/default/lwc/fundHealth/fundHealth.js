import { LightningElement, api, track } from 'lwc';
import getFundHealth from '@salesforce/apex/FundReviewController.getFundHealth';

export default class FundHealth extends LightningElement {
    _fundId;
    @track result;
    @track isLoading = false;
    @track error;
    _isConnected = false;

    @api
    get fundId() {
        return this._fundId;
    }

    set fundId(value) {
        const hasChanged = value !== this._fundId;
        this._fundId = value;
        if (this._isConnected && hasChanged) {
            this.analyze();
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._fundId) {
            this.analyze();
        }
    }

    async analyze() {
        if (!this._fundId) {
            return;
        }
        this.isLoading = true;
        this.error = null;
        this.result = null;
        try {
            const response = await getFundHealth({ fundId: this._fundId });
            this.result = JSON.parse(response);
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Unable to load fund health.';
        } finally {
            this.isLoading = false;
        }
    }

    get deploymentBarStyle() {
        const pct = this.result?.deploymentPercentage ?? 0;
        return `width: ${pct}%;`;
    }
}
