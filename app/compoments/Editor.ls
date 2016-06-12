require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent, MyCheckbox, MyDropdown} = common

require! {
    \./TypeDropdown
    \../models/types
    \../history : myhistory
}

inte = (a,b) -> parseInt(a) == parseInt(b)

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
            *   value:"ps", text: ``<div><i className="wizard icon"></i>Paint selection</div>``
            *   value:"paint", text: ``<div><i className="paint brush icon"></i>Free Paint</div>``
        ]
        @state.cMark = \0
        @state.smooth = false
        @state.showMark = true
        @state.editMode = "spotting"
        @state.listState = "all"
        @state.autosave = true
        @state.saveStatus = "saved"
        @state.autosave-interval = 5000
        @state.paintState = "foreground" # background foreground hair
        @state.paint-brush-size = 10
        @autosave!
        @contour-anime!

        @time-evaluate = false

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

    create-typeimage-symbol: ->
        @typeimages = {}
        for k,v of types.url-map
            raster = new paper.Raster v
            @typeimages[k] = new paper.Symbol raster
            raster.remove!
        #@test-symbol @typeimages[k]

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
        @cross-symbol = new paper.Symbol linegroup
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
        if @state.marks and
            @state.currentItem.marks != JSON.stringify @state.marks
            @set-changed!

    rebuild: ->
        @check-changed!
        if @rebuild-group
            @rebuild-group.remove!
        @rebuild-group = new paper.Group
        @offset-group.addChild @rebuild-group
        @rebuild-group.apply-matrix = false
        wfactor = 1 / @layer.scaling.x
        paper.project.current-style =
            fillColor : \red
            strokeColor : \black
            strokeWidth : wfactor
        segm-op = if @state.editMode==\pan then 0.5 else 1
        spot-op = if @state.editMode==\pan then 0.8 else 0.8

        # draw paints
        @paints = {}
        @paints.foreground = new paper.CompoundPath
            ..fillColor = \green
        @paints.background = new paper.CompoundPath
            ..fillColor = \red
        @paints.hair = new paper.CompoundPath
            ..fillColor = \yellow
        for k,v of @paints
            v.strokeWidth = 0
            v.opacity = 0.7
            v.closed = true
        @rebuild-group.addChildren [ v for k,v of @paints ]
        paint-json = @state.marks[@state.cMark]?paints
        if paint-json
            for k,v of @paints
                v.importJSON paint-json[k]

        # draw contours
        contours = @state.marks[@state.cMark]?contours
        if contours
            @gen-contours contours

        # draw box
        @box-group = new paper.Group
        @rebuild-group.addChild @box-group
        for i,mark of @state.marks
            unless mark.bbox? then continue
            p1 = new paper.Point mark.bbox.p1
            p2 = new paper.Point mark.bbox.p2
            path = new paper.Path.Rectangle p1, p2
            path.opacity = if inte(i,@state.cMark) then 0.8 else 0.3
            @box-group.addChild path
            path.mydata = {i}
            if inte(i,@state.cMark)
                path.selected = true
            path.closed = true
            # add rect


        # draw segments
        @segments-group = new paper.Group
        @rebuild-group.addChild @segments-group
        for i,mark of @state.marks
            for j,segment of mark.segments.data
                path = new paper.Path
                path.opacity = segm-op * if inte(i,@state.cMark) then 1 else 0.5
                @segments-group.addChild path
                path.mydata = {i,j}
                if inte(i,@state.cMark) and
                   inte(j,mark.segments.active.j)
                    path.selected = true
                path.closed = true
                for k,p of segment
                    pt = new paper.Point p
                    path.add pt
                if @state.smooth then path.smooth!

        # draw spots
        @spots-group = new paper.Group
        @rebuild-group.addChild @spots-group
        for i,mark of @state.marks
            type-symbol = undefined
            if @state.showMark and mark.type and @typeimages[mark.type]
                type-symbol = @typeimages[mark.type]
            for j,spot of mark.spots
                instance = @cross-symbol.place!
                instance.position = spot
                instance.scale wfactor
                instance.opacity = spot-op * if inte(@state.cMark,i) then 1 else 0.5
                @spots-group.addChild instance
                instance.mydata = {i,j}
                if type-symbol
                    instance = type-symbol.place!
                    instance.scale 0.3 * wfactor
                    instance.position = spot
                    @rebuild-group.addChild instance

        paper.view.draw!

    componentWillReceiveProps: (next-props) ->
        if @props.currentItem._id != next-props.currentItem._id
            @state.currentItem = next-props.currentItem
            @parse-mark!
            @load-session!

    parse-mark: ->
        mark-str = @state.currentItem.marks
        if mark-str == undefined or mark-str == ""
            @state.marks = []
        else
        try
            @state.marks = JSON.parse @state.currentItem.marks
        catch error
            toastr.error "Error when parsing marks: #{error.to-string!}"

    componentWillMount: ->
        @state.currentItem = @props.currentItem
        @parse-mark!

    get-current-mark: ->
        c = @state.cMark
        if c? then mark = @state.marks[c]
        unless mark then return
        return mark

    gen-contours: (contours) ->
        if @contour-path
            @contour-path.remove!
            @contour-path = null

        paths = contours.map ~>
            seg = it.map ~> [it.x, it.y]
            new paper.Path do
                segments: seg.reverse!
                closed: true

        path = new paper.CompoundPath do
            children: paths.reverse!
            fillColor: new paper.Color 0,1,0,0.3
            fillRule: \evenodd
            strokeColor: \black
            strockWidth: 2
            opacity: 1
            dashArray: [10,4]
        @rebuild-group.addChild path
        @contour-path = path

    send-cmd: (cmd, data) ->
        @ts ?= 0
        @cts ?= -1
        @ts += 1
        data.ts = @ts
        @socket.emit cmd, data
        if @time-evaluate
            console.time @ts

    # drop command before
    drop-cmd: ->
        @cts = @ts

    receive-cmd: (data) ~>
        if data.pcmd == \open-session
            toastr.success "Session load success, total seg: #{data.return.regCount}"
        else if data.pcmd == \load-region
            toastr.success "Region load success, total seg selected: #{data.return.segCount}"
        if data.ts and data.ts <= @cts
            return
        if @time-evaluate
            console.timeEnd data.ts

        mark = @get-current-mark!
        unless mark then return

        if data.pcmd == \paint and data.contours?
            @gen-contours data.contours
            paper.view.draw!

            mark.contours = data.contours
            @check-changed!

    check-tool-switch: (e) ~>
        if e.key >= '1' and e.key <= '9'
            v = -1 + parse-int e.key
            v = @modeOption[v]?.value
            if v then
                @set-state editMode:v

    load-session: ~>
        if @socket then that.disconnect!
        @drop-cmd!
        socket = io!
        @socket = socket
        @send-cmd \open-session, id:@state.currentItem._id
        @on-current-mark-change!

        imgUrl = @state.currentItem.url
        if @background then @background.remove!
        raster = new paper.Raster imgUrl
        @background = raster
        raster.on-load = ~>
            console.log "The image has loaded.", imgUrl
            @background.position = paper.view.center
            @offset-group.translate @background.bounds.point
            s1 = paper.view.size
            s2 = @background.size
            @layer.matrix.reset!
            @layer.scaling = Math.min s1.width/s2.width, s1.height/s2.height
            @forceUpdate!


    componentDidMount: ->
        @helpModal = $ \#helpModal
            ..modal!

        paper.setup 'canvas'
        @layer = paper.project.activeLayer
            ..apply-matrix = false
        @load-session!

        @offset-group = new paper.Group
            ..apply-matrix = false


        @create-cross-symbol!
        @create-typeimage-symbol!
        #@rebuild!
        @spotting-tool = new paper.Tool

        @spotting-tool.on-mouse-down = (e) ~>
            tmatrix = @spots-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            hitOptions =
                stroke: true
                tolerance: 5
            hit-result = @spots-group.hit-test point, hitOptions
            console.log hit-result
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

        @segment-tool = new paper.Tool

        @segment-tool.on-mouse-down = (e) ~>
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
            if e.modifiers.control or mark.segments.data.length == 0
                data = mark.segments.data
                data.push [point{x,y}]
                mark.segments.active = {i:c,j:(data.length-1).to-string!}
                @forceUpdate!
            else
                #if hit-result?item?mydata?i != @state.cMark
                #    @set-state cMark:i
                if hit-result?item?mydata
                    {i,j} = that
                    if inte i,@state.cMark
                        mark = @state.marks[i]
                        poly = mark.segments.data[j]
                        if hit-result.segment
                            k = hit-result.item.segments.index-of that
                            point = poly[k]
                        if hit-result.location
                            k = hit-result.location.index + 1
                        switch hit-result?type
                        case \fill
                            if e.modifiers.shift
                                mark.segments.data.splice j,1
                            else
                                @drag-func = (poly, e) ~~>
                                    movePolygon poly, e.delta.multiply tmatrix.scaling
                                    @rebuild!
                                @drag-func = @drag-func poly
                        case \segment
                            if e.modifiers.shift
                                poly.splice k, 1
                            else
                                @drag-func = (point, e) ~~>
                                    delta = e.delta.multiply tmatrix.scaling
                                    np = delta.add point
                                    point{x,y} = np
                                    @rebuild!
                                @drag-func = @drag-func point
                        case \stroke
                            if e.modifiers.shift
                                null
                            else
                                poly.splice k, 0, point{x,y}
                        mark.segments.active.j = j
                        @rebuild!
                        @forceUpdate!
                        return

                j = mark.segments?active?j
                if j?
                    poly = mark.segments.data[j]
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

                @drag-func = (e) ~>
                    delta = e.delta.multiply tmatrix.scaling
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
        @box-tool.on-mouse-move = ~> @pan-tool.on-mouse-move it

        @pan-tool = new paper.Tool
        @pan-tool.on-mouse-move = (e) ~>
            @mouse-position = e.point
        @pan-tool.on-mouse-drag = (e) ~>
            if e.modifiers.control
                @layer.scale(e.delta.y / 100.0 + 1, e.downPoint)
            else
                @layer.translate e.delta
            @rebuild!
        @pan-tool.on-key-down = (e) ~>
            @check-tool-switch e
            if e.key == 'z'
                @layer.scale 1.1, @mouse-position
            else if e.key == 'x'
                @layer.scale 1/1.1, @mouse-position

        @paint-tool = new paper.Tool
        #@paint-tool.minDistance = 10

        @cursor = new paper.Path.Circle [0,0], @state.paint-brush-size - 1
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

        @socket.on \ok, @receive-cmd

        @paint-tool.on-mouse-down = (e) ~>
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
                @paints[@state.paintState] = cpath = npath
                @rebuild-group.addChild cpath
                mark.paints = { [k, v.exportJSON!] for k,v of @paints }

                @set-changed!
                #cpath.smooth!

            add-path @rp

            @drag-func = (e) ~>
                point = e.point.transform tmatrix
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
            @cursor.scaling =  @state.paint-brush-size / 10.0

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
            @cursor.scaling =  @state.paint-brush-size / 10.0
        @ps-tool.on-key-up = (e) ~>
            if e.key == 'shift'
                @cursor.strokeColor = \green

        @ps-tool.on-mouse-drag = ~> @drag-func? it
        @ps-tool.on-mouse-down = (e) ~>
            @drag-func = undefined
            # get current mark
            mark = @get-current-mark!
            unless mark then return
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix

            is_erase = e.modifiers.shift
            @send-cmd \paint, {stroke:[point{x,y}], size:@state.paint-brush-size, is_bg:is_erase}

            @drag-func = (e) ~>
                point = e.point.transform tmatrix
                lpoint = e.lastPoint.transform tmatrix
                @send-cmd \paint, {stroke:[point{x,y},lpoint{x,y}], size:@state.paint-brush-size, is_bg:is_erase}
                @cursor.position = point
        @ps-tool.on-mouse-move = (e) ~>
            tmatrix = @segments-group.globalMatrix.inverted!
            point = e.point.transform tmatrix
            #@cursor.scaling = 10.0 / @state.paint-brush-size
            @cursor.position = point
            paper.view.draw!

        @empty-tool = new paper.Tool
        $ document .on \keypress, @on-key-down
        @componentDidUpdate!

    componentWillUnmount: ->
        $ document .off \keypress, @on-key-down
        @socket.disconnect!


    componentDidUpdate: ->
        @cursor.visible = false
        if @state.editMode == \spotting
            @spotting-tool.activate!
        else if @state.editMode == \segment
            @segment-tool.activate!
        else if @state.editMode == \pan
            @pan-tool.activate!
        else if @state.editMode == \paint
            @paint-tool.activate!
            @cursor.visible = true
        else if @state.editMode == \ps
            @ps-tool.activate!
            @cursor.visible = true
        else if @state.editMode == \box
            @box-tool.activate!
        else
            @empty-tool.activate!
        @rebuild!

    save: ~>
        if @state.saveStatus == \saving
            toastr.info "Saving request is pending, please wait."
            return
        pre-status = @state.saveStatus
        @state.currentItem.marks = JSON.stringify @state.marks
        @set-state saveStatus:\saving
        $.ajax do
            method: \POST
            url: \/api/new-object
            data: @state.currentItem
            error: ~>
                toastr.error it.response-text
                if @state.saveStatus == \saving
                    @set-state saveStatus: pre-status
            success: ~>
                if @state.saveStatus == \saving
                    @set-state saveStatus: \saved

    switchCurrentMark: ~>
        @set-state cMark:it
        @on-current-mark-change it

    addMark: ~>
        # TODO : fix the model initial
        @state.marks.push type:"",state:"set-type",spots:[],segments:{active:{},data:[]}
        @state.cMark = @state.marks.length - 1
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
        if mark
            mark = @state.marks[mark]
        else
            mark = @get-current-mark!
        if mark?contours
            @send-cmd \load-region, contours:that
        else
            @send-cmd \load-region, contours:[]

    on-key-down: (e) ~>
        key = String.from-char-code e.char-code
        if key == 'a'
            @addMark!
        else if key == 'd'
            @delMark!

    find-neighbour: (is-next) ~>
        data = {is-next} <<< @state.currentItem{_id,parent}
        if @state.listState != 'all'
            data.state = @state.listState
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

    show-help: ~> @helpModal.modal \show

    render: ->
        list-option =
            *   value: 'all'
            *   value: 'annotated'
            *   value: 'un-annotated'
            *   value: 'issued'
        console.log \editor-render
        imgUrl = @state.currentItem?.url
        {marks,cMark} = @state
        imgSizeStr = @background?size?to-string!
        marksUI = for i of marks
            switchCMark = @switchCurrentMark.bind @, i
            switchType = (i, data) ->
                @state.marks[i].type = data
                @forceUpdate!
            switchType .= bind @, i
            hitStr = "#{@state.marks[i].spots.length} spots, #{@state.marks[i].segments.data.length} segments"
            ``<tr key={i}>
                <td><a onClick={switchCMark}><div className={i==cMark?"ui ribbon label":""}>{i}</div></a></td>
                <td>{}<TypeDropdown data={marks[i].type} onChange={switchType}/></td>
                <td>{hitStr}, {marks[i].state}</td>
            </tr>
            ``
        if @state.editMode == \paint
            paintDropdown = ``<MyDropdown
                dataOwner={[this, "paintState"]}
                defaultText="Paint Mode"
                options={[
                    {value:"background", text:"Background"},
                    {value:"foreground", text:"Foreground"},
                    {value:"hair", text:"hair"}
                ]} />``
        ``<div className="ui segment">
            <div className="ui modal" id="helpModal">
                <i className="close icon"></i>
                <div className="header">
                    Help
                </div>
                <div className="content">
                    <p>number <b>key[123456]</b> for tool switching</p>
                    <p><b>z/x</b> zoom in zoom out in tool 1234</p>
                    <p><b>z/x</b> increase/decrease brush size in tool 1234</p>
                    <p><b>a/d</b> add/delete item</p>
                </div>
            </div>
            <div className="ui grid">
                <div className="myCanvas ten wide column">
                    <canvas id='canvas'></canvas>
                </div>
                <div className="six wide column">
                    <div><b>Save status:</b> {this.state.saveStatus}</div>
                    <div><b>Image size:</b>{imgSizeStr}</div>
                    <div className="ui divider" />
                    <div className="ui button"
                        onClick={this.save}>Save</div>
                    <div className="ui button"
                        onClick={this.loadSession}>Reload</div>
                    <div className="ui button"
                        onClick={this.showHelp}>Help</div>
                    <div className="ui divider" />
                    <MyDropdown
                        dataOwner={[this, "listState"]}
                        defaultText="List state"
                        options={listOption} />
                    <br />
                    <div className="ui button"
                        onClick={this.onPrevClick}>prev</div>
                    <div className="ui button"
                        onClick={this.onNextClick}>next</div>
                    <div className="ui divider" />
                    <MyDropdown
                        data={this.state.editMode}
                        dataOwner={[this, "editMode"]}
                        defaultText="Edit mode"
                        options={this.modeOption} />
                    {paintDropdown}
                    <div className="ui divider" />

                    <MyCheckbox
                        text="Show mark"
                        dataOwner={[this,"showMark"]}/>
                    <MyCheckbox
                        text="Smooth"
                        dataOwner={[this, "smooth"]}/>
                    <MyCheckbox
                        text="Autosave"
                        dataOwner={[this, "autosave"]}/>

                    <div className="ui divider" />
                    <div className="ui button"
                        onClick={this.addMark}>add</div>
                    <div className="ui button"
                        onClick={this.delMark}>delete</div>
                    <table className="ui celled table">
                        <thead>
                            <tr><th>Mark ID</th>
                            <th>type</th>
                            <th>state</th></tr>
                        </thead>
                        <tbody>
                        {marksUI}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>``

movePolygon = (poly, delta) ->
    delta = new paper.Point delta
    for i of poly then poly[i]{x,y} = delta.add poly[i]
