---
-- @Liquipedia
-- page=Module:Hotkey
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
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
---@param args {hotkey: string|number|nil}
---@return string
---@overload fun(hotkey: table): string
function Hotkeys.hotkey(args)
	local hotkey = args.hotkey
	return tostring(mw.html.create('span'):addClass('hotkey-key'):wikitext(hotkey or ''))
end

---Creates a keyboard-button-like hotkey display of 2 hotkeys
---@param args {hotkey1: string|number|nil, hotkey2: string|number|nil, seperator: string?}
---@return string
function Hotkeys.hotkey2(args)
	local seperator = args.seperator
	local hotkey1 = Hotkeys.hotkey{hotkey = args.hotkey1}
	local hotkey2 = Hotkeys.hotkey{hotkey = args.hotkey2}
	seperator = SEPERATORS[string.lower(seperator or '')] or
		seperator or ''

	return '<b>' .. hotkey1 .. seperator .. hotkey2 .. '</b>'
end

return Class.export(Hotkeys, {frameOnly = true, exports = {'hotkey', 'hotkey2'}})
