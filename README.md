# DoseLab

DoseLab 是一个开源、local-first、可离线使用的用药自我观察工具。

它面向长期用药者、对药代动力学感兴趣的用户，以及希望用更透明的数据记录和医生/药师沟通的人。DoseLab 的目标不是替代医疗判断，而是帮助用户更清楚地看到自己的服药节律、提醒时间、估算浓度变化和数据来源。

## 当前状态

项目处于早期原型阶段，当前优先实现网页端 PWA。

当前已有：

- 单页网页原型：`web/index.html`
- PWA 清单：`web/manifest.json`
- Service Worker 离线缓存：`web/sw.js`
- openFDA 药品查询实验脚本：`scripts/`
- 精神/神经类药物中文名映射：`web/data/zh_drug_map.json`
- 中英文药品名映射策略文档：`docs/DRUG_NAME_MAPPING.md`

线上原型当前部署在：

```text
http://27.215.225.251:2280
```

## 为什么做 DoseLab

很多人不是不知道要吃药，而是很难长期稳定地按时服药。

DoseLab 想解决的问题是：

- 什么时候该吃药
- 距离上次服药已经过了多久
- 可能什么时候进入低浓度区间
- 什么时候需要特别留意过高浓度风险
- 当前估算来自哪些参数和数据源

这些信息应当可以在本地离线查看，而不是依赖一个必须在线的服务。

## 产品方向

- PWA，可安装到手机主屏幕
- 离线可访问，静态资源由 Service Worker 缓存
- 用户药品列表本地保存
- 用药提醒和通知
- 剂量、间隔、最近服药时间记录
- 半衰期模型浓度曲线
- 治疗窗、警戒区、中毒区可视化
- 个性化参数覆盖，例如半衰期、阈值、剂量间隔
- openFDA 药品参考数据查询
- FDA 标签数据和查询结果缓存
- 中英文药品名映射，优先覆盖精神/神经类药物
- 用户拥有数据，后续支持 JSON 导入/导出

## 当前原型能力

### 药品搜索

DoseLab 直接查询 openFDA：

- `drug/ndc.json`：药品名称、NDC、剂型、规格、厂家等
- `drug/label.json`：标签、药代动力学文本、半衰期候选参数等

openFDA 不支持中文字段查询，所以中文药名会先在本地映射表中解析成英文标准名，再请求 FDA。

示例：

```text
盐酸舍曲林 → sertraline → openFDA
奥氮平 → olanzapine → openFDA
喹硫平 → quetiapine → openFDA
```

### 我的药品

用户可以把搜索结果加入“我的药品”：

- 保存药品名称、NDC、规格、剂量、服药间隔
- 开关通知提醒
- 记录“刚刚服药”时间
- 显示下次服药倒计时
- 超时后显示已超时状态

数据保存在浏览器 IndexedDB 中。

### 离线能力

当前 PWA 会缓存：

- 主页面
- PWA manifest
- Service Worker
- 中文药品名映射表
- 已查询过的部分 FDA 标签参数

后续目标是支持更完整的离线药品参考数据包。

### 浓度估算

当前模型使用半衰期指数衰减和多次给药叠加：

```text
C(t) = C0 * (1/2) ^ (t / half_life)
```

图表会显示：

- 多次服药叠加曲线
- 估算峰值位置
- 治疗窗
- 警戒区
- 中毒风险区

这些只是模型估算，不等同于真实血药浓度。

## 数据来源

DoseLab 初始使用 openFDA：

- openFDA API: `https://api.fda.gov`
- NDC 数据：药品目录和包装信息
- Label 数据：SPL 标签文本和药代动力学信息

相关说明见：

- `docs/FDA_API.md`
- `docs/DRUG_NAME_MAPPING.md`

中英文药品名映射计划采用组合来源：

- Wikidata：中文标签和别名
- RxNorm/RxNav：英文药品标准化和 RxCUI
- PubChem：化合物同义词和 CID
- openFDA：FDA 产品和标签数据
- 人工整理：中文商品名、盐型名、精神药品优先收录

## 安全边界

DoseLab 不提供：

- 医疗建议
- 诊断建议
- 治疗建议
- 处方建议
- 自动调药建议
- 漏服后是否补服的医学判断

DoseLab 只能用于个人记录、提醒、模拟和可视化。

所有浓度曲线都是基于用户输入和公开参数的估算，可能与真实血药浓度存在显著差异。不要基于本软件自行开始、停止、增加、减少或调整任何药物。任何用药相关决定都应咨询合格医生或药师。

## 本地运行

当前无需构建步骤，可以用任意静态文件服务器运行：

```sh
python3 -m http.server 2280 -d web
```

然后访问：

```text
http://localhost:2280
```

如果使用公网服务器，请确认端口开放，并通过 HTTPS 部署以获得更完整的 PWA 和通知能力。

## 仓库结构

```text
.
├── README.md
├── AGENTS.md
├── docs/
│   ├── FDA_API.md
│   ├── PRODUCT.md
│   ├── ROADMAP.md
│   └── DRUG_NAME_MAPPING.md
├── scripts/
│   ├── fda_query.py
│   └── query_sertraline.py
└── web/
    ├── index.html
    ├── manifest.json
    ├── sw.js
    └── data/
        └── zh_drug_map.json
```

## Roadmap

- 拆分前端代码，降低 `index.html` 复杂度
- 完善 IndexedDB 数据模型
- 批量构建 3,000 条左右中英文药品映射
- 优先扩展精神/神经类药物
- 支持用户自定义治疗窗、警戒值、中毒阈值
- 支持 JSON 导入/导出
- 支持离线药品数据包
- 改进后台通知和定时提醒可靠性
- 后续评估 Flutter/原生移动端实现

## License

待定。
