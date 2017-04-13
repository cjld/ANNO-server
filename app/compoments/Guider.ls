require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
{MyComponent, MyCheckbox, MyDropdown, MyIdInput, MyIdInputs} = common


deep-copy = -> JSON.parse JSON.stringify it

require! {
    \./../models/Object : {object: my-object, seeker}
    \./../models/document
    \./Breadcrumb
    \mongoose
}

module.exports = class Guider extends React.Component
    ->
        super ...
        @state =
            *   ajaxing: false
                select-all-state: false
                # modal type, edit or add
                modalType: \add
                doc: new document {}, my-object
                is-admin: false

        store.connect-to-component this, [
            \currentItem
            \displayType
        ]

    componentDidMount: ->
        is-admin = false
        if $.cookie('user') == 'admin'
            @set-state is-admin: true
            is-admin = true
        self = this
        #dialog = $ \#addModal .dialog do
        #    auto-open: false
        #    modal: true
        dialog = $ \#addModal
        dialog.modal detachable:false

        upload-dialog = $ \#uploadModal
        upload-dialog.modal detachable:false
        @upload-progress = $('#upload-progress').progress();

        del-dialog = $ \#delModal
        del-dialog.modal do
            detachable:false
            on-approve: ~>
                {selects} = store.get-state!
                actions.deleteItems selects

        $ \#uploadForm .ajax-form do
            before-send: ->
                console.log \before-send

                self.upload-progress.progress 'set active'
                self.upload-progress.progress 'set label', "File is uploading..."
                self.upload-progress.progress percent:0
            upload-progress: (event, position, total, percentComplete) ->
                console.log &
                self.upload-progress.progress percent:percentComplete
            complete: (xhr) ->
                self.upload-progress.progress 'remove active'
                self.upload-progress.progress 'set label', "Complete"
                if xhr.statusText == 'OK'
                    toastr.success xhr.response-text
                    self.upload-progress.progress 'set success'
                    upload-dialog.modal \hide
                    actions.fetchContent!
                else
                    toastr.error xhr.response-text
                    self.upload-progress.progress 'set error'

        #$ \#uploadForm .submit ->
        #    $ \#status .empty!.text "File is uploading..."
        #    #$ this .ajax-submit do
        #    #    error: (xhr) ->
        #    #        toastr.error "Error: " + xhr.status
        #    #    success: (response) ->
        #    #        toastr.success response
        #    return false

        if is-admin
            $ \#addItemBtn .click ~>
                @set-state modalType:\add
                @origin-doc = {}
                dialog.modal \show

            $ \#uploadBtn .click ~>
                upload-dialog.modal \show
                $ \#upload-parent .val @state.currentItem?._id

            $ \#editItemBtn .click ~>
                {selects} = store.get-state!
                ids = Object.keys(selects)
                if ids.length == 0
                    item = @state.currentItem
                else if ids.length != 1
                    toastr.error "Please select only one item."
                    return
                else
                    item = store.get-state!.items[ids[0]]
                for k,v of item
                    # attribute selector
                    @state.doc[k] = v
                    dom = addItemForm.find "[name='#{k}']"
                    dom.val(v)
                @origin-doc = deep-copy @state.doc

                @set-state modalType:\edit
                @edit-id = item._id
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
        addItemForm.submit (e) ~>
            e.prevent-default!
            inputs = addItemForm.find \input
            textareas = addItemForm.find \textarea
            values = {}
            for input in inputs
                values[input.name] = $(input).val!
            for textarea in textareas
                values[textarea.name] = $(textarea).val!

            if self.state.modalType == \edit
                id = @edit-id
                unless id? then return
                values._id = id
            else
                fid = store.get-state!.fatherId
                if fid then values.parent = fid
                values._id = undefined
            doc = new document {}, my-object
            doc <<< @state.doc
            doc <<< values
            self.set-state ajaxing: true
            {selects} = store.get-state!
            ids = Object.keys(selects)
            if ids.length == 0
                self.state.currentItem <<< values
            doc-copy = deep-copy doc
            for k of doc-copy
                if k == \_id then continue
                if doc-copy[k] === @origin-doc[k]
                    doc-copy[k] = undefined
            $.ajax do
                method: \POST
                url: \/api/new-object
                data: JSON.stringify doc-copy
                contentType: "application/json"
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
        unless mainDescription? then mainDescription="No description."
        self = this
        displayBar = [ \grid \list \block ].map (it) ->
            ``<a
            className={"ui "+ (it==self.state.displayType?"active":"") +" item"}
            onClick={function(){actions.setStore({displayType:it})}}
            key={it}
            ><i className={it+" layout icon"}></i></a>
            ``
        availItems = []
        for key of my-object.tree
            unless key in seeker[@state.doc.type]
                continue
            if my-object.tree[key] == String or my-object.tree[key].type == String
                if key == 'marks' then continue
                if my-object.tree[key].enum
                    option = [{value: v} for v in that]
                if key == 'state'
                    valui = ``<MyDropdown name={key} options={option} data={this.state.doc.state}  dataOwner={[this, "doc.state"]}/>``
                else if key == 'type'
                    valui = ``<MyDropdown name={key} options={option} data={this.state.doc.type} dataOwner={[this, "doc.type"]}/>``
                else if key == 'config'
                    valui = ``<textarea type="text" name={key} placeholder={key}/>``
                else
                    valui = ``<input type="text" name={key} placeholder={key}/>``
            else if my-object.tree[key] == mongoose.Schema.Types.ObjectId or
                my-object.tree[key].type == mongoose.Schema.Types.ObjectId
                valui = ``<MyIdInput name={key} data={this.state.doc[key]} dataOwner={[this, "doc."+key]} />``
            else if key == \taskImages
                valui = ``<MyIdInputs name={key} data={this.state.doc[key]} dataOwner={[this, "doc."+key]} />``
            else continue
            availItems.push ``<div className="field" key={key}>
                <label>{key}</label>
                {valui}
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

        uploadModal = ``<div className="ui modal" id="uploadModal">
            <i className="close icon"></i>
            <div className="header">
                Upload Items
            </div>
            <div className="content">
            <form id="uploadForm"
            encType="multipart/form-data"
            action="/api/upload"
            method="post">
                <input type="file" name="userPhoto" multiple className="ui small button"/>
                <div className="ui hidden divider" />
                <input type="submit" value="Upload Image" name="submit" className="ui green button"/>
                <input type='text' id='upload-parent' name='parent' style={{display:'none'}} />
                <div className="ui hidden divider" />
                <div className="ui active progress" id="upload-progress">
                  <div className="bar">
                    <div className="progress"></div>
                  </div>
                  <div className="label"><span id = "status"></span></div>
                </div>
            </form>
            </div>
        </div>
        ``

        opClass = "ui disabled item"
        if @state.is-admin
            opClass = "ui item"

        ``<div>
        {delModal}
        {uploadModal}
        <div className="ui modal" id="addModal">
            <i className="close icon"></i>
            <div className="header">
                {this.state.modalType == "edit"?"Edit":"Add"}
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

                <div className={"ui right floated small menu"}>
                    <a className={opClass} id="selectAllBtn"><i className=
                    {self.state.selectAllState?"check circle icon":"check circle outline icon"}></i></a>
                    <a className={opClass} id="addItemBtn"><i className="green add circle icon"></i></a>
                    <a className={opClass} id="delItemBtn"><i className="red minus circle icon"></i></a>
                    <a className={opClass} id="editItemBtn"><i className="edit icon"></i></a>
                    <a className={opClass} id="uploadBtn"><i className="upload icon"></i></a>
                </div>

                <Breadcrumb/>

            </div>
            <div className="ui fitted hidden clearing divider"></div>
            <div className="ui vertical segment">
                <big>{mainDescription}</big>
            </div>
        </div>
        ``
