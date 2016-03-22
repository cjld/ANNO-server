require! {
    \alt
    \./mainAction : {Actions, create-main-actions}
}

alt = new alt

default-values =
    a:0
    b:1
    c:-1
    d:-2

class MyActions extends Actions
    ->
        super ...
        @gen-dep [\a,\b], (data) ->
            if data.a? and data.b?
                return c:data.a+data.b

        @gen-dep [\c], (data) ->
            if data.c?
                return d:data.c+1


{actions, store, BasicStore} = create-main-actions alt, MyActions, default-values

# SubStore
class SubStore extends BasicStore
    ->
        super ...
        @import-initial store, [\a,\b]

sub-store = alt.create-store SubStore

store.listen ->
    console.log "store:", it
sub-store.listen ->
    console.log "sub-store:", it

actions.set-store a:1
actions.set-store a:2
actions.set-store b:3
