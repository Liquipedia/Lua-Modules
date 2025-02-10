liquipedia.rankingTable = {
    toggleButton: '[data-ranking-table="toggle"]',
    graphRow: '[data-ranking-table="graph-row"]',
    identifierAttribute: 'data-ranking-table-id',

    init: function () {
        this.toggleGraphVisibility();
    },

    toggleGraphVisibility: function () {
        const elements = document.querySelectorAll(this.toggleButton);
        elements.forEach(element => {
            element.addEventListener('click', () => {
                const graphRowId = element.getAttribute(this.identifierAttribute);
                const graphRow = document.querySelector(`[data-ranking-table="graph-row"][data-ranking-table-id="${graphRowId}"]`);
                if (graphRow) {
                    graphRow.classList.toggle('d-none');
                    // Set existing aria-expanded attribute to the opposite value
                    const isExpanded = element.getAttribute('aria-expanded') === 'true';
                    element.setAttribute('aria-expanded', String(!isExpanded));
                }
            });
        });
    }
};

liquipedia.core.modules.push( 'rankingTable' );