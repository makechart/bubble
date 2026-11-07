module.exports =
  pkg:
    name: 'bubble', version: '0.0.1'
    # lite: 不帶 d3 的 base. 補間改用 chart.anim, 可以逐格錄影 ( 見 @plotdb/chart utils/anim )
    extend: {name: "@makechart/base", path: "lite/index.html"}
    # 版面用 d3-hierarchy ( pack ) 與 d3-force ( 依相依順序載入, 不需要 d3 core ) 加 d3-force-boundary
    dependencies: [
    * name: \d3-hierarchy, version: "3.1.2", path: "dist/d3-hierarchy.min.js", async: false
    * name: \d3-dispatch, version: "3.0.1", path: "dist/d3-dispatch.min.js", async: false
    * name: \d3-quadtree, version: "3.0.1", path: "dist/d3-quadtree.min.js", async: false
    * name: \d3-timer, version: "3.0.1", path: "dist/d3-timer.min.js", async: false
    * name: \d3-force, version: "3.0.0", path: "dist/d3-force.min.js", async: false
    * name: \d3-force-boundary, path: "dist/d3-force-boundary.min.js"
    ]
    i18n:
      "zh-TW":
        "K": \千
        "M": \百萬
  init: ({root, ctx, pubsub, t}) ->
    pubsub.fire \init, mod: mod {ctx, t} .then ~> it.0

mod = ({ctx, t}) ->
  {d3,forceBoundary,ldcolor,chart,wrap-svg-text} = ctx
  {scale: Scale, shape, anim: {join}} = chart.utils
  svgns = "http://www.w3.org/2000/svg"
  kids = (p, sel) -> Array.from(p.querySelectorAll ":scope > #sel")
  # 同 d3.extent: 略過 null / NaN
  extent = (list) ->
    vs = list.filter -> it? and +it >= +it
    if vs.length => [vs.reduce(((a,b) -> if b < a => b else a)), vs.reduce(((a,b) -> if b > a => b else a))]
    else [undefined, undefined]
  sample: ->
    raw: [0 to 100].map (val) ~>
      name: "N-#val-" + Math.random!toString(16).substring(Math.ceil(Math.random! * 10))
      val1: (Math.random! * 100).toFixed(1)
      val2: (Math.random! * 100).toFixed(1)
      val3: (Math.random! * 100).toFixed(1)
      cat: Math.floor(Math.random! * 6)
    binding:
      group: {key: \cat}
      name: {key: \name}
      #color: {key: \cat}
      #area: [{key: \val1}, {key: \val2}]
      area: [{key: \val1, unit: 'MB'}]
  config: chart.utils.config.from({
    preset: \default
    legend: \legend
    tip: \tip
  }) <<<
    bubble:
      min-radius: name: "min radius", type: \number, default: 1, min: 0, max: 10, step: 1
      max-radius: name: "max radius", type: \number, default: 100, min: 0.1, max: 100, step: 0.1
    dynamics:
      anchor:
        name: "Anchor Layout", type: \choice, default: \none
        values: [
        * name: "Default", value: \default
        * name: "Circular", value: \circular
        * name: "Array", value: \array
        * name: "none", value: \none
        ]
    pie:
      order: type: \choice, values: <[group ratio]>, default: \ratio
      color:
        type: \choice, name: "colorscheme",
        values: ["from palette", "lightness", "dark to light", "light to dark"]
        default: "dark to light"
      contrast:
        type: \number, name: "lightness contrast"
        default: 0.5, min: 0.1, max: 0.9, step: 0.01
      legend: chart.utils.config.from({preset: \legend})
    label:
      enabled: type: \choice, default: \both, values: <[both name value none]>
      format: type: \format, default: \.3s
      overflow:
        type: \number
        desc: "percentage of tolerance when label overflow"
        default: 0, min: 0, max: 1, step: 0.01
      font: chart.utils.config.from({preset: \font})
      wrap: type: \boolean, default: true
      trim:
        enabled:
          type: \boolean, default: false
          desc: "limit maximal amount of labels to show"
        keep:
          type: \number
          desc: "amount of labels to keep when trim"
          default: 100, min: 0, max: 100, step: 1
    unit: position: type: \choice, values: <[inner outside none]>
  dimension:
    group: {type: \C, name: "group", priority: 2}
    color: {type: \NR, name: "color", priority: 4}
    area: {type: \R, name: "area", priority: 1, multiple: true}
    name: {type: \NC, name: "name", priority: 3}
  init: ->
    obj = @
    @tint = tint = new chart.utils.tint!
    @unit = {}
    @parsed = @parsed or []
    @g = Object.fromEntries <[view unit legend]>.map ~> [it, @layout.get-group it]
    node = @root.querySelector '[ld=tip]'
    @tip = new chart.utils.tip {
      root: @root
      accessor: ({evt}) ~>
        if !(evt.target and d = evt.target.__data__) => return null
        fmt = if @cfg.tip.format => chart.utils.format.d3(@cfg.tip.format) else @fmt
        value = if !(ret = fmt d.area) => '' else "#ret#{@unit.text}"
        if @binding.area and @binding.area.length > 1 =>
          b = @binding.area[d.idx] or {}
          if (b = b.name or b.key or '') => value = "#b: #value"
        return {group: d.group or '', name: d.name, value}
      range: ~> return @layout.get-node \view .getBoundingClientRect!
    }

    @legend = new chart.utils.legend do
      layout: @layout
      name: \legend
      root: @root
      shape: (d) -> @setAttribute \fill, tint.get d.key
      direction: if @cfg.{}legend.position == \bottom => \horizontal else \vertical
      cfg: selectable: true
    @legend.on \select, ~> @bind!; @resize!; @render!

    base = @
    @pie-legend = new chart.utils.legend do
      layout: @layout
      name: \pie-legend
      root: @root
      shape: (d,i) ->
        idx = if base.cfg.pie.color == 'dark to light' => d.idx else (1 - d.idx)
        if base.binding.group =>
          contrast = base.cfg.pie.contrast * 2
          l = 100 * (idx * contrast + (0.5 - contrast / 2)) >? 10 <? 90
          @setAttribute \fill, ldcolor.web({h: 0, c: 0, l: l})
        else
          i = if /\/(\d+)/.exec(d.key) => +that.1 else 0
          c = tint.get((obj.binding.area[i] or {}).key or i)
          @setAttribute \fill, c
      direction: if @cfg.{}legend.position == \bottom => \horizontal else \vertical
      cfg: selectable: true
    @pie-legend.on \select, ~> @bind!; @resize!; @render!

    @arc = shape.arc!
      .startAngle 0
      .endAngle(Math.PI / 2)
    @_color = (d,i) ~>
      if @binding.color => return tint.get(+d.color)
      g = if @groups.length => d.group else ''
      g = if g? => g else ''

      c = if (@groups.length and @cfg.pie.color != 'from palette') or i == 0 => g
      else "#g/#i"

      # without groups, we can use palette directly for wedges.
      if @groups.length and @cfg.pie.color != 'from palette' =>
        c = tint.get c
        # lightness, while keep group color in the first place
        contrast = @cfg.pie.contrast * 100
        if @cfg.pie.color == \lightness =>
          hcl = ldcolor.hcl(c)
          p = i / (d.paths.length or 1)
          l = if hcl.l >= 60 => hcl.l - contrast * p
          else hcl.l + contrast * p
          c = if hcl.c >= 90 => hcl.c
          else hcl.c + (90 - hcl.c) * p
          hcl <<< {c, l}
        else
          hcl = ldcolor.hcl(c)
          j = if @cfg.pie.color == 'dark to light' => i else ((d.paths.length - i - 1) >? 0)
          if hcl.l > 60 + (contrast / 5) =>
            if d.paths.length == 1 => p = 1
            else p = j / ((d.paths.length - 1) >? 1)
            hcl.l = (hcl.l - contrast) + contrast * p
          else
            p = j / ((d.paths.length - 1) >? 1)
            hcl.l = hcl.l + contrast * p
          hcl.l = hcl.l >? 10 <? 90

        return ldcolor.web(hcl)
      else
        c = tint.get((@binding.area[i] or {}).key or i)
        ldcolor.web c
  destroy: -> @tip.destroy!

  parse: ->
    @tint.reset!
    @data.for-each ->
      it._area = it.area
      # sometimes there are the same names in different groups.
      # thus, we prepare additional `_id` for identifying old / new bubble pairs.
      it._id = "#{it.group or \-}/#{it.name or it._idx}"
    @valid = @data.filter -> Array.isArray(it.area) and !isNaN(it.area.reduce(((a,b) -> a + b),0))
    @groups = Array.from(new Set(@valid.map -> it.group)).filter(-> it?)
    @sim = null
    lgdata = @groups.map -> {key: it, text: it}
    lgdata.sort (a, b) -> if a.key > b.key => 1 else if a.key < b.key => -1 else 0
    @legend.data lgdata

    if @binding.color =>
      @tint.extent(extent(@data.filter(->!isNaN(it.color)).map(->+it.color)))
      @tint.mode chart.utils.tint.mode.continuous
    else
      @tint.mode chart.utils.tint.mode.ordinal

    # lightness respect group color and use different lightness in other wedges.
    #  - not applicable since we don't have an explicit order or lightness (unlike dark to light / light to dark)
    # from palette uses colors from palette, which totally mess up with the color.
    if (@cfg.pie.color in ["from palette", "lightness"]) and @groups.length => plgdata = []
    else
      plgdata = @binding.area.map (b,i) ~>
        key: if i => "/#i" else '' # align with _color keyword
        idx: i/((@binding.area.length - 1) >? 1)
        text: b.name or b.key
    if @cfg.pie.legend.position == \bottom => plgdata.sort (a,b) -> b.idx - a.idx
    @pie-legend.data(if plgdata.length > 1 => plgdata else [])

  resize: ->
    @fmt = chart.utils.format.from @cfg.label.format

    lg-on = (d = @legend.data!) and d.length and @cfg.legend.enabled
    lg-bt = @cfg.legend.position == \bottom
    @root.querySelector('.pdl-layout').classList.toggle \lg-bt, (lg-on and lg-bt)
    @root.querySelector('.pdl-layout').classList.toggle \lg-rt, (lg-on and !lg-bt)

    plg-on = (d = @pie-legend.data!) and d.length > 1 and @cfg.pie.legend.enabled
    plg-bt = @cfg.pie.legend.position == \bottom
    @root.querySelector('.pdl-layout').classList.toggle \lgp-bt, (plg-on and plg-bt)
    @root.querySelector('.pdl-layout').classList.toggle \lgp-rt, (plg-on and !plg-bt)

    @unit.text = (@binding.area?0 or {})?unit or ''
    @unit <<<
      inner: if @cfg.{}unit.position == \inner => @unit.text else ''
      outer: (
        if @cfg.{}unit.position in <[inner none]> => ''
        else if @unit.text => "#{t('unit')}: #{@unit.text}" else ''
      )
    @layout.get-node \unit
      ..style.display = if !@unit.outer => 'none' else ''
      ..textContent = @unit.outer

    @tip.toggle(if @cfg.tip.enabled? => @cfg.tip.enabled else true)
    list = (
      [{key: 'root', root: true}] ++
      @groups.map(->{key: "group-#it"}) ++
      (if !@groups.length => @valid else @valid.filter(~> !@cfg.legend.enabled or @legend.is-selected it.group))
    )
    if @legend.enabled! => list = list.filter ~> !it._raw or !@groups.length or @legend.is-selected it.group
    @legend.config @cfg.legend
    @legend.update!

    @pie-legend.config @cfg.pie.legend
    @pie-legend.update!

    @layout.update false

    if plg-on =>
      selected = (@binding.area or []).map (d,i) ~> @pie-legend.is-selected(if i => "/#i" else "")
      list.map -> if Array.isArray(it._area) => it.area = it._area.map (d,i) -> if selected[i] => d else 0

    ret = d3.hierarchy(
      d3.stratify!
        .id(->if it._idx? => it._idx else it.key)
        # no group-based position
        #.parentId(-> if it.root => '' else 'root' ) list
        # group-based position
        .parentId(-> if it.root => '' else if it.group? => "group-#that" else \root) list
    )
      .sum -> (it.data.area or []).reduce(((a,b) -> a + b), 0)
      .sort (a,b) -> b.value - a.value # sort or not

    box = @vbox = @layout.get-box \view
    pack = d3.pack!size([box.width, box.height]) ret
    @parsed = ret.leaves!
      .map (d) ~>
        d._raw = d.data.data._raw
        ddata = d.data.data

        # if @parsed exists, then this is a data / size / config update.
        # we use the old data position for a smooth transition effect.
        od = if @parsed =>
          p = @parsed
            .filter (p) -> p._id == ddata._id
            .0
          if p => p else d
        else d
        {x,y} = d
        d <<< {x, y}
        d <<< ddata{_idx, _id, name, color, group, area}
        if od._x => d._x = od._x else if !d._x => d._x = d.x
        if od._y => d._y = od._y else if !d._y => d._y = d.y

        d.paths = (d.area or []).map (e,i) ->
          {name: d.name, group: d.group, area: e, idx: i} <<< ((od.paths or [])[i] or {}){old, cur}
        sum = 0
        da = if d.paths.length > 1 => (d.paths.0.area - d.paths.1.area)/4 else 0
        for i from 0 til d.paths.length =>
          d.paths[i].s = sum - da
          d.paths[i].e = (sum += d.paths[i].area) - da
        d.rate = da
        d.total = sum or 1
        d
      .filter -> it.area? and !isNaN(it.x) and !isNaN(it.y)

    exts = {}
    @parsed.map (d,i) ->
      exts{}[d.group].x1 <?= d.x
      exts{}[d.group].x2 >?= d.x
      exts{}[d.group].y1 <?= d.y
      exts{}[d.group].y2 >?= d.y

    # we calculate dr ( first two area ratio ) and find its extent + mean
    # with mean, we can then proper pose the pie centered in canvas even if some wedges are switched off.
    exts-dr = {}
    drs = @parsed
      .filter (d) -> d.paths.length > 1
      .map (d) -> d._dr = (d.paths.0.area - d.paths.1.area) / ((d.paths.0.area + d.paths.1.area or 1))
    exts-dr.x1 = Math.min.apply Math, drs
    exts-dr.x2 = Math.max.apply Math, drs
    ddr = (exts-dr.x2 - exts-dr.x1) or 1
    dmid = (exts-dr.x2 + exts-dr.x1) / 2

    @parsed.map (d,i) ~>
      if d.paths.length <= 1 => return
      # we use dmid to normalize so it will center even if exts-dr{x1, x2} are equal
      dr = ((d._dr - dmid) * 2) / ddr
      e = exts[d.group]
      if @cfg.pie.order == \group =>
        d <<< x: dr * (e.x2 - e.x1) * 0.5 + (e.x2 + e.x1) / 2
      else
        d <<< x: dr * box.width * 0.4 + box.width * 0.5
    gn = @cfg.dynamics.anchor
    exthash = Object.fromEntries @groups.map (d,i) -> [d,i]
    for k, v of exts =>
      @{}gcenter[k] = if gn == \circular =>
        [i,r] = [exthash[k], Math.min(@vbox.width, @vbox.height)]
        x: @vbox.width * 0.5 + r * Math.cos(i * Math.PI * 2 / (@groups.length or 1)) * 0.3
        y: @vbox.height * 0.5 + r * Math.sin(i * Math.PI * 2 / (@groups.length or 1)) * 0.3
      else if gn == \array =>
        i = exthash[k]
        side = Math.sqrt((@vbox.width * @vbox.height) / (@groups.length or 1))
        cx = Math.floor(@vbox.width / side)
        cy = Math.floor(@vbox.height / side)
        list = [
          [cx, cy, cx * cy]
          [cx + 1, cy, (cx + 1) * cy]
          [cx, cy + 1, cx * (cy + 1)]
          [cx + 1, cy + 1, (cx + 1) * (cy + 1)]
        ]
        list.sort (a,b) -> if a.2 < b.2 => -1 else if a.2 > b.2 => 1 else 0
        _list = list.filter ~> it.2 >= @groups.length
        [cx, cy] =  if !_list.length => list[* - 1] else _list.0
        side = Math.min(@vbox.width / cx, @vbox.height / cy)
        dx = (@vbox.width - side * cx) / 2
        dy = (@vbox.height - side * cy) / 2
        x: side * ((i % (cx or 1)) + 0.5) + dx, y: side * (Math.floor(i / (cx or 1)) + 0.5) + dy
      else x: (v.x1 + v.x2) * 0.5, y: (v.y1 + v.y2) * 0.5
    @sim = null
    @start!

    # automatically adjust circle size based on canvas size.
    @rate = rate = 0.85 * # make it slightly smaller. adjust as your wish
      Math.PI / (2 * Math.sqrt(3)) * # wasted space from exterior hexagon to circle
      Math.sqrt(box.width * box.height / @parsed.map(-> Math.PI * (it.r ** 2)).reduce(((a,b) -> a + b),0))
    rext = extent @parsed.map (d,i) ~> d.rr = (d.r * @rate)
    minr = @cfg.bubble.min-radius or 0
    minr <?= Math.min(box.width, box.height) / 2
    maxr = Math.min((@cfg.bubble.max-radius or 0) * box.width * 0.25 / 100, rext.1) >? minr
    maxr <?= Math.min(box.width, box.height) / 2
    radius-scale = Scale.linear!domain([0,rext.1]).range [0, maxr]
    @parsed.map (d,i) ~>
      d.rr = radius-scale d.rr
      if d.rr => d.rr >?= minr

  render: ->
    {fmt, _color, cfg, binding, tint, layout, unit} = @
    box = @vbox

    node = layout.get-node \unit
    ret = wrap-svg-text {node, useRange: true}
    @g.unit.textContent = ''
    @g.unit.appendChild ret

    @parsed.map (d,i) ->
      d.paths.map (p,j) ->
        s = p.s * 2 * Math.PI / d.total
        e = p.e * 2 *  Math.PI / d.total
        p.old = p.cur or {r: d.rr, s, e}
        p.cur = {r: d.rr, s, e}

    tint.set(@cfg.palette)

    interpolate-arc = (a1, a2, i) ~> (t) ~>
      @arc
        .innerRadius 0
        .outerRadius (a2.r - a1.r) * t + a1.r
      [s,e] = <[s e]>.map (i) -> (a2[i] - a1[i]) * t + a1[i]
      @arc.startAngle s .endAngle e
      @arc!

    tween = (n, attrs, opt = {}) ~> @anim.tween n, attrs, {duration: 350} <<< opt
    bj = join root: @g.view, tag: \g, cls: \bubble, data: @parsed, key: (->it._id)
    # 移除的: 扇形半徑縮到 0, 縮完才把整個 bubble 拿掉
    bj.exit.map (n) ->
      d = n.__data__
      d._removing = true
      d.paths.map -> it.old.r = it.cur.r; it.cur.r = 0
    bj.enter.map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d._x},#{d._y})"
      d._removing = false
    kids(@g.view, \g.bubble).map (n) ->
      _d = n.__data__
      n.setAttribute \transform, "translate(#{_d._x},#{_d._y})"
      pj = join root: n, tag: \path, cls: \data, data: _d.paths, key: (d,i) -> i
      pj.exit.map -> it.remove!
      pj.enter.map (p, i) ->
        p.setAttribute \opacity, 0
        p.setAttribute \fill, _color _d, pj.nodes.indexOf(p)
      remove = -> if n.__data__._removing and n.parentNode => n.remove!
      if !pj.nodes.length and _d._removing => remove!
      pj.nodes.map (p, i) ->
        d = p.__data__
        opt = if _d._removing and i == pj.nodes.length - 1 => {end: remove} else {}
        tween p, {d: interpolate-arc(d.old, d.cur, i), fill: _color(_d, i), opacity: 1}, opt
    trimmed-parsed = if !@cfg?label?trim?enabled => @parsed
    else
      @parsed
        .sort (a,b) -> if +a.total < +b.total => 1 else if +a.total > +b.total => -1 else 0
        .slice 0, (@cfg?label?trim?keep or 0)
    lj = join root: @g.view, tag: \g, cls: \label, data: trimmed-parsed, key: (._id)
    lj.exit.map ~>
      @anim.interrupt it
      it.remove!
    lj.enter.map (n) ->
      d = n.__data__
      n.setAttribute \class, 'label data'
      n.setAttribute \transform, "translate(#{d.x},#{d.y})"
      n.setAttribute \opacity, 0
      n.setAttribute \font-size, (cfg.label.font.size or '1em')
      n.style <<< pointer-events: \none, cursor: \pointer
      # use group + wrap-svg-text below
      [0,1].map ->
        n.appendChild document.createElementNS(svgns, \g)
          ..setAttribute \class, \inner
          ..setAttribute \opacity, 0
    kids(@g.view, \g.label).map (n) ->
      d = n.__data__
      n.setAttribute \font-size, (cfg.label.font.size or '1em')
      n.setAttribute \transform, "translate(#{d._x},#{d._y})"
      n.setAttribute \class, "label #{if cfg.label.font.family => (that.className or '') else ''}"
      t = (e,i) ->
        if i != 0 => return d.name or ''
        sum = d.area.reduce(((a,b) -> a + b),0)
        if !(ret = fmt sum) => ''
        else "#{ret}#{unit.inner}"
      fs = (e, i, r = 1) ->
        # adaptive font size
        text = t(e,i)
        s = if !i => 1.1
        else 0.9 * ((1 - 0.1 * (text.length / 5)) >? 0.7)
        return s * r
      inners = kids(n, \.inner)
      # use g + wrap-svg-text
      inners.map (g, i) ->
        g.__data__ = d
        for j from g.childNodes.length - 1 to 0 by -1 => g.removeChild g.childNodes[j]
        ret = wrap-svg-text {
          text: t(d,i)
          style: {
            width: "#{if cfg.label.wrap => d.rr * 2 else box.width}px"
            lineHeight: fs(d, i, 1.2)
            fontSize: cfg.label.font.size or ''
          }
        }
        ret.style.transform = if cfg.label.enabled != \both => "translate(0,0)"
        else "translate(0,#{i * (0.3 + 1.1 / fs(d,i,1))}em)"
        Array.from(ret.querySelectorAll("text")).map ->
          it.setAttribute \text-anchor, \middle
        g.appendChild ret
      get-opacity = (e, i) ->
        c = cfg.label.enabled
        if c == \both => return 1
        if c == \name => return (if i == 0 => 0 else 1)
        if c == \value => return (if i == 1 => 0 else 1)
        if c == \none => return 0
        return 1
      inners.map (g, i) ->
        g.setAttribute \font-size, "#{fs(d,i,1)}em"
        tween g, do
          "style:visibility": if get-opacity(d,i) => \visible else \hidden
          opacity: get-opacity(d,i)
          fill: if ldcolor.hcl(_color d, 0).l < 70 => \#fff else \#000

    kids(@g.view, \g.label).map (n) -> tween n, {"font-size": cfg.label.font.size}, {duration: 150}
    # even with delay, opacity is calculated before font-size is fully updated,
    # thus box size with pre-font-size is returned.
    # we use setTimeout to enfoce opacity to be calculated after font-size is updated.
    if @h => clearTimeout @h
    @h = setTimeout (~>
      @h = null
      get-opacity = (d,i) ->
        box = d._box # @getBoundingClientRect!
        [w,h] = [box.width, box.height]
        # tolerance for label overflowing out of circle
        s = 2 * d.rr * ((cfg.label.overflow or 0) + 1)
        if s < w or 2 * d.rr < h => 0 else 1
      kids(@g.view, \g.label).map (n, i) ->
        d = n.__data__
        d._box = box = n.getBoundingClientRect!
        [w,h] = [box.width, box.height]
        kids(n, \.inner).map -> it.setAttribute \transform, "translate(0,#{-h/2})"
        op = get-opacity(d,i)
        tween n, {opacity: op, "style:visibility": (if op => \visible else \hidden)}, {duration: 150}
    ), 150
    @legend.render!

    @pie-legend.render!

  tick: ->
    # TODO actually we don't have pad config. remove it?
    pad = @cfg.pad or 5
    box = @vbox
    if !@sim =>
      kickoff = true
      @fc = fc = d3.forceCollide!strength 0.5 .iterations 10 .radius ~> it.rr
      # in fx, fy, we can tweak d.group to group with different dimensions
      @fx = d3.forceX(
        (d) ~> (@gcenter[d.group] or {}).x or @vbox.width / 2
      ).strength(0.3)
      @fy = d3.forceY(
        (d) ~> (@gcenter[d.group] or {}).y or @vbox.height / 2
      ).strength(0.3)
      @fg = d3.forceCenter!strength 0.5
      @fb = forceBoundary(
        (~> it.rr + pad), (~> it.rr + pad),
        (~> box.width - it.rr - pad), (~> box.height - it.rr - pad)
      ).strength 0.5
      @sim = d3.forceSimulation!
        # we can't make it center properly so disable it for now.
        #.force \center, @fg
        .force \b, @fb
        .force \collide, @fc
      @sim.stop!
      @sim.alpha 1
    #@fg.x(box.width / 2)
    #@fg.y(box.height / 2)
    if (@cfg.dynamics or {}).anchor == \none or !(@cfg.dynamics or {}).anchor =>
      @sim.force(\x, null).force(\y, null)
    else @sim.force(\x, @fx).force(\y,@fy)

    @sim.nodes(@parsed)
    @sim.tick if kickoff => 10 else 1
    @parsed.map ->
      it._x = it._x + (it.x - it._x) * 0.1
      it._y = it._y + (it.y - it._y) * 0.1

    (kids(@g.view, \g.bubble) ++ kids(@g.view, \g.label)).map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d._x},#{d._y})"
