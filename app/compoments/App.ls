require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \./../models/Object : my-object
    \../alt
    \../actions/mainAction : {Actions, create-main-actions}
    \../models/types
}

def-vals =
    loadingCounter: true
    counter: {}

    loadingItems: true
    items: {}

    selects: {}
    showedItems: []

    tabType: \total

    fatherId: undefined
    currentItem: undefined
    ancestors: []

    editMode: ""

class MainActions extends Actions
    ->
        super ...

        # update showed-items
        @gen-dep [\tabType, \items], (data) ->
            {tabType, items} = data
            showed-items = [v for k,v of items].filter ~>
                if tabType == \total
                    return 1
                return it.state == tabType
            return {showed-items}

        # update items
        @gen-dep [\fatherId], ~>
            # dirty here
            actions.fetchContent!
            actions.findAncestor!
            return {}

    fetchContent: ->
        @resetSelects!
        @fetchCounter!
        @fetchItems!

    fetchCounter: ->
        @set-store loadingCounter:true
        $ .ajax do
            method: \POST
            url: \/api/counter
            data: {parent:store.get-state!.fatherId}
            error: ->
                toastr.error it.response-text
            success: ~>
                @set-store counter:it
            complete: ~>
                @set-store loadingCounter:false

    find-objects: (cond, cb) ->
        $ .ajax do
            method: \POST
            url: \/api/find-objects
            data: cond
            error: ->
                toastr.error it.response-text
            success: cb

    findAncestor: ->
        ancestors = []
        my-func = ~>
            i = it[0]
            if i
                ancestors.push(i)
                if ancestors.length == 1
                    @set-store currentItem:i
            if i and i.parent
                @find-objects {_id:i.parent}, my-func
            else
                @set-store {ancestors}
        if store.get-state!.fatherId?
            @find-objects {_id:store.get-state!.fatherId}, my-func
        else
            @set-store {ancestors, currentItem:undefined}

    fetchItems: ->
        @set-store loadingItems:true
        $ .ajax do
            method: \POST
            url: \/api/list-objects
            data: {parent:store.get-state!.fatherId}
            error: ->
                toastr.error it.response-text
            success: ~>
                items = {[i._id, i] for i in it}
                @set-store {items}
            complete: ~>
                @set-store loadingItems:false

    deleteItems: (items) ->
        if not Array.isArray items
            items = [ k for k,v of items when v ]
        $ .ajax do
            method: \POST
            url: \/api/delete-items
            data: {items}
            error: ->
                toastr.error it.response-text
            success: ~>
                toastr.info it
                @fetchContent!
                @set-store selects:{}
            complete: ~>

    resetSelects: ->
        @set-store selects:{}

    selectToggle: ->
        {selects} = @store.get-state!
        if not Array.isArray it
            then it = [it]
        for i in it
            if selects[i]?
                delete selects[i]
            else
                selects[i] = true
        @set-store {selects}

    selectShowed: ->
        {showed-items} = @store.get-state!
        selects = { [i._id, true] for i in showed-items }
        @set-store {selects}

{actions, store, BasicStore} = create-main-actions alt, MainActions, def-vals

class Navbar extends React.Component
    render: ->
        onlineUserCount = 108
        navList = [ \Explore \Datasets \Stats \Category \Whatever ]
        navs = navList.map (it) ->
            ``<a href={it.toLowerCase()} className="item" key={it}>
                {it}
            </a>
            ``
        ``<div className="ui menu">
                    <a className="header item" href="/">ANNOTATE
                        <div className="floating ui red circular mini label" style={{top:'20%'}}>
                            {onlineUserCount}
                        </div>
                    </a>
                    <div className="item">
                        <div className="ui small left labeled right icon input">
                            <div className="ui label">Whole datasets</div>
                            <input type="text" placeholder="Search"/>
                            <i className="search icon"></i>
                        </div>
                    </div>
                    {navs}
                    <div className="ui right floated text menu">
                        <div className="item">
                            <div className="ui buttons">
                                <div className="ui green button">
                                    Sign up
                                </div>
                                <div className="or"></div>
                                <div className="ui button">
                                    Sign in
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
        ``

class Footer extends React.Component
    render: ->
        ``<div className="footer">
            <div className="ui divider">
            </div>
            <div className="ui disabled basic inverted center aligned segment">
                <b>Annotate</b>, © 2016 Dun Liang.
            </div>
        </div>
        ``

class Breadcrumb extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \ancestors
        ]

    render: ->
        lists = []
        p = [] <<< @state.ancestors
        for a in p.reverse!
            lists.push ``<div key={a._id} className="divider">/</div>``
            lists.push ``<Link key={a._id+"-link"} to={"/i/"+a._id}>{a.name}</Link>``

        ``<div>
            <Link to="/i/"><i className="big database icon" /></Link>
            <div className="ui huge breadcrumb">
                {lists}
            </div>
        </div>``

class Guider extends React.Component
    ->
        super ...
        @state =
            *   displayType: \grid # grid list block
                ajaxing: false
                select-all-state: false
                # modal type, edit or add
                modalType: \add

        store.connect-to-component this, [
            \currentItem
        ]

    componentDidMount: ->
        self = this
        #dialog = $ \#addModal .dialog do
        #    auto-open: false
        #    modal: true
        dialog = $ \#addModal
        dialog.modal detachable:false

        del-dialog = $ \#delModal
        del-dialog.modal do
            detachable:false
            on-approve: ~>
                {selects} = store.get-state!
                actions.deleteItems selects


        $ \#addItemBtn .click ~>
            @set-state modalType:\add
            dialog.modal \show

        $ \#editItemBtn .click ~>
            {selects} = store.get-state!
            ids = Object.keys(selects)
            if ids.length != 1
                toastr.error "Please select only one item."
                return
            item = store.get-state!.items[ids[0]]
            for k,v of item
                # attribute selector
                dom = addItemForm.find "input[name='#{k}']"
                dom.val(v)

            @set-state modalType:\edit
            dialog.modal \show

        $ \#delItemBtn .click ->
            del-dialog.modal \show

        $ \#selectAllBtn .click ->
            self.set-state select-all-state: !self.state.select-all-state
            if self.state.select-all-state
                actions.selectShowed!
            else
                actions.resetSelects!

        addItemForm = $ \#addItemForm
        addItemForm.submit (e) ->
            e.prevent-default!
            inputs = addItemForm.find \input
            values = {}
            for input in inputs
                values[input.name] = $(input).val!

            if self.state.modalType == \edit
                id = Object.keys(store.get-state!.selects)[0]
                unless id? then return
                values._id = id
            else
                fid = store.get-state!.fatherId
                if fid then values.parent = fid
            self.set-state ajaxing: true
            $.ajax do
                method: \POST
                url: \/api/new-object
                data: values
                error: ->
                    toastr.error it.response-text
                success: ->
                    toastr.success it
                    dialog.modal \hide
                    addItemForm[0].reset!
                    actions.fetchContent!
                complete: ->
                    self.set-state ajaxing: false

    render: ->
        mainDescription = @state.currentItem?.description
        unless mainDescription? then mainDescription=\Home
        self = this
        displayBar = [ \grid \list \block ].map (it) ->
            ``<a
            className={"ui "+ (it==self.state.displayType?"active":"") +" item"}
            onClick={function(){self.setState({displayType:it})}}
            key={it}
            ><i className={it+" layout icon"}></i></a>
            ``
        availItems = []
        for key of my-object.tree
            if my-object.tree[key] == String
                availItems.push ``<div className="field" key={key}>
                  <label>{key}</label>
                  <input type="text" name={key} placeholder={key}/>
                </div>
                ``

        delModal = ``<div className="ui modal" id="delModal">
            <i className="close icon"></i>
            <div className="header">
                Delete Item
            </div>
            <div className="content">
                Are you sure you delete those items?
            </div>
            <div className="actions">
                <div className="ui approve button">OK</div>
                <div className="ui cancel button">Cancel</div>
            </div>
        </div>
        ``

        ``<div>
        {delModal}
        <div className="ui modal" id="addModal">
            <i className="close icon"></i>
            <div className="header">
                New Item
            </div>
            <div className="content">
                <form className={self.state.ajaxing?"ui loading form":"ui form"} id="addItemForm">

                    {availItems}

                    <button className="ui button" type="submit">Submit</button>
                </form>
            </div>
        </div>

            <div className="ui container">

                <div className="ui right floated small menu">
                    {displayBar}
                </div>

                <div className="ui right floated small menu">
                    <a className="ui item" id="selectAllBtn"><i className=
                    {self.state.selectAllState?"check circle icon":"check circle outline icon"}></i></a>
                    <a className="ui item" id="addItemBtn"><i className="green add circle icon"></i></a>
                    <a className="ui item" id="delItemBtn"><i className="red minus circle icon"></i></a>
                    <a className="ui item" id="editItemBtn"><i className="edit icon"></i></a>
                </div>

                <Breadcrumb/>

            </div>
            <div className="ui fitted hidden clearing divider"></div>
            <div className="ui vertical segment">
                <big>{mainDescription}</big>
            </div>
        </div>
        ``

class Displayer extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \tabType
            \selects
            \showedItems
            \loadingItems
            \counter
        ]

    componentDidUpdate: ->
        node = $ ReactDOM.findDOMNode this
        node.find \.imgGalleryBoxOuter .popup inline:true

    render: ->
        self = this
        tabs =
            *   type: \total, iconstr:  "file archive outline icon"
            *   type: \annotated, iconstr:  "file icon"
            *   type: \un-annotated, iconstr:  "file outline icon"
            *   type: \issued, iconstr:  "warning sign icon"

        for i in tabs
            i.number = self.state.counter[i.type]

        tabsUI = tabs.map (it) ->
            ``<a href="#"
                className={(self.state.tabType==it.type?"active":"")+" item"}
                onClick={function(){actions.setStore({tabType:it.type})}}
                key={it.type}>
                <i className={it.iconstr}></i>
                <b>{it.number}</b>&nbsp;
                {it.type}
            </a>
            ``
        tabsUI = ``<div className="ui four item top attached tabular menu">
            {tabsUI}
        </div>
        ``
        infos = [ \category \description \name ]

        imgsUI = @state.showedItems.map (it, index) ->
            listUI = infos.map (info) ->
                ``<div className="item" key={info}>
                    <div className="header">
                        {info}
                    </div>
                    <div className="description">
                        {it[info]}
                    </div>
                </div>
                ``

            iconname = if self.state.selects[it._id]
                then "checkmark box icon"
                else "square outline icon"
            obj = it
            onClick = ->
                actions.selectToggle obj._id

            colorMap = {
                '' : ''
                \annotated : \green
                \un-annotated : \red
                \issued : \yellow
            }

            ``<div className="column" key={index}>
                <div className={"ui "+colorMap[it.state]+" segment imgGalleryBoxOuter"} style={{overflow:'hidden'}}>
                    <a className="ui left corner label" onClick={onClick}>
                        <i className={iconname}></i>
                    </a>
                    <Link className="imgGalleryBox" to={"/i/"+obj._id}>
                        <img className="ui bordered image" src={it.url} alt="" />
                    </Link>
                </div>
                <div className="ui special popup">
                    <div className="ui bulleted list">
                        {listUI}
                    </div>
                </div>
            </div>
            ``

        return ``<div>
        {tabsUI}
        <div className={"ui bottom attached "+(self.state.ajaxing?"loading":"")+" segment"}>
            <div className="ui three column grid">
                {imgsUI}
            </div>
            <div className="ui pagination secondary pointing menu">
              <a className="active item">
                1
              </a>
              <div className="disabled item">
                ...
              </div>
              <a className="item">
                10
              </a>
              <a className="item">
                11
              </a>
              <a className="item">
                12
              </a>
            </div>
        </div></div>
        ``

class MyPolygon
    ->
        @data = [] <<< it
        @rebuild!

    rebuild: ->
        it = @data
        @objs = []
        @points = []
        @lines = []
        for [x,y] in it
            r = 5
            c = new fabric.Circle do
                left: x - r
                top: y - r
                strokeWidth: 2
                radius: r
                fill: '#fff'
                stroke: '#666'
                selectable: false
            c.hasControls = c.hasBorders = false
            @points.push c
            c.myindex = @points.length - 1
        for i til it.length
            if i==0 then j=it.length-1 else j=i-1
            a = it[i]
            b = it[j]
            l = new fabric.Line [a[0],a[1],b[0],b[1]], {
                fill: 'red'
                stroke: 'red'
                strokeWidth: 2
                selectable: false
            }
            l.hasControls = l.hasBorders = false
            @lines.push l
            l.myindex = @lines.length - 1
        cp = -> [ {x,y} for [x,y] in it ]
        @polygon = new fabric.Polygon cp it
        @polygon.set fill:\red, opacity:0.5
        @polygon.hasControls = false
        @polygon.hasBorders = false
        @polygon.selectable = false
        @objs.push @polygon
        for l in @lines then @objs.push l
        for p in @points then @objs.push p

    toPoly: ->
        v = []
        if  it instanceof fabric.Circle or
            it instanceof fabric.Rect
        then
            rect = it.getBoundingRect!
            v = [
                {x:it.left, y:it.top}
                {x:it.left, y:it.top+it.height}
                {x:it.left+it.width, y:it.top+it.height}
                {x:it.left+it.width, y:it.top}
            ]
        else if it instanceof fabric.Line
            {x1,y1,x2,y2} = it
            if x1 == y1 and x2 == y2 then
                y2 += 1
            dx = y1 - y2
            dy = x2 - x1
            len = Math.sqrt(dx*dx+dy*dy)
            dx /= len
            dy /= len
            v = [
                {x:it.x1, y:it.y1}
                {x:it.x2, y:it.y2}
            ]
        else if it instanceof fabric.Polygon
            minx = miny = 1e30
            v = for p in it.points
                minx <?= p.x
                miny <?= p.y
                {x:p.x+it.left, y:p.y+it.top}
            for p in v
                p.x -= minx
                p.y -= miny
        return v

    update: ->
        for obj in @objs then obj.remove!
        @rebuild!
        for obj in @objs then @canvas.add obj
        @canvas.renderAll!

    addTo: (canvas) ->
        canvas.add @polygon
        @canvas = canvas
        for l in @lines then canvas.add l
        for p in @points then canvas.add p
        mp = new fabric.Rect
        w = 5
        mp.width = mp.height = w*2
        mp.selectable = false
        canvas.add mp
        my-target = null
        canvas.on \mouse:down, ~>
            {e} = it
            if my-target?type == \circle and e.ctrl-key
                i = my-target.myindex
                @data.splice i, 1
                my-target := null
                @update!
                return
            if my-target?type == \line
                i = my-target.myindex
                @data.splice i, 0, [e.offsetX, e.offsetY]
                @update!
                my-target := @points[i]
                return
        canvas.on \mouse:move, ~>
            {e,target} = it
            if e.buttons != 0
                if my-target?type == \polygon
                    for i of @data
                        @data[i] = [
                            @data[i][0]+e.movementX
                            @data[i][1]+e.movementY
                        ]
                    @update!
                    return
                else if my-target?type == \circle
                    i = my-target.myindex
                    @data[i][0] += e.movementX
                    @data[i][1] += e.movementY
                    @update!
                    return

            mp.left = e.offsetX - w
            mp.top = e.offsetY - w
            my-target := null
            for obj in ([] <<< @objs).reverse!
                pa = @toPoly mp
                pb = @toPoly obj
                v = intersectionPolygons pa, pb
                if v.length
                    my-target := obj
                    break

            console.log my-target?type
            canvas.render-all!

class Editor extends React.Component
    ->
        store.connect-to-component this, [\currentItem]
        @state.marks = [
            *   type: \cow, state:\set-mark, spots:[{x:100,y:200}]
            *   type: \dog, state:\set-mark2, spots:[]
        ]
        @state.cMark = \0

    updateSpots: ->
        if @spots
            @canvas.get-objects!.splice @spots.l, @spots.r - @spots.l
        @spots = {l:@canvas.get-objects!.length}
        for i,mark of @state.marks
            console.log i, @state.cMark, i == @state.cMark
            color = if i == @state.cMark then '#f00' else '#00f'
            w = 20
            sw = 4
            config =
                strokeWidth: sw
                fill: color
                stroke: color
                selectable: false
                hasBorders: false
                hasControls: false
            for spot in mark.spots
                l1 = new fabric.Line [spot.x - w, spot.y, spot.x + w, spot.y], config
                l2 = new fabric.Line [spot.x, spot.y - w, spot.x, spot.y + w], config
                lg = new fabric.Group [l1,l2]
                lg.hasControls = lg.hasBorders = false
                canvas.add lg
        @spots.r = @canvas.get-objects!.length

    componentDidMount: ->
        data = [
            *   points: [[100,100],[200,200],[200,100]]
            #*   points: [[300,300],[400,400],[400,300]]
        ]
        canvas = new fabric.Canvas \canvas, {width:600,height:600}
        @canvas = window.canvas = canvas
        imgUrl = @state.currentItem?.url

        #objs = [ new MyPolygon i.points for i in data]
        #for obj in objs then obj.addTo canvas

        canvas.on \mouse:down, ~>
            if @state.editMode == \spotting
                if it.e.ctrl-key
                    # delete pt
                    it.target?.del?!
                    return
                unless it.target == @img then return
                @state.marks[@state.cMark].spots.push do
                    x: it.e.offsetX
                    y: it.e.offsetY
                console.log \add, it.e.offsetX, it.e.offsetY
                @updateSpots!
                #canvas.renderAll!

        fabric.Image.fromURL imgUrl, (img) ~>
            @img = img
            img.selectable = false
            canvas.insertAt img, 0
            @updateSpots!
            #canvas.renderAll!

        jq = $ ReactDOM.findDOMNode this
        jq.find \#editModeDD .dropdown do
            onChange: ~>
                @set-state editMode:it

    add: ~>
        data = [
            *   points: [[100,100],[200,200],[200,100]]
            #*   points: [[300,300],[400,400],[400,300]]
        ]
        objs = [ new MyPolygon i.points for i in data]
        for obj in objs then obj.addTo @canvas
        @canvas.renderAll!

    addMark: ~>
        @state.marks.push type:"",state:"set-type"
        @forceUpdate!
    delMark: ~>
        @state.marks.splice @cMark, 1
        @forceUpdate!

    componentDidUpdate: ->
        @updateSpots!

    render: ->
        imgUrl = @state.currentItem?.url
        {marks,cMark} = @state
        marksUI = for i of marks
            switchCMark = ->
                @set-state cMark:it
            ``<tr key={i}>
                <td><a onClick={switchCMark.bind(this,i)}><div className={i==cMark?"ui ribbon label":""}>{i}</div></a></td>
                <td>{}<TypeDropdown stype={marks[i].type}/></td>
                <td>{marks[i].state}</td>
            </tr>
            ``
        ``<div className="ui segment">
            <div className="ui grid">
                <div className="myCanvas ten wide column">
                    <canvas id='canvas'></canvas>
                </div>
                <div className="six wide column">
                    <div className="ui button" onClick={this.addMark}>add</div>
                    <div className="ui button" onClick={this.delMark}>delete</div>
                    <div className="ui button" onClick={this.add}>pan</div>
                    <div className="ui selection dropdown" id="editModeDD">
                      <input type="hidden" name="gender" />
                      <i className="dropdown icon"></i>
                      <div className="default text">Edit Mode</div>
                      <div className="menu">
                        <div className="item" data-value="spotting">Instance Spotting</div>
                        <div className="item" data-value="segment">Instance Segmentation</div>
                      </div>
                    </div>
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

class TypeDropdown extends React.Component

    componentWillMount: ->
        @set-state @props

    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @popup = jq.find ".menu a" .popup do
            popup: jq.find \.popup
            on: \click
            position : 'bottom left'
            # avoid popup set width
            setFluidWidth: false

    my-set-state: ->
        @set-state it
        if @popup
            @popup.popup \hide
        if this.props.onChange then this.props.onChange it

    render: ->
        text = if @state.stype == "" then "Please select" else @state.stype
        img-url = types.url-map[@state.stype]

        types-ui = []
        for k,v of types.all-data
            # if k>4 then break
            subList = []
            for i in v.types
                f = @my-set-state.bind this, stype:i.title
                subList.push ``<a onClick={f}>
                    <img src={i.src} title={i.title} className="ui mini left floated image" style={{margin:'1px'}}/></a>``
            types-ui.push ``<div className="column" style={{padding:'3px'}}>
                <h4 className="ui header">{v.description}</h4>
                <div className="">
                    {subList}
                </div>
            </div>``

        ``<div>
        <div className="ui text menu">
          <a className="item">
            <img src={imgUrl} />
          </a>
          <a className="browse item">
            {text}
            <i className="dropdown icon"></i>
          </a>
        </div>
        <div className="ui flowing basic admission fluid popup"
        style={{width: '960px'}}>
          <div className="ui eleven column relaxed divided grid">
                {typesUi}
          </div>
        </div></div>
        ``

class MainPage extends React.Component
    ->
        store.connect-to-component this, [\currentItem]

    render: ->
        type = @state.currentItem?type
        ``<div className="ui container">
            <Guider />
            {
                type == "item"? <Editor /> : <Displayer />
            }
        </div>
        ``

class App extends React.Component

    componentDidMount: ->
        actions.set-store fatherId:@props.params.itemId

    componentWillUpdate: ->
        actions.set-store fatherId:it.params.itemId

    render: ->
        ``<div>
            <Navbar />
            <MainPage />
            <Footer />
        </div>
        ``

module.exports = App
