# DoseLab

DoseLab 是一个开源、local-first、可离线使用的用药自我观察工具。

面向长期用药者、对药代动力学感兴趣的用户，以及希望用更透明的数据记录和医生/药师沟通的人。DoseLab 不替代医疗判断，而是帮助用户看清自己的服药节律、提醒时间、估算浓度变化和数据来源。

---

## 当前状态

Flutter + FastAPI 架构，已完成从单文件 PWA 原型到完整的跨平台应用迁移。

### 已实现

- 药品搜索：前端直接查 openFDA，中英文药名映射后查询。
- 本地药物管理：添加/删除/服药记录，Drift 数据库持久化。
- PK 浓度曲线：基于半衰期的指数衰减叠加模型，多剂量模拟，治疗窗/警戒区/中毒区可视化。
- 停药阈值估算：输入身高体重，计算体表面积、mg/kg，估算停药后多久浓度低于最低有效水平。
- 用药提醒：本地通知，支持开关、到期提示。
- 相互作用检查：本地规则匹配，提供参考信息。
- PDF 报告：中英文双语标题/表头，嵌入 Roboto + DroidSansFallback 中文字体。
- 设置：亮/暗/跟随系统主题，中/英文切换，应用锁。
- PWA：Service Worker 离线缓存，manifest，可安装到桌面。
- 后端（可选）：FastAPI，JWT 注册/登录，药品 CRUD，PK 计算 API，Celery FDA 刷新任务。

### 技术栈

- 前端：Flutter 3.44，Material 3，Riverpod，go_router，Drift (SQLite / WebDatabase)，Dio，fl_chart
- 后端：FastAPI，异步 SQLAlchemy，Celery，httpx
- 离线：Service Worker cache-first 策略，IndexedDB 本地存储

---

## 仓库结构

```
.
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/          # env、constants
│   │   ├── di/              # Riverpod 全局注册表
│   │   ├── router/          # go_router + Routes 常量
│   │   ├── theme/           # Material 3 主题
│   │   ├── network/         # Dio + JWT 拦截 + FDA key 脱敏
│   │   ├── storage/         # Drift 数据库、表、条件导入连接
│   │   └── error/           # Freezed Failure
│   ├── features/
│   │   ├── auth/            # 本地账号/锁屏
│   │   ├── dashboard/       # 首页：药物卡片 + 功能网格
│   │   ├── drug_search/     # openFDA 直接查询 + 中文映射
│   │   ├── pk_engine/       # PK 计算、曲线、停药阈值
│   │   ├── medication_schedule/  # 药物列表、服药记录、提醒
│   │   ├── interaction_check/    # 本地相互作用规则
│   │   ├── sync/            # WebDAV JSON 导入/导出
│   │   ├── pdf_report/      # 中文 PDF 报告
│   │   └── settings/        # 语言、主题、身高体重
│   └── shared/
│       ├── widgets/         # disclaimer、empty state、loading
│       ├── utils/           # PK 正则、UUID
│       ├── constants/       # 存储 key、API path
│       ├── l10n/            # 手工中英双语
│       └── extensions/      # String、Duration 扩展
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI 入口
│   │   ├── core/            # config、database、security (JWT/bcrypt)
│   │   ├── api/v1/routes/   # auth / drugs / pk / interactions / sync / reports
│   │   ├── models/          # SQLAlchemy ORM
│   │   ├── schemas/         # Pydantic
│   │   ├── services/        # FDA 查询代理、PK 计算
│   │   └── tasks/           # Celery FDA 标签刷新
│   └── requirements.txt
├── web/                     # PWA 壳子
│   ├── index.html           # 应用入口 + 中文加载页
│   ├── manifest.json        # PWA 清单
│   ├── service_worker.js    # 离线缓存策略
│   ├── sql-wasm.js          # Drift Web SQL 引擎
│   ├── sql-wasm.wasm
│   └── icons/               # PWA 图标 192/512
├── assets/
│   ├── data/zh_drug_map.json   # 中→英药名映射
│   └── fonts/                  # Roboto + DroidSansFallback (PDF 用)
├── docs/                    # 产品/API/映射策略文档
├── scripts/                 # openFDA 查询实验脚本
└── pubspec.yaml
```

---

## 本地运行

### Flutter 前端

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift + Freezed codegen
flutter analyze
```

开发模式：

```sh
flutter run -d chrome
```

构建 Web 部署包：

```sh
flutter build web --no-wasm-dry-run \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=FDA_API_KEY=your_key_here
```

静态服务（如 2252 端口）：

```sh
python3 -m http.server 2252 --directory build/web
```

### FastAPI 后端（可选）

```sh
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

API 文档：`http://localhost:8000/docs`

Celery 可选任务：

```sh
celery -A app.tasks.celery_app worker -l info
```

---

## 数据来源

- openFDA `drug/ndc.json`：药品目录、NDC、规格、剂型
- openFDA `drug/label.json`：SPL 标签文本、药代动力学候选参数
- 中文药名映射（`assets/data/zh_drug_map.json`）：优先覆盖精神/神经类药物

所有 FDA 衍生数据都附带请求 URL（已脱敏 api_key）、检索时间和 `meta.last_updated`。

---

## 安全边界

DoseLab 不提供：医疗建议、诊断建议、治疗建议、处方建议、自动调药建议、漏服后是否补服的医学判断。

DoseLab 只能用于个人记录、提醒、模拟和可视化。

所有浓度曲线都是基于用户输入和公开参数的估算，可能与真实血药浓度存在显著差异。不要基于本软件自行开始、停止、增加、减少或调整任何药物。任何用药相关决定都应咨询合格医生或药师。

---

## 路线图

- 接入真实账号体系（前端 OAuth + 后端 JWT）
- WebDAV / 后端双通道同步冲突处理
- FDA 标签 PK 参数自动提取与缓存
- 交互规则扩充至更多药物组合
- 多源药物数据整合（Wikidata / RxNorm / PubChem）

## License

待定。
