---
-- @Liquipedia
-- page=Module:Infobox/Extension/VersionDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local VERSION_DATA = {
	['4.5'] = {version = '4.5', date = '2018-07-03'},
	['5.0'] = {version = '5.0', date = '2018-07-17'},
	['5.10'] = {version = '5.10', date = '2018-07-24'},
	['5.10 (Content Update)'] = {version = '5.10 (Content Update)', date = '2018-07-31'},
	['5.20'] = {version = '5.20', date = '2018-08-07'},
	['5.21'] = {version = '5.21', date = '2018-08-15'},
	['5.30'] = {version = '5.30', date = '2018-08-23'},
	['5.30 (Content Update)'] = {version = '5.30 (Content Update)', date = '2018-08-28'},
	['5.40'] = {version = '5.40', date = '2018-09-06'},
}
VERSION_DATA['2018-07-03'] = VERSION_DATA['4.5']
VERSION_DATA['2018-07-17'] = VERSION_DATA['5.0']
VERSION_DATA['2018-07-24'] = VERSION_DATA['5.10']
VERSION_DATA['2018-07-31'] = VERSION_DATA['5.10 (Content Update)']
VERSION_DATA['2018-08-07'] = VERSION_DATA['5.20']
VERSION_DATA['2018-08-15'] = VERSION_DATA['5.21']
VERSION_DATA['2018-08-23'] = VERSION_DATA['5.30']
VERSION_DATA['2018-08-28'] = VERSION_DATA['5.30 (Content Update)']
VERSION_DATA['2018-09-06'] = VERSION_DATA['5.40']

local VersionDisplay = {}

---@param input string?
---@return Widget|string?
function VersionDisplay.run(input)
	local versionData = VERSION_DATA[input]
	if not versionData then return input end

	return HtmlWidgets.Fragment{
		children = {
			Link{
				link = 'Version ' .. versionData.version,
				children = {versionData.version},
			},
			'&nbsp;',
			HtmlWidgets.I{
				children = {HtmlWidgets.Small{
					children = {
						'(',
						versionData.date,
						')',
					}
				}}
			}
		}
	}
end

return VersionDisplay
