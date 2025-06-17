---
-- @Liquipedia
-- page=Module:Icon/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

return {
	-- Usage: Match results
	winner = 'fas fa-check',
	draw = 'fas fa-minus',
	loss = 'fas fa-times',

	-- Usage: Other Match detail pop up icons
	matchpagelink = 'fas fa-external-link', -- Should we really use external for this?
	matchpopup = 'fas fa-info-circle',
	timeout = 'far fa-clock',
	veto = 'fas fa-times',
	casters = 'fas fa-microphone-alt',
	comment = 'far fa-comment',
	mvp = 'fas fa-medal',
	startleft = 'fas fa-chevron-left',
	startright = 'fas fa-chevron-right',
	elimination = 'fas fa-skull',
	explosion_valorant = 'fas fa-fire-alt',
	defuse = 'fas fa-wrench',
	outoftime = 'fas fa-hourglass',

	-- Usage: Rumors, Predictions, etc.
	correct = 'fas fa-check',
	uncertain = 'fas fa-question',
	wrong = 'fas fa-times',

	--Usage: A match or stream is live
	live = 'fas fa-circle',

	-- Usage: Previous and Next event in infoboxes
	previous = 'fas fa-chevron-left',
	next = 'fas fa-chevron-right',

	-- Usage: Expanding and collapsing hidden sections
	expand = 'far fa-chevron-down',
	collapse = 'far fa-chevron-up',

	-- Usage: to indicate a selection of something was either left, right, down or up
	up = 'fas fa-chevron-circle-up',
	right = 'fas fa-chevron-circle-right',
	down = 'fas fa-chevron-circle-down',
	left = 'fas fa-chevron-circle-left',

	-- Usage: Indicate if a team/player went up or down in placement in a league system or in a ranking system
	rankup = 'fas fa-long-arrow-up',
	rankdown = 'fas fa-long-arrow-down',

	-- Usage: Main Page buttons
	featuredon = 'far fa-star',
	featuredoff = 'fas fa-star',
	upcoming = 'far fa-alarm-clock',
	ongoing = 'far fa-stopwatch',
	upcomingandongoing = 'far fa-clock',
	concluded = 'fas fa-check',
	transfers = 'fas fa-handshake-alt',
	createaccount = 'fas fa-user-plus',
	login = 'fas fa-sign-in-alt',
	discord = 'fab fa-discord',
	helparticles = 'far fa-life-ring',

	-- Usage: To indicate different transfer type with icon difference not just background colour
	transferbetween = 'fas fa-arrow-alt-right',
	transfertofreeagent = 'fas fa-arrow-alt-from-left',
	fransferfromfreeagent = 'fas fa-arrow-alt-to-right',

	-- Usage: Reference links in tables (ie transfers)
	reference = 'fad fa-external-link-alt',
	link = 'fad fa-link',
	insidesource = 'fad fa-user-secret',
	transferdatabase = 'fad fa-scroll',

	-- Usage: Section links, navigation
	activestage = 'fas fa-bell-exclamation',
	prizepool = 'fas fa-sack-dollar',
	teams = 'fas fa-users',
	results = 'fas fa-th-list',
	standings = 'fad fa-list-ol',
	headlines = 'fas fa-newspaper',
	achievements = 'fas fa-medal',
	activeroster = 'fas fa-users',
	history = 'fas fa-books',
	media = 'fas fa-newspaper',
	['goto'] = 'far fa-arrow-right',

	-- Usage: buildtime, duration, cooldown, ...
	time = 'far fa-clock',

	-- Usage: Squad Table
	captain = 'fas fa-crown',
	substitute = 'fas fa-people-arrows',

	-- Usage: Deadlock
	amberhand = 'fas fa-hand-paper',
	sapphireflame = 'fas fa-fire',

	-- Usage: Accommodations
	accommodation = 'far fa-home-alt',

	-- Usage: Matches etc
	firstplace = 'fas fa-trophy',
	map = 'far fa-map',
	rank = 'fas fa-hashtag',
	team = 'fas fa-users',
	points = 'fas fa-star',
	placement = 'fas fa-trophy-alt',
	kills = 'fas fa-skull',
	matchpoint = 'fad fa-diamond',

	-- Usage: qualification
	qualified = 'fas fa-check-circle',
	tobedetermined = 'fas fa-question',
	notqualified = 'fas fa-times',
	ineligible = 'fas fa-ban',

	-- Usage: standings
	standings_up = 'fas fa-chevron-double-up',
	standings_stayup = 'fas fa-chevron-up',
	standings_stay = 'fas fa-equals',
	standings_staydown = 'fas fa-chevron-down',
	standings_down = 'fas fa-skull',

	-- Usage: sorting
	sort = 'far fa-arrows-alt-v',

	-- Usage: Lists
	checkcircle = 'fas fa-check-circle',

	-- Usage: "Hubs" (additional Main Pages)
	esports_hub = 'far fa-trophy',
	game_hub = 'far fa-swords',
	main_hub = 'far fa-user-chart',

	-- Usage: Match Stats
	damage = 'fas fa-sword',
	gold = 'fas fa-coins',
	kda = 'fas fa-skull-crossbones',
	acs = 'far fa-abacus',
	kast = 'fas fa-hands-helping',
	headshot = 'far fa-crosshairs',

	dota2_gpm = 'fas fa-coin',
	dota2_lhdn = 'fas fa-swords',
	dota2_tower = 'fas fa-chess-rook',
	dota2_barrack = 'fas fa-warehouse',

	leagueoflegends_kda = 'fas fa-swords fa-flip-vertical',

	-- Usage: Indicate boolean info in Infobox
	yes = 'fa fa-check',
	no = 'fa fa-times',

	-- Usage: Stormgate
	coop = 'fas fa-dungeon',
	mayhem = 'fab fa-fort-awesome',

	-- Usage: Charts
	chart = 'far fa-chart-line',

	-- Usage: PatchList
	patch = 'fas fa-file-alt',
	calendar = 'fas fa-calendar-alt',
	highlights = 'fas fa-star',

	-- Usage: Chess
	chesskingoutline = 'far fa-chess-king',
	chesskingfull = 'fas fa-chess-king',
}
