liquipedia.rankingTable = {
    identifierAttribute: 'data-ranking-table-id',
    toggleButton: '[data-ranking-table="toggle"]',
    graphRow: '[data-ranking-table="graph-row"]',
    dropdownContainer: '[data-ranking-table="dropdown-container"]',
    patchLabel: '[data-ranking-table="patch-label"]',
    patchLabelElement: null,
    // temp test data
    options: [
        {
            value: 'option1',
            text: 'April 22, 2024',
            patch: 'Patch 1.2.3'
        },
        {
            value: 'option2',
            text: 'April 15, 2024',
            patch: 'Patch 1.2.2'
        },
        {
            value: 'option3',
            text: 'April 08, 2024',
            patch: 'Patch 1.2.1'
        }
    ],

    init: function () {
        this.toggleGraphVisibility();
        this.createAndAppendSelectElementWithOptions();
    },

    // addCallbackForDropdown: function () {
    //     const selectElement = document.querySelector('#weekSelector');
    //     if (selectElement) {
    //         selectElement.addEventListener('change', (event) => {
    //             console.log('change', event.target.tagName);
    //             if (event.target.tagName === 'SELECT') {
    //                 const week = event.target.value;
    //                 this.fetchRatingsData(week);
    //             }
    //         });
    //     }
    // },

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

    updatePatchLabel: function (patch) {
        if (!this.patchLabelElement) {
            this.patchLabelElement = document.querySelector(this.patchLabel);
        }
        this.patchLabelElement.innerText = patch;
    },

    createAndAppendSelectElementWithOptions: function () {
        const selectContainer = document.querySelector(this.dropdownContainer);

        if (!selectContainer) {
            return;
        }

        const selectElement = this.createSelectElement();
        const optionElements = this.createOptions();

        selectElement.append(...optionElements);
        selectContainer.insertBefore(selectElement, selectContainer.firstChild);
    },

    createSelectElement: function () {
        const selectElement = document.createElement('select');
        selectElement.id = 'weekSelector';
        selectElement.classList.add('ranking-table__dropdown-select');
        return selectElement;
    },

    createOptions: function () {
        const options = [];

        this.options.forEach( (option, index ) => {
            const optionElement = document.createElement('option');

            // Set the first option as selected by default
            if (index === 0) {
                optionElement.selected = true;
                this.updatePatchLabel(option.patch);
            }
            optionElement.value = option.value;
            optionElement.innerText = option.text;
            options.push(optionElement);
        });

        return options;
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