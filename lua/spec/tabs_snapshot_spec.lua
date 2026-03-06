local Tabs = require('Module:Tabs')
local HtmlWidgets = require('Module:Widget/Html/All')

insulate('Tabs snapshots', function()
	it('dynamic variants', function()
		local arrayContent = HtmlWidgets.Ul{children = {
			HtmlWidgets.Li{children = {'Item A1'}},
			HtmlWidgets.Li{children = {'Item A2'}},
		}}

		local output = HtmlWidgets.Div{children = {
			HtmlWidgets.Div{children = {'Dynamic Tabs Variants (Snapshot)'}},

			HtmlWidgets.Div{children = {'Horizontal (icons)'}},
			Tabs.dynamic{
				variant = 'horizontal',
				name1 = 'Overview',
				icon1 = 'notification',
				content1 = 'Overview content',
				name2 = 'Results',
				icon2 = 'results',
				content2 = 'Results content',
				name3 = 'Stats',
				icon3 = 'statistics',
				content3 = 'Stats content',
			},

			HtmlWidgets.Div{children = {'Vertical'}},
			Tabs.dynamic{
				variant = 'vertical',
				name1 = 'Spring Split',
				icon1 = 'calendar',
				content1 = 'Spring content',
				name2 = 'Summer Split',
				icon2 = 'day',
				content2 = 'Summer content',
				name3 = 'Worlds',
				icon3 = 'firstplace',
				content3 = 'Worlds content',
			},

			HtmlWidgets.Div{children = {'Icon-only (with show all)'}},
			Tabs.dynamic{
				variant = 'icon-only',
				name1 = 'Home',
				icon1 = 'projecthome',
				content1 = 'Home content',
				name2 = 'Login',
				icon2 = 'login',
				content2 = 'Login content',
				name3 = 'Profile',
				icon3 = 'player',
				content3 = 'Profile content',
			},

			HtmlWidgets.Div{children = {'Array content'}},
			Tabs.dynamic{
				variant = 'horizontal',
				name1 = 'Array A',
				icon1 = 'notification',
				content1 = {'Intro line', arrayContent},
				name2 = 'Array B',
				icon2 = 'results',
				content2 = {'Intro line', arrayContent},
			},
		}}

		GoldenTest('tabs_dynamic_variants', tostring(output))
	end)
end)
