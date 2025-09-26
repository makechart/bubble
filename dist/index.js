(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'bubble',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: [],
      i18n: {
        "zh-TW": {
          "K": '千',
          "M": '百萬'
        }
      }
    },
    init: function(arg$){
      var root, ctx, pubsub, t;
      root = arg$.root, ctx = arg$.ctx, pubsub = arg$.pubsub, t = arg$.t;
      return pubsub.fire('init', {
        mod: mod({
          ctx: ctx,
          t: t
        })
      }).then(function(it){
        return it[0];
      });
    }
  };
  mod = function(arg$){
    var ctx, t, d3, forceBoundary, ldcolor, chart, wrapSvgText, ref$;
    ctx = arg$.ctx, t = arg$.t;
    d3 = ctx.d3, forceBoundary = ctx.forceBoundary, ldcolor = ctx.ldcolor, chart = ctx.chart, wrapSvgText = ctx.wrapSvgText;
    return {
      sample: function(){
        return {
          raw: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100].map(function(val){
            return {
              name: ("N-" + val + "-") + Math.random().toString(16).substring(Math.ceil(Math.random() * 10)),
              val1: (Math.random() * 100).toFixed(1),
              val2: (Math.random() * 100).toFixed(1),
              val3: (Math.random() * 100).toFixed(1),
              cat: Math.floor(Math.random() * 6)
            };
          }),
          binding: {
            group: {
              key: 'cat'
            },
            name: {
              key: 'name'
            },
            area: [{
              key: 'val1',
              unit: 'MB'
            }]
          }
        };
      },
      config: (ref$ = chart.utils.config.from({
        preset: 'default',
        legend: 'legend',
        tip: 'tip'
      }), ref$.pie = {
        order: {
          type: 'choice',
          values: ['group', 'ratio'],
          'default': 'ratio'
        },
        color: {
          type: 'choice',
          name: "colorscheme",
          values: ["from palette", "lightness", "dark to light", "light to dark"],
          'default': "dark to light"
        },
        contrast: {
          type: 'number',
          name: "lightness contrast",
          'default': 0.5,
          min: 0.1,
          max: 0.9,
          step: 0.01
        },
        legend: chart.utils.config.from({
          preset: 'legend'
        })
      }, ref$.label = {
        enabled: {
          type: 'choice',
          'default': 'both',
          values: ['both', 'name', 'value']
        },
        format: {
          type: 'format',
          'default': '.3s'
        },
        overflow: {
          type: 'number',
          'default': 0,
          min: 0,
          max: 1,
          step: 0.01
        },
        font: chart.utils.config.from({
          preset: 'font'
        }),
        wrap: {
          type: 'boolean',
          'default': true
        }
      }, ref$.unit = {
        position: {
          type: 'choice',
          values: ['inner', 'outside', 'none']
        }
      }, ref$),
      dimension: {
        group: {
          type: 'C',
          name: "group",
          priority: 2
        },
        color: {
          type: 'NR',
          name: "color",
          priority: 4
        },
        area: {
          type: 'R',
          name: "area",
          priority: 1,
          multiple: true
        },
        name: {
          type: 'NC',
          name: "name",
          priority: 3
        }
      },
      init: function(){
        var obj, tint, node, ref$, base, this$ = this;
        obj = this;
        this.tint = tint = new chart.utils.tint();
        this.unit = {};
        this.parsed = this.parsed || [];
        this.g = Object.fromEntries(['view', 'unit', 'legend'].map(function(it){
          return [it, d3.select(this$.layout.getGroup(it))];
        }));
        node = this.root.querySelector('[ld=tip]');
        this.tip = new chart.utils.tip({
          root: this.root,
          accessor: function(arg$){
            var evt, d, fmt, value, ret, b;
            evt = arg$.evt;
            if (!(evt.target && (d = d3.select(evt.target).datum()))) {
              return null;
            }
            fmt = this$.cfg.tip.format
              ? d3.format(this$.cfg.tip.format)
              : this$.fmt;
            value = !(ret = fmt(d.area))
              ? ''
              : ret + "" + this$.unit.text;
            if (this$.binding.area && this$.binding.area.length > 1) {
              b = this$.binding.area[d.idx] || {};
              if (b = b.name || b.key || '') {
                value = b + ": " + value;
              }
            }
            return {
              group: d.group || '',
              name: d.name,
              value: value
            };
          },
          range: function(){
            return this$.layout.getNode('view').getBoundingClientRect();
          }
        });
        this.legend = new chart.utils.legend({
          layout: this.layout,
          name: 'legend',
          root: this.root,
          shape: function(d){
            return d3.select(this).attr('fill', tint.get(d.key));
          },
          direction: ((ref$ = this.cfg).legend || (ref$.legend = {})).position === 'bottom' ? 'horizontal' : 'vertical',
          cfg: {
            selectable: true
          }
        });
        this.legend.on('select', function(){
          this$.bind();
          this$.resize();
          return this$.render();
        });
        base = this;
        this.pieLegend = new chart.utils.legend({
          layout: this.layout,
          name: 'pie-legend',
          root: this.root,
          shape: function(d, i){
            var idx, contrast, l, ref$, ref1$, that, c;
            idx = base.cfg.pie.color === 'dark to light'
              ? d.idx
              : 1 - d.idx;
            if (base.binding.group) {
              contrast = base.cfg.pie.contrast * 2;
              l = (ref$ = (ref1$ = 100 * (idx * contrast + (0.5 - contrast / 2))) > 10 ? ref1$ : 10) < 90 ? ref$ : 90;
              return d3.select(this).attr('fill', ldcolor.web({
                h: 0,
                c: 0,
                l: l
              }));
            } else {
              i = (that = /\/(\d+)/.exec(d.key)) ? +that[1] : 0;
              c = tint.get((obj.binding.area[i] || {}).key || i);
              return d3.select(this).attr('fill', c);
            }
          },
          direction: ((ref$ = this.cfg).legend || (ref$.legend = {})).position === 'bottom' ? 'horizontal' : 'vertical',
          cfg: {
            selectable: true
          }
        });
        this.pieLegend.on('select', function(){
          this$.bind();
          this$.resize();
          return this$.render();
        });
        this.arc = d3.arc().startAngle(0).endAngle(Math.PI / 2);
        return this._color = function(d, i){
          var g, c, contrast, hcl, p, l, j, ref$, ref1$;
          if (this$.binding.color) {
            return tint.get(+d.color);
          }
          g = this$.groups.length ? d.group : '';
          g = g != null ? g : '';
          c = (this$.groups.length && this$.cfg.pie.color !== 'from palette') || i === 0
            ? g
            : g + "/" + i;
          if (this$.groups.length && this$.cfg.pie.color !== 'from palette') {
            c = tint.get(c);
            contrast = this$.cfg.pie.contrast * 100;
            if (this$.cfg.pie.color === 'lightness') {
              hcl = ldcolor.hcl(c);
              p = i / (d.paths.length || 1);
              l = hcl.l >= 60
                ? hcl.l - contrast * p
                : hcl.l + contrast * p;
              c = hcl.c >= 90
                ? hcl.c
                : hcl.c + (90 - hcl.c) * p;
              hcl.c = c;
              hcl.l = l;
            } else {
              hcl = ldcolor.hcl(c);
              j = this$.cfg.pie.color === 'dark to light'
                ? i
                : (ref$ = d.paths.length - i - 1) > 0 ? ref$ : 0;
              if (hcl.l > 60 + contrast / 5) {
                if (d.paths.length === 1) {
                  p = 1;
                } else {
                  p = j / ((ref$ = d.paths.length - 1) > 1 ? ref$ : 1);
                }
                hcl.l = (hcl.l - contrast) + contrast * p;
              } else {
                p = j / ((ref$ = d.paths.length - 1) > 1 ? ref$ : 1);
                hcl.l = hcl.l + contrast * p;
              }
              hcl.l = (ref$ = (ref1$ = hcl.l) > 10 ? ref1$ : 10) < 90 ? ref$ : 90;
            }
            return ldcolor.web(hcl);
          } else {
            c = tint.get((this$.binding.area[i] || {}).key || i);
            return ldcolor.web(c);
          }
        };
      },
      destroy: function(){
        return this.tip.destroy();
      },
      parse: function(){
        var lgdata, ref$, plgdata, this$ = this;
        this.tint.reset();
        this.data.forEach(function(it){
          it._area = it.area;
          return it._id = (it.group || '-') + "/" + (it.name || it._idx);
        });
        this.valid = this.data.filter(function(it){
          return Array.isArray(it.area) && !isNaN(it.area.reduce(function(a, b){
            return a + b;
          }, 0));
        });
        this.groups = Array.from(new Set(this.valid.map(function(it){
          return it.group;
        }))).filter(function(it){
          return it != null;
        });
        this.sim = null;
        lgdata = this.groups.map(function(it){
          return {
            key: it,
            text: it
          };
        });
        lgdata.sort(function(a, b){
          if (a.key > b.key) {
            return 1;
          } else if (a.key < b.key) {
            return -1;
          } else {
            return 0;
          }
        });
        this.legend.data(lgdata);
        if (this.binding.color) {
          this.tint.extent(d3.extent(this.data.filter(function(it){
            return !isNaN(it.color);
          }).map(function(it){
            return +it.color;
          })));
          this.tint.mode(chart.utils.tint.mode.continuous);
        } else {
          this.tint.mode(chart.utils.tint.mode.ordinal);
        }
        if (((ref$ = this.cfg.pie.color) === "from palette" || ref$ === "lightness") && this.groups.length) {
          plgdata = [];
        } else {
          plgdata = this.binding.area.map(function(b, i){
            var ref$;
            return {
              key: i ? "/" + i : '',
              idx: i / ((ref$ = this$.binding.area.length - 1) > 1 ? ref$ : 1),
              text: b.name || b.key
            };
          });
        }
        if (this.cfg.pie.legend.position === 'bottom') {
          plgdata.sort(function(a, b){
            return b.idx - a.idx;
          });
        }
        return this.pieLegend.data(plgdata.length > 1
          ? plgdata
          : []);
      },
      resize: function(){
        var lgOn, d, lgBt, plgOn, plgBt, ref$, ref1$, ref2$, x$, list, selected, ret, box, pack, exts, extsDr, drs, ddr, dmid, this$ = this;
        this.fmt = chart.utils.format.from(this.cfg.label.format);
        lgOn = (d = this.legend.data()) && d.length && this.cfg.legend.enabled;
        lgBt = this.cfg.legend.position === 'bottom';
        this.root.querySelector('.pdl-layout').classList.toggle('lg-bt', lgOn && lgBt);
        this.root.querySelector('.pdl-layout').classList.toggle('lg-rt', lgOn && !lgBt);
        plgOn = (d = this.pieLegend.data()) && d.length > 1 && this.cfg.pie.legend.enabled;
        plgBt = this.cfg.pie.legend.position === 'bottom';
        this.root.querySelector('.pdl-layout').classList.toggle('lgp-bt', plgOn && plgBt);
        this.root.querySelector('.pdl-layout').classList.toggle('lgp-rt', plgOn && !plgBt);
        this.unit.text = (this.binding.area[0] || {}).unit || '';
        ref$ = this.unit;
        ref$.inner = ((ref1$ = this.cfg).unit || (ref1$.unit = {})).position === 'inner' ? this.unit.text : '';
        ref$.outer = (ref1$ = ((ref2$ = this.cfg).unit || (ref2$.unit = {})).position) === 'inner' || ref1$ === 'none'
          ? ''
          : this.unit.text ? t('unit') + ": " + this.unit.text : '';
        x$ = this.layout.getNode('unit');
        x$.style.display = !this.unit.outer ? 'none' : '';
        x$.textContent = this.unit.outer;
        this.tip.toggle(this.cfg.tip.enabled != null ? this.cfg.tip.enabled : true);
        list = [{
          key: 'root',
          root: true
        }].concat(this.groups.map(function(it){
          return {
            key: "group-" + it
          };
        }), !this.groups.length
          ? this.valid
          : this.valid.filter(function(it){
            return !this$.cfg.legend.enabled || this$.legend.isSelected(it.group);
          }));
        if (this.legend.enabled()) {
          list = list.filter(function(it){
            return !it._raw || !this$.groups.length || this$.legend.isSelected(it.group);
          });
        }
        this.legend.config(this.cfg.legend);
        this.legend.update();
        this.pieLegend.config(this.cfg.pie.legend);
        this.pieLegend.update();
        this.layout.update(false);
        if (plgOn) {
          selected = (this.binding.area || []).map(function(d, i){
            return this$.pieLegend.isSelected(i ? "/" + i : "");
          });
          list.map(function(it){
            if (Array.isArray(it._area)) {
              return it.area = it._area.map(function(d, i){
                if (selected[i]) {
                  return d;
                } else {
                  return 0;
                }
              });
            }
          });
        }
        ret = d3.hierarchy(d3.stratify().id(function(it){
          if (it._idx != null) {
            return it._idx;
          } else {
            return it.key;
          }
        }).parentId(function(it){
          var that;
          if (it.root) {
            return '';
          } else if ((that = it.group) != null) {
            return "group-" + that;
          } else {
            return 'root';
          }
        })(list)).sum(function(it){
          return (it.data.area || []).reduce(function(a, b){
            return a + b;
          }, 0);
        }).sort(function(a, b){
          return b.value - a.value;
        });
        box = this.vbox = this.layout.getBox('view');
        pack = d3.pack().size([box.width, box.height])(ret);
        this.parsed = ret.leaves().map(function(d){
          var ddata, od, p, x, y, sum, da, i$, to$, i;
          d._raw = d.data.data._raw;
          ddata = d.data.data;
          od = this$.parsed ? (p = this$.parsed.filter(function(p){
            return p._id === ddata._id;
          })[0], p ? p : d) : d;
          x = d.x, y = d.y;
          d.radius = Math.pow(ddata.area, 0.5);
          d.x = x;
          d.y = y;
          d._idx = ddata._idx;
          d._id = ddata._id;
          d.name = ddata.name;
          d.color = ddata.color;
          d.group = ddata.group;
          d.area = ddata.area;
          if (od._x) {
            d._x = od._x;
          } else if (!d._x) {
            d._x = d.x;
          }
          if (od._y) {
            d._y = od._y;
          } else if (!d._y) {
            d._y = d.y;
          }
          d.paths = (d.area || []).map(function(e, i){
            var ref$, ref1$;
            return ref1$ = {
              name: d.name,
              group: d.group,
              area: e,
              idx: i
            }, ref1$.old = (ref$ = (od.paths || [])[i] || {}).old, ref1$.cur = ref$.cur, ref1$;
          });
          sum = 0;
          da = d.paths.length > 1 ? (d.paths[0].area - d.paths[1].area) / 4 : 0;
          for (i$ = 0, to$ = d.paths.length; i$ < to$; ++i$) {
            i = i$;
            d.paths[i].s = sum - da;
            d.paths[i].e = (sum += d.paths[i].area) - da;
          }
          d.rate = da;
          d.total = sum || 1;
          return d;
        }).filter(function(it){
          return it.area != null && !isNaN(it.x) && !isNaN(it.y);
        });
        exts = {};
        this.parsed.map(function(d, i){
          var ref$, ref1$, key$, ref2$;
          (ref$ = exts[key$ = d.group] || (exts[key$] = {})).x1 <= (ref1$ = d.x) || (ref$.x1 = ref1$);
          (ref$ = exts[key$ = d.group] || (exts[key$] = {})).x2 >= (ref1$ = d.x) || (ref$.x2 = ref1$);
          (ref$ = exts[key$ = d.group] || (exts[key$] = {})).y1 <= (ref1$ = d.y) || (ref$.y1 = ref1$);
          return (ref2$ = (ref$ = exts[key$ = d.group] || (exts[key$] = {})).y2) >= (ref1$ = d.y)
            ? ref2$
            : ref$.y2 = ref1$;
        });
        extsDr = {};
        drs = this.parsed.filter(function(d){
          return d.paths.length > 1;
        }).map(function(d){
          return d._dr = (d.paths[0].area - d.paths[1].area) / (d.paths[0].area + d.paths[1].area || 1);
        });
        extsDr.x1 = Math.min.apply(Math, drs);
        extsDr.x2 = Math.max.apply(Math, drs);
        ddr = extsDr.x2 - extsDr.x1 || 1;
        dmid = (extsDr.x2 + extsDr.x1) / 2;
        this.parsed.map(function(d, i){
          var dr, e;
          if (d.paths.length <= 1) {
            return;
          }
          dr = ((d._dr - dmid) * 2) / ddr;
          e = exts[d.group];
          if (this$.cfg.pie.order === 'group') {
            return d.x = dr * (e.x2 - e.x1) * 0.5 + (e.x2 + e.x1) / 2, d;
          } else {
            return d.x = dr * box.width * 0.4 + box.width * 0.5, d;
          }
        });
        this.sim = null;
        return this.start();
      },
      render: function(){
        var fmt, _color, cfg, binding, tint, layout, unit, box, rate, interpolateArc, x$, y$, that, this$ = this;
        fmt = this.fmt, _color = this._color, cfg = this.cfg, binding = this.binding, tint = this.tint, layout = this.layout, unit = this.unit;
        box = this.vbox;
        this.g.unit.call(function(){
          var node, ret;
          node = layout.getNode('unit');
          ret = wrapSvgText({
            node: node,
            useRange: true
          });
          this$.g.unit.node().textContent = '';
          return this$.g.unit.node().appendChild(ret);
        });
        this.rate = rate = 0.85 * Math.PI / (2 * Math.sqrt(3)) * Math.sqrt(box.width * box.height / this.parsed.map(function(it){
          return Math.PI * Math.pow(it.r, 2);
        }).reduce(function(a, b){
          return a + b;
        }, 0));
        this.parsed.map(function(d, i){
          var ref$;
          return d.rr = (ref$ = d.r * this$.rate) > 2 ? ref$ : 2;
        });
        this.parsed.map(function(d, i){
          return d.paths.map(function(p, j){
            var s, e;
            s = p.s * 2 * Math.PI / d.total;
            e = p.e * 2 * Math.PI / d.total;
            p.old = p.cur || {
              r: d.rr,
              s: s,
              e: e
            };
            return p.cur = {
              r: d.rr,
              s: s,
              e: e
            };
          });
        });
        tint.set(this.cfg.palette);
        interpolateArc = function(a1, a2, i){
          return function(t){
            var ref$, s, e;
            this$.arc.innerRadius(0).outerRadius((a2.r - a1.r) * t + a1.r);
            ref$ = ['s', 'e'].map(function(i){
              return (a2[i] - a1[i]) * t + a1[i];
            }), s = ref$[0], e = ref$[1];
            this$.arc.startAngle(s).endAngle(e);
            return this$.arc();
          };
        };
        x$ = this.g.view.selectAll('g.bubble').data(this.parsed, function(it){
          return it._id;
        });
        x$.exit().each(function(d, i){
          d._removing = true;
          return d.paths.map(function(it){
            it.old.r = it.cur.r;
            return it.cur.r = 0;
          });
        });
        x$.exit().transition().delay(150).on('end', function(d){
          if (d._removing) {
            return d3.select(this).remove();
          }
        });
        x$.enter().append('g').attr('class', 'bubble').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        }).each(function(d){
          return d._removing = false;
        });
        this.g.view.selectAll('g.bubble').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        }).each(function(_d, i){
          var n, x$;
          n = d3.select(this);
          x$ = n.selectAll('path.data').data(_d.paths, function(d, i){
            return i;
          });
          x$.exit().remove();
          x$.enter().append('path').attr('class', 'data').attr('opacity', function(d, i){
            return 0;
          }).attr('fill', function(d, i){
            return _color(_d, i);
          });
          return n.selectAll('path.data').transition().duration(350).attrTween('d', function(d, i){
            return interpolateArc(d.old, d.cur, i);
          }).attr('fill', function(d, i){
            return _color(_d, i);
          }).attr('opacity', 1);
        });
        y$ = this.g.view.selectAll('g.label').data(this.parsed, function(it){
          return it._id;
        });
        y$.exit().remove();
        y$.enter().append('g').attr('class', 'label data').attr('transform', function(d, i){
          return "translate(" + d.x + "," + d.y + ")";
        }).attr('opacity', 0).attr('font-size', function(){
          return cfg.font.size;
        }).style('pointer-events', 'none').style('cursor', 'pointer').each(function(d, i){
          /* use group + wrap-svg-text below */
          var this$ = this;
          return [0, 1].map(function(){
            return d3.select(this$).append('g').attr('class', 'inner');
          }).map(function(it){
            return it.attr('opacity', 0).style('pointer-event', 'none');
          });
        });
        this.g.view.selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        }).attr('class', "label " + ((that = cfg.label.font.family) ? that.className : '')).each(function(d, i){
          var t, fs;
          t = function(e, i){
            var sum, ret;
            if (i !== 0) {
              return d.name || '';
            }
            sum = d.area.reduce(function(a, b){
              return a + b;
            }, 0);
            if (!(ret = fmt(sum))) {
              return '';
            } else {
              return ret + "" + unit.inner;
            }
          };
          fs = function(e, i, r){
            var text, s, ref$;
            r == null && (r = 1);
            text = t(e, i);
            s = !i
              ? 1.1
              : 0.9 * ((ref$ = 1 - 0.1 * (text.length / 5)) > 0.7 ? ref$ : 0.7);
            return s * r;
          };
          /*
          d3.select(@).selectAll \text.inner
            .text t
            .attr \dy, (e,i) ->
              if cfg.label.enabled != \both or !binding.name => return '.28em'
              if i == 0 => '-.28em' else '.88em'
          */
          d3.select(this).selectAll('g.inner').each(function(e, i){
            var i$, j, ret;
            for (i$ = this.childNodes.length - 1; i$ >= 0; --i$) {
              j = i$;
              this.removeChild(this.childNodes[j]);
            }
            ret = wrapSvgText({
              text: t(d, i),
              style: {
                width: (cfg.label.wrap
                  ? d.rr * 2
                  : box.width) + "px",
                lineHeight: fs(d, i, 1.2)
              }
            });
            ret.style.transform = "translate(0," + i * (0.3 + 1.1 / fs(d, i, 1)) + "em)";
            Array.from(ret.querySelectorAll("text")).map(function(it){
              return it.setAttribute('text-anchor', 'middle');
            });
            return this.appendChild(ret);
          });
          return d3.select(this).selectAll('.inner').attr('font-size', function(e, i){
            return fs(e, i, 1) + "em";
          }).transition().duration(350).attr('opacity', function(e, i){
            var c;
            c = cfg.label.enabled;
            if (c === 'both') {
              return 1;
            }
            if (c === 'name') {
              return i === 0 ? 0 : 1;
            }
            if (c === 'value') {
              return i === 1 ? 0 : 1;
            }
            return 1;
          }).attr('fill', function(){
            var hcl;
            hcl = ldcolor.hcl(_color(d, 0));
            if (hcl.l < 70) {
              return '#fff';
            } else {
              return '#000';
            }
          });
        });
        this.g.view.selectAll('g.label').transition().duration(150).attr('font-size', cfg.label.font.size);
        if (this.h) {
          clearTimeout(this.h);
        }
        this.h = setTimeout(function(){
          this$.h = null;
          return this$.g.view.selectAll('g.label').each(function(d, i){
            var box, ref$, w, h;
            d._box = box = this.getBoundingClientRect();
            ref$ = [box.width, box.height], w = ref$[0], h = ref$[1];
            return d3.select(this).selectAll('.inner').attr('transform', function(){
              return "translate(0," + -h / 2 + ")";
            });
          }).transition().duration(150).attr('opacity', function(d, i){
            var box, ref$, w, h, s;
            box = d._box;
            ref$ = [box.width, box.height], w = ref$[0], h = ref$[1];
            s = 2 * d.rr * ((cfg.label.overflow || 0) + 1);
            if (s < w || 2 * d.rr < h) {
              return 0;
            } else {
              return 1;
            }
          });
        }, 150);
        this.legend.render();
        return this.pieLegend.render();
      },
      tick: function(){
        var pad, box, kickoff, fc, this$ = this;
        pad = this.cfg.pad || 5;
        box = this.vbox;
        if (!this.sim) {
          kickoff = true;
          this.fc = fc = d3.forceCollide().strength(0.5).iterations(20).radius(function(it){
            return this$.rate * it.r;
          });
          this.fg = d3.forceCenter().strength(0.5);
          this.fb = forceBoundary(function(it){
            return it.rr + pad;
          }, function(it){
            return it.rr + pad;
          }, function(it){
            return box.width - it.rr - pad;
          }, function(it){
            return box.height - it.rr - pad;
          }).strength(0.5);
          this.sim = d3.forceSimulation().force('b', this.fb).force('collide', this.fc);
          this.sim.stop();
          this.sim.alpha(0.9);
        }
        this.fg.x(box.width / 2);
        this.fg.y(box.height / 2);
        this.sim.nodes(this.parsed);
        this.sim.tick(kickoff ? 10 : 1);
        this.parsed.map(function(it){
          it._x = it._x + (it.x - it._x) * 0.1;
          return it._y = it._y + (it.y - it._y) * 0.1;
        });
        this.g.view.selectAll('g.bubble').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        });
        return this.g.view.selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        });
      }
    };
  };
}).call(this);
