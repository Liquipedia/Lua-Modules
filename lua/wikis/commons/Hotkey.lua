---
-- @Liquipedia
-- wiki=commons
-- page=Module:Hotkey
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Hotkeys = {}

local SEPERATORS = {
	['->'] = '&nbsp;→&nbsp;',
	['then'] = '&nbsp;→&nbsp;',
	['arrow'] = '&nbsp;→&nbsp;',
	['+'] = '&nbsp;+&nbsp;',
	['and'] = '&nbsp;+&nbsp;',
	['&'] = '&nbsp;+&nbsp;',
	['plus'] = '&nbsp;+&nbsp;',
	['/'] = '&nbsp;→&nbsp;',
	['or'] = '&nbsp;→&nbsp;',
	['forwardslash'] = '&nbsp;→&nbsp;',
	['slash'] = '&nbsp;/&nbsp;',
	['space'] = '&nbsp;',
	['nbsp'] = '&nbsp;',
	['&nbsp;'] = '&nbsp;'
}

---Creates a keyboard-button-like hotkey display
---@param hotkey string|number|nil
---@return string
---@overload fun(hotkey: table): string
function Hotkeys.hotkey(hotkey)
	if type(hotkey) == 'table' then
		hotkey = hotkey.hotkey or hotkey[1]
	end
	return tostring(mw.html.create('span'):addClass('hotkey-key'):wikitext(hotkey or ''))
end

---Creates a keyboard-button-like hotkey display of 2 hotkeys
---@param hotkey1 string|number|nil
---@param hotkey2 string|number|nil
---@param seperator string?
---@return string
---@overload fun(hotkey1: table): string
function Hotkeys.hotkey2(hotkey1, hotkey2, seperator)
	if type(hotkey1) == 'table' then
		hotkey2 = hotkey1.hotkey2 or hotkey1[2]
		seperator = hotkey1.seperator or hotkey1[3]
		hotkey1 = hotkey1.hotkey or hotkey1[1]
	end
	hotkey1 = Hotkeys.hotkey(hotkey1)
	hotkey2 = Hotkeys.hotkey(hotkey2)
	seperator = SEPERATORS[string.lower(seperator or '')] or
		seperator or ''

	return '<b>' .. hotkey1 .. seperator .. hotkey2 .. '</b>'
end

return Class.export(Hotkeys, {frameOnly = true})
