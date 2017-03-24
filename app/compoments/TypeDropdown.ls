require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent} = common

require! {
    \../models/types
}

class TypePopup extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \config, \typeMap
        ]


    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @popup = jq.find ".menu a" .popup do
            popup: jq.find \.popup
            on: \click
            position : 'bottom left'
            # avoid popup set width
            setFluidWidth: false
            # target: 'body'

    componentDidMount: ->
        types-ui = []
        type-data = []
        if @state.config?types
            type-data = that
        for k,v of type-data
            # if k>4 then break
            subList = []
            for id,i of v.types
                f = ->
                    @set-data it
                    if @popup then @popup.popup \hide
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

    render: ->
        ``<div className="ui flowing basic admission fluid popup"
        style={{maxWidth:'60%', maxHeight:'50%', overflowY:'scroll'}}>
          <div className="ui one column relaxed divided grid">
                {typesUi}
          </div>
        </div>
        ``



module.exports = class TypeDropdown extends MyComponent
    ->
        super ...
        store.connect-to-component this, [
            \config, \typeMap
        ]

    componentDidMount: ->

    shouldComponentUpdate: (next-props, next-state) ->
        res = next-props.data != @state.data or next-state.typeMap !== @state.typeMap
        @state.data = next-props.data
        res

    render: ->
        text = if @state.data == "" then "Please select" else @state.data

        img-url = @state.typeMap[@state.data]?.src
        ccolor = @state.typeMap[@state.data]?.color
        if img-url? then imgui = ``<img src={imgUrl} />``

        ``<div>
        <div className="ui text menu">
          <a className="item" style={{backgroundColor:ccolor}}>
            {imgui}
          </a>
          <a className="browse item">
            {text}
            <i className="dropdown icon"></i>
          </a>
        </div>
        </div>
        ``
