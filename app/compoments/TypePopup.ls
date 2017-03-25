require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class TypePopup extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \config, \typeMap
        ]
        @state.recent-used = []
        @recent-used-max = 10

    componentDidMount: ->
        try
            cookie = JSON.parse $.cookie \recent-used
            if cookie and cookie.length
                @set-state recent-used: cookie
        jq = $ ReactDOM.findDOMNode this
        ppdom = jq.find \.popup
        @mtg = jq.find \.mtg
        @popup = ppdom.popup do
            #on: \click
            popup: ppdom
            #position : 'bottom left'
            # avoid popup set width
            setFluidWidth: false
            duration: 0
            # TODO
            target: @mtg

        $ document .on \keydown, @on-key-down

    componentWillUnmount: ->
        $ document .off \keydown, @on-key-down

    toggle: ~>
        @mtg.offset top:window.currentMousePos.y, left:window.currentMousePos.x
        @popup.popup \toggle

    on-key-down: (e) ~>
        key = String.fromCharCode(e.keyCode).to-lower-case!
        if key == \t
            @toggle!

    update-recent: (data) ->
        for a in @state.recent-used
            if a.title == data then findit = a
        if not findit
            if @state.recent-used.length >= @recent-used-max-1
                @state.recent-used.=slice 0, @recent-used-max-1
            p = {} <<< @state.typeMap[data]
            p.count = 1
            p.title = data
            @state.recent-used.push p
        else
            findit.count++
            @state.recent-used.sort (a,b) -> b.count - a.count
        @forceUpdate!
        $.cookie \recent-used, JSON.stringify @state.recent-used

    cleanRecent: ~>
        @set-state recent-used: []
        $.cookie \recent-used, ""

    render: ->
        types-ui = []
        type-data = [ {description: ``<div>Recent used <a onClick={this.cleanRecent}>[clean]</a></div>``, types:@state.recent-used} ]
        if @state.config?types
            type-data = type-data.concat that

        for k,v of type-data
            # if k>4 then break
            subList = []
            for id,i of v.types
                f = ->
                    @props.onChange? it
                    if @popup then @popup.popup \hide
                    @update-recent it
                f .= bind this, i.title
                color = @state.typeMap[i.title]?.color
                tag-ui = if i.src?
                    ``<img src={i.src} title={i.title} className="ui mini left floated image" style={{margin:'1px'}}/>``
                else
                    ``<div className='ui tiny button'
                        style={{
                            'backgroundColor':color,
                            'color':'#FFF',
                            'marginBottom': '5px',
                            'textShadow': '1px 0 1px #000000, 0 1px 1px #000000, 0 -1px 1px #000000, -1px 0 1px #000000'}}>{i.title}</div>``
                subList.push ``<a onClick={f} key={id}> {tagUi} </a>``
            types-ui.push ``<div className="column" style={{padding:'3px'}} key={k}>
                <h4 className="ui header">{v.description}</h4>
                <div className="">
                    {subList}
                </div>
            </div>``
        if not types-ui.length
            types-ui = ``<p>Error: No type configuration found, Please setup the config.</p>``
        ``<div>
        <div className="mtg" style={{position:"absolute", width:"1px"}} />
        <div className="ui flowing basic admission fluid popup"
        style={{maxWidth:'60%', maxHeight:'50%', overflowY:'scroll'}}>
          <div className="ui one column relaxed divided grid">
                {typesUi}
          </div>
        </div>
        </div>
        ``
