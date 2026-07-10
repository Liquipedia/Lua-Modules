--- Triple Comment to Enable our LLS Plugin
insulate('DateRange', function()
	it('DateRange display test #snapshot', function()
		local Array = require('Module:Array')
		local DateRange = require('Module:Widget/Misc/DateRange')
		local Html = require('Module:Widget/Html')

		local start_y = {year = 2023}
		local start_ym = {year = 2023, month = 10}
		local start_ymd = {year = 2023, month = 10, day = 3}

		local end_y = {year = 2024}
		local end_ym = {year = 2024, month = 11}
		local end_ymd = {year = 2024, month = 11, day = 4}

		local data = {
			-- TBA display
			{},
			{start_y, },
			{start_ym, },
			{start_ymd, },

			{nil, end_y},
			{start_y, end_y},
			{start_ym, end_y},
			{start_ymd, end_y},

			{nil, end_ym},
			{start_y, end_ym},
			{start_ym, end_ym},
			{start_ymd, end_ym},

			{nil, end_ymd},
			{start_y, end_ymd},
			{start_ym, end_ymd},
			{start_ymd, end_ymd},

			{start_ymd, {year = 2023, month = 10}},
			{start_ymd, {year = 2023, month = 10, day = 04}},
			{start_ymd, start_ymd},
		}

		local function dateDisplay(date)
			if not date then
				return ''
			end
			return (date.year or '????') .. '-'
				.. (date.month or '??') .. '-'
				.. (date.day and (
					(date.day < 10 and 0 or '') .. date.day
				) or '??')
		end

		GoldenTest('date range display',
			tostring(Html.Table{
				classes = {'wikitable', 'wikitable-striped'},
				children = Array.extend(
					{
						Html.Tr{children={
							Html.Th{children="startDate"},
							Html.Th{children="endDate"},
							Html.Th{children="DateRange (showYear)"},
							Html.Th{children="DateRange (not showYear)"},
						}}
					},
					Array.map(data, function (entry)
						return Html.Tr{children={
							Html.Td{children=dateDisplay(entry[1])},
							Html.Td{children=dateDisplay(entry[2])},
							Html.Td{children=DateRange{
								startDate = entry[1],
								endDate = entry[2],
								showYear = true
							}},
							Html.Td{children=DateRange{
								startDate = entry[1],
								endDate = entry[2],
							}},
						}}
					end)
				)
			}),
			-- Use the full size of the page for this
			'<style>#top {padding: unset}</style>'
		)
	end)
end)
