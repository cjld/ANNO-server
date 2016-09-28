require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

root-content =
    title: "Home"
    children: [
        *   title: "如何浏览图片"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/browser.ogv" style={{width:'100%'}}></video>
                </div>
                <p>在图片浏览界面，你可以通过点击图片进入图片标注编辑界面，也可以点击
                文件夹来打开文件。</p>
                <p>在导航栏的下方有显示父级元素的导航条，你可以通过这些链接来返回父级目录</p>
                <p>在浏览窗口下方有分页导航条，可以通过分页导航条切换分页</p>
                <p></p>
            </div>``
        *   title: "如何添加/删除图片"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/add_delete.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过点击工具栏的加减按钮来添加删除目标，你可以添加删除一个文件夹，或者添加删除一个图片</p>
            </div>``
        *   title: "如何浏览标注"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/browse_mark.ogv" style={{width:'100%'}}></video>
                </div>
                <p>在标注列表中点击标注的编号来浏览不同的标注。</p>
            </div>``
        *   title: "如何添加/删除标注"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/add_delete_mark.ogv" style={{width:'100%'}}></video>
                </div>
                <p>你可以使用add，delete按钮来添加删除标注，也可以通过快捷键a，d来删除添加</p>
            </div>``
        *   title: "如何使用Paint Selection工具"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/ps.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过快捷键5切换到Paint Selection工具</p>
                <p>快捷键z、x来放大缩小笔刷</p>
                <p>按住shift，光标变红，笔刷变为删除笔刷，可以删除选区</p>
            </div>``
        *   title: "如何使用Pan工具"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/pan.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过快捷键1切换到Pan工具，z、x放大缩小画布，鼠标移动来拖动画布</p>
            </div>``
    ]

module.exports = class Help extends React.Component
    ->
        super ...
        @state = stack:[]

    render: ->
        stack-s = [root-content]
        for i of @state.stack
            next = stack-s[i].children?[@state.stack[i]]
            if next?
                stack-s.push next
            else
                break
        stacks = []
        for i,node of stack-s
            cstack = @state.stack.splice 0, i
            goStack = -> @set-state stack:it
            goStack .= bind @, cstack
            stacks.push ``<a onClick={goStack}>{node.title}</a>``
            stacks.push ``<div className="divider">/</div>``
        stacks = ``<div className="ui breadcrumb">
            {stacks}
        </div>``
        var content
        if node.children?
            content = for i,c of node.children
                cstack = @state.stack.concat [i]
                goStack = -> @set-state stack:it
                goStack .= bind @, cstack
                ``<p key={i}><a onClick={goStack}>{c.title}</a></p>``
        else
            content = node.content
        return ``<div className="ui container">
            {stacks}
            <div className="ui divider"></div>
            {content}
        </div>``
