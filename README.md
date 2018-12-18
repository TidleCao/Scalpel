# Scalpel
Scalpels是一款集动态库注入与删除、IPA元数据修改、重签名功能为一体的MacOS应用，旨在为您提供贴心的一条龙服务。

[Scalpel的实现](https://blog.csdn.net/jerryandliujie/article/details/84845162)
# 环境
Xcode10.1<br/>
Swift 4.0<br/>
MacOS 10.12+

# 功能介绍
### 1、动态库注入与删除
当添加动态库时，你需要进以下设置：
* **选择一个待添加的动态库**： 你可以选择```framework```或其他任何文件作为动态库，Scalpel不会对你选择的文件做后缀检查，因为可能出于某些目的，你需要对文件名做一些混淆，比如你可能给某个动态库起名叫Button.png等等（唯一要注意的是，如果你选择的是 framework ，那么请不要更改它的后缀，因为Scalpel需要对framework做特殊处理）。

* **设置包内存放路径**：此处用于设置添加的动态库在包内存放的路径，是相对路径，不可以以'/'开头，你可以设置任何带目录的路径，比如：a/b/c/d.dylib, Scalpel 将会自动为你创建不存在的目录。

设置完成后，Scalpel 将会在App的Mach-O（executable文件）文件中添加一条Dylib Link，比如: @executable_path/a/b/c/d.dylib（你可以使用 otool -L 命令查看Mach-O文件link的所有动态库）, 所有使用Scalpel添加的Dylib Link都会采用@executable_path开头的形式。<br/>

##### 示例：
![image](https://raw.githubusercontent.com/cjsliuj/ScalpelDocResource/master/DylibLinkAddExample.gif)

### 2、IPA元数据修改
目前，可以修改的IPA元数据有下面几种：
* 版本号
* App名称
* 添加额外的资源文件
* 删除 Nested Apps (Extension)

##### 操作面板：
![image](https://raw.githubusercontent.com/cjsliuj/ScalpelDocResource/master/IpaMetaDataEditTab.png)

### 3、重签名
你需要进行以下操作以完成重签名所需的相关信息设置：
* **选择一个mobileprovision 文件**： 最简单的情况下，你只需要选择完 mobileprovision 文件即可完成重签名配置。
* **选择一个签名证书**：如果你选择的 mobileprovision 文件中有多个证书，你可以在此处选择你想用于签名的证书(默认会选中 mobileprovision 中的第一个证书)。
* **选择一个BundleID策略**： 
    * **保持不变**： 当选择该策略时，BundleID将不会发生改变。

    * **与mobileprovision保持一致**： 当选择该策略时，App的BundleID将会根据 mobileprovision 中的BundleID进行设置（Entitlements -> application-identifier字段中的那个BundleID）。
    根据该BundleID是否是wildcard形式采取下面两种不同的设置方案：
	    * **是 Wildcard 形式**：
		 如果原始BundleID与 mobileprovision内BundleID匹配，那么保持原始BundleID不变。
		 如果原始BundleID与 mobileprovision内BundleID不匹配，那么会采用 mobileprovision内BundleID，并使用随机字符串替换其通配位。
	    * **是 Explicit 形式**：
		 如果原始BundleID与 mobileprovision内BundleID匹配，那么保持原始BundleID不变。
		 如果原始BundleID与 mobileprovision内BundleID不匹配，那么修改为mobileprovision内BundleID。

        **上述逻辑示例:**

        原始BundleID | Mobileprovision BundleID |  是否匹配 | 最终BundleID | 备注
        ---|---|---|---|---
        com.cn.test |  com.cn.test | ✅| com.cn.test|使用原始BundleID
        com.cn.test | com.cn.hi| ❌| com.cn.hi|使用Mobileprovision BundleID
        com.cn.test | com.cn.* | ✅| com.cn.test|使用原始BundleID
        com.cn.test | com.*.hi | ❌| com.foobar.hi|使用Mobileprovision BundleID，通配位上使用随机字符串(foobar是一个随机的任意字符串)。


* **Nested App 配置：** 此处用于给 Nested App(Extension)配置签名用的 mobileprovision 文件，该mobileprovision文件中的BundleID务必是要以主App的BundleID为前缀的(如果你是一个iOS开发者，你应该会很清楚的这一点)。当然， 如果你觉得Nested App对你没什么用处，那你可以在**元数据修改 Tab**中将相应的**Nested App**删除，这样就不需要给**Nested App**配置 mobileprovision 文件了。

##### 操作面板：
![image](https://raw.githubusercontent.com/cjsliuj/ScalpelDocResource/master/ResignConfigTab.png)
