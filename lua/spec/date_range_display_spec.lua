--- Triple Comment to Enable our LLS Plugin
insulate('DateRange', function()
	it('DateRange display test', function()
		local DateRange = require('Module:Widget/Misc/DateRange')
		local HtmlWidgets = require('Module:Widget/Html/All')

        local start_y = {year = 2023}
        local start_ym = {year = 2023, month = 10}
        local start_ymd = {year = 2023, month = 10, day = 3}

        local end_y = {year = 2024}
        local end_ym = {year = 2024, month = 11}
        local end_ymd = {year = 2024, month = 11, day = 4}

        local widgets = {
            -- hideYear

            -- TBA display
            DateRange{},
            DateRange{startDate = start_y},
            DateRange{startDate = start_y, endDate = end_y},
            DateRange{endDate = end_ymd},

            -- Month display
            DateRange{startDate = start_ym},
            DateRange{startDate = start_ym, endDate = end_ymd},
            DateRange{startDate = start_ym, endDate = start_ym},

            -- Day display
            DateRange{startDate = start_ymd},
            DateRange{startDate = start_ymd, endDate = end_ym},
            DateRange{startDate = start_ymd, endDate = {year = 2023, month = 10}},
            DateRange{startDate = start_ymd, endDate = {year = 2023, month = 10, day = 04}},
            DateRange{startDate = start_ymd, endDate = end_ymd},
            DateRange{startDate = start_ymd, endDate = start_ymd},

            -- showYear
        }

		GoldenTest('date range display', tostring(HtmlWidgets.Div{children=widgets}))
	end)
end)