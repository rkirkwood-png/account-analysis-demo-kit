import { LightningElement, api, track } from 'lwc';
import getMeetingPrep from '@salesforce/apex/MeetingPrepController.getMeetingPrep';

export default class MeetingPrepBrief extends LightningElement {
    @track sections;
    @track isLoading = false;
    @track error;
    _accountId;

    @api
    get accountId() {
        return this._accountId;
    }
    set accountId(value) {
        this._accountId = value;
        if (value) this.load();
    }

    async load() {
        this.isLoading = true;
        this.error = null;
        this.sections = null;
        try {
            const response = await getMeetingPrep({ accountId: this._accountId });
            this.sections = this.parseSections(response);
        } catch (e) {
            this.error = 'Unable to generate meeting prep. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    parseSections(text) {
        const iconMap = {
            growth: 'utility:trending_up',
            product: 'utility:product',
            competitive: 'utility:shield',
            linkedin: 'utility:people',
            question: 'utility:help',
            news: 'utility:broadcast',
            source: 'utility:link',
            default: 'utility:info'
        };
        const lines = text.split('\n');
        const sections = [];
        let current = null;
        for (const line of lines) {
            const headingMatch = line.match(/^#{1,3}\s+(.+)/);
            if (headingMatch) {
                if (current) sections.push(current);
                const title = headingMatch[1].replace(/\*\*/g, '').trim();
                const titleLower = title.toLowerCase();
                let icon = iconMap.default;
                for (const key of Object.keys(iconMap)) {
                    if (titleLower.includes(key)) {
                        icon = iconMap[key];
                        break;
                    }
                }
                current = { id: sections.length, title, icon, lines: [], content: '' };
            } else if (current) {
                current.lines.push(line);
            }
        }
        if (current) sections.push(current);
        return sections.map((s) => ({
            ...this.buildSectionContent(s)
        }));
    }

    buildSectionContent(section) {
        const cleanedLines = section.lines.map((line) => line.replace(/\*\*(.+?)\*\*/g, '$1').trim());
        const titleLower = section.title.toLowerCase();
        const isSourcesSection = titleLower.includes('source');
        const links = [];
        const contentLines = [];

        cleanedLines.forEach((line) => {
            const urlMatch = line.match(/https?:\/\/[^\s`]+/);
            if (isSourcesSection && urlMatch) {
                const url = urlMatch[0];
                links.push({
                    id: `${section.id}-${links.length}`,
                    url,
                    label: this.formatUrlLabel(url)
                });
            } else if (line) {
                contentLines.push(line);
            }
        });

        return {
            ...section,
            hasLinks: links.length > 0,
            links,
            content: contentLines.join('\n').trim()
        };
    }

    formatUrlLabel(url) {
        return url
            .replace(/^https?:\/\//, '')
            .replace(/\/$/, '');
    }
}
