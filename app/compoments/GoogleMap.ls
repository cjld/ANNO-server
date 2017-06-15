require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! \./../history : myhistory

module.exports = class GoogleMap extends React.Component
    ->
        super ...

    componentDidMount: ->
        @map = new google.maps.Map @mapDom
        @map.setMapTypeId "satellite"
        @map.setTilt 0

    render: ->
        ``<div id="map" className="google-map" ref={(v) => this.mapDom = v}></div>``
