# DoseLab

DoseLab 是一个开源、local-first、可离线使用的用药自我观察工具。

它面向长期用药者、对药代动力学感兴趣的用户，以及希望用更透明的数据记录和医生/药师沟通的人。DoseLab 的目标不是替代医疗判断，而是帮助用户更清楚地看到自己的服药节律、提醒时间、估算浓度变化和数据来源。

## 当前状态

项目从单文件 PWA 原型迁移到 Flutter + FastAPI 架构。

- 前端：Flutter（lib/）。Material 3 主题、Riverpod 状态、go_router 路由、Drift 本地 SQLite、Dio 网络层、fl_chart 渲染浓度曲线。
- 后端：FastAPI（backend/）。异步 SQLAlchemy、JWT、PK 计算 API、可选同步/报告接口。
- 共享：openFDA envelope 形态、中文药名映射表、PK 半衰期解析正则保持与之前完全一致，便于行为对齐。

## 为什么做 DoseLab

很多人不是不知道要吃药，而是很难长期稳定地按时服药。DoseLab 想回答的问题是：

- 什么时候该吃药
- 距离上次服药已经过了多久
- 可能什么时候进入低浓度区间
- 什么时候需要特别留意过高浓度风险
- 当前估算来自哪些参数和数据源

这些信息应当可以在本地离线查看，而不是依赖一个必须在线的服务。

## 产品方向

- 跨平台 Flutter 应用（iOS / Android / Web / Desktop）
- 本地优先：Drift SQLite 保存药品、用药记录、缓存的 PK 参数
- 用药提醒（flutter_local_notifications）
- 半衰期模型浓度曲线、治疗窗 / 警戒区 / 中毒区可视化
- openFDA 药品参考数据查询（中英文药名映射后查询）
- WebDAV 同步与 PDF 报告分享
- 后端：可选账号、同步/报告接口、PK 计算 API；FDA 参考数据由前端直接查询 openFDA

## 仓库结构

```text
.
├── README.md
├── AGENTS.md
├── CLAUDE.md
├── analysis_options.yaml
├── netlify.toml
├── pubspec.yaml
├── assets/
│   └── data/zh_drug_map.json
├── docs/
│   ├── FDA_API.md
│   ├── PRODUCT.md
│   ├── ROADMAP.md
│   └── DRUG_NAME_MAPPING.md
├── scripts/
│   ├── fda_query.py
│   └── query_sertraline.py
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/        # env、constants
│   │   ├── di/            # 全局 Riverpod 注册表
│   │   ├── router/        # go_router + Routes 常量
│   │   ├── theme/         # Material 3 主题
│   │   ├── network/       # Dio + JWT 拦截
│   │   ├── storage/       # Drift 数据库 + 表
│   │   └── error/         # Freezed Failure
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── drug_search/
│   │   ├── pk_engine/
│   │   ├── medication_schedule/
│   │   ├── interaction_check/
│   │   ├── sync/
│   │   ├── pdf_report/
│   │   └── settings/
│   └── shared/
│       ├── widgets/
│       ├── utils/
│       ├── constants/
│       ├── l10n/
│       └── extensions/
└── backend/
    ├── requirements.txt
    ├── .env.example
    └── app/
        ├── main.py
        ├── core/          # config、database、security
        ├── api/v1/routes/ # auth / drugs / pk / interactions / sync / reports
        ├── models/        # SQLAlchemy ORM
        ├── schemas/       # Pydantic
        ├── services/      # FDA 代理、PK 计算
        └── tasks/         # Celery + FDA 刷新任务
```

## 本地运行

### Flutter 前端

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs    # 生成 Drift / Freezed
flutter run -d chrome                                       # 或 -d <device>
```

环境变量通过 `--dart-define` 传入：

```sh
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=FDA_API_KEY=your_key_here
```

### FastAPI 后端

```sh
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

文档默认在 `http://localhost:8000/docs`。Celery 任务：

```sh
celery -A app.tasks.celery_app worker -l info
```

## 数据来源

- openFDA `drug/ndc.json`：药品目录、NDC、规格、剂型
- openFDA `drug/label.json`：SPL 标签文本、药代动力学候选参数
- 中文药名映射（`assets/data/zh_drug_map.json`）：优先覆盖精神/神经类药物
- 后续：Wikidata / RxNorm / PubChem 多源整合（见 `docs/DRUG_NAME_MAPPING.md`）

所有 FDA 衍生数据都附带请求 URL（已脱敏）、检索时间和 `meta.last_updated`。

## 安全边界

DoseLab 不提供：医疗建议、诊断建议、治疗建议、处方建议、自动调药建议、漏服后是否补服的医学判断。

DoseLab 只能用于个人记录、提醒、模拟和可视化。

所有浓度曲线都是基于用户输入和公开参数的估算，可能与真实血药浓度存在显著差异。不要基于本软件自行开始、停止、增加、减少或调整任何药物。任何用药相关决定都应咨询合格医生或药师。

## Roadmap

- 完善 Drift 迁移机制与 schema v2
- 接入真实账号体系（前端 OAuth + 后端 JWT）
- 扩充中英文药品映射至 ~3000 条
- WebDAV / 后端双通道同步冲突处理
- PDF 报告本地化模板
- Celery 周期任务：openFDA 标签数据增量刷新与失效检测

## License

待定。
