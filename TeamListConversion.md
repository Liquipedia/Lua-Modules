# Conversion of Template:TeamList

## Affected Wikis
- stormgate: 8 pages
- starcraft2: ~600 pages
- starcraft: ~2k pages

## Steps
- [x] Convert all Template:TeamList/Team calls to Template:TeamCard calls
- [x] Delete Template:TeamList/Team
- [x] Convert all usages of pure TeamCard calls (usually with box stuff arround them) to use TeamList wrapper (TeamCard already uses TeamList under the hood)
- [x] Clean up `Toggle group start`/`Toggle group end` usages in combi with TeamList
- [ ] wait for necessary features of TeamParticipants
  - [ ] #6872
  - [ ] #7319
  - [ ] check if the sc(2) specific TC "roles" (captain, 2v2) work in TeamParticipants, if not see how to make them work
  - [ ] check if combi of DNP & captain "role" work in TeamParticipants, if not see how to make it work
  - [ ] check how player notes are handled and if this is doable ...
- [ ] Write a conversion wrapper (as dev of TeamList modules)
- [ ] Test conversion wrapper (incl perf test)
- [ ] Inplace replace TeamList modules with the conversion wrapper
- [ ] Replace TeamCard and TeamList/Section usage with jsons (`subst:#json:`, TeamCard already does ecaxtly that when reaching this point, TeamList/Section only adds a single param)
  - [ ] sc2
  - [ ] sg
  - [ ] bw
- [ ] Delete Template:TeamCard on all 3 wikis & delete Template:TeamList/Section on commons
  - [ ] sc2
  - [ ] sg
  - [ ] bw
  - [ ] commons
- [ ] If there are no issues mentioned within X months after inplace conversion start a (subst) replace run to use the option of the conversion wrapper to generate the wiki code
  - [ ] sc2
  - [ ] sg
  - [ ] bw
- [ ] Archive/Delete the TeamList modules (i.e. the conversion wrappers) and Template:TeamList

## Conversion wrapper
- Basically mirror what TeamList modules do (import auto dnp etc pp) just without display and without storage
- Instead of display/storage convert the collected data to new params and call TeamParticipants with them
  - If section stuff is used each section has to call TeamParticipants stuff and then wrap all the TeamParticipants calls into Tabs dynamic
- Add an **option** to generate wiki code instead of calling TeamParticipants
- Add a check that adds a cleanup category if it finds `'<%s*br%s*/?>'` in any of the inputs

### Param Mapping
#### new params
##### top level
- minimumplayers --> useless
- showplayerinfo --> useless
- mergeStaffTabIfOnlyOneStaff --> useless
- sortAlphabetically (#7319) --> legacy wrapper will do the sorting beforehand
- date
- store
- |X= --> Json of team data

##### team level
- contenders --> useless
- qualification --> useless
- syncPlayerTeam --> false (legacy wrapper will do it beforehand)
- import --> always false (just fucks things up on these 3 wikis (plus warcraft) ...), better would be to forbid this entirely ...
- autoplayed --> (#6872) false (legacy wrapper will do it beforehand)
- date
- aliases
- notes
  - --> {{Json|note1|note2|note3}}
  - --> note conversion has to be done manually as most of the notes are below the TeamLists and only a numebr is set in the TeamCards ...
  - --> check how to handle the player notes (possibly a cluster fuck ...) ...
- players --> Json-Array of player level inputs
- template --> team template

##### player level
- trophies --> nil, unwanted
- number --> nil, unwanted
- type --> always `'player'`, we do not have nor want the staff shit at all ...
- played --> provided by wrapper info
- results --> nil (defaults to played input)
- role --> 'Captain'/'2v2'/nil
- status --> 'former'/'sub'/nil, unknown how to handle this atm
- name
- flag
- faction
- link
- team --> if different from main team ...

### data available when mapping
todo - will be added at a later date (when i have the time to sift through the current module + check stuff with logging data)
