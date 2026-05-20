import { LightningElement, api, track } from 'lwc';
import getInvestmentBreakdown from '@salesforce/apex/FundReviewController.getInvestmentBreakdown';

export default class InvestmentBreakdown extends LightningElement {
    _fundId;
    @track result;
    @track isLoading = false;
    @track error;
    _isConnected = false;
    currencyFormatter = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    });

    @api
    get fundId() {
        return this._fundId;
    }

    set fundId(value) {
        const hasChanged = value !== this._fundId;
        this._fundId = value;
        if (this._isConnected && hasChanged) {
            this.load();
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._fundId) {
            this.load();
        }
    }

    async load() {
        if (!this._fundId) {
            return;
        }
        this.isLoading = true;
        this.error = null;
        this.result = null;
        try {
            const response = await getInvestmentBreakdown({ fundId: this._fundId });
            this.result = JSON.parse(response);
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Unable to load investments.';
        } finally {
            this.isLoading = false;
        }
    }

    get hasInvestments() {
        return Boolean(this.result?.investments?.length);
    }

    get investmentRows() {
        const investments = this.result?.investments || [];
        return investments.map((investment, index) => ({
            key: `${investment.investorName || 'investor'}-${index}`,
            investorName: investment.investorName || 'Unknown',
            investorType: investment.investorType || 'N/A',
            amount: this.formatCurrency(investment.amount),
            capitalCalled: this.formatCurrency(investment.capitalCalled),
            capitalRemaining: this.formatCurrency(investment.capitalRemaining)
        }));
    }

    formatCurrency(value) {
        if (value === null || value === undefined || value === '') {
            return 'N/A';
        }
        const numberValue = Number(value);
        if (Number.isNaN(numberValue)) {
            return 'N/A';
        }
        return this.currencyFormatter.format(numberValue);
    }
}
