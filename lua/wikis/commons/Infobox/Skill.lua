---
-- @Liquipedia
-- page=Module:Infobox/Skill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Hotkey = require('Module:Hotkey')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class SkillInfobox: BasicInfobox
local Skill = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Skill.run(frame)
	local skill = Skill(frame)
	return skill:createInfobox()
end

---@return string
function Skill:createInfobox()
	local args = self.args

	if String.isEmpty(args.informationType) then
		error('You need to specify an informationType, e.g. "Spell", "Ability, ...')
	end

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = args.informationType .. ' Information'},
		Customizable{
			id = 'caster',
			children = {
				Cell{name = 'Caster(s)', content = self:getAllArgsForBase(args, 'caster', {makeLink = true})},
			}
		},
		Customizable{
			id = 'cost',
			children = {
				Cell{name = 'Cost', content = {args.cost}},
			}
		},
		Customizable{
			id = 'hotkey',
			children = {
				Cell{name = 'Hotkey', content = {self:_getHotkeys(args)}},
			}
		},
		Cell{name = 'Range', content = {args.range}},
		Cell{name = 'Radius', content = {args.radius}},
		Customizable{
			id = 'cooldown',
			children = {
				Cell{name = 'Cooldown', content = {args.cooldown}},
			}
		},
		Customizable{
			id = 'duration',
			children = {
				Cell{name = 'Duration', content = {args.duration}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		local categories = self:getCategories(args)
		self:categories(unpack(categories))
		self:_setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string?
function Skill:nameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---@param args table
---@return string[]
function Skill:getCategories(args)
	return {}
end

---@param args table
function Skill:_setLpdbData(args)
	local skillIndex = (tonumber(Variables.varDefault('skill_index')) or 0) + 1
	Variables.varDefine('skill_index', skillIndex)

	local lpdbData = {
		objectName = 'skill_' .. skillIndex .. '_' .. self.name,
		name = args.name,
		type = args.informationType,
		image = args.image,
		imagedark = args.imagedark,
		extradata = {},
	}
	lpdbData = self:addToLpdb(lpdbData, args)
	local objectName = Table.extract(lpdbData, 'objectName')

	mw.ext.LiquipediaDB.lpdb_datapoint(objectName, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Skill:addToLpdb(lpdbData, args)
	return lpdbData
end

---@param args table
---@return string?
function Skill:_getHotkeys(args)
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey2{hotkey1 = args.hotkey, hotkey2 = args.hotkey2, seperator = 'slash'}
		else
			display = Hotkey.hotkey{hotkey = args.hotkey}
		end
	end

	return display
end

return Skill
