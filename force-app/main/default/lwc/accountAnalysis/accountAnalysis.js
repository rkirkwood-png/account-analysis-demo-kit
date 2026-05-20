import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountResearchController.searchAccounts';
import dealAnalysisLogo from '@salesforce/resourceUrl/dealAnalysisLogo';

export default class AccountAnalysis extends LightningElement {
    @track selectedAccountId;
    @track selectedAccountName;
    @track searchResults;
    @track searchTerm;
    searchTimeout;
    logoUrl = dealAnalysisLogo;

    handleSearchInput(event) {
        const term = event.detail.value;
        this.searchTerm = term;
        clearTimeout(this.searchTimeout);
        if (term && term.length > 1) {
            this.searchTimeout = setTimeout(() => {
                searchAccounts({ searchTerm: term })
                    .then(results => { this.searchResults = results.length > 0 ? results : null; })
                    .catch(() => { this.searchResults = null; });
            }, 300);
        } else {
            this.searchResults = null;
        }
    }

    handleAccountSelect(event) {
        this.selectedAccountId = event.currentTarget.dataset.id;
        this.selectedAccountName = event.currentTarget.dataset.name;
        this.searchResults = null;
        this.searchTerm = '';
    }

    clearSelection() {
        this.selectedAccountId = null;
        this.selectedAccountName = null;
        this.searchResults = null;
        this.searchTerm = '';
    }
}