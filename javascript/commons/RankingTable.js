liquipedia.rankingTable = {
    toggleButton: '[data-ranking-table="toggle"]',
    graphRow: '[data-ranking-table="graph-row"]',
    identifierAttribute: 'data-ranking-table-id',

    init: function () {
        this.toggleGraphVisibility();

        // find select element
        const selectElement = document.querySelector('#weekSelector');
        if (selectElement) {
            selectElement.addEventListener('change', (event) => {
                console.log('change', event.target.tagName);
                if (event.target.tagName === 'SELECT') {
                    const week = event.target.value;
                    this.fetchRatingsData(week);
                }
            });
        }
    },

    fetchRatingsData: function(week) {
    const api = new mw.Api();
        api.get({
            action: 'parse',
            format: 'json',
            contentmodel: 'wikitext',
            maxage: 600,
            smaxage: 600,
            disablelimitreport: true,
            uselang: 'content',
            prop: 'text',
            text: `{{RatingsList|week=${week}}}`
        }).done((data) => {
            if (data.parse?.text?.['*']) {
                this.updateRatingListTable(data.parse.text['*']);
            }
        });
    },

    updateRatingListTable: function (htmlContent) {
        const ratingsListTable = document.getElementById('ratingsListTable');
        if (ratingsListTable) {
            ratingsListTable.outerHTML = htmlContent;
        }
    },

    toggleGraphVisibility: function () {
        const elements = document.querySelectorAll(this.toggleButton);
        elements.forEach(element => {
            element.addEventListener('click', () => {
                const graphRowId = element.getAttribute(this.identifierAttribute);
                const graphRow = document.querySelector(`${this.graphRow}[${this.identifierAttribute}="${graphRowId}"]`);
                if (graphRow) {
                    graphRow.classList.toggle('d-none');
                    const isExpanded = element.getAttribute('aria-expanded') === 'true';
                    element.setAttribute('aria-expanded', String(!isExpanded));

                    if (!graphRow.classList.contains('d-none')) {
                        // Initialize or resize charts when the div is visible
                        graphRow.querySelectorAll('[_echarts_instance_]').forEach(chart => {
                            let chartInstance = echarts.getInstanceByDom(chart);
                            if (chartInstance) {
                                chartInstance.resize();
                            } else {
                                // Initialize the chart if it is not already initialized
                                chartInstance = echarts.init(chart);
                            }
                        });
                    }
                }
            });
        });
    }
};

liquipedia.core.modules.push( 'rankingTable' );