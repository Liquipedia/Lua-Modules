--- Triple Comment to Enable our LLS Plugin
insulate('DateRange', function()
	it('DateRange display test', function()
        local Array = require('Module:Array')
		local DateRange = require('Module:Widget/Misc/DateRange')
		local HtmlWidgets = require('Module:Widget/Html/All')

        local start_y = {year = 2023}
        local start_ym = {year = 2023, month = 10}
        local start_ymd = {year = 2023, month = 10, day = 3}

        local end_y = {year = 2024}
        local end_ym = {year = 2024, month = 11}
        local end_ymd = {year = 2024, month = 11, day = 4}

        local data = {
            -- hideYear
            -- TBA display
            {},
            {start_y, },
            {start_y, end_y},
            {nil, end_ymd},

            -- Month display
            {start_ym},
            {start_ym, end_ymd},
            {start_ym, start_ym},

            -- Day display
            {start_ymd},
            {start_ymd, end_ym},
            {start_ymd, {year = 2023, month = 10}},
            {start_ymd, {year = 2023, month = 10, day = 04}},
            {start_ymd, end_ymd},
            {start_ymd, start_ymd},

            -- showYear
        }


		GoldenTest(
            'date range display',
            tostring(HtmlWidgets.Table{
                classes={'wikitable wikitable-striped'},
                children=Array.extend(
                    {
                        HtmlWidgets.Tr{children={
                            HtmlWidgets.Th{children="startDate"},
                            HtmlWidgets.Th{children="endDate"},
                            HtmlWidgets.Th{children="DateRange display"},
                        }}
                    },
                    Array.map(data, function (entry)
                        return HtmlWidgets.Tr{children={
                            HtmlWidgets.Td{children=mw.dumpObject(entry[1] or {})},
                            HtmlWidgets.Td{children=mw.dumpObject(entry[2] or {})},
                            HtmlWidgets.Td{children=DateRange{startDate = entry[1], endDate = entry[2]}},
                        }}
                    end)
                )
            })
        )
	end)
end)
