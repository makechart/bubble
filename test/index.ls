# bubble 的 test case ( @makechart/viewer 的 mctest )
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, areas = 1, groups = 4, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map (i) ->
    ret = {name: "N-#i", cat: "G#{Math.floor(rnd! * groups)}"}
    for j from 0 til areas => ret["v#j"] = Math.round(rnd! * 1000) / 10
    ret
  binding:
    group: {key: \cat}
    name: {key: \name}
    area: [{key: "v#j", unit: \MB} for j from 0 til areas]
nogroup = (d) -> delete d.binding.group; d
# 版面由 mod.tick 的模擬推動. 切到 manual 前已用真實時間跑過幾格, 清掉舊位置重排 ( pack ) 再跑完模擬.
# lite 版推 anim 的時鐘, d3 版等真實時間
reset = (c) ->
  c.parsed = null
  c.resize!; c.render!
run = (c, ctx) ->
  if c.anim => for i from 0 til 400 => c.anim.step 16
  else ctx.wait 8000
layout = [reset, run]
# 滑到扇形上: tip 讀 evt.target 的資料
hover = (sel, idx = 0) -> (c, ctx) ->
  n = ctx.root.querySelectorAll(sel)[idx]
  r = n.getBoundingClientRect!
  n.dispatchEvent new MouseEvent(\mousemove, {bubbles: true, clientX: Math.round(r.x + r.width / 2), clientY: Math.round(r.y + r.height / 2)})
pick = (keys) -> (c) ->
  c.legend.select keys
  c.bind!; c.resize!; c.render!

mctest.suite do
  size: [560, 400]
  tolerance: 1
  data:
    one: mk 40
    two: mk 30, 2, 3
    three: mk 20, 3, 2, 7
    flat: nogroup mk 25, 1, 1, 3
  cases:
    * name: "one", data: \one, steps: layout
    * name: "two", data: \two, steps: layout
    * name: "three", data: \three, steps: layout
    * name: "flat", data: \flat, steps: layout
    * name: "anchor:circular", data: \one, config: {dynamics: {anchor: \circular}}, steps: layout
    * name: "anchor:array", data: \one, config: {dynamics: {anchor: \array}}, steps: layout
    * name: "pie:lightness", data: \two, config: {pie: {color: \lightness}}, steps: layout
    * name: "label:name", data: \one, config: {label: {enabled: \name}}, steps: layout
    * name: "unit:inner", data: \one, config: {unit: {position: \inner}}, steps: layout
    * name: "legend:pick", data: \one, steps: layout ++ [(pick <[G0 G2]>), run]
    * name: "hover", data: \two, steps: layout ++ [hover('g.bubble path.data', 5)]

# lite 版才有: 版面收斂與扇形變化的中間格
mctest.suite do
  size: [560, 400]
  data: one: mk 40
  cases:
    * name: "anim:pick-frames", data: \one
      steps:
        * reset
        * run
        * (c, ctx) ->
            pick(<[G0 G2]>) c
            for i from 1 to 3
              c.anim.step 100
              ctx.capture "t#{i * 100}"
