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

        local dataShowYear = {
            {},
            {start_y, },
            {start_y, end_y},
            {nil, end_y},
        }

        local dataHideYear = {
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

        local function dateDisplay(date)
            if not date then
                return ''
            end
            return (date.year or '????') .. '-'
                .. (date.month or '??') .. '-'
                .. (date.day or '??')
        end

		GoldenTest(
            'date range display',
            tostring(HtmlWidgets.Div{children={
                HtmlWidgets.Table{
                    classes={'wikitable wikitable-striped'},
                    children=Array.extend(
                        {
                            HtmlWidgets.Tr{children={
                                HtmlWidgets.Th{children="startDate"},
                                HtmlWidgets.Th{children="endDate"},
                                HtmlWidgets.Th{children="DateRange display"},
                            }}
                        },
                        Array.map(dataShowYear, function (entry)
                            return HtmlWidgets.Tr{children={
                                HtmlWidgets.Td{children=dateDisplay(entry[1])},
                                HtmlWidgets.Td{children=dateDisplay(entry[2])},
                                HtmlWidgets.Td{children=DateRange{
                                    startDate = entry[1],
                                    endDate = entry[2]},
                                    showYear = true
                                },
                            }}
                        end)
                    )
                },
                HtmlWidgets.Table{
                    classes={'wikitable wikitable-striped'},
                    children=Array.extend(
                        {
                            HtmlWidgets.Tr{children={
                                HtmlWidgets.Th{children="startDate"},
                                HtmlWidgets.Th{children="endDate"},
                                HtmlWidgets.Th{children="DateRange display"},
                            }}
                        },
                        Array.map(dataHideYear, function (entry)
                            return HtmlWidgets.Tr{children={
                                HtmlWidgets.Td{children=dateDisplay(entry[1])},
                                HtmlWidgets.Td{children=dateDisplay(entry[2])},
                                HtmlWidgets.Td{children=DateRange{
                                    startDate = entry[1],
                                    endDate = entry[2]
                                }},
                            }}
                        end)
                    )
                },
            }}
            )
        )
	end)
end)
