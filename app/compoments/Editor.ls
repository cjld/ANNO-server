require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent, MyCheckbox, MyDropdown} = common

require! {
    \./TypeDropdown
    \./TypePopup
    \./Help
    \../models/Object : object
    \mongoose
    \../history : myhistory
    \../worker
    \./GoogleMap
}

inte = (a,b) -> parseInt(a) == parseInt(b)
deep-copy = (a) -> JSON.parse(JSON.stringify(a))

module.exports = class Editor extends React.Component implements TimerMixin
    ->
        super ...
        #store.connect-to-component this, [\currentItem]
        @state = {} # currentItem:store.get-state!.currentItem
        @modeOption = [
            *   value:"pan", text:``<div><i className="move icon"></i>Pan</div>``
            *   value:"spotting", text:``<div><i className="crosshairs icon"></i>Instance Spotting</div>``
            *   value:"box", text:``<div><i className="square outline icon"></i>Bounding box</div>``
            *   value:"segment", text:``<div><i className="cube icon"></i>Instance Segmentation</div>``
            *   value:"ps", text: ``<div><i className="wizard icon"></i>Quick selection</div>``
            *   value:"paint", text: ``<div><i className="paint brush icon"></i>Free Paint</div>``
        ]
        @state.cMark = \0
        @state.smooth = false
        @state.simplify = false
        @state.showMark = true
        @state.autobox = false
        @state.hideImage = false
        @state.hideAnnotation = false
        @state.editMode = "ps"
        @state.listState = "all"
        @state.autosave = true
        @state.saveStatus = "saved"
        @state.autosave-interval = 5000
        @state.paintState = "foreground" # background foreground hair
        @state.default-brush-size = 15.0
        @state.paint-brush-size = @state.default-brush-size
        @state.imageLoaded = false
        @state.time-evaluate = false
        @state.simplifyTolerance = 1
        @state.propagate-back = undefined
        @state.propagating = false
        @has-googlemap = false
        @map-scaling = 100000000
        store.connect-to-component this, [\typeMap, \config]

    autosave: ->
        if @state.autosave and @state.saveStatus == \changed
            @save!
            console.log "autosave"
        @set-timeout @autosave, @state.autosave-interval

    contour-anime: ->
        if @contour-path
            if not @anime-dashOffset
                @anime-dashOffset = 0
            @anime-dashOffset += 1
            @contour-path.dashOffset = @anime-dashOffset
            paper.view.draw!
        @set-timeout @contour-anime, 100

    shouldComponentUpdate: (next-props, next-state) ->
        if next-state.config !== @state.config
            @reload-config next-state.config
        if next-state.typeMap !== @state.typeMap
            @create-typeimage-symbol next-state.typeMap
        return true

    create-typeimage-symbol: (typeMap)->
        text-style =
            fillColor: 'red'
            strokeColor: 'white'
            strokeWidth: 1
            fontWeight: 'bold'
            fontSize: '20px'
        fixit = []
        @typeimages = {
            find: ->
                if this[it] then return that
                pp = this[it.split('-')[0]]
                if not pp then return undefined
                ps = pp.place [0,-30]
                text = new paper.PointText
                text.style = text-style
                ss = it.split('-')
                if ss.length == 2
                    text.content = ss[1]
                else
                    text.content = ss[1] + '-' + ss[2]
                g = new paper.Group [text, ps]
                g.remove!
                fixit.push it
                return this[it] = new paper.Symbol g

            set: (a,b) -> this[a.split('-')[0]] = b
        }
        pending = 0
        for k,v of typeMap
            text = new paper.PointText
            text.style = text-style
            text.content = k
            g = new paper.Group [text, new paper.Path.Rectangle [0,23,0,0]]
            @typeimages.set(k, new paper.Symbol g)
            g.remove!
            if v.src
                pending++
                raster = new paper.Raster v.src
                raster.visible = false
                func = (raster, k) ->
                    raster.visible = true
                    raster.fit-bounds new paper.Rectangle(0,0,35,35)
                    g = new paper.Group [raster, new paper.Path.Rectangle [0,70,0,0]]
                    @typeimages.set(k, new paper.Symbol g)
                    g.remove!
                    pending--
                    if pending == 0
                        for it in fixit
                            @typeimages[it] = undefined
                        @rebuild!
                raster.on-load = func.bind this, raster, k

    create-cross-symbol: ->
        w = 7
        line = new paper.Path [
            new paper.Point -w,0
            new paper.Point w,0
        ]
        line2 = new paper.Path [
            new paper.Point 0,-w
            new paper.Point 0,w
        ]
        linegroup = new paper.Group [line,line2]
        linegroup.strokeColor = \yellow
        linegroup.strokeWidth = 3
        raster = linegroup.rasterize!
        @cross-symbol = raster
        raster.remove!
        linegroup.remove!
        #@test-symbol @cross-symbol

    test-symbol: (symbol) ->
        for i til 100
            instance = symbol.place!
            instance.position = paper.Point.random!.multiply paper.view.size
            instance.rotate Math.random! * 360
            instance.scale 0.25 + Math.random! * 1.75


    set-changed: ->
        if @state.saveStatus != \changed
            @set-state saveStatus:\changed

    check-changed: ->
        if @state.currentItem.marks !== @state.marks
            @set-changed!

    update-backgroud: ->
        s = @layer.scaling
        t = @layer.matrix.translation
        if @has-googlemap
            @update-googlemap!
        else
            @background.style.width = (@origin-width * s.x) + 'px'
            @background.style.height = (@origin-height * s.y) + 'px'
            @background.style.left = t.x + 'px'
            @background.style.top = t.y + 'px'

    update-googlemap: ->
        s = @layer.scaling
        t = @layer.matrix.translation
        s1 = paper.view.size
        xx = (t.x - s1.width / 2) / s.x
        yy = (t.y - s1.height / 2) / s.y
        #console.log s,t, @googleMap.map.get-center!.toString!
        #bounds = @googleMap.map.get-bounds!
        #console.log t.x/s.x, t.y/s.y, xx/s.x, yy/s.y, bounds.toString!
        @googleMap.map.set-center new google.maps.LatLng lng:xx / @map-scaling, lat:yy / @map-scaling
        zoom = Math.round(@init-zoom + Math.log2(-s.x/@init-scale[0]))
        @googleMap.map.set-zoom zoom

        bounds = @googleMap.map.get-bounds!
        s1 = paper.view.size
        bwidth = bounds.getNorthEast!.lng! - bounds.getSouthWest!.lng!
        if bwidth<=0 then bwidth += 360
        bheight = bounds.getNorthEast!.lat! - bounds.getSouthWest!.lat!
        scale = [s1.width / bwidth, -s1.height / bheight]
        #console.log scale[1] / scale[0], s.y / s.x
        #console.log scale, s
        @layer.scaling.y =  @layer.scaling.x * scale[1] / scale[0]



    calc-bbox: ->
        # auto bbox
        autobox = false
        updatebox = (obj)->
            if obj.bounds.area == 0 then return
            if autobox
                autobox := autobox.unite obj.bounds
            else
                autobox := obj.bounds

        mark = @state.marks[@state.cMark]
        if mark
            if mark.contours
                updatebox @contour-path
            if mark.paints
                updatebox @paints.foreground
                updatebox @paints.background
            updatebox @current-segments-group

        if @state.autobox
            if autobox == false
                if mark?bbox
                    if @current-box
                        @current-box.remove!
                        @current-box = undefined
                    if @current-type
                        @current-type.remove!
                        @current-type = undefined
                    mark.bbox = undefined
                    @set-changed!
                return
            newbox = {p1:autobox.topLeft{x,y}, p2:autobox.bottomRight{x,y}}
            if newbox !== mark.bbox
                # FIXME: duplicate code
                mark.bbox = newbox
                if @current-box
                    @current-box.remove!
                #paper.project.current-style = @box-style
                p1 = new paper.Point newbox.p1
                p2 = new paper.Point newbox.p2
                @current-box = new paper.Path.Rectangle p1, p2
                @current-box.selected = true
                @current-box.closed = true
                @current-box.mydata = {i:@state.cMark}
                @current-box <<< @box-style
                @current-box.strokeWidth = 4

                if @current-type
                    @current-type.position = @current-box.bounds.topLeft.add [@current-box.bounds.width / 2, 0]
                @box-group.addChild @current-box
                #paper.project.current-style = {}
                @set-changed!

    path-convert: (contours) ->
        return contours.map ~>
            if it.length
                prev = it[it.length-1]
            if @state.smooth
                seg = for xyd in it
                    d = if xyd.d!=undefined then xyd.d else 0.5
                    res = if prev.x == xyd.x
                        if prev.y < xyd.y
                            [prev.x-0.5+d, prev.y+0.5]
                        else
                            [prev.x-0.5+d, xyd.y+0.5]
                    else
                        if prev.x < xyd.x
                            [prev.x+0.5, prev.y-0.5+d]
                        else
                            [xyd.x+0.5, prev.y-0.5+d]
                    prev = xyd
                    res
                path = new paper.Path do
                    segments: seg
                    closed: true
                #path.smooth!
                return path
            else
                seg = it.map ~> [it.x, it.y]
                return new paper.Path do
                    segments: seg
                    closed: true

    path-simplify: (cp) ->
        for c,i in cp.children
            xy = for seg in c.segments
                seg.point{x,y}
            new-xy = simplify xy, @state.simplifyTolerance, true
            cp.children[i] = new paper.Path new-xy
    rebuild: ->
        @activate-canvas!
        if @props.viewonly and not @props.markonly
            @state.cMark = -1
        if @state.hideImage
            @background?style.opacity = 0
        else
            @background?style.opacity = 1
        if @state.hideAnnotation
            @canvas.style.opacity = 0
        else
            @canvas.style.opacity = 1
        @check-changed!
        if @rebuild-group
            @rebuild-group.remove!
        paper.project.current-style = {}
        @rebuild-group = new paper.Group
        @offset-group.addChild @rebuild-group
        @rebuild-group.apply-matrix = false
        if @has-googlemap
            wfactor = [-1 / @layer.scaling.x, -1 / @layer.scaling.y]
        else
            wfactor = 1 / @layer.scaling.x
        segm-op = if @state.editMode==\pan then 0.5 else 0.5
        spot-op = if @state.editMode==\pan then 0.8 else 0.8

        @boxtype-group = new paper.Group
        @rebuild-group.addChild @boxtype-group
        # draw box
        @box-style =
            fillColor : new paper.Color 0,0,0,0
            strokeColor : \red
            strokeWidth : 2
            strokeScaling: false
        @box-group = new paper.Group
        @rebuild-group.addChild @box-group
        @current-box = undefined
        @current-type = undefined
        if @state.showMark
            for i,mark of @state.marks
                unless mark.bbox? then continue
                p1 = new paper.Point mark.bbox.p1
                p2 = new paper.Point mark.bbox.p2
                path = new paper.Path.Rectangle p1, p2
                path <<< @box-style
                #paper.project.current-style = @box-style
                @box-group.addChild path
                if @state.showMark and mark.type and @typeimages.find(mark.type)
                    #paper.project.current-style = {}
                    type-symbol = @typeimages.find(mark.type)
                    symbol = type-symbol.place path.bounds.topLeft.add [path.bounds.width / 2, 0]
                    # strokeScaling affact symbol, dont know why, TODO
                    symbol.scale wfactor
                    @boxtype-group.addChild symbol
                    if inte(i,@state.cMark)
                        @current-type = symbol

                path.mydata = {i}
                if inte(i,@state.cMark)
                    @current-box = path
                    path.strokeWidth = 4
                    path.selected = true
                path.closed = true

        # draw paints
        paper.project.current-style = {}
        @paints = {}
        @paints.foreground = new paper.CompoundPath
            ..fillColor = \green
        @paints.background = new paper.CompoundPath
            ..fillColor = \red
        @paints.alpha = new paper.CompoundPath
            ..fillColor = \yellow
        @strokeStyle =
            strokeWidth: 0
            closed: true
            #dont use opacity, use alpha instead
        for k,v of @paints
            v <<< @strokeStyle
            v.fillColor.alpha = 0.7
        @rebuild-group.addChildren [ v for k,v of @paints ]
        paint-json = @state.marks[@state.cMark]?paints
        if paint-json
            for k,v of @paints
                v.importJSON paint-json[k]

        # draw contours
        mark = @state.marks[@state.cMark]
        contours = mark?contours
        if contours
            color = @state.typeMap.findType(mark.type)?.color
            @gen-contours contours, color

        #draw other contours
        for mark in @state.marks
            if mark == @state.marks[@state.cMark]
                continue
            contours = mark?contours
            if contours
                color = @state.typeMap.findType(mark.type)?.color
                @other-contours = new paper.Group
                @rebuild-group.addChild @other-contours

                paths = @path-convert contours

                fillColor = new paper.Color color
                fillColor.alpha = if @state.hideImage then 1 else 0.5
                path = new paper.CompoundPath do
                    children: paths
                    fillColor: fillColor
                    fillRule: \evenodd
                    strokeColor: \black
                    strokeWidth: 2
                    dashArray: [10, 4]
                    strokeScaling: false

                if @state.simplify
                    @path-simplify path
                @other-contours.addChild path

        paper.project.current-style =
            strokeWidth : 2
            strokeScaling: false

        # draw segments
        @segments-group = new paper.Group
        @rebuild-group.addChild @segments-group
        @current-segments-group = new paper.Group
        @segments-group.addChild @current-segments-group
        for i,mark of @state.marks
            for j,segment of mark.segments
                path = new paper.Path
                alpha = segm-op * if inte(i,@state.cMark) then 1 else 0.5
                path.strokeColor = new paper.Color \black
                path.fillColor = new paper.Color \red
                    ..alpha = alpha
                path.mydata = {i,j}
                if inte(i,@state.cMark) and
                   inte(j,mark.active-segment.j)
                    path.selected = true
                path.closed = true
                for k,p of segment
                    pt = new paper.Point p
                    path.add pt
                if @state.smooth then path.smooth!
                if inte(i,@state.cMark)
                    @current-segments-group.addChild path
                else
                    @segments-group.addChild path

        @calc-bbox!

        # draw spots
        paper.project.current-style = {}
        @spots-group = new paper.Group
        @rebuild-group.addChild @spots-group
        for i,mark of @state.marks
            type-symbol = undefined
            rtype = mark.type.split('-')[0]
            if @state.showMark and mark.type and @typeimages.find(mark.type)
                type-symbol = @typeimages.find(mark.type)
            for j,spot of mark.spots
                instance = @cross-symbol.clone!
                instance.position = spot
                instance.scale wfactor
                instance.opacity = spot-op * if inte(@state.cMark,i) then 1 else 0.5
                @spots-group.addChild instance
                instance.mydata = {i,j}
                if type-symbol
                    if @state.typeMap[rtype]?spotsType
                        type-symbol = @typeimages.find(mark.type + "-" + that[j])
                    instance = type-symbol.place spot
                    instance.scale wfactor
                    @spots-group.addChild instance
            if @state.typeMap[rtype]?spotsEdge
                for [s,t,c] in that
                    c ?= \red
                    s = mark.spots[s]
                    t = mark.spots[t]
                    if !s or !t then continue
                    path = new paper.Path new paper.Point(s), new paper.Point(t)
                    path.strokeColor = c
                    path.strokeScaling = false
                    @rebuild-group.addChild path

        if @state.latlngBounds
            p1 = new paper.Point [that.sw.lng, that.sw.lat]
            p2 = new paper.Point [that.ne.lng, that.ne.lat]
            path = new paper.Path.Rectangle p1, p2
            path <<< @box-style
            #paper.project.current-style = @box-style
            @rebuild-group.addChild path

        @boxtype-group.bring-to-front!
        paper.view.draw!

    componentWillReceiveProps: (next-props) ->
        if @props.currentItem._id != next-props.currentItem._id
            @state.currentItem = next-props.currentItem
            @parse-mark!
            @load-session!

    parse-mark: ->
        @state.marks = deep-copy @state.currentItem.marks
        if @state.marks == undefined or @state.marks === []
            @state.marks = @new-mark!
            @state.cMark = 0
        if @contour-override
            @state.marks[0].contours = @contour-override
            @contour-override = undefined

    componentWillMount: ->
        @state.currentItem = @props.currentItem
        @parse-mark!

    get-current-mark: ->
        c = @state.cMark
        if c? then mark = @state.marks[c]
        unless mark then return
        return mark

    gen-contours: (contours, color) ->
        if @contour-path
            @contour-path.remove!
            @contour-path = null

        paths = @path-convert contours

        fillColor = new paper.Color color
        if not @state.hideImage
            fillColor.alpha = 0.5
        path = new paper.CompoundPath do
            children: paths
            fillColor: fillColor
            fillRule: \evenodd
            strokeColor: \black
            strokeWidth: 2
            dashArray: [10, 4]
            strokeScaling: false
        @rebuild-group.addChild path
        @contour-path = path
        if @state.simplify
            @path-simplify @contour-path

    send-cmd: (cmd, data) ->
        if @props.viewonly then return
        @ts ?= 0
        @cts ?= -1
        @ts += 1
        data.ts = @ts
        if @worker
            @worker.get-cmd cmd, data
        else
            @socket.emit cmd, data
        if @state.time-evaluate
            console.time @ts

    # drop command before
    drop-cmd: ->
        @cts = @ts

    receive-cmd: (data) ~>
        if data.pcmd == \open-session
            toastr.success "Session load success, total seg: #{data.return.regCount}"
        else if data.pcmd == \load-region
            toastr.success "Region load success, total seg selected: #{data.return.segCount}"
        else if data.pcmd == \propagate
            @set-state propagating: false
            @contour-override = data.return.contours
            myhistory.push "/i/"+@propagate-to._id
            # TODO

        if data.ts and data.ts <= @cts
            return
        if @state.time-evaluate
            console.timeEnd data.ts

        mark = @get-current-mark!
        unless mark then return

        if data.pcmd == \paint and data.contours?
            color = @state.typeMap.findType(mark.type)?.color
            mark.contours = data.contours
            @check-changed!
            @gen-contours data.contours, color
            @calc-bbox!
            #paper.view.draw!


    check-tool-switch: (e) ~>
        if e.key >= '1' and e.key <= '9'
            v = -1 + parse-int e.key
            v = @modeOption[v]?.value
            if v then
                @set-state editMode:v

    getBase64Image: (img) ->
        # Create an empty canvas element
        canvas = document.createElement("canvas")
        canvas.width = img.width
        canvas.height = img.height

        # Copy the image contents to the canvas
        ctx = canvas.getContext("2d")
        ctx.drawImage(img, 0, 0)

        # Get the data-URL formatted image
        # Firefox supports PNG and JPEG. You could check img.src to
        # guess the original format, but be aware the using "image/jpg"
        # will re-encode the image.
        dataURL = canvas.toDataURL("image/png")

        return dataURL.replace(/^data:image\/(png|jpg);base64,/, "")

    load-session: ~>
        @state.paint-brush-size = @state.default-brush-size

        if not @state.currentItem.latlngBounds
            if not @props.viewonly
                @drop-cmd!
                if not @worker
                    @send-cmd \open-session, id:@state.currentItem._id
                @on-current-mark-change!

        @layer.matrix.reset!
        @offset-group.matrix.reset!

        imgUrl = @get-img-url!
        @background.style.cssText = ""

        @set-state imageLoaded: false

        #a = new google.maps.LatLng({lat:-48.950725273448164, lng:103.49028906249998})
        #b = new google.maps.LatLng({lat:3.8213823008568584, lng:158.59771093749998})
#37.612024, -122.394866
#37.620370, -122.380060
        if @state.currentItem.latlngBounds
            bounds = JSON.parse that
            @has-googlemap = true
            a = new google.maps.LatLng(bounds.sw)
            b = new google.maps.LatLng(bounds.ne)
            @origin-mapbounds = new google.maps.LatLngBounds(a, b)
            @googleMap.map.set-center a
            @googleMap.map.fit-bounds @origin-mapbounds
            is-load = false
            bounds.sw.lat *= @map-scaling
            bounds.sw.lng *= @map-scaling
            bounds.ne.lat *= @map-scaling
            bounds.ne.lng *= @map-scaling
            @set-state latlngBounds: bounds
            #google.maps.event.removeListener @googleMap.map
            google.maps.event.addListenerOnce @googleMap.map, 'idle', ~>
                if is-load then return
                is-load = true
                bounds = @googleMap.map.get-bounds!
                @set-state imageLoaded: true
                console.log "google map loaded. ", bounds
                s1 = paper.view.size
                bwidth = bounds.getNorthEast!.lng! - bounds.getSouthWest!.lng!
                if bwidth<=0 then bwidth += 360
                bheight = bounds.getNorthEast!.lat! - bounds.getSouthWest!.lat!
                bwidth *= @map-scaling
                bheight *= @map-scaling
                scale = [s1.width / bwidth, -s1.height / bheight]
                @init-scale = scale
                @init-zoom = @googleMap.map.get-zoom!

                @state.paint-brush-size /= scale[0]
                @cursor.scaling =  @state.paint-brush-size / @state.default-brush-size
                @scale scale, [0,0]
                @layer.translate [-bounds.getSouthWest!.lng! * @map-scaling * scale[0], -bounds.getNorthEast!.lat! * @map-scaling * scale[1]]
        else
            @set-state latlngBounds: null
            @background.src = imgUrl
            @has-googlemap = false
            @background.onload = ~>
                console.log "The image has loaded.", imgUrl
                actions.prefetchImage @state.currentItem
                if @worker
                    data = @getBase64Image @background
                    console.log "base64Length #{data.length}"
                    @worker.open-base64 data
                @origin-width = @background.width
                @origin-height = @background.height
                if @state.currentItem.shape !== [@origin-width, @origin-height]
                    @state.currentItem.shape = [@origin-width, @origin-height]
                    @set-changed!
                #@background.position = paper.view.center
                #@offset-group.translate @background.bounds.point
                s1 = paper.view.size
                s2 = @background.{width, height}
                ss = Math.min s1.width/s2.width, s1.height/s2.height
                @state.paint-brush-size /= ss
                @cursor.scaling =  @state.paint-brush-size / @state.default-brush-size
                @scale ss, [0,0]
                #@layer.translate @layer.matrix.translation
                @update-backgroud!
                @set-state imageLoaded: true
                #@forceUpdate!

    scale: (factor, center)->
        @layer.scale factor, center
        if typeof(factor) == 'number'
            rfactor = 1.0/factor
        else
            rfactor = factor.map -> -1.0/it
        for ins in @spots-group.children
            ins.scale rfactor
        for ins in @boxtype-group.children
            ins.scale rfactor

    reload-config: ->
        config = @state.config
        if it then config = it
        if config
            @send-cmd "config", {}<<<that
        if config.autoType
            if @state.marks[0].type==""
                @state.marks[0].type = config.types[0].types[0].title
        for k,v of config
            if (@state.has-own-property k) and @state[k] != v
                @set-state {"#{k}":v}


    componentDidMount: ->
        if not @props.viewonly
            @autosave!
            @contour-anime!

            actions.connect-socket!
            @socket = socket

            if inElectron
                @worker = new worker
                @worker.spawn!
                @worker.on-data = (msg, data) ~>
                    if msg == \ok
                        @receive-cmd data
                    else
                        toastr.error "Worker error: "+data
            else
                @socket.emit \spawn
                @socket.on \ok, @receive-cmd
                @socket.on \s-error, -> toastr.error "Worker error: "+it



            $ \body .css \overflow, \hidden

            @helpModal = $ \#helpModal
                ..modal detachable:false
            @propagateModal = $ \#propagateModal
                ..modal detachable:false

        @reload-config!
        jq = $ ReactDOM.findDOMNode this
        paper.setup(jq.find \canvas .0)
        @canvas = jq.find \canvas .0
        @background = jq.find '.myCanvas img' .0
        @project = paper.project
        @layer = paper.project.activeLayer
            ..apply-matrix = false
        @offset-group = new paper.Group
            ..apply-matrix = false
        @load-session!


        @create-cross-symbol!
        @create-typeimage-symbol @state.typeMap
        #@rebuild!
        @spotting-tool = new paper.Tool

        @spotting-tool.on-mouse-down = (e) ~>
            if @check-bbox-click e then return
            tmatrix = @spots-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                tolerance: 5
            hit-result = @spots-group.hit-test point, hitOptions
            @drag-func = undefined
            if hit-result?item?mydata
                {i,j} = that
                if @state.cMark != i
                    @switchCurrentMark i
                if e.modifiers.shift
                    @state.marks[i].spots.splice j,1
                    @rebuild!
                    return @forceUpdate!
                @drag-func = (i,j,e) -->
                    @state.marks[i].spots[j]{x,y} = e.point.transform tmatrix
                    @rebuild!
                @drag-func = @drag-func i,j
            else
                if @state.cMark? and @state.marks[@state.cMark]
                    type = @state.marks[@state.cMark].type
                    if type
                        type = @state.typeMap.findType(type)?spotsType
                        if type and type.length <= @state.marks[@state.cMark].spots.length
                            toastr.error "More spots are not allowed."
                            return
                    @state.marks[@state.cMark].spots.push point{x,y}
                    @rebuild!
                    return @forceUpdate!

        @spotting-tool.on-mouse-up = (e) ~>
            @up-func? e
            #console.log \on-mouse-up, e
        @spotting-tool.on-mouse-drag = (e) ~>
            @drag-func? e
        @spotting-tool.on-key-down = (e) ~>
            @pan-tool.on-key-down e
        @spotting-tool.on-mouse-move = (e) ~>
            @pan-tool.on-mouse-move e
            tmatrix = @spots-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                tolerance: 5
            hit-result = @spots-group.hit-test point, hitOptions
            if hit-result?item?mydata
                {i,j} = that
                if e.modifiers.shift
                    @canvas.style.cursor = "no-drop"
                    return
                @canvas.style.cursor = "move"
            else
                @canvas.style.cursor = "crosshair"


        @segment-tool = new paper.Tool

        @segment-tool.on-mouse-down = (e) ~>
            if @check-bbox-click e then return
            @drag-func = undefined
            c = @state.cMark
            if c? then mark = @state.marks[c]
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: 5
            hit-result = @segments-group.hit-test point, hitOptions
            console.log hit-result
            if e.modifiers.control or mark.segments.length == 0
                data = mark.segments
                data.push [point{x,y}]
                mark.active-segment = {i:c,j:(data.length-1).to-string!}
                @forceUpdate!
            else
                #if hit-result?item?mydata?i != @state.cMark
                #    @set-state cMark:i
                if hit-result?item?mydata
                    {i,j} = that
                    if inte i,@state.cMark
                        mark = @state.marks[i]
                        poly = mark.segments[j]
                        if hit-result.segment
                            k = hit-result.item.segments.index-of that
                            point = poly[k]
                        if hit-result.location
                            k = hit-result.location.index + 1
                        switch hit-result?type
                        case \fill
                            if e.modifiers.shift
                                mark.segments.splice j,1
                            else
                                @drag-func = (poly, e) ~~>
                                    delta = e.delta.multiply tmatrix.scaling
                                    if @has-googlemap
                                        delta = delta.multiply -1
                                    movePolygon poly, delta
                                    @rebuild!
                                @drag-func = @drag-func poly
                        case \segment
                            if e.modifiers.shift
                                poly.splice k, 1
                            else
                                @drag-func = (point, e) ~~>
                                    delta = e.delta.multiply tmatrix.scaling
                                    if @has-googlemap
                                        delta = delta.multiply -1
                                    np = delta.add point
                                    point{x,y} = np
                                    @rebuild!
                                @drag-func = @drag-func point
                        case \stroke
                            if e.modifiers.shift
                                null
                            else
                                poly.splice k, 0, point{x,y}
                        mark.active-segment.j = j
                        @rebuild!
                        @forceUpdate!
                        return

                j = mark.active-segment.j
                if j?
                    poly = mark.segments[j]
                    poly?.push point{x,y}
            @rebuild!


        @segment-tool.on-mouse-up = (e) ~>
            @up-func? e

        @segment-tool.on-mouse-drag = (e) ~>
            @drag-func? e

        @segment-tool.on-key-down = (e) ~>
            @pan-tool.on-key-down e
        @segment-tool.on-mouse-move = (e) ~>
            @pan-tool.on-mouse-move e
            c = @state.cMark
            if c? then mark = @state.marks[c]
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: 5
            hit-result = @segments-group.hit-test point, hitOptions
            if e.modifiers.control or mark.segments.length == 0
                @canvas.style.cursor = \copy
            else
                #if hit-result?item?mydata?i != @state.cMark
                #    @set-state cMark:i
                if hit-result?item?mydata
                    {i,j} = that
                    if inte i,@state.cMark
                        mark = @state.marks[i]
                        poly = mark.segments[j]
                        if hit-result.segment
                            k = hit-result.item.segments.index-of that
                            point = poly[k]
                        if hit-result.location
                            k = hit-result.location.index + 1
                        switch hit-result?type
                        case \fill
                            if e.modifiers.shift
                                @canvas.style.cursor = \no-drop
                            else
                                @canvas.style.cursor = \move
                        case \segment
                            if e.modifiers.shift
                                @canvas.style.cursor = \no-drop
                            else
                                @canvas.style.cursor = \pointer
                        case \stroke
                            if e.modifiers.shift
                                @canvas.style.cursor = \no-drop
                            else
                                @canvas.style.cursor = \pointer
                        return
                @canvas.style.cursor = \crosshair

        @box-tool = new paper.Tool

        @box-tool.on-mouse-down = (e) ~>
            @drag-func = undefined
            mark = @get-current-mark!
            unless mark then return
            tmatrix = @rebuild-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: 5
            hit-result = @box-group.hit-test point, hitOptions
            if hit-result?item
                i = hit-result.item.mydata.i
                if not inte i, @state.cMark
                    @set-state cMark:i
                    mark = @get-current-mark!
                if hit-result.segment?
                    p = hit-result.segment.point
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else if hit-result.location?
                    pa = hit-result.location._segment1.point
                    pb = hit-result.location._segment2.point
                    p = (pa.add pb).multiply 0.5
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else
                    q1 = q2 = q3 = q4 = true

                if e.modifiers.shift
                    mark.bbox = undefined
                else
                    @drag-func = (e) ~>
                        delta = e.delta.multiply tmatrix.scaling
                        if @has-googlemap
                            delta = delta.multiply -1
                        if q1 then mark.bbox.p1.x += delta.x
                        if q2 then mark.bbox.p2.x += delta.x
                        if q3 then mark.bbox.p1.y += delta.y
                        if q4 then mark.bbox.p2.y += delta.y
                        @rebuild!
                @rebuild!
                return

            mark.bbox = p1: point{x,y}, p2: point{x,y}
            @rebuild!
            @drag-func = (e) ~>
                point = e.point.transform tmatrix
                mark.bbox.p2 = point{x,y}
                @rebuild!
        @box-tool.on-mouse-drag = ~> @drag-func it
        @box-tool.on-key-down = ~> @pan-tool.on-key-down it
        @box-tool.on-mouse-move = (e) ~>
            @pan-tool.on-mouse-move e
            mark = @get-current-mark!
            unless mark then return
            tmatrix = @rebuild-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            tolerance = 5
            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: tolerance
            hit-result = @box-group.hit-test point, hitOptions
            if hit-result?item
                if e.modifiers.shift
                    @canvas.style.cursor = 'no-drop'
                    return
                i = hit-result.item.mydata.i
                if not inte i, @state.cMark
                    @set-state cMark:i
                    mark = @get-current-mark!
                if hit-result.segment?
                    p = hit-result.segment.point
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else if hit-result.location?
                    pa = hit-result.location._segment1.point
                    pb = hit-result.location._segment2.point
                    p = (pa.add pb).multiply 0.5
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else
                    q1 = q2 = q3 = q4 = true
                count = 0
                if mark.bbox.p1.x > mark.bbox.p2.x
                    [q1,q2] = [q2,q1]
                if mark.bbox.p1.y > mark.bbox.p2.y
                    [q3,q4] = [q4,q3]
                for q in [q1,q2,q3,q4]
                    if q then count++
                if count == 4
                    @canvas.style.cursor = "move"
                else if count == 1 and (q1 or q2)
                    @canvas.style.cursor = "ew-resize"
                else if count == 1 and (q3 or q4)
                    @canvas.style.cursor = "ns-resize"
                else if count == 2 and ((q1 and q3) or (q2 and q4))
                    @canvas.style.cursor = "nwse-resize"
                else
                    @canvas.style.cursor = "nesw-resize"
            else
                @canvas.style.cursor = "crosshair"

        @check-bbox-click = (e) ~>
            if e.event.button != 2 then return false
            e.event.prevent-default!

            mark = @get-current-mark!
            unless mark then return
            tmatrix = @rebuild-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            hitOptions =
                stroke: true
                fill: true
                segments: true
                tolerance: 5
            hit-result = @box-group.hit-test point, hitOptions
            if hit-result?item
                if e.modifiers.shift
                    @canvas.style.cursor = 'no-drop'
                    return
                i = hit-result.item.mydata.i
                if not inte i, @state.cMark
                    @set-state cMark:i
                    mark = @get-current-mark!
                if hit-result.segment?
                    p = hit-result.segment.point
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else if hit-result.location?
                    pa = hit-result.location._segment1.point
                    pb = hit-result.location._segment2.point
                    p = (pa.add pb).multiply 0.5
                    q1 = p.x == mark.bbox.p1.x
                    q2 = p.x == mark.bbox.p2.x
                    q3 = p.y == mark.bbox.p1.y
                    q4 = p.y == mark.bbox.p2.y
                else
                    q1 = q2 = q3 = q4 = true
                count = 0
                if mark.bbox.p1.x > mark.bbox.p2.x
                    [q1,q2] = [q2,q1]
                if mark.bbox.p1.y > mark.bbox.p2.y
                    [q3,q4] = [q4,q3]
                for q in [q1,q2,q3,q4]
                    if q then count++
                return true
            else
                return false

        @zoom = (factor, center) ~>
            if @has-googlemap
                if factor>1
                    if @googleMap.map.get-zoom! == 19
                        factor = 1
                    else
                        factor = 2
                else
                    if @googleMap.map.get-zoom! == 3
                        factor = 1
                    else
                        factor = 1/2
            @state.paint-brush-size /= factor
            @scale factor, center
            @update-backgroud!
            @cursor.scaling =  @state.paint-brush-size / @state.default-brush-size
            paper.view.draw!

        @pan = (delta) ~>
            @layer.translate delta
            @update-backgroud!
            paper.view.draw!

        @pan-tool = new paper.Tool
        @pan-tool.on-mouse-move = (e) ~>
            @mouse-position = e.point
        @pan-tool.on-mouse-drag = (e) ~>
            if e.modifiers.control
                @zoom(e.delta.y / 100.0 + 1, e.downPoint)
            else
                @pan e.delta
            @rebuild!
        @pan-tool.on-key-down = (e) ~>
            @check-tool-switch e
            if e.key == 'z'
                @zoom 1.1, @mouse-position
            else if e.key == 'x'
                @zoom 1/1.1, @mouse-position

        @paint-tool = new paper.Tool
        #@paint-tool.minDistance = 10

        @cursor = new paper.Path.Circle [0,0], @state.paint-brush-size
            ..fillColor = undefined
            ..strokeColor = \green
            ..strokeWidth = 2
        @cursor.apply-matrix = false
        @offset-group.addChild @cursor

        @paint-tool.on-mouse-move = (e) ~>
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            #@cursor.scaling = 10.0 / @state.paint-brush-size
            @cursor.position = point
            paper.view.draw!

        @paint-tool.on-mouse-down = (e) ~>
            if @check-bbox-click e then return
            @paint-tool.minDistance = 10
            @drag-func = undefined
            # get current mark
            c = @state.cMark
            if c? then mark = @state.marks[c]
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            @rp = new paper.Path.Circle(point, @state.paint-brush-size)

            add-path = (path) ~>
                cpath = @paints[@state.paintState]
                if e.modifiers.shift
                    npath = cpath.subtract path
                else
                    npath = cpath.unite path
                cpath.strokeWidth = 0
                cpath.remove!
                path.remove!
                paper.project.current-style = {}
                npath = new paper.CompoundPath [npath]
                npath.fillColor = cpath.fillColor
                npath <<< @strokeStyle
                @paints[@state.paintState] = cpath = npath
                @rebuild-group.addChild cpath
                mark.paints = { [k, v.exportJSON!] for k,v of @paints }
                @calc-bbox!

                @set-changed!
                #cpath.smooth!

            add-path @rp

            @drag-func = (e) ~>
                point = e.point.transform tmatrix
                @cursor.position = point
                lpoint = e.lastPoint.transform tmatrix
                d = e.delta.normalize!.rotate 90 .multiply @state.paint-brush-size
                p = new paper.Path
                @offset-group.addChild p
                p.add point.subtract d
                p.arcTo point.add d
                p.add lpoint.add d
                p.arcTo lpoint.subtract d
                p.closed = true
                add-path p

        @paint-tool.on-mouse-drag = ~> @drag-func? it

        @paint-tool.on-mouse-up = ~>
            @paint-tool.minDistance = 0

        @paint-tool.on-key-down = (e) ~>
            @check-tool-switch e
            if e.key == 'z'
                @state.paint-brush-size++
            else if e.key == 'x'
                @state.paint-brush-size--
            if @state.paint-brush-size < 1 then @state.paint-brush-size = 1
            if @state.paint-brush-size > 1000 then @state.paint-brush-size = 1000
            @cursor.scaling =  @state.paint-brush-size / @state.default-brush-size

        @ps-tool = new paper.Tool
        @ps-tool.minDistance = 0
        @ps-tool.on-key-down = (e) ~>
            @check-tool-switch e
            if e.key == 'z'
                @state.paint-brush-size++
            else if e.key == 'x'
                @state.paint-brush-size--
            else if e.key == 'shift'
                @cursor.strokeColor = \red
            if @state.paint-brush-size < 1 then @state.paint-brush-size = 1
            if @state.paint-brush-size > 1000 then @state.paint-brush-size = 1000
            @cursor.scaling =  @state.paint-brush-size / @state.default-brush-size
        @ps-tool.on-key-up = (e) ~>
            if e.key == 'shift'
                @cursor.strokeColor = \green

        @ps-tool.on-mouse-drag = ~> @drag-func? it
        @ps-tool.on-mouse-down = (e) ~>
            if @check-bbox-click e then return
            @drag-func = undefined
            # get current mark
            mark = @get-current-mark!
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            is_erase = e.modifiers.shift
            paint-cmd = {stroke:[point{x,y}], size:@state.paint-brush-size, is_bg:is_erase}
            if not mark.strokes then mark.strokes = []
            mark.strokes.push {} <<< paint-cmd <<< {date: (new Date).to-string!}
            @send-cmd \paint, paint-cmd


            @drag-func = (e) ~>
                point = e.point.transform tmatrix
                lpoint = e.lastPoint.transform tmatrix
                paint-cmd = {stroke:[point{x,y},lpoint{x,y}], size:@state.paint-brush-size, is_bg:is_erase}
                mark.strokes.push paint-cmd
                @send-cmd \paint, paint-cmd
                @cursor.position = point
        @ps-tool.on-mouse-move = (e) ~>
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            #@cursor.scaling = 10.0 / @state.paint-brush-size
            @cursor.position = point
            #paper.view.draw!

        @empty-tool = new paper.Tool
        if not @props.viewonly
            $ document .on \keydown, @on-key-down
            $ document .on \keyup, @on-key-up
        $ @canvas .on \wheel, (e) ~>
            @activate-canvas!
            ee = e.originalEvent
            if ee.deltaY > 0
                @zoom 1.1, {x:ee.offsetX, y:ee.offsetY}
            else
                @zoom 1/1.1, {x:ee.offsetX, y:ee.offsetY}
            e.prevent-default!

        $ @canvas .on \wheel, (e) ~>
            @activate-canvas!
            ee = e.originalEvent
            if ee.deltaY > 0
                @zoom 1.1, {x:ee.offsetX, y:ee.offsetY}
            else
                @zoom 1/1.1, {x:ee.offsetX, y:ee.offsetY}
            e.prevent-default!

        $ @canvas .on \mouseover, ~> @activate-canvas!

        @componentDidUpdate!

    activate-canvas: ->
        if @props.viewonly
            @project.activate!
            @pan-tool.activate!

    componentWillUnmount: ->
        if not @props.viewonly
            if @worker
                @worker.kill-proc!
                @worker = undefined
            else
                @socket.off \ok, @receive-cmd
                @socket.off \s-error
            $ \body .css \overflow, \auto
            $ document .off \keydown, @on-key-down
            $ document .off \keyup, @on-key-up
        $ @canvas .off \wheel
        $ @canvas .off \mouseover
        (TimerMixin.componentWillUnmount.bind @)!
        #@socket.disconnect!

    switchTool: (editMode) ->
        if @props.viewonly
            @pan-tool.activate!
            @cursor.visible = false
            @canvas.style.cursor = "move"
            return

        @cursor.visible = false
        ucursor = ""
        if not editMode
            editMode = @state.editMode
        if editMode == \spotting
            @spotting-tool.activate!
            ucursor = "crosshair"
        else if editMode == \segment
            @segment-tool.activate!
            ucursor = "crosshair"
        else if editMode == \pan
            @pan-tool.activate!
            ucursor = "move"
        else if editMode == \paint
            @paint-tool.activate!
            @cursor.visible = true
            ucursor = "none"
        else if editMode == \ps
            @ps-tool.activate!
            @cursor.visible = true
            ucursor = "none"
        else if editMode == \box
            @box-tool.activate!
            ucursor = "crosshair"
        else
            @empty-tool.activate!
        @canvas.style.cursor = ucursor


    componentDidUpdate: ->
        @switchTool!
        @rebuild!

    save: (savestr)~>
        if @state.saveStatus == \saving
            toastr.info "Saving request is pending, please wait."
            return
        pre-status = @state.saveStatus
        @state.currentItem.marks = deep-copy @state.marks
        @set-state saveStatus:\saving
        $.ajax do
            method: \POST
            url: \/api/new-object
            data: JSON.stringify @state.currentItem
            contentType: "application/json"
            error: ~>
                toastr.error it.response-text
                if @state.saveStatus == \saving
                    @set-state saveStatus: pre-status
            success: ~>
                if @state.saveStatus == \saving
                    @set-state saveStatus: \saved
                if savestr
                    toastr.success savestr

    switchCurrentMark: ~>
        if inte it, @state.cMark then return
        @set-state cMark:it
        @on-current-mark-change it

    nextMark: ~>
        cMark = parseInt @state.cMark
        if cMark == NaN then return
        cMark++
        if cMark >= @state.marks.length then return
        @switchCurrentMark cMark


    prevMark: ~>
        cMark = parseInt @state.cMark
        if cMark == NaN then return
        cMark--
        if cMark < 0 then return
        @switchCurrentMark cMark

    new-mark: ->
        mark = (new mongoose.Document {}, object.mark).to-object!
        if @state.config?autoType
            if @state.marks == undefined
                tid = 0
            else
                tid = @state.marks.length
            if @state.config?types?0?types
                if tid>=that.length then tid = 0
                mark.type = that[tid].title
        return [mark]

    addMark: ~>
        # TODO : fix the model initial
        @state.marks = @new-mark!.concat @state.marks
        @state.cMark = 0
        @on-current-mark-change!
        @forceUpdate!
    delMark: ~>
        if @state.marks.length == 0
            toastr.error "No item to delete."
            return
        @state.marks.splice @state.cMark, 1
        if @state.marks.length > 0 and @state.cMark >= @state.marks.length
            @state.cMark = @state.marks.length - 1
        @on-current-mark-change!
        @forceUpdate!

    on-current-mark-change: (mark) ->
        @drop-cmd!
        bgContours = []
        for omk,i in @state.marks
            type = omk.type
            if type
                type = @state.typeMap.findType(type)?spotsType
                if type and type.length != omk.spots.length
                    toastr.error "number of spots invalid."
                    @state.cMark = i
                    break
        if mark
            mark = @state.marks[mark]
        else
            mark = @get-current-mark!
        if not @state.config.allowedOverlap
            for omk in @state.marks
                if omk != mark and omk.contours then
                    bgContours.=concat omk.contours
        if mark?contours
            @send-cmd \load-region, {contours:that, bgContours}
        else
            @send-cmd \load-region, {contours:[], bgContours}

    keys: {}

    on-key-down: (e) ~>
        key = String.fromCharCode(e.keyCode).to-lower-case!
        if key == 'a'
            @addMark!
        else if key == 'd'
            @delMark!
        else if key == 'n'
            @on-next-click!
        else if key == 'p'
            @on-prev-click!
        else if key == 'h'
            @show-help!
        else if key == 'q'
            @markAs \annotated
        else if key == 'w'
            @markAs \un-annotated
        else if key == 'e'
            @markAs \issued
        else if key == 's'
            @save \Saved.
        else if key == 'v'
            @set-state hideImage: not @state.hideImage
        else if key == 'b'
            @set-state hideAnnotation: not @state.hideAnnotation
        else if key == 'b'
            @set-state hideAnnotation: not @state.hideAnnotation
        else if key == 'b'
            @set-state hideAnnotation: not @state.hideAnnotation
        else if e.keyCode == 40 # up key
            e.prevent-default!
            @nextMark!
        else if e.keyCode == 38 # down key
            e.prevent-default!
            @prevMark!
        else if key == ' '
            e.prevent-default!
            if not @keys[key]
                @prev-mode = @state.editMode
                @set-state editMode:\pan
        @keys[key] = true

    on-key-up: (e) ~>
        key = String.fromCharCode(e.keyCode).to-lower-case!
        if key == ' '
            @set-state editMode:@prev-mode
        @keys[key] = false

    find-neighbour: (is-next) ~>
        if @state.saveStatus == \changed
            @save!
        data = {is-next} <<< @state.currentItem{_id,parent}
        if @state.listState != 'all'
            data.state = @state.listState
        @background.src = ""
        @set-state imageLoaded: false
        $.ajax do
            method: \POST
            data: data
            url: \/api/find-neighbour
            error: -> toastr.error it.response-text
            success: (data) ~>
                if data._id?
                    myhistory.push "/i/"+data._id
                else
                    toastr.info "Reaching the end of files."

    on-next-click: (e) ~> @find-neighbour 1
    on-prev-click: (e) ~> @find-neighbour 0

    on-propagate-click: ~>
        @propagateModal.modal \show
        $ .ajax do
            method: \GET
            url: \/api/prefetch-objects
            data: @state.currentItem{parent,_id}
            error: ->
                #toastr.error it.response-text
                console.error it.response-text
            success: ~>
                #items = {[i._id, i] for i in it}
                @set-state propagate-back:it

    do-propagate: (from, to) ~>
        @set-state propagating: true
        @propagate-to = to
        @send-cmd \propagate, {from: from, to: to}

    show-help: ~> @helpModal.modal \show

    markAs: (str) ~>
        @state.currentItem.state = str
        @save "Marked!"

    switchType: (data) ~>
        if @state.marks[@state.cMark]
            that.type = data
            @forceUpdate!
        else
            toastr.error "No mark found."

    get-img-url: ~>
        if @state.currentItem.type == \item
            return @state.currentItem?.url
        else
            return @state.currentItem.originImage?.url

    render: ->
        list-option =
            *   value: 'all'
            *   value: 'annotated'
            *   value: 'un-annotated'
            *   value: 'issued'
        console.log \editor-render
        imgUrl = @get-img-url!
        {marks,cMark} = @state
        imgSizeStr = \width: + @origin-width + ', ' + \height: + @origin-height
        marksUI = for i of marks
            switchCMark = @switchCurrentMark.bind @, i
            openTypePopup = ~> @typePopup.toggle!
            if @props.viewonly
                openTypePopup = -> 0
            hitStr = "#{@state.marks[i].spots.length} spots, #{@state.marks[i].segments.length} segments"
            ``<tr key={i} className={i==cMark?"positive":""} onClick={switchCMark}>
                <td className='selectable'><a><div className={i==cMark?"ui green ribbon label":""}>{i}</div></a></td>
                <td onClick={openTypePopup}><TypeDropdown data={marks[i].type} viewonly={this.props.viewonly} /></td>
                <td>{hitStr}</td>
            </tr>
            ``

        markTable = ``<table className="ui selectable celled small compact table">
                <thead>
                    <tr><th>Mark ID</th>
                    <th>type</th>
                    <th>state</th></tr>
                </thead>
                <tbody>
                {marksUI}
                </tbody>
            </table>``

        if @state.editMode == \paint
            paintDropdown = ``<MyDropdown
                dataOwner={[this, "paintState"]}
                defaultText="Paint Mode"
                options={[
                    {value:"background", text:"Background"},
                    {value:"foreground", text:"Foreground"},
                    {value:"alpha", text:"alpha"}
                ]} />``

        if @props.markonly
            utils = ``<div className="six wide column editor-utils canvas-vh45">
                    {markTable}
                </div>``
        else
            annotationsUI = undefined
            if @state.currentItem.annotations?length
                annotationsList = for aid,i in @state.currentItem.annotations
                    ``<li key={i}><Link to={'/i/'+aid}>{aid}</Link></li>``
                annotationsUI = ``
                <div><b>Annotations:</b><ul>{annotationsList}</ul></div>
                ``

            utils = ``<div className="six wide column editor-utils">
                <div className="ui horizontal divider" >Mark as</div>
                <div className="ui mini green button"
                    onClick={this.markAs.bind(this,'annotated')}>annotated</div>
                <div className="ui mini red button"
                    onClick={this.markAs.bind(this,'un-annotated')}>un-annotated</div>
                <div className="ui mini yellow button"
                    onClick={this.markAs.bind(this,'issued')}>issued</div>


                <div className="ui horizontal divider" >Tool</div>
                <MyDropdown
                    data={this.state.editMode}
                    dataOwner={[this, "editMode"]}
                    defaultText="Edit mode"
                    options={this.modeOption} />
                {paintDropdown}

                <div className="ui horizontal divider" >Config</div>
                <MyCheckbox
                    text="Hide image"
                    dataOwner={[this,"hideImage"]} data={this.state.hideImage}/>
                <MyCheckbox
                    text="Hide annotation"
                    dataOwner={[this,"hideAnnotation"]} data={this.state.hideAnnotation}/>
                <MyCheckbox
                    text="Auto bounding box"
                    dataOwner={[this,"autobox"]} data={this.state.autobox}/>
                <MyCheckbox
                    text="Show bounding box"
                    dataOwner={[this,"showMark"]} data={this.state.showMark}/>
                <MyCheckbox
                    text="Smooth"
                    dataOwner={[this, "smooth"]} data={this.state.smooth}/>
                <MyCheckbox
                    text="Simplify"
                    dataOwner={[this, "simplify"]} data={this.state.simplify}/>
                <MyCheckbox
                    text="Autosave"
                    dataOwner={[this, "autosave"]} data={this.state.autosave}/>

                <div className="ui horizontal divider" >Marks</div>
                <div className="ui mini positive button"
                    onClick={this.addMark}>add</div>
                <div className="ui mini negtive button"
                    onClick={this.delMark}>delete</div>
                {markTable}

                <div className="ui horizontal divider">Status</div>
                <div><b>Save status:</b> {this.state.saveStatus}</div>
                <div><b>Image size:</b>{imgSizeStr}</div>
                {
                    this.state.currentItem.type == "annotation"?
                        <div><b>Origin image:</b><Link to={"/i/"+this.state.currentItem.originImage._id}>{this.state.currentItem.originImage.name}</Link></div>
                    : ""
                }
                {annotationsUI}

                <div className="ui horizontal divider">File</div>
                <div className="ui mini button"
                    onClick={() => this.save("Saved.")}>Save</div>
                <div className="ui mini button"
                    onClick={this.loadSession}>Reload</div>
                <div className="ui mini button"
                    onClick={this.showHelp}>Help</div>

                <div className="ui horizontal divider" >Navigation</div>
                <MyDropdown
                    dataOwner={[this, "listState"]}
                    defaultText="List state"
                    options={listOption} />
                <div className="ui mini button"
                    onClick={this.onPrevClick}>prev</div>
                <div className="ui mini button"
                    onClick={this.onNextClick}>next</div>
                <div className="ui mini button"
                    onClick={this.onPropagateClick}>propagate</div>
            </div>``

        popup = ``<TypePopup ref={(it) => {this.typePopup = it}} onChange={this.switchType}/>``

        if @props.viewonly
            popup = undefined
        if @props.viewonly and not @props.markonly
            utils = undefined

        twoColumn = utils?

        if @props.viewonly
            helpModal = undefined
            propagateModal = undefined
        else
            helpModal = ``<div className="ui modal" id="helpModal">
                    <i className="close icon"></i>
                    <div className="header">
                        Help
                    </div>
                    <div className="content">
                        <Help />
                    </div>
                </div>``
            propagateContent = undefined
            if @state.propagate-back
                propagateContent = for item,i in @state.propagate-back
                    onClick = @do-propagate.bind this, @state.currentItem, item
                    ``<div className="column imgGalleryBoxOuter" key={i}>
                        <a className="imgGalleryBox" onClick={onClick}>
                            <img className="ui image" src={item.url}/>
                        </a>
                    </div>``
                propagateContent = ``<div className="ui three column grid">
                    {propagateContent}
                </div>``
            propagateModal = ``<div className="ui modal" id="propagateModal">
                    <i className="close icon"></i>
                    <div className="header">
                        Propagate
                    </div>
                    <div className={"modal-scroll ui vertical segment content "+(propagateContent && ! this.state.propagating?"":"loading")}>
                        {propagateContent}
                    </div>
                </div>``
        ``<div className={this.state.imageLoaded?"ui segment":"ui loading segment"}>
            {helpModal}
            {propagateModal}
            <div className="ui grid">
                <div className={!twoColumn ? "myCanvas sixteen wide column canvas-vh30" : this.props.markonly?"myCanvas ten wide column canvas-vh45":"myCanvas ten wide column canvas-vh75"}>
                    <div className="canvas-border">
                        <img id='canvas-bg' crossOrigin="anonymous"/>
                        { (this.state.currentItem.latlngBounds)?
                            <GoogleMap ref={(v) => this.googleMap = v}/>
                        :
                            undefined
                        }
                        <canvas id='canvas' data-paper-resize></canvas>
                    </div>
                </div>
                {utils}
                {popup}
            </div>
        </div>``

movePolygon = (poly, delta) ->
    delta = new paper.Point delta
    for i of poly then poly[i]{x,y} = delta.add poly[i]
