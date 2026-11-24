---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---Head to head query form configuration, rendered when the Results subpage exists.
---@class ProfileTabsHeadToHead
---@field mediawikiForm string
---@field form string
---@field template string
---@field queryArg string

---Statistics query form configuration, rendered when the `statistics` flag is set and results exist.
---@class ProfileTabsStatistics
---@field mediawikiForm string
---@field form string
---@field template string
---@field queryArg string

---Query form configuration for tabsToForms, taking over the replaced tab's slot.
---@class ProfileTabsToForms
---@field display string
---@field mediawikiForm string
---@field form string
---@field template string
---@field queryArg string

---Per-type metadata that drives all player/team differences.
---@class ProfileTypeDefinition
---@field lpdbType string
---@field lpdbQuery string
---@field displayField string
---@field matchFilterField string
---@field tabs string[]
---@field tabDisplay table<string, string>?
---@field headToHead ProfileTabsHeadToHead
---@field statistics ProfileTabsStatistics?
---@field tabsToForms table<string, ProfileTabsToForms>?

---@type table<string, ProfileTypeDefinition>
local PROFILE_TYPES = {
	player = {
		lpdbType = 'player',
		lpdbQuery = 'id',
		displayField = 'id',
		matchFilterField = 'opponent',
		tabs = {
			'Results',
			'Played Matches',
			'Coaching',
			'Broadcasts',
			'Awards',
			'Statistics',
			'Managing',
			'Organized Events',
			'Maps Created',
			'Notable Wins',
			'Doubles Results',
			'VODs',
		},
		tabDisplay = {
			Broadcasts = 'Talent',
		},
		headToHead = {
			mediawikiForm = 'Match history',
			form = 'H2H',
			template = 'Head_to_head_query',
			queryArg = 'player',
		},
		statistics = {
			mediawikiForm = 'PlayerStats',
			form = 'PlayerStats/LH',
			template = 'PlayerStatistics',
			queryArg = 'player',
		},
		tabsToForms = {
			['Results'] = {
				display = 'Results',
				mediawikiForm = 'Player Results',
				form = 'Player Results/LH',
				template = 'Player results',
				queryArg = 'player',
			},
			['Played Matches'] = {
				display = 'Matches',
				mediawikiForm = 'Player Matches',
				form = 'Player Matches/LH',
				template = 'Player matches',
				queryArg = 'player',
			},
		},
	},
	team = {
		lpdbType = 'team',
		lpdbQuery = 'name',
		displayField = 'name',
		matchFilterField = 'opponent',
		tabs = {
			'Results',
			'Played Matches',
			'Player Results',
			'Awards',
			'Bootcamps',
			'History',
			'Teamkills',
			'Player Matches',
			'Organized Events',
		},
		headToHead = {
			mediawikiForm = 'Head2head',
			form = 'H2H',
			template = 'Headtohead',
			queryArg = 'team',
		},
		tabsToForms = {
			['Results'] = {
				display = 'Team Results',
				mediawikiForm = 'Team Results',
				form = 'Team Results/LH',
				template = 'Team results',
				queryArg = 'team',
			},
			['Played Matches'] = {
				display = 'Team Matches',
				mediawikiForm = 'Team Matches',
				form = 'Team Matches/LH',
				template = 'Team matches',
				queryArg = 'team',
			},
			['Player Results'] = {
				display = 'Player Results',
				mediawikiForm = 'Team Player Results',
				form = 'Team Player Results/LH',
				template = 'Team player results',
				queryArg = 'team',
			},
		},
	},
}

return PROFILE_TYPES
