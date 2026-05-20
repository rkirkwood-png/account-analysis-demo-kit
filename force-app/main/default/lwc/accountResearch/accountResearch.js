import { LightningElement, api, track } from 'lwc';
import getAccountResearch from
'@salesforce/apex/AccountResearchController.getAccountResearch';

export default class AccountResearch extends LightningElement {
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
            this.research();
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._accountId) {
            this.research();
        }
    }

    async research() {
        this.isLoading = true;
        this.error = null;
        this.result = null;
        try {
            const response = await getAccountResearch({ accountId: this.accountId });
            this.result = JSON.parse(response);
        } catch (e) {
            this.error = 'Unable to research this account. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    get newsWithLinks() {
        if (!this.result || !this.result.news) return [];
        return this.result.news.map(item => ({
            ...item,
            resolvedUrl: item.url || `https://www.google.com/search?q=${encodeURIComponent(item.title)}&tbm=nws`
        }));
    }
}