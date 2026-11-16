# SciToolbox — macOS 科研数据检索工具箱

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23053444.svg)](https://doi.org/10.5281/zenodo.23053444)

> 本应用仅供学习交流，不提供任何形式的商业服务。使用者需自行确保其使用行为符合当地法律法规。

> 开源发布的科研检索工具，欢迎使用与反馈。不登录、不采集任何用户个人数据。

> 原生 SwiftUI macOS 应用，聚合 15 个公开学术数据库，一站式检索；内置离线生物信息学工具箱。

> 当前版本：**1.0.0**

## 功能概览

### 15 个数据源

| 分类 | 工具 | 数据来源 |
| --- | --- | --- |
| 分类与物种 | GTDB 官方分类 | gtdb-api.ecogenomic.org |
| 分类与物种 | NCBI 分类检索 | eutils.ncbi.nlm.nih.gov |
| 分类与物种 | BacDive 菌株 | api.bacdive.dsmz.de |
| 分类与物种 | MGnify 微生物组 | www.ebi.ac.uk/metagenomics |
| 分类与物种 | GBIF 物种 | api.gbif.org |
| 基因与序列 | NCBI 基因/序列 | eutils.ncbi.nlm.nih.gov |
| 基因与序列 | Ensembl 基因 | rest.ensembl.org |
| 蛋白与结构 | UniProt 蛋白质 | rest.uniprot.org |
| 蛋白与结构 | RCSB PDB 结构 | data.rcsb.org |
| 蛋白与结构 | AlphaFold 结构 | alphafold.ebi.ac.uk |
| 蛋白与结构 | Pfam / InterPro | www.ebi.ac.uk/interpro |
| 功能与通路 | KEGG 在线检索 | rest.kegg.jp |
| 功能与通路 | GO 术语查询 | www.ebi.ac.uk/QuickGO |
| 文献 | PubMed 文献 | eutils.ncbi.nlm.nih.gov |
| 文献 | Europe PMC 文献 | www.ebi.ac.uk/europepmc |

### 本地工具（离线可用）

- **反向互补**：DNA 序列反向互补计算，支持简并碱基（R/Y/N 等）
- **GC 含量**：快速计算序列 GC 比例，自动忽略非 ACGT 字符
- **翻译（蛋白质）**：DNA → 氨基酸翻译，支持标准 / 细菌密码子表、多阅读框
- **序列比对**：Needleman-Wunsch 全局比对 + Smith-Waterman 局部比对，纯本地离线计算
- **蛋白理化性质**：分子量、理论等电点（pI）、消光系数（ε₂₈₀）计算
- **FASTA 重排**：序列按指定宽度换行、去重
- **批量识别**：粘贴多行 Accession，批量路由到对应数据库
- **文件解析**：导入 FASTA / FASTQ / GenBank / GFF3 文件，自动解析并生成结构化详情（离线）
- **结果集**：保存搜索结果为命名结果集，支持集合运算（并集 / 交集 / 差集）
- **结果统计**：Swift Charts 可视化结果集的来源分布与年份分布
- **本地搜索**：SQLite FTS5 全文检索收藏 / 集合 / 结果集（断网可用）

### 系统集成

- **URL Scheme**：`scitoolbox://` 协议支持从浏览器或其他 App 直接跳转搜索 / 识别 / 打开本地工具
- **Spotlight 索引**：本地收藏与集合自动索引至系统 Spotlight，全局搜索可检索
- **文件关联**：双击 .fasta / .fa / .fastq / .fq / .gb / .gff3 文件直接在 SciToolbox 中打开
- **系统服务菜单**：任意 App 中选中文本 → 右键「Identify in SciToolbox」直接识别
- **剪贴板监控**：自动检测剪贴板中的 Accession 编号，一键识别
- **Dock 菜单**：Dock 右键菜单快速新建窗口 / 显示主窗口
- **数据备份与恢复**：一键备份全部本地数据（收藏 / 集合 / 结果集 / 导入文件 / 历史），支持 JSON 导入恢复

### 核心特性

- **极简设计**：纯色背景、细线分割、大留白、零阴影的克制美学；详情栏随数据库分类色浸染（五色视觉签名）
- **侧边栏重构**：分组化布局（分类色圆点+大写标题），子项缩进；模块主题色图标（分类与物种=蓝、基因与序列=绿、蛋白与结构=橙、功能与通路=青、文献=紫）；选中态左侧 3px 品牌色竖线+浅色背景+文字/图标变主题色；鼠标悬浮圆角背景；键盘焦点环
- **品牌头部**：侧边栏顶部展示渐变色 Logo + "SciToolbox" 文字标识（渐变色统一使用 Theme.brandGradient 令牌）
- **三栏布局**：侧边栏（工具导航）→ 中栏（首页概览 / 搜索 + 结果列表）→ 右栏（详情），各栏可独立调整宽度
- **首页概览**：中栏首页改为概览/启动台（最近查询、收藏、分类浏览），点击分类可下钻到该分类工具列表；左栏为唯一常驻工具导航，全局工具搜索由 ⌘K 承担
- **搜索框自动聚焦**：打开工具或跨库跳转后，搜索框自动获得焦点（仅首次进入时，避免反复切换抢焦点），省去一次点击
- **中栏选中高亮**：点击结果后，中栏当前条目高亮显示（左侧分类色条+浅色底色），高亮色与分类色体系一致；结果行支持 hover 悬浮态、键盘焦点环与行内「加入集合」快捷入口
- **面包屑导航**：跨库互链 / 侧边栏切换均保留上一跳上下文，右栏顶部常驻面包屑路径与「返回」按钮（返回时恢复上一工具检索词）；详情浏览历史（⌘[ / ⌘]）与跨库面包屑并存
- **侧边栏折叠与隐藏**：分类 / 收藏 / 其他分组标题可点击折叠（A1）；⌘\ 一键显示 / 隐藏侧边栏，偏好跨会话记忆（P2-11）
- **冷启动引导**：首次启动显示「快速上手」速览卡（智能识别 / 全库搜索 / 跨库互链 / ⌘K / 项目集合），可关闭并在设置中重看
- **⌘K 命令面板**：随时按 ⌘K 输入工具名直达，15 个库键盘切换零摩擦；支持 ↑↓ 方向键光标导航+高亮行+Enter 选定；无呈现动画（高频操作零延迟），Escape 键关闭
- **全局按压反馈**：所有按钮按下时 scale(0.97) + easeOut(120ms) 微缩反馈，尊重 Reduce Motion 设置
- **详情状态过渡**：详情栏加载/结果/错误/空状态之间交叉淡入（easeOut 200ms），消除突兀跳变
- **查询历史**：纯本地存储最近查询，按工具分组展示，最多保留 200 条，一键重查
- **本地收藏**：详情页可收藏条目，纯本地存储、可导出为文本/JSON
- **分页加载**：UniProt / PubMed / PDB 支持加载更多，突破 30 条限制
- **PubMed 结果筛选**：搜索栏下方提供全部时间 / 近2年 / 近5年 / 近10年四档药丸式筛选（轻量自定义按钮，替代突兀的分段控件），切换即重新检索
- **KEGG 智能检索**：根据输入自动识别数据库类型（KO/通路/化合物/酶/模块/疾病/药物/基因组），无需手动选择
- **直连公开 API**：无需云函数代理，原生 HTTP 直连各数据库
- **深色模式**：跟随系统自动切换；分类色在深色模式下自动提亮以确保 WCAG AA 对比度
- **结果缓存**：磁盘级 TTL 缓存，降低重复请求
- **超时重试**：指数退避重试策略（超时/429/5xx），请求超时 15s
- **NCBI 节流**：对 NCBI E-utilities 强制 3 秒最小请求间隔，避免触发 429 速率限制
- **离线检测**：NWPathMonitor 实时监控网络状态，断网时显示顶部橙色警告条（WCAG AA 对比度），搜索前置拦截
- **搜索竞态防护**：搜索和详情请求均支持 Task 取消，防止快速连续点击时旧结果覆盖新结果
- **筛选防抖**：首页工具筛选输入后延迟 500ms 触发，避免逐字过滤卡顿
- **空结果引导**：搜索无结果时显示"未找到与「关键词」相关的结果，建议检查拼写或更换关键词重试"
- **跨库互链**：详情页可跳转到相关数据库（UniProt↔PDB/Pfam/GO/PubMed/Ensembl/AlphaFold 等双向互链）
- **序列导出**：FASTA 格式复制
- **引用导出**：BibTeX + RIS 格式复制（PubMed、Europe PMC）
- **Accession 智能识别路由**：首页「智能识别」框与搜索框「识别」按钮，粘贴 P12345 / 1ABC / 基因符号 / DOI / GO / ENS / PF / K / TaxID 等，自动判断类型并路由到对应数据库；置信度足够高时直接跳转，存在歧义时弹窗让你选择目标库
- **全库搜索（1.9.0）**：首页新增「全库搜索」框，一个关键词并行检索全部 15 个数据库，结果按五大分类分组呈现（含命中数与单库打开入口）；单库失败不影响其他库
- **详情浏览历史（1.9.0）**：同库 / 跨库预览的详情浏览自动入栈，⌘[ / ⌘] 或面包屑上的 ←/→ 在条目间回溯；跨库互链支持 ⌘点击「仅预览详情」，不离开当前列表
- **⌘K 带查询直达（1.9.0）**：命令面板支持 `uniprot:P12345` 或 `P12345 @uniprot` 语法，选中后一并携带查询词；新增 ⌘F 一键聚焦搜索框 / 首页智能识别框
- **破坏性操作护栏（1.9.0）**：清空历史 / 收藏 / 缓存 / 删除集合均二次确认（附明确数量）；单条删除收藏 / 历史 / 集合实体改为「删除 + 可撤销 Toast」；设置新增「导出全部本地数据（含集合）」与「重置应用」
- **备注系统（1.9.0）**：收藏项、集合、集合实体均可添加 / 编辑备注（详情页星标旁、收藏夹行内、集合「…」菜单、实体行内），导出文本 / JSON 已含 note 字段
- **批量核对重构（1.9.0）**：「对比 / 批量查询」更名为「批量核对 / 重新拉取」，逐项状态（等待 / 加载 / 成功 / 失败）+ 总体进度条 + 失败行单条重试；含 NCBI 条目时预估耗时提示
- **错误恢复（1.9.0）**：搜索 / 详情错误态一键「重试」；空结果引导提供「在所有数据库中搜索」；顶部「检索范围」与「本地过滤（仅已加载 N 条）」语义分离，过滤激活时提示「加载更多已暂停」
- **键盘体系（1.9.0）**：结果列表 ↑/↓ 方向键移动并联动详情（搜索框聚焦时不抢占）；⌘\ 显示 / 隐藏侧边栏；帮助菜单与首页提供「键盘快捷键」速查（⌘/）；侧边栏分组可折叠，分类叠加单字缩写标签（分/基/蛋/功/文，色觉障碍友好）
- **细节打磨（1.9.0）**：详情加载保留旧内容做骨架过渡（不再闪空）；外部链接安全渲染（消除强制解包崩溃风险）；超长 KV 字段可展开；导出按扩展名选择正确文件类型（json/csv）；NCBI 限速排队提示；缓存命中提示；复制结果校验
- **跨库并排对比（1.10.0，C10）**：从结果行 hover「加入对比」或详情页头部「加入对比」（最多 4 条），详情栏顶部常驻对比工具栏（对比数 / 查看对比 / 清空）；进入对比模式后以并排表格逐字段对照多条跨库条目，点击任一列可在详情栏单独打开该条目（自动退出对比）
- **跨库字段对齐（1.10.0，C11）**：统一抽取对比字段——名称 / 来源库 / 分类 / 物种描述作为固定对齐列，各库首个详情分区的属性行以 `attr:` 前缀统一呈现，解决不同库字段命名不一致导致的逐项对照困难；不改动任何 Provider，对齐逻辑收敛于 `DetailModel` 层
- **首页头部上移（1.10.0）**：侧边栏「SciToolbox」标题与各库数量说明小字调整至搜索框上方，层级更清晰
- **NCBI 基因/序列图标修复（1.10.0）**：原 `dna` 非 SF Symbols 目录内符号（仅 emoji），不可见；改为 `flask`，侧边栏与详情头部图标恢复正常显示
- **结果批量操作**：搜索结果进入多选模式后，可批量复制编号列表、批量收藏、批量加入集合、一键导出为 CSV 表格
- **引用导出（写文件）**：PubMed / Europe PMC 详情页在原有「复制 BibTeX / RIS」基础上，新增「导出 BibTeX / 导出 RIS」，经保存面板写入本地文件（引用格式支持 EndNote / Mendeley / Zotero 等）
- **项目集合（课题）**：侧边栏新增「项目集合」，把一组相关 accession / 基因 / 文献组织成课题维度；支持从结果多选、详情页或结果行 hover 快捷加入、CSV / JSON 导出、批量核对（逐一重新拉取并汇总成表，离线失败时回退显示留痕）
- **结构预览**：PDB / AlphaFold 详情页展示静态结构图，加载失败时显示占位图，深色模式兼容
- **无障碍标签**：图标按钮均添加 accessibilityLabel，VoiceOver 友好；结果行、工具行、侧栏项均为原生 Button 并具备键盘焦点环；显式尊重系统 Reduce Motion 设置；hover 动画统一检查 reduceMotion
- **WCAG AA 对比度**：全应用文本对比度满足 WCAG AA 标准；`ink4` 严格限定为装饰性元素（分隔线、箭头图标），不用于传达信息的文本或交互元素；`ink2`(0.75) 与 `ink3`(0.55) 拉开层级差距
- **磁盘缓存异步化**：缓存读写均为异步 IO，避免同步磁盘操作阻塞协作线程
- **应用图标**：自定义 Logo（渐变底 + 烧瓶 + 原子轨道），全尺寸 icns
- **.app 打包**：一键生成原生 macOS 应用包
- **中英文双语切换（1.12.0）**：设置页新增语言切换器，支持中文/English 一键切换，全程即时生效（侧边栏、搜索、详情、收藏、集合、设置等所有界面文本均本地化）；相对时间格式（如「3分钟前」「3 hours ago」）随语言自动切换；语言偏好持久化存储，跨会话记忆
- **UI 细节打磨（1.0.0）**：项目集合与跨库对比的全部文案补齐双语；切换语言主窗口即时刷新；全局按钮禁用态变暗提示；破坏性操作统一 `semanticError` 配色；集合列表整行可点击并带 hover 高亮；VoiceOver 标签补齐本地化
- **首页工作台（1.0.0）**：首页新增快捷动作区（本地工具入口 / 导入文件 / 智能识别）与示例数据一键加载，降低新用户上手门槛
- **离线引导（1.0.0）**：首次启动展示三步引导卡（数据源概览 / 本地工具 / 系统集成），可在设置中重看

## 环境要求

- macOS 15.0+（开发机为 macOS 26）
- Swift 6.0+（命令行工具或 Xcode）
- 运行测试需安装完整 Xcode（命令行工具不含 XCTest）

## 构建与运行

### 快速启动

```bash
cd SciToolbox
./run.sh run
```

### 手动构建

```bash
# 调试构建
swift build

# 运行
swift run SciToolbox

# 发布构建
swift build -c release
# 运行发布版本
.build/release/SciToolbox
```

### 打包为 .app 应用

```bash
# 一键打包（编译 release + 组装 .app）
./run.sh app

# 打包并安装到 /Applications
./run.sh install
```

生成的 `.app` 位于 `build/SciToolbox.app`，可直接双击打开，也可拖入 `/Applications`。

### 运行解析测试

```bash
# 需安装完整 Xcode（swift test 依赖 XCTest）
swift test
```

测试覆盖 71 个用例：样例 JSON 解析（UniProt / PubMed / PDB / GTDB）、本地工具（序列操作 / 翻译 / 比对 / 理化性质）、文件解析（FASTA / FASTQ / GenBank / GFF3）、集合运算、URL Scheme 路由、离线详情序列化。
运行测试需安装完整 Xcode（命令行工具不含 XCTest）。

## 工程结构

```
SciToolbox/
├── Package.swift                 # Swift Package 配置（含测试 target）
├── SciToolbox.xcodeproj          # Xcode 工程（Mac App Store 上架用）
├── ExportOptions.plist           # 归档导出配置（method = app-store-connect）
├── preflight-appstore.sh         # 上传前预检（隐私清单 / 权限 / 图标 / 环境）
├── make-screenshots.sh           # 截屏归一化到 ASC 要求的精确像素
├── docs/                         # GitHub Pages 站点（隐私政策 + 支持页，供 App Store 引用）
├── App/                          # 打包资源（Xcode 工程专用，勿放入 SwiftPM 源码目录）
│   ├── Info.plist                # 包元数据（用 $(MARKETING_VERSION) 等构建设置变量）
│   ├── SciToolbox.entitlements   # App Sandbox 权限
│   ├── PrivacyInfo.xcprivacy     # 隐私清单（必要原因 API 申报）
│   └── Assets.xcassets/          # 图标资产目录（AppIcon 全套 10 张）
├── AppIcon.icns                  # 应用图标（全尺寸 icns，本地打包用）
├── generate-icon.swift           # 图标生成脚本（Swift + Core Graphics）
├── gen_pbxproj.py                # Xcode 工程文件生成器（改工程结构后重跑）
├── run.sh                        # 构建运行脚本（run/build/release/app/install）
├── build-app.sh                  # 本地开发 .app 打包脚本（ad-hoc，不可上架）
├── Sources/SciToolbox/
│   ├── SciToolboxApp.swift       # 应用入口、主窗口、三栏导航 ContentView、AppDelegate
│   ├── Models.swift              # 共享数据模型（ResultItem/DetailModel/KVSection 等）
│   ├── OfflineDetail.swift       # 离线详情快照（Codable，用于持久化 / 文件解析 / 结果集）
│   ├── APIClient.swift           # 统一网络层（超时/重试/错误处理）
│   ├── ToolRegistry.swift        # ToolProvider 协议 + 工具注册表
│   ├── Theme.swift               # 设计系统（颜色/间距/字体令牌 + SidebarDensity + PressableButtonStyle）
│   ├── Localization.swift        # 中英文双语本地化（AppLanguage 语言管理器 + L10n 字符串表）
│   ├── Util.swift                # 剪贴板/导出/Toast/阶元映射/网络监控(NetworkMonitor)
│   ├── ResponseCache.swift       # 磁盘缓存（TTL，无用户数据）
│   ├── CommonViews.swift         # 通用视图（SearchBar/StateView/ResultList/KeyValueDetail）
│   ├── SearchScreen.swift        # 搜索容器（搜索栏 + 结果列表 + 历史 + 分页 + 结果统计入口）
│   ├── HomeView.swift            # 首页分组视图（工具入口 + 快捷动作 + 示例数据 + 收藏/历史）
│   ├── GlobalSearch.swift        # 全库搜索（AggregatedSearchService + 首页输入框 + 分组结果视图）
│   ├── SettingsView.swift        # 设置页（外观/密度/缓存/历史/收藏/数据与隐私/快捷键/关于）
│   ├── CommandPalette.swift      # ⌘K 命令面板（输入即筛、回车直达，支持 工具:查询 语法）
│   ├── SearchHistory.swift       # 查询历史管理器（纯本地 UserDefaults）
│   ├── LocalFavorites.swift      # 本地收藏管理器（纯本地 + 可导出）
│   ├── CollectionStore.swift     # 项目集合管理器（课题：纯本地 + 可导出 + 批量查询）
│   ├── CollectionsView.swift     # 项目集合列表 / 详情 / 对比（批量查询）视图
│   ├── AccessionRouter.swift     # Accession 智能识别路由（纯函数分类器，带置信度）
│   ├── AccessionUI.swift         # 智能识别输入框与歧义选择弹窗
│   ├── FavoritesAndHistoryViews.swift  # 收藏夹/历史列表视图
│   ├── LocalTools/               # 离线生物信息学工具（无网络依赖）
│   │   ├── LocalTool.swift       # 工具注册（反向互补 / GC / 翻译 / 比对 / 理化性质 / FASTA / 批量识别）
│   │   ├── LocalToolView.swift   # 工具 UI（输入 + 运行 + 结果展示）
│   │   ├── SequenceTools.swift   # 序列操作纯函数（reverseComplement / gcContent / translate / composition）
│   │   └── Analysis/             # 算法实现
│   │       ├── PairwiseAlignment.swift  # Needleman-Wunsch + Smith-Waterman
│   │       └── ProteinProps.swift      # 分子量 / pI / 消光系数
│   ├── FileImport/               # 生物信息学文件解析
│   │   ├── FileParsers.swift     # FASTA / FASTQ / GenBank / GFF3 解析器
│   │   └── MyFilesView.swift     # 导入文件管理 UI（会话内 + UserDefaults 持久化）
│   ├── LocalSearch/              # 本地全文搜索
│   │   └── LocalSearchIndex.swift # SQLite FTS5 索引与查询（收藏/集合/结果集）
│   ├── ResultSets/               # 结果集管理
│   │   ├── ResultSetStore.swift  # 结果集存储 + 集合运算（并/交/差/去重）
│   │   └── ResultSetsView.swift  # 结果集列表 / 详情 / 集合运算 UI
│   ├── Charts/                   # 结果统计可视化
│   │   └── ResultStatsView.swift  # Swift Charts（来源分布 / 年份分布）
│   ├── Onboarding/               # 首次启动引导
│   │   ├── OnboardingView.swift  # 三步引导卡（数据源 / 本地工具 / 系统集成）
│   │   └── SampleData.swift      # 示例数据加载器
│   ├── SystemIntegration/        # macOS 系统集成
│   │   ├── SystemIntegration.swift  # URL Scheme 路由 / ClipboardMonitor / SpotlightIndexer / Dock 菜单
│   │   └── BackupArchive.swift     # 备份 / 恢复数据序列化
│   ├── Resources/                # 捆绑资源（AppIcon_1024.png）
│   └── Providers/                # 15 个数据源 Provider
│       ├── UniProtProvider.swift
│       ├── PDBProvider.swift
│       ├── AlphaFoldProvider.swift
│       ├── PubMedProvider.swift
│       ├── NCBITaxonomyProvider.swift
│       ├── NCBIGeneProvider.swift
│       ├── EnsemblProvider.swift
│       ├── KEGGProvider.swift
│       ├── GOProvider.swift
│       ├── PfamProvider.swift
│       ├── BacDiveProvider.swift
│       ├── MGnifyProvider.swift
│       ├── GBIFProvider.swift
│       ├── EuropePMCProvider.swift
│       └── GTDBOfficialProvider.swift
└── Tests/SciToolboxTests/
    ├── ParseTests.swift          # 样例 JSON 解析测试（schema 预警）
    ├── LocalToolsTests.swift     # 本地工具测试（序列操作 / 翻译 / 比对 / 理化性质）
    ├── FileImportTests.swift     # 文件解析测试（FASTA / FASTQ / GenBank / GFF3）
    ├── PairwiseAlignmentTests.swift  # 比对算法测试
    ├── ProteinPropsTests.swift   # 蛋白理化性质测试
    ├── SetOpsTests.swift         # 集合运算测试（并/交/差/去重）
    ├── URLSchemeTests.swift      # URL Scheme 路由测试
    ├── OfflineDetailTests.swift  # 离线详情序列化测试
    └── Fixtures/                 # 测试样例数据
        ├── uniprot_search.json
        ├── uniprot_detail.json
        ├── pubmed_search.json
        ├── pdb_search.json
        ├── pdb_entry.json
        ├── gtdb_detail.json
        ├── sample.fasta
        ├── sample.fastq
        ├── sample.gb
        └── sample.gff3
```

## 架构设计

### 核心抽象

- **`ToolProvider` 协议**：每个数据源实现一个 provider，约定 `search(query:offset:pickerId:)` 和 `detail()` 方法。支持分页（offset）和选择器（pickerId）参数，picker 状态由 SearchScreen 管理（避免多窗口共享实例串状态）
- **`ToolRegistry`**：注册所有 provider，按分类分组
- **`ContentView`（三栏布局）**：`NavigationSplitView` 三栏 — 侧边栏（工具导航 + 首页 + 收藏/历史 + 设置）→ 中栏（`SearchScreen` 搜索 + 结果列表）→ 右栏（`KeyValueDetail` 详情）
- **`SearchScreen`**：搜索容器，负责搜索 + 结果列表 + 查询历史展示 + 分页加载；点击结果通过 `onItemTapped` 回调通知父级加载详情
- **`SearchHistory`**：纯本地查询历史，UserDefaults 存储，按工具分组，最多保留 200 条
- **`LocalFavorites`**：纯本地收藏，UserDefaults 存储，支持导出为文本/JSON
- **`CollectionStore`**：纯本地项目集合（课题），UserDefaults 存储，支持 CSV / JSON 导出；Entry 记录来源工具与编号及重新拉取所需的 context，可重新跳转或批量重新拉取做对比
- **`AccessionRouter`**：纯函数 accession 分类器，按正则识别编号类型（UniProt / PDB / GO / Ensembl / Pfam / KEGG / DOI / 基因符号 / PMID / TaxID 等），返回带置信度的候选；由 ContentView 根据置信度阈值决定直接跳转或弹窗选择（避免无感知的错路由）
- **`CommandPaletteView`**：⌘K 命令面板，复用 HomeView 的过滤逻辑，输入即筛、回车直达
- **`SidebarDensity`**：侧边栏间距枚举（默认正常），控制行高、字号、图标大小、缩进量、内边距
- **`NetworkMonitor`**：基于 NWPathMonitor 的网络连通性检测，断网时显示警告条+搜索前置拦截
- **`SidebarItemView` / `SidebarSectionHeader`**：自定义侧边栏组件，实现分类色图标、强选中态、悬浮背景、分组标题
- **`APIClient`**：统一 HTTP 客户端，内置超时（15s）、指数退避重试、错误友好化、NCBI 节流（`RequestThrottle` actor）
- **`DetailModel.imageUrl`**：可选预览图（PDB 结构、AlphaFold cartoon），`AsyncImage` 异步加载
- **`OfflineDetail`**：离线详情快照（Codable），用于文件解析结果、结果集持久化、备份归档；解耦了 DetailModel 中的非 Codable 成员（闭包 / URL）
- **`LocalSearchIndex`**：基于 SQLite3 FTS5 的本地全文搜索引擎，索引收藏 / 集合 / 结果集，断网可用
- **`URLSchemeRouter`**：`scitoolbox://` 协议路由中心，支持 search / identify / local-tools / my-files 等路径
- **`SpotlightIndexer`**：Core Spotlight 索引器，将本地研究资产推送至系统搜索
- **`BackupManager`**：全量数据备份 / 恢复，JSON 归档格式（BackupArchive）
- **`PairwiseAlignment`**：Needleman-Wunsch 全局比对 + Smith-Waterman 局部比对（纯函数，无网络）
- **`ProteinProps`**：蛋白质理化性质计算器（分子量 / pI / 消光系数，纯函数）
- **`SequenceTools`**：序列操作工具集（反向互补 / GC 含量 / 翻译 / 组成分析，纯函数）
- **`FastaParser / FastqParser / GenBankParser / GffParser`**：生物信息学文件格式解析器，统一输出 `ParsedFile`（映射至 OfflineDetail）

### 与微信小程序的对应关系

| 小程序资产 | macOS/SwiftUI 对应 |
| --- | --- |
| `utils/proxy.js`（callProxy/错误/复制） | `APIClient` + `Util`（错误映射、Clipboard） |
| `utils/search-page.js`（createSearchPage） | `SearchScreen` + `ToolProvider` 协议 |
| `constants/tools.js`（工具注册表） | `ToolRegistry` + 元数据 |
| `components/{search-bar,state-view,result-list,kv-detail}` | `CommonViews.swift` 中的对应视图 |
| `styles/app.wxss`（设计令牌 + 深色模式） | `Theme.swift` + 系统自适应颜色 |
| `cloudfunctions/*Proxy` | **取消**：改为各 `Provider` 直连公开 API |

## 合规声明

- ✅ 无登录、无账户体系
- ✅ 不采集 / 不上传任何用户个人数据
- ✅ 查询历史和收藏均为纯本地存储（UserDefaults），不联网、可随时清除或导出
- ✅ 缓存仅"请求→结果"，不关联任何用户/设备标识
- ✅ 仅展示公开数据库的公开内容，保留"数据来源"标注
- ✅ 遵守各外部 API 使用条款、频率上限与署名要求
- ✅ 本地工具（序列操作 / 比对 / 理化性质 / 文件解析）完全离线运行，数据不出本机
- ✅ 隐私清单（PrivacyInfo.xcprivacy）已申报 UserDefaults + FileTimestamp 两项必要原因 API
- ✅ App Sandbox 启用，仅申请出站网络 + 用户选择文件读写权限

## 技术说明

- 使用 Swift Package Manager 构建，无需 Xcode 项目文件
- SwiftUI 原生开发，部署目标 macOS 15.0
- Swift 语言模式设为 v5（避免严格并发检查的干扰）
- 所有网络请求均为 HTTPS，满足 ATS
- 应用图标由 `generate-icon.swift` 用 Core Graphics 绘制，经 `iconutil` 转为 icns
- 测试使用样例 JSON Fixture，对冲 15 个上游 API 的 schema 变更风险

### 重新生成图标

```bash
swift generate-icon.swift          # 生成 1024×1024 PNG
mkdir -p AppIcon.iconset           # 创建 iconset
# 用 sips 生成各尺寸，再 iconutil 转换
# 详见 generate-icon.swift 头部注释
```
