require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent, MyCheckbox, MyDropdown} = common

require! {
    \./TypeDropdown
    \../models/types
}

module.exports = class Editor extends React.Component implements TimerMixin
    ->
        super ...
        store.connect-to-component this, [\currentItem]
        @state.cMark = \0
        @state.smooth = false
        @state.showMark = false
        @state.editMode = "spotting"
        @state.autosave = true
        @state.saveStatus = "saved"
        @state.autosave-interval = 5000
        @autosave!

    autosave: ->
        if @state.autosave and @state.saveStatus == \changed
            @save!
            console.log "autosave"
        @set-timeout @autosave, @state.autosave-interval

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

    rebuild: ->
        if @state.marks and
            @state.currentItem.marks != JSON.stringify @state.marks
            if @state.saveStatus != \changed
                @set-state saveStatus:\changed
        if @rebuild-group
            @rebuild-group.remove!
        @rebuild-group = new paper.Group
        @rebuild-group.apply-matrix = false
        @rebuild-group.translate @background.bounds.point
        wfactor = 1 / @layer.scaling.x
        paper.project.current-style =
            fillColor : \red
            strokeColor : \black
            strokeWidth : wfactor
        segm-op = if @state.editMode==\pan then 0.5 else 1
        spot-op = if @state.editMode==\pan then 0.8 else 1
        # draw segments
        @segments-group = new paper.Group
        @rebuild-group.addChild @segments-group
        for i,mark of @state.marks
            for j,segment of mark.segments.data
                path = new paper.Path
                path.opacity = segm-op * if i==@state.cMark then 1 else 0.5
                @segments-group.addChild path
                path.mydata = {i,j}
                if i==@state.cMark and
                   j==mark.segments.active.j
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
                instance.opacity = spot-op * if @state.cMark == i then 1 else 0.5
                @spots-group.addChild instance
                instance.mydata = {i,j}
                if type-symbol
                    instance = type-symbol.place!
                    instance.scale 0.3 * wfactor
                    instance.position = spot
                    @rebuild-group.addChild instance
        paper.view.draw!

    componentWillMount: ->
        mark-str = @state.currentItem.marks
        if mark-str == undefined or mark-str == ""
            @state.marks = []
        else
        try
            @state.marks = JSON.parse @state.currentItem.marks
        catch error
            toastr.error "Error when parsing marks: #{error.to-string!}"

    componentDidMount: ->

        imgUrl = @state.currentItem.url
        paper.setup 'canvas'
        @layer = paper.project.activeLayer
            ..apply-matrix = false
        raster = new paper.Raster imgUrl
        @background = raster
        raster.on-load = ~>
            console.log "The image has loaded."
            @background.position = paper.view.center
            @rebuild!

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
                    @set-state cMark:i
                if e.modifiers.shift
                    @state.marks[i].spots.splice j,1
                    @rebuild!
                    return @forceUpdate!
                @drag-func = (i,j,e) -->
                    @state.marks[i].spots[j]{x,y} = e.point.transform tmatrix
                    @rebuild!
                @drag-func = @drag-func i,j
            else
                if @state.cMark and @state.marks[@state.cMark]
                    @state.marks[@state.cMark].spots.push point{x,y}
                    @rebuild!
                    return @forceUpdate!

        @spotting-tool.on-mouse-up = (e) ~>
            @up-func? e
            #console.log \on-mouse-up, e
        @spotting-tool.on-mouse-drag = (e) ~>
            @drag-func? e

        @segment-tool = new paper.Tool

        @segment-tool.on-mouse-down = (e) ~>
            @drag-func = undefined
            c = @state.cMark
            if c then mark = @state.marks[c]
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
            if e.modifiers.control
                data = mark.segments.data
                data.push [point{x,y}]
                mark.segments.active = {i:c,j:(data.length-1).to-string!}
                @forceUpdate!
            else
                #if hit-result?item?mydata?i != @state.cMark
                #    @set-state cMark:i
                if hit-result?item?mydata
                    {i,j} = that
                    if i == @state.cMark
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

        @pan-tool = new paper.Tool
        @pan-tool.on-mouse-drag = (e) ~>
            if e.modifiers.control
                @layer.scale(e.delta.y / 100.0 + 1, e.downPoint)
            else
                @layer.translate e.delta
            @rebuild!

        @empty-tool = new paper.Tool
        @empty-tool.activate!

    componentDidUpdate: ->
        if @state.editMode == \spotting
            @spotting-tool.activate!
        else if @state.editMode == \segment
            @segment-tool.activate!
        else if @state.editMode == \pan
            @pan-tool.activate!
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

    addMark: ~>
        @state.marks.push type:"",state:"set-type",spots:[],segments:{active:{},data:[]}
        @forceUpdate!
    delMark: ~>
        @state.marks.splice @cMark, 1
        @forceUpdate!

    render: ->
        imgUrl = @state.currentItem?.url
        {marks,cMark} = @state
        imgSizeStr = @background?size?to-string!
        marksUI = for i of marks
            switchCMark = ->
                @set-state cMark:it
            switchCMark .= bind @, i
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
        ``<div className="ui segment">
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
                    <div className="ui divider" />
                    <MyDropdown
                        dataOwner={[this, "editMode"]}
                        defaultText="Edit mode"
                        options={[
                            {value:"pan",text:"Pan"},
                            {value:"spotting",text:"Instance Spotting"},
                            {value:"segment",text:"Instance Segmentation"}]} />
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
