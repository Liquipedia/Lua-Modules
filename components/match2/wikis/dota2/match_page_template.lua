---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchPage/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- todo's:
-- Team logo's are currently 50x50 => need to be 80x80. Already made preparations for this in the css.

-- luacheck: ignore
return {
	header =
		[=[
			<div class="match-bm-lol-match-header">
				<div class="match-bm-match-header-powered-by">[[File:SAP logo.svg|link=]]</div>
				<div class="match-bm-lol-match-header-overview">
					<div class="match-bm-match-header-team">{{#opponents.1}}{{&iconDisplay}}<div class="match-bm-match-header-team-group"><div class="match-bm-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div class="match-bm-lol-match-header-round-results">{{#seriesDots}}<div class="match-bm-lol-match-header-round-result result--{{.}}"></div>{{/seriesDots}}</div>{{/opponents.1}}</div></div>
					<div class="match-bm-match-header-result">{{#isBestOfOne}}{{#games.1.apiInfo}}{{team1.scoreDisplay}}&ndash;{{team2.scoreDisplay}}{{/games.1.apiInfo}}{{/isBestOfOne}}{{^isBestOfOne}}{{opponents.1.score}}&ndash;{{opponents.2.score}}{{/isBestOfOne}}<div class="match-bm-match-header-result-text">{{statusText}}</div></div>
					<div class="match-bm-match-header-team">{{#opponents.2}}{{&iconDisplay}}<div class="match-bm-match-header-team-group"><div class="match-bm-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div class="match-bm-lol-match-header-round-results">{{#seriesDots}}<div class="match-bm-lol-match-header-round-result result--{{.}}"></div>{{/seriesDots}}</div>{{/opponents.2}}</div></div>
				</div>
				<div class="match-bm-lol-match-header-tournament">[[{{parent}}|{{tournament}}]]</div>
				<div class="match-bm-lol-match-header-date">{{&dateCountdown}}</div>
			</div>
			{{#isBestOfOne}}<div class="match-bm-lol-game-overview"><div class="match-bm-lol-game-summary">
			<div class="match-bm-lol-game-summary-team">{{#games.1.teams.1.side}}[[File:Dota2 faction {{games.1.teams.1.side}}.png|link=|{{games.1.teams.1.side}} side]]{{/games.1.teams.1.side}}</div>
			<div class="match-bm-lol-game-summary-center"><div class="match-bm-lol-game-summary-score-holder"><div class="match-bm-lol-game-summary-length">{{games.1.length}}</div></div></div>
			<div class="match-bm-lol-game-summary-team">{{#games.1.teams.2.side}}[[File:Dota2 faction {{games.1.teams.2.side}}.png|link=|{{games.1.teams.1.side}} side]]{{/games.1.teams.2.side}}</div>
			</div></div>{{/isBestOfOne}}
			{{#extradata.mvp}}<div class="match-bm-lol-match-mvp"><b>MVP</b> {{#players}}[[{{name}}|{{displayname}}]]{{/players}}</div>{{/extradata.mvp}}
		]=],
	footer =
		[=[
			<h3>Additional Information</h3>
			<div class="match-bm-match-additional">
				{{#vods.1}}
					<div class="match-bm-match-additional-section">
						<div class="match-bm-match-additional-section-header">VODs</div>
						<div class="match-bm-match-additional-section-body">{{#vods}}{{&.}}{{/vods}}</div>
					</div>{{/vods.1}}{{#links.1}}
					<div class="match-bm-match-additional-section">
						<div class="match-bm-match-additional-section-header">Socials</div>
						<div class="match-bm-match-additional-section-body">{{#links}}[[{{icon}}|link={{link}}|15px|{{text}}]]{{/links}}</div>
					</div>{{/links.1}}{{#patch}}
					<div class="match-bm-match-additional-section">
						<div class="match-bm-match-additional-section-header">Patch</div>
						<div class="match-bm-match-additional-section-body">[[Version {{patch}}]]</div>
					</div>
				{{/patch}}
			</div>
		]=],
	game =
		[=[
			{{^isBestOfOne}}<div class="match-bm-lol-game-overview">
				<div class="match-bm-lol-game-summary">
					<div class="match-bm-lol-game-summary-team">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-lol-game-summary-center">
						<div class="match-bm-lol-game-summary-faction">{{#teams.1.side}}[[File:Dota2 faction {{teams.1.side}}.png|link=|{{teams.1.side}} side]]{{/teams.1.side}}</div>
						<div class="match-bm-lol-game-summary-score-holder">{{#finished}}<div class="match-bm-lol-game-summary-score">{{teams.1.scoreDisplay}}&ndash;{{teams.2.scoreDisplay}}</div><div class="match-bm-lol-game-summary-length">{{length}}</div>{{/finished}}</div>
						<div class="match-bm-lol-game-summary-faction">{{#teams.2.side}}[[File:Dota2 faction {{teams.2.side}}.png|link=|{{teams.2.side}} side]]{{/teams.2.side}}</div>
					</div>
					<div class="match-bm-lol-game-summary-team">{{&opponents.2.iconDisplay}}</div>
				</div>
			</div>{{/isBestOfOne}}
			<h3>Draft</h3>
			<div class="match-bm-game-veto-wrapper">
				<div class="match-bm-lol-game-veto-overview-team">
					<div class="match-bm-game-veto-overview-team-header">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-game-veto-overview-team-veto">
						<div class="match-bm-game-veto-overview-team-veto-row match-bm-game-veto-overview-team-veto-row--{{teams.1.side}}" aria-labelledby="picks">
							{{#teams.1.picks}}
							<div class="match-bm-game-veto-overview-team-veto-row-item">
								<div class="match-bm-game-veto-overview-team-veto-row-item-icon">{{&heroIcon}}</div>
								<div class="match-bm-game-veto-overview-team-veto-row-item-text">#{{vetoNumber}}</div>
							</div>
							{{/teams.1.picks}}
						</div>
						<div class="match-bm-game-veto-overview-team-veto-row  match-bm-game-veto-overview-team-veto-row--ban" aria-labelledby="bans">
							{{#teams.1.bans}}
							<div class="match-bm-game-veto-overview-team-veto-row-item">
								<div class="match-bm-game-veto-overview-team-veto-row-item-icon">{{&heroIcon}}</div>
								<div class="match-bm-game-veto-overview-team-veto-row-item-text">#{{vetoNumber}}</div>
							</div>
							{{/teams.1.bans}}
						</div>
					</div>
				</div>
				<div class="match-bm-lol-game-veto-overview-team">
					<div class="match-bm-game-veto-overview-team-header">{{&opponents.2.iconDisplay}}</div>
					<div class="match-bm-game-veto-overview-team-veto">
						<div class="match-bm-game-veto-overview-team-veto-row match-bm-game-veto-overview-team-veto-row--{{teams.2.side}}" aria-labelledby="picks">
							{{#teams.2.picks}}
							<div class="match-bm-game-veto-overview-team-veto-row-item">
								<div class="match-bm-game-veto-overview-team-veto-row-item-icon">{{&heroIcon}}</div>
								<div class="match-bm-game-veto-overview-team-veto-row-item-text">#{{vetoNumber}}</div>
							</div>
							{{/teams.2.picks}}
						</div>
						<div class="match-bm-game-veto-overview-team-veto-row  match-bm-game-veto-overview-team-veto-row--ban" aria-labelledby="bans">
							{{#teams.2.bans}}
							<div class="match-bm-game-veto-overview-team-veto-row-item">
								<div class="match-bm-game-veto-overview-team-veto-row-item-icon">{{&heroIcon}}</div>
								<div class="match-bm-game-veto-overview-team-veto-row-item-text">#{{vetoNumber}}</div>
							</div>
							{{/teams.2.bans}}
						</div>
					</div>
				</div>
			</div>
			<h3>Team Stats</h3>
			<div class="match-bm-team-stats">
				<div class="match-bm-team-stats-header">
					{{#winnerName}}<h4 class="match-bm-team-stats-header-title">{{winnerName}} Victory</h4>{{/winnerName}}
					{{^winnerName}}<h4 class="match-bm-team-stats-header-title">No winner determined yet</h4>{{/winnerName}}
				</div>
				<div class="match-bm-team-stats-container">
					<div class="match-bm-team-stats-team">
						<div class="match-bm-team-stats-team-logo">{{&opponents.1.iconDisplay}}</div>
						<div class="match-bm-team-stats-team-side">{{&teams.1.side}}</div>
						<div class="match-bm-team-stats-team-state state--{{teams.1.scoreDisplay}}">{{teams.1.scoreDisplay}}</div>
					</div>
					<div class="match-bm-team-stats-list">
						<div class="match-bm-team-stats-list-row">
							<div class="match-bm-team-stats-list-cell">{{#finished}}{{teams.1.kills}}<span class="slash">/</span>{{teams.1.deaths}}<span class="slash">/</span>{{teams.1.assists}}{{/finished}}</div>
							<div class="match-bm-team-stats-list-cell cell--middle"><i class="fas fa-skull-crossbones cell--icon"></i>KDA</div>
							<div class="match-bm-team-stats-list-cell">{{#finished}}{{teams.2.kills}}<span class="slash">/</span>{{teams.2.deaths}}<span class="slash">/</span>{{teams.2.assists}}{{/finished}}</div>
						</div>
						<div class="match-bm-team-stats-list-row">
							<div class="match-bm-team-stats-list-cell">{{teams.1.gold}}</div>
							<div class="match-bm-team-stats-list-cell cell--middle"><i class="fas fa-coins cell--icon"></i>Gold</div>
							<div class="match-bm-team-stats-list-cell">{{teams.2.gold}}</div>
						</div>
						<div class="match-bm-team-stats-list-row">
							<div class="match-bm-team-stats-list-cell">{{teams.1.objectives.towers}}</div>
							<div class="match-bm-team-stats-list-cell cell--middle"><i class="fas fa-chess-rook cell--icon"></i>Towers</div>
							<div class="match-bm-team-stats-list-cell">{{teams.2.objectives.towers}}</div>
						</div>
						<div class="match-bm-team-stats-list-row">
							<div class="match-bm-team-stats-list-cell">{{teams.1.objectives.barracks}}</div>
							<div class="match-bm-team-stats-list-cell cell--middle"><i class="fas fa-warehouse cell--icon"></i>Barracks</div>
							<div class="match-bm-team-stats-list-cell">{{teams.2.objectives.barracks}}</div>
						</div>
						<div class="match-bm-team-stats-list-row">
							<div class="match-bm-team-stats-list-cell">{{teams.1.objectives.roshans}}</div>
							<div class="match-bm-team-stats-list-cell cell--middle"><span class="liquipedia-custom-icon liquipedia-custom-icon-roshan"></span>Roshan</div>
							<div class="match-bm-team-stats-list-cell">{{teams.2.objectives.roshans}}</div>
						</div>
					</div>
					<div class="match-bm-team-stats-team">
						<div class="match-bm-team-stats-team-logo">{{&opponents.2.iconDisplay}}</div>
						<div class="match-bm-team-stats-team-side">{{&teams.2.side}}</div>
						<div class="match-bm-team-stats-team-state state--{{teams.2.scoreDisplay}}">{{teams.2.scoreDisplay}}</div>
					</div>
				</div>
			</div>
			<h3>Player Performance</h3>
			<div class="match-bm-players-wrapper">
				<div class="match-bm-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.1.iconDisplay}}</div>
					{{#teams.1.players}}
						<div class="match-bm-players-player">
							<div class="match-bm-players-player-character">
								<div class="match-bm-players-player-avatar"><div class="match-bm-players-player-icon">{{&heroIcon}}</div><div class="match-bm-players-player-role role--{{teams.1.side}}">[[File:Dota2 facet {{facet}}.png|link=|{{facet}}]]</div></div>
								<div class="match-bm-lol-players-player-name">[[{{player}}]]<i>{{character}}</i></div>
							</div>
							<div class="match-bm-players-player-loadout">
								<!-- Loadout -->
								<div class="match-bm-players-player-loadout-items">
									<!-- Items -->
									<div class="match-bm-players-player-loadout-item">[[File:{{items.1}} itemicon dota2 gameasset.png|24px]][[File:{{items.2}} itemicon dota2 gameasset.png|24px]][[File:{{items.3}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-item">[[File:{{items.4}} itemicon dota2 gameasset.png|24px]][[File:{{items.5}} itemicon dota2 gameasset.png|24px]][[File:{{items.6}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-item">[[File:{{backpackitems.1}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.2}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.3}} itemicon dota2 gameasset.png|24px]]</div>
								</div>
								<div class="match-bm-players-player-loadout-rs-wrap">
									<!-- Runes/Spells -->
									<div class="match-bm-players-player-loadout-rs">[[File:{{neutralitem}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|24px]]{{/shard}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|24px]]{{/scepter}}</div>
								</div>
							</div>
							<div class="match-bm-players-player-stats">
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-skull-crossbones"></i>KDA</div><div class="match-bm-players-player-stat-data">{{kills}}<span class="slash">/</span>{{deaths}}<span class="slash">/</span>{{assists}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-sword"></i>DMG</div><div class="match-bm-players-player-stat-data">{{displayDamageDone}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-swords"></i>LH/DN</div><div class="match-bm-players-player-stat-data">{{lasthits}}<span class="slash">/</span>{{denies}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coin"></i>NET</div><div class="match-bm-players-player-stat-data">{{displayGold}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coins"></i>GPM</div><div class="match-bm-players-player-stat-data">{{gpm}}</div></div>
							</div>
						</div>
					{{/teams.1.players}}
				</div>
				<div class="match-bm-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.2.iconDisplay}}</div>
					{{#teams.2.players}}
						<div class="match-bm-players-player">
							<div class="match-bm-players-player-character">
								<div class="match-bm-players-player-avatar"><div class="match-bm-players-player-icon">{{&heroIcon}}</div><div class="match-bm-players-player-role role--{{teams.2.side}}">[[File:Dota2 facet {{facet}}.png|link=|{{facet}}]]</div></div>
								<div class="match-bm-lol-players-player-name">[[{{player}}]]<i>{{character}}</i></div>
							</div>
							<div class="match-bm-players-player-loadout">
								<!-- Loadout -->
								<div class="match-bm-players-player-loadout-items">
									<!-- Items -->
									<div class="match-bm-players-player-loadout-item">[[File:{{items.1}} itemicon dota2 gameasset.png|24px]][[File:{{items.2}} itemicon dota2 gameasset.png|24px]][[File:{{items.3}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-item">[[File:{{items.4}} itemicon dota2 gameasset.png|24px]][[File:{{items.5}} itemicon dota2 gameasset.png|24px]][[File:{{items.6}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-item">[[File:{{backpackitems.1}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.2}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.3}} itemicon dota2 gameasset.png|24px]]</div>
								</div>
								<div class="match-bm-players-player-loadout-rs-wrap">
									<!-- Runes/Spells -->
									<div class="match-bm-players-player-loadout-rs">[[File:{{neutralitem}} itemicon dota2 gameasset.png|24px]]</div>
									<div class="match-bm-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|24px]]{{/shard}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|24px]]{{/scepter}}</div>
								</div>
							</div>
							<div class="match-bm-players-player-stats">
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-skull-crossbones"></i>KDA</div><div class="match-bm-players-player-stat-data">{{kills}}<span class="slash">/</span>{{deaths}}<span class="slash">/</span>{{assists}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-sword"></i>DMG</div><div class="match-bm-players-player-stat-data">{{displayDamageDone}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-swords"></i>LH/DN</div><div class="match-bm-players-player-stat-data">{{lasthits}}<span class="slash">/</span>{{denies}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coin"></i>NET</div><div class="match-bm-players-player-stat-data">{{displayGold}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coins"></i>GPM</div><div class="match-bm-players-player-stat-data">{{gpm}}</div></div>
							</div>
						</div>
					{{/teams.2.players}}
				</div>
			</div>

		]=]
}
