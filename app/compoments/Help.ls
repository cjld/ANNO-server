require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

configDemoStr = '''
{
    "autoType": true,
    "allowedOverlap": false,
    "types": [
        {
            "description": "人像",
            "types": [
                {
                    "title": "主播人像",
                    "color": "#00EC8B"
                },
                {
                    "title": "遮挡物",
                    "color": "#FFC125"
                },
                {
                    "title": "其他-x"
                }
            ]
        }
    ]
}
'''

root-content =
    title: "Home"
    url: ""
    children: [
        *   title: "如何构建自己的数据集"
            url: "dataset"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="" style={{width:'100%'}}></video>
                </div>
                <p>第一步：创建数据集文件夹</p>
                <p>第二步：填写数据集配置文件，设置标注类别。</p>
                <p>第三步：上传图片到数据集文件夹，如果需要可以在数据集文件夹下创建子文件夹。</p>
                <p></p>
            </div>``
        *   title: "如何填写数据集配置文件"
            url: "config"
            content: ``<div>
                <p>一个配置文件实例</p>
                <pre>{configDemoStr}</pre>
                <p>配置文件包含的key：autoType, allowedOverlap, types</p>
                <p>types: 描述了所有的类别，types对应的key是一个数组，代表了有多少个大类。
                每个大类有两个key， description和types，分别代表大类的描述和所有小类。
                每个小类有三个key，title，color，src，其中title代表了类别名，如果你的类别
                名包含有"-x"的后缀名，那么代表这个类别还需要一个额外的输入信息，比如某些限速标志，对于不同速度的限速
                标志pl15,pl40,pl60,您可以声明title为pl-x，这样当用户选择这个类别的时候，会要求额外输入一个字符串信息，
                color代表了这个
                类别在绘制的时候使用的颜色，可以不填，src代表了这个类别的图标，可以不填。</p>
                <p>autoType：在编辑器工作的时候是否开启自动类别，是一个为了方便标注人员标注的选项，
                开启时会自动将新建的标注按顺序赋予类别</p>
                <p>allowedOverlap: 在使用PaintSelection时是否允许不同类别之间产生重叠</p>
                <p>autosaveInterval: 自动保存的间隔，默认5000，单位毫秒</p>
                <p>showMark: 是否显示包围盒和类别，默认为true</p>
                <p>autobox: 是否自动计算包围盒，默认为true</p>
                <p>hideImage: 是否隐藏图片，默认为false</p>
                <p>hideAnnotation: 是否隐藏标注，默认为false</p>
                <p>editMode: 初始使用的工具，默认为ps，paint selection工具，可选工具有[spotting, segment, pan, paint, ps, box]</p>
            </div>``
        *   title: "如何浏览图片"
            url: "browser"
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
            url: "newimage"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/add_delete.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过点击工具栏的加减按钮来添加删除目标，你可以添加删除一个文件夹，或者添加删除一个图片</p>
            </div>``
        *   title: "如何浏览标注"
            url: "browsemark"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/browse_mark.ogv" style={{width:'100%'}}></video>
                </div>
                <p>在标注列表中点击标注的编号来浏览不同的标注。</p>
                <p>按下键盘上的n键或者点击工具栏的next按钮来切换浏览不同的图片</p>
            </div>``
        *   title: "如何添加/删除标注"
            url: "newmark"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/add_delete_mark.ogv" style={{width:'100%'}}></video>
                </div>
                <p>你可以使用add，delete按钮来添加删除标注，也可以通过快捷键a，d来删除添加</p>
                <p>标注如果完成，你可以点击上方的annotated绿色按钮，表示标注已经完成</p>
                <p>如果你是检查人员，你可以通过下方的navigation来浏览所有标注好的或者是没有标注好的图片，如果
                存在标注问题，你可以点击issued黄色按钮表示该图片存在问题。</p>
            </div>``
        *   title: "如何使用Paint Selection工具"
            url: "paintselection"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/ps.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过快捷键5切换到Paint Selection工具</p>
                <p>快捷键z、x来放大缩小笔刷</p>
                <p>鼠标滚轮放大缩小画布</p>
                <p>按住shift，光标变红，笔刷变为删除笔刷，可以删除选区</p>
                <p>按住空格键可以切换回pan工具，用于拖动画布</p>
            </div>``
        *   title: "如何使用Pan工具"
            url: "pan"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="/video/pan.ogv" style={{width:'100%'}}></video>
                </div>
                <p>通过快捷键1切换到Pan工具，z、x放大缩小画布，鼠标移动来拖动画布，滚轮缩放画布，按住空格可以临时切换回pan工具</p>
            </div>``
        *   title: "如何使用BoundingBox工具"
            url: "bbox"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="" style={{width:'100%'}}></video>
                </div>
                <p>BoundingBox是用于标注物品包围盒的工具，每一个标注可以拥有一个包围盒。</p>
                <p>通过快捷键3切换到BoundingBox工具，鼠标点击拖动即可绘制出包围盒，鼠标位于包围盒的
                边缘可以改变大小，位于包围盒中间可以拖动包围盒，按下shift键加鼠标点击可以删除包围盒</p>
            </div>``
        *   title: "如何使用Spotting工具"
            url: "bbox"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="" style={{width:'100%'}}></video>
                </div>
                <p>Spotting是用于标注物品中心位置的工具，每一个标注可以拥有多个位置。</p>
                <p>通过快捷键2切换到Spotting工具，鼠标点击新建点，鼠标拖动可以改变点的位置，按下shift键加鼠标点击可以删除点</p>
            </div>``
        *   title: "如何使用Segmentation工具"
            url: "bbox"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="" style={{width:'100%'}}></video>
                </div>
                <p>Segmentation是用于标注物品的多边形轮廓的工具，每一个标注可以拥有一个或者多个多边形轮廓。</p>
                <p>通过快捷键4切换到Segmentation工具，鼠标点击即可绘制出多边形的各个点，ctrl加鼠标点击可以新建
                一个多边形。
                shift加鼠标点击可以删除多边形或者多边形的某一个顶点，鼠标点击多边形的边缘可以增加多边形的顶点。</p>
            </div>``
        *   title: "快捷键一览"
            url: "shortcut"
            content: ``<div>
                <div className="ui segment">
                    <video controls="controls" src="" style={{width:'100%'}}></video>
                </div>
                <p>z/x: 放大缩小笔刷（free paint模式或者paint selection模式），或者放大缩小画布</p>
                <p>a/d: 添加/删除标注</p>
                <p>n/p: 下一张/上一张图片</p>
                <p>123456：切换使用不同的工具</p>
                <p>方向键上/方向键下: 上一个标注/下一个标注</p>
                <p>h：打开帮助</p>
                <p>t：类型选择</p>
                <p>q/w/e：标记此张图片为：已标注完成/未标注/标注存在问题</p>
                <p>s:保存标注</p>
                <p>v:隐藏/显示图片</p>
                <p>b:隐藏/显示标注</p>
                <p>鼠标左键点击：选择标注, 需要标注物体存在包围盒，可以配合勾选auto boundingbox 使用</p>
                <p>shift+鼠标左键，删除标注</p>
                <p>ctrl+鼠标左键，添加标注（segment模式下）</p>
                <p>按住空格：切换回pan工具，可以拖动画布</p>
            </div>``
    ]

module.exports = class Help extends React.Component
    ->
        super ...
        @state = stack:[]

    get-stack: (node, helpUrl) ->
        if helpUrl == undefined or helpUrl == ""
            return []
        for i,c of node.children
            if c.url == helpUrl
                return [i]
            res = @get-stack c, helpUrl
            if res
                return [i].concat res
        return false

    goStack: ->
        if @helpPage
            node = root-content
            for i in it then node = node.children[i]
            myhistory.push "/help/#{node.url}"
        else
            @set-state stack:it

    render: ->
        if @props.params?
            @state.stack = @get-stack root-content, @props.params.helpUrl
            if @state.stack == false then @state.stack = []
            @helpPage = true
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
            go = @goStack.bind @, cstack
            stacks.push ``<a key={i+'1'} onClick={go}>{node.title}</a>``
            stacks.push ``<div key={i+'2'} className="divider">/</div>``
        stacks = ``<div className="ui breadcrumb">
            {stacks}
        </div>``
        var content
        if node.children?
            content = for i,c of node.children
                cstack = @state.stack.concat [i]
                go = @goStack.bind @, cstack
                ``<p key={i}><a onClick={go}>{c.title}</a></p>``
        else
            content = node.content
        return ``<div className="ui container">
            {stacks}
            <div className="ui divider"></div>
            {content}
        </div>``
