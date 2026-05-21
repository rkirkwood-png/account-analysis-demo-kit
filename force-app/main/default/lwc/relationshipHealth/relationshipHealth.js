import { LightningElement, api, track } from 'lwc';
import getRelationshipHealth from
'@salesforce/apex/RelationshipHealthController.getRelationshipHealth';
import getMeetingSummaries from
'@salesforce/apex/MeetingPrepController.getMeetingSummaries';

export default class RelationshipHealth extends LightningElement {
    _accountId;
    @track result;
    @track isLoading = false;
    @track error;
    @track meetingSummaries;
    @track meetingsLoading = false;
    _isConnected = false;

    @api
    get accountId() {
        return this._accountId;
    }

    set accountId(value) {
        const hasChanged = value !== this._accountId;
        this._accountId = value;
        if (this._isConnected && hasChanged && value) {
            this.analyze();
            this.loadMeetingSummaries(value);
        }
    }

    connectedCallback() {
        this._isConnected = true;
        if (this._accountId) {
            this.analyze();
            this.loadMeetingSummaries(this._accountId);
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

    get scoreDashOffset() {
        if (!this.result) return 283;
        return 283 - ((this.result.score / 100) * 283);
    }

    get scoreRingStyle() {
        return `stroke-dashoffset: ${this.scoreDashOffset};`;
    }

    async loadMeetingSummaries(accountId) {
        this.meetingsLoading = true;
        this.meetingSummaries = null;
        try {
            const response = await getMeetingSummaries({ accountId });
            if (response) {
                this.meetingSummaries = { html: response, meetings: [{ id: 0 }] };
            }
        } catch (e) {
            this.meetingSummaries = null;
        } finally {
            this.meetingsLoading = false;
        }
    }

    parseMeetings(text) {
        const lines = text.split('\n').filter((l) => l.trim());
        const meetings = [];
        let intro = null;
        let current = null;

        for (const line of lines) {
            const emojiMatch = line.match(/^(\p{Emoji_Presentation}|\p{Extended_Pictographic})/u);
            if (emojiMatch) {
                if (current) meetings.push(current);
                current = { id: meetings.length, emoji: emojiMatch[0], text: line.replace(emojiMatch[0], '').trim() };
            } else if (!current && !intro) {
                intro = line.trim();
            } else if (current) {
                current.text += ` ${line.trim()}`;
            }
        }
        if (current) meetings.push(current);
        return { intro, meetings };
    }

    get hasMeetingSummaries() {
        return !!(this.meetingSummaries && this.meetingSummaries.meetings && this.meetingSummaries.meetings.length);
    }
}