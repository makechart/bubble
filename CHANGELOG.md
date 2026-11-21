# Change Logs

## v0.0.9

 - pin `d3-force-boundary` to 0.0.3 ( it was unversioned, so the latest was loaded; 0.0.3 is what was loaded already, layout unchanged )
 - devDependencies: @makechart/viewer ^0.0.8 ( every case checks mod.tabinfo ), refresh the test snapshots ( they were taken with d3-force 3.0.1 / d3-force-boundary 0.0.2 from node_modules, now the declared versions are loaded )

## v0.0.8

 - add `tabinfo`: descriptions ( en / zh-TW ) of the config sections, shown on the section tabs in the makechart style panel ( needs @plotdb/chart >= 3.17.0 )

## v0.0.7

 - add `desc` ( en / zh-TW ) to the config items, shown under the label in the makechart style panel

## v0.0.6

 - extend the lite base ( `@makechart/base` `lite/index.html`, no d3 ): needs `@makechart/base` >= 0.2.0
   and `@plotdb/chart` >= 3.7.0
   d3 is replaced by `d3-hierarchy`, `d3-force` ( with `d3-dispatch`, `d3-quadtree`, `d3-timer` ) and `d3-force-boundary`
   transitions run on `chart.anim`, so animation can be recorded frame by frame ( `anim.manual` / `step` )
 - add test cases ( `test/index.ls`, run with `npm test` via `@makechart/viewer` )


## v0.0.5

 - add d3-force-boundary dependency
 - ensure accessing unit with an existed object


## v0.0.4

 - enforce maximal radius based on canvas size to prevent overflow
 - tweak force dynamics
 - support `trim` config with amount of entries to keep in label config
 - fix bug: label should apply `label.font.size` instead of `font.size`


## v0.0.3

 - add minimal radius (in pixel)


## v0.0.2

 - remove unused `radius` since it's not correct anyway
 - add `none` option for label mode.
 - align label based on enabled mode
 - support different force layout anchor points
 - support bubble max radius limitation (based on canvas size)
 - improve performance by setting visibility to hidden for a text label if it's transparent


## v0.0.1

init release
