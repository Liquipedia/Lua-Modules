---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local NameAliases = Lua.requireIfExists('Module:CharacterNames', {loadData = true})
local Patch = Lua.import('Module:Patch')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param label string
---@return Widget
local function createPriceLabel(label)
	return HtmlWidgets.Sup{
		children = {
			HtmlWidgets.Span{
				classes = { 'elm-bg' },
				css = {
					['font-family'] = 'monospace',
					['font-weight'] = 'bold',
					padding = '0 1px'
				},
				children = { label }
			}
		}
	}
end

local STANDARD_EDITION_LABEL = createPriceLabel('SE')
local SEASON_PASS_LABEL = createPriceLabel('SP')
local TEAM_ATTACK = AutoInlineIcon.display{category = 'M', lookup = 'attackTeam'}
local TEAM_DEFENSE = AutoInlineIcon.display{category = 'M', lookup = 'defenseTeam'}

local OPERATOR_PRICES = {
	launch = {
		renown = 0,
		credit = 300
	},
	['36m'] = {
		renown = 10000,
		credit = 240
	},
	['24m'] = {
		renown = 15000,
		credit = 360
	},
	['12m'] = {
		renown = 20000,
		credit = 480
	},
	['0m'] = {
		renown = 25000,
		credit = 600
	}
}

local ARMOR_SPEED_DATA = {
	slow = {
		armorValue = 3,
		armor = 'Heavy (125 HP)',
		speedValue = 1,
		speed = 'Slow'
	},
	medium = {
		armorValue = 2,
		armor = 'Medium (110 HP)',
		speedValue = 2,
		speed = 'Medium'
	},
	fast = {
		armorValue = 1,
		armor = 'Light (100 HP)',
		speedValue = 3,
		speed = 'Fast'
	}
}

local DIFFICULTY_DATA = {
	easy = {
		value = 1,
		display = 'Easy'
	},
	normal = {
		value = 2,
		display = 'Normal'
	},
	hard = {
		value = 3,
		display = 'Hard'
	}
}

---@class RainbowsixOperatorInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Operator'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'country' then
		local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
			birthdate = args.birthdate,
			birthlocation = args.birthplace,
		})

		return ageCalculationSuccess and {
			Cell{name = 'Born', content = {age.birth}},
		} or {}
	elseif id == 'role' then
		return WidgetUtil.collect(
			Cell{
				name = 'Team',
				children = self.caller:_getTeam(args)
			},
			Cell{
				name = 'Operator Role',
				content = Array.map(
					self.caller:getAllArgsForBase(args, 'function'),
					function (role)
						return Link{
							link = ':Category:' .. role .. ' Operators',
							children = role
						}
					end
				),
			}
		)
	elseif id == 'class' then
		return {
			Cell{
				name = 'Team Rainbow',
				content = self.caller:_getTeamRainbow(args),
				options = { separator = ' ' }
			},
			Cell{
				name = 'Affiliation',
				content = { args.affiliation }
			}
		}
	elseif id == 'release' then
		if Logic.isEmpty(args.releasedate) then
			return {}
		end
		local patchData = Patch.getPatchByDate(args.releasedate) or {}

		return {
			Cell{
				name = 'Released',
				content = WidgetUtil.collect(
					Logic.isNotEmpty(patchData) and Link{
						link = patchData.pageName,
						children = patchData.displayName
					} or 'Launch',
					HtmlWidgets.Small{
						children = { args.releasedate }
					}
				)
			}
		}
	elseif id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_getAdditionalInfo(args),
			self.caller:_getBaseStats(args)
		)
	end

	return widgets
end

---@return Widget[]
function CustomCharacter:_getTeam(args)
	local team = (args.team or ''):lower()
	if team == 'attack' then
		return { TEAM_ATTACK }
	elseif team == 'defense' then
		return { TEAM_DEFENSE }
	elseif team == 'both' then
		return { TEAM_ATTACK, TEAM_DEFENSE }
	else
		return {}
	end
end

---@return (Widget|string)[]
function CustomCharacter:_getTeamRainbow(args)
	local teamRainbow = (args['team rainbow'] or ''):lower()
	if teamRainbow == 'wolfguard' then
		return self:_buildTeamRainbowWidgets('Wolfguard', true)
	elseif teamRainbow == 'nighthaven' then
		return self:_buildTeamRainbowWidgets('Nighthaven')
	elseif teamRainbow == 'ghosteyes' then
		return self:_buildTeamRainbowWidgets('Ghosteyes')
	elseif teamRainbow == 'redhammer' then
		return self:_buildTeamRainbowWidgets('Redhammer')
	elseif teamRainbow == 'viperstrike' then
		return self:_buildTeamRainbowWidgets('Viperstrike', true)
	else
		return {}
	end
end

---@param teamName string
---@param allmode boolean?
---@return (Widget|string)[]
function CustomCharacter:_buildTeamRainbowWidgets(teamName, allmode)
	return {
		IconImageWidget{
			imageLight = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'lightmode') .. '.png',
			imageDark = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'darkmode') .. '.png',
			link = teamName
		},
		teamName
	}
end

---@param args table<string, any>
---@return Widget[]
function CustomCharacter:_getAdditionalInfo(args)
	return WidgetUtil.collect(
		Logic.isNotEmpty(args.height) and Cell{
			name = 'Height',
			content = { args.height, 'm' },
			options = { separator = ' ' }
		} or nil,
		Logic.isNotEmpty(args.weight) and Cell{
			name = 'Weight',
			content = { args.weight, 'kg' },
			options = { separator = ' ' }
		} or nil,
		Logic.isNotEmpty(args.voice) and Cell{
			name = 'Voiced by',
			content = { args.voice }
		} or nil,
		self:_getPriceCells(args.renownprice or args.creditprice),
		Cell{
			name = 'Has Elite Skin',
			content = WidgetUtil.collect(
				HtmlWidgets.Fragment{
					children = Logic.readBool(args.eliteskin) and {
						IconFa{ iconName = 'yes', color = 'forest-green-text' },
						' ',
						HtmlWidgets.I{
							css = {
								['padding-left'] = '2px',
								['vertical-align'] = '-1px'
							},
							children = { 'Yes' }
						}
					} or {
						IconFa{ iconName = 'no', color = 'cinnabar-text' },
						' ',
						HtmlWidgets.I{
							css = {
								['padding-left'] = '2px',
								['vertical-align'] = '-1px'
							},
							children = { 'No' }
						}
					}
				},
				Logic.isNotEmpty(args['eliteskin-date']) and HtmlWidgets.I{
					children = {
						HtmlWidgets.Small{
							children = { args['eliteskin-date'] }
						}
					}
				} or nil
			)
		},
		Cell{
			name = 'Availability',
			content = { args.availability }
		}
	)
end

---@param input string
---@return Widget[]|nil
function CustomCharacter:_getPriceCells(input)
	local lowerInput = (input or ''):lower()
	if (lowerInput == 'launch') then
		local lang = mw.getContentLanguage()
		return {
			Cell{
				name = 'Renown price',
				content = WidgetUtil.collect(
					'Free',
					Array.map({ 500, 1000, 1500, 2000 }, function (renownPrice)
						return HtmlWidgets.Fragment{
							children = {
								lang:formatNum(renownPrice),
								' ',
								STANDARD_EDITION_LABEL
							}
						}
					end),
					HtmlWidgets.Fragment{
						children = {
							'10% off ',
							SEASON_PASS_LABEL
						}
					}
				),
			},
			self:_getPriceCell('Renown', OPERATOR_PRICES.launch.credit)
		}
	elseif Logic.isNotEmpty(OPERATOR_PRICES[lowerInput]) then
		local priceData = OPERATOR_PRICES[lowerInput]
		return {
			self:_getPriceCell('Renown', priceData.renown),
			self:_getPriceCell('R6 Credit', priceData.credit)
		}
	end
	return nil
end

---@param currency string
---@param price integer
---@return Widget
function CustomCharacter:_getPriceCell(currency, price)
	local lang = mw.getContentLanguage()
	return Cell{
		name = currency .. ' price',
		content = {
			lang:formatNum(price),
			HtmlWidgets.Fragment{
				children = {
					lang:formatNum(price * 0.9),
					' ',
					SEASON_PASS_LABEL
				}
			}
		},
	}
end

---@param args table<string, any>
---@return Widget[]
function CustomCharacter:_getBaseStats(args)
	return WidgetUtil.collect(
		Title{ children = 'Base Stats' },
		self:_getArmorAndSpeedDisplay((args.speed or ''):lower()),
		CustomCharacter._generateDifficultyCell((args.difficulty or ''):lower())
	)
end

---@param speed 'slow'|'medium'|'fast'
---@return CellWidget[]
function CustomCharacter:_getArmorAndSpeedDisplay(speed)
	local armorSpeedData = ARMOR_SPEED_DATA[speed]
	return Logic.isNotEmpty(armorSpeedData) and {
		CustomCharacter._generateStatCell(
			'Armor/Health', 'armor', armorSpeedData.armorValue, armorSpeedData.armor
		),
		CustomCharacter._generateStatCell(
			'Speed', 'speed', armorSpeedData.speedValue, armorSpeedData.speed
		),
	} or {}
end

---@param difficulty string
---@return CellWidget|nil
function CustomCharacter._generateDifficultyCell(difficulty)
	local difficultyData = DIFFICULTY_DATA[difficulty]
	return Logic.isNotEmpty(difficultyData)
		and CustomCharacter._generateStatCell('Difficulty', 'difficulty', difficultyData.value, difficultyData.display)
		or nil
end

---@param title string
---@param datatype string
---@param value number|string
---@param display string
---@return CellWidget
function CustomCharacter._generateStatCell(title, datatype, value, display)
	return Cell{
		name = title,
		content = {
			Image.display(
				'R6S operator-rating-' .. datatype .. '-' ..  value .. ' lightmode.png',
				'R6S operator-rating-' .. datatype .. '-' ..  value .. ' darkmode.png',
				{ size = '40x20px', link = '' }
			),
			HtmlWidgets.I{
				css = {
					['padding-left'] = '2px',
					['vertical-align'] = '-1px'
				},
				children = { display }
			}
		},
		options = { separator = ' ' }
	}
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	local categories = {}
	local speed = (args.speed or ''):lower()
	local difficulty = (args.difficulty or ''):lower()
	local speedEq = FnUtil.curry(Operator.eq, speed)
	local difficultyEq = FnUtil.curry(Operator.eq, difficulty)

	Array.extendWith(categories, Array.map(self:getAllArgsForBase(args, 'function'), function (element)
		return element .. ' Operators'
	end))

	if Array.any(Array.extractKeys(ARMOR_SPEED_DATA), speedEq) then
		Array.appendWith(categories, ARMOR_SPEED_DATA[speed].speedValue .. ' Speed Operators')
	end

	if Array.any(Array.extractKeys(DIFFICULTY_DATA), difficultyEq) then
		Array.appendWith(categories, DIFFICULTY_DATA[difficulty].value .. ' Difficulty Operators')
	end

	return categories
end

---@param args table
---@return string?
function CustomCharacter:nameDisplay(args)
	return CharacterIcon.Icon{
		character = NameAliases[self.name:lower()],
		size = '50px'
	} .. ' ' .. self.name
end

return CustomCharacter
