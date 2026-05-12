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
- [ ] Write conversion wrapper (as dev of `TeamList` modules)
  - [x] initial
  - [ ] test & debug
  - [ ] perf test
- [ ] wait for necessary features of TeamParticipants for using wrapper
  - [ ] check if the sc(2) specific TC "roles" (captain, 2v2) work in TeamParticipants, if not see how to make them work
  - [ ] check if combi of DNP & captain "role" work in TeamParticipants, if not see how to make it work
- [ ] Inplace replace TeamList modules with the conversion wrapper
- [ ] wait for necessary features of TeamParticipants
  - [ ] #6872
  - [ ] #7319
- [ ] start using TeamParticipants on new pages
- [ ] Replace `TeamCard` and `TeamList/Section` usage with jsons (`subst:#json:`, TeamCard already does ecaxtly that when reaching this point, `TeamList/Section` only adds a single param (`|type=section`))
  - [ ] sc2
  - [ ] sg
  - [ ] bw
- [ ] Delete `Template:TeamCard` on all 3 wikis & delete `Template:TeamList/Section` on commons
  - [ ] sc2
  - [ ] sg
  - [ ] bw
  - [ ] commons
- [ ] If there are no issues mentioned within X months after inplace conversion start a (subst) replace run to use the option of the conversion wrapper to generate the wiki code
  - [ ] sc2
  - [ ] sg
  - [ ] bw
- [ ] Archive/Delete the TeamList modules (i.e. the conversion wrappers) on commons and `Template:TeamList` on the 3 wikis
  - [ ] commons
  - [ ] sc2
  - [ ] sg
  - [ ] bw

## Conversion wrapper
- Basically mirror what TeamList modules do (import auto dnp etc pp) just without display and without storage
- Instead of display/storage convert the collected data to new params and call TeamParticipants with them
  - If section stuff is used each section has to call TeamParticipants stuff and then wrap all the TeamParticipants calls into Tabs dynamic
- Add an **option** to generate wiki code instead of calling TeamParticipants
- Add a check that adds a cleanup category if it finds `'<%s*br%s*/?>'` in any of the inputs
