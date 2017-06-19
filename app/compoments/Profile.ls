require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! {
    \owasp-password-strength-test : owasp
    \../history : myhistory
}


owasp.config do
    maxLength              : 128,
    minLength              : 7,
    minOptionalTestsToPass : 1

module.exports = class Profile extends React.Component
    ->
        super ...
        @state = { passwordError: "" }
        @state.otherProfile = null
        @state.tasklist = undefined
        store.connect-to-component this, [\userProfile]

    submit: ~>
        data = $ @form .serializeArray!
        data2 = {}
        ps = ""
        for kv in data
            if kv.value == "" then continue
            if kv.value == @state.userProfile[kv.name]
                continue
            if kv.name == \password or kv.name == \password2 or kv.name == \oldpassword
                ps = kv.value
                kv.value = md5 ps
            data2[kv.name] = kv.value
        if ps != ""
            if data2["password"] != data2["password2"]
                @set-state passwordError: "Two password different."
                return false
            result = owasp.test ps
            if not result.strong
                @set-state passwordError: result.errors.join("\n")
                return false
            else
                @set-state passwordError: ""
        $.ajax do
            method: \POST
            url: \/api/edit-profile
            data: data2
            success: ->
                toastr.success "Edit profile successful."
                actions.set-store userProfile: it
            error: (e)->
                toastr.error "Edit profile error: "+e.response-text
        return false

    fetchTask: (id) ->
        if not id or @state.tasklist
            return
        $.ajax do
            method: \POST
            url: \/api/find-objects
            data: worker:id, type:\directory
            success: ~>
                @set-state tasklist: it


    componentDidMount: ->
        @form = $ "form" .0
        @form?onsubmit = @submit

        if @props.location.query.uid
            $.ajax do
                method: \POST
                url: \/api/profile
                data: uid:@props.location.query.uid
                success: ~>
                    @set-state otherProfile:it
                error: (e)->
                    toastr.error "Load profile error: "+e.response-text
            @fetchTask @props.location.query.uid
        else if @state.userProfile
            @fetchTask @state.userProfile.id

    componentDidUpdate: ->
        @form = $ "form" .0
        @form?onsubmit = @submit
        if @state.userProfile and not @props.location.query.uid
            @fetchTask @state.userProfile.id

    componentWillUnmount: ->

    render: ->
        if not @state.userProfile
            return ``<div className="ui padded text container segment">
                <div className="ui header"> Please login first </div>
            </div>``
        errc = ""
        userProfile = @state.userProfile
        if @state.otherProfile
            userProfile = that
        if not @state.otherProfile or @state.userProfile.is-admin
            billing = ``<div>
                <h4 className="ui dividing header">Billing info</h4>
                <div className="field">
                    <label>Real Name(真实姓名)</label>
                    <input type="text" name="realName" placeholder="" defaultValue={userProfile.realName}/>
                </div>
                <div className="field">
                    <label>ID Number(身份证号)</label>
                    <input type="text" name="idNumber" placeholder="" defaultValue={userProfile.idNumber}/>
                </div>
                <div className="field">
                    <label>Card Number(银行卡号)</label>
                    <input type="text" name="cardNumber" placeholder="" defaultValue={userProfile.cardNumber}/>
                </div>
                <div className="field">
                    <label>Bank(开户行)</label>
                    <input type="text" name="bank" placeholder="" defaultValue={userProfile.bank}/>
                </div>
            </div>``
        if @state.passwordError
            errc = " error"
            errorMsg = ``<div className="ui error message">
                    <div className="header">Action Forbidden</div>
                    <pre>{this.state.passwordError}</pre>
                </div>``
        if @state.tasklist
            tasklist = for task,i in @state.tasklist
                ``<li key={i}><Link to={"/i/"+task._id}>{task.name}</Link></li>``
            mytask = ``<div>
                <div className="ui header"> Tasks </div>
                <ul className="ui list">
                    {tasklist}
                </ul>
            </div>``
        return ``<div className="ui padded text container segment" key={userProfile.id}>
            {mytask}
            <div className="ui header"> Profile </div>
            <div className="ui divider"></div>
            <form className={"ui form"+errc}>
                <div className="field">
                    <label>ID</label>
                    <input type="text" name="id" placeholder="" value={userProfile.id} readOnly />
                </div>
                <div className="field">
                    <label>Email</label>
                    <input type="text" name="email" placeholder="" value={userProfile.email} readOnly />
                </div>
                <div className="field">
                    <label>Name</label>
                    <input type="text" name="name" placeholder="" defaultValue={userProfile.name}/>
                </div>
                {billing}
                <div style={{display: this.state.otherProfile?"none":"block"}}>
                    <h4 className="ui dividing header">Change password</h4>
                    <div className="field">
                        <label>Old password</label>
                        <input type="password" name="oldpassword" placeholder="" />
                    </div>
                    <div className="field">
                        <label>New password</label>
                        <input type="password" name="password" placeholder="" />
                    </div>
                    <div className="field">
                        <label>New password again</label>
                        <input type="password" name="password2" placeholder="" />
                    </div>
                    {errorMsg}
                    <button className="ui green button" type="submit">Change Profile</button>
                    <h4 className="ui dividing header">Google acccount</h4>
                    {userProfile.googleId ?
                        <div className="field">
                            <label>Google ID</label>
                            <input type="text" name="googleId" placeholder="" value={userProfile.googleId} readOnly/>
                        </div>
                    :
                      <button type="button" className="ui google plus button" onClick={()=>location.href = "/api/auth/google"}>
                        <i className="google icon"></i>
                        Link with Google
                      </button>
                    }
                </div>
            </form>
        </div>``
