require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent} = common

module.exports = class TypeDropdown extends MyComponent
    ->
        super ...
        store.connect-to-component this, [
            \typeMap
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
