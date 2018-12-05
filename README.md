# Scalpel
这是一个集动态库注入与删除、Ipa元数据修改、重签名为一体的MacOS应用，旨在为您提供贴心的一条龙服务。

# 运行环境
Xcode10.1
Swift 4.0
MacOS 10.12+

#功能介绍
### 动态库注入与删除
你可以添加或删除Macho Link的动态库，当注入动态库时，你需要进行两步操作:
* '动态库'选择: 你可以选择framework或其他任何文件作为动态库，Scalpel不会对你选择的文件做后缀检查，因为可能出于某些目的，你需要对文件名做一些混淆，比如你可能给某个动态库起名叫BlueButton.png等等（唯一要注意的是，如果你待注入的是 framework ，那么请不要更改它的后缀，因为Scalpel会对framework做特殊处理）。
* '包内存放路径'设置: 此处是用于设置你选择的动态库在包内存放的路径，该出是一个相对路径，所以不可以以'/'开头，你可以设置任何带目录的路径,比如:a/b/c/d.dylib, Scalpel 将会自动为你创建不存在的目录。
最终，操作完这两步后，Scalpel 将会在App的Macho（executable文件）文件中添加一条dylib link，比如: @executable_path/a/b/c/d.dylib, Scalpel会为所有注入的dylib link使用@executable_path开头的形式。
演示图:

### Ipa元数据修改
目前，可以修改如下信息:
版本号
App名称
添加额外的资源文件
删除 Nested Apps (Extension)

### 重签名
'mobileprovision 文件选择': 最简单的情况下，你只需要选择 mobileprovision 文件即可完成重签名配置。
'证书选择': 如果你选择的 mobileprovision 文件中有多个证书，你可以在此处选择你想用于签名的证书(默认会选中 mobileprovision 中的第一个证书)。
'BundleID策略' 选择栏: 对于BundleID的修改策略，目前提供了下面两种方案：
* 保持不变: 当选择该策略时，BundleID将不会发生改变。

* 与mobileprovision保持一致: 当选择该策略时，App的BundleID将会根据 mobileprovision 中 'Entitlements -> application-identifier'字段中包含的那个BundleID进行设置。分为以下几种情况:
	* BundleID是 wildcard 形式的:
		 如果原始BundleID与 mobileprovision内BundleID匹配，那么保持原始BundleID不变。
		 如果原始BundleID与 mobileprovision内BundleID不匹配，那么会采用 mobileprovision内BundleID，并在其通配位上随机一串字符。
	* BundleID是 exlicard 形式的:
		 如果原始BundleID与 mobileprovision内BundleID匹配，那么保持原始BundleID不变。
		 如果原始BundleID与 mobileprovision内BundleID不匹配，那么修改为mobileprovision内BundleID。

用一个图表示例:
xxx

'Nested App'配置: 此处用于给 Nested App配置签名用的 mobileprovision 文件，该mobileprovision文件中的BundleID务必是要以主App的BundleID为前缀的(如果你是一个iOS开发者，你应该会很清楚的这一点)。当然， 如果你觉得Nested App对你没什么用处，那你可以在'元数据修改'tab中将相应的'Nested App'删除，这样就不需要给'Nested App'配置mobileprovision 文件了。




