<p align="center"><img src="assets/icon.svg" width="88" alt="JianShanAgent"></p>

<h1 align="center">template-instance</h1>

<p align="center">基于 <a href="https://github.com/JianShanAgent/agent-core">JianShanAgent（见山）</a> 快速搭建你自己的 MediaWiki QQ 问答机器人实例。</p>

<p align="center">
  <img src="https://img.shields.io/badge/模板-部署实例-2f6b5a?style=flat-square&labelColor=1f3b34" alt="模板：部署实例">
  <img src="https://img.shields.io/github/license/JianShanAgent/template-instance?label=License&color=2f6b5a&style=flat-square&labelColor=1f3b34" alt="License">
</p>

<sub>Starter template for deploying a JianShanAgent QQ bot for any MediaWiki site. Supports native Python (`uv`) execution, one-command `docker compose`, and in-repo custom plugins.</sub>

## 这个模板是什么

[`agent-core`](https://github.com/JianShanAgent/agent-core) 是见山的通用核心框架，不包含任何具体 Wiki 的地址或凭据。**每个实际的机器人部署都对应一个“实例仓库”**，本仓库就是新建实例时使用的脚手架模板。

使用本模板你**不需要**手动克隆 `agent-core`，也**不需要**安装 Node.js 编译前端——依赖里会自动拉取核心包与预编译好的 Web 管理后台。同时支持 **Python 原生直跑**与 **Docker Compose 一键启动**，自己写的专属插件直接放进本仓库的 `sites/` 或 `plugins/` 目录就能跟着 Git 一起同步。

（想参考一个已经在线上稳定运行的真实生产实例，可查看阴阳师 Wiki 的 [`instance-yys`](https://github.com/JianShanAgent/instance-yys)。）

## 快速开始

### 1. 用模板新建仓库并克隆

点击本页面右上角的 **Use this template → Create a new repository**，创建一个你自己的仓库（例如 `instance-mywiki`，存放在你自己的配置与插件，如果含私有信息可设为 Private），然后克隆到本地：

```bash
git clone https://github.com/<你的用户名>/instance-mywiki.git
cd instance-mywiki
```

### 2. 填写 Wiki 地址与 API 密钥

**（1）编辑 [`config/core.wiki.yaml`](config/core.wiki.yaml)，填入目标 MediaWiki 地址：**

```yaml
name: "某某游戏"                            # 必填：Wiki 名称，会注入查证与对话提示词
about: "某某游戏玩家资料站"                  # 可选：一句话背景说明
wikis:                                     # 挂哪几个 wiki；一般只有一个，同题材的几个 wiki 也可以都挂上
  - id: main                               # 必填：这个 wiki 在部署里的名字（知识库的目录名、密钥的键）
    api_url: "https://your.wiki/api.php"   # 必填：MediaWiki 的 api.php 接口地址
    site: ""                               # 暂不用站点插件时留空
```

> **你的 Wiki 已经有人做好了站点插件？** 这里可以写成 `wikis: []`，启动以后打开管理后台的「Wiki」页：站点目录按平台（灰机、BWiki……）列着做好了的站，点「添加」就下载它的站点插件并挂上，地址不用自己填，也不用重启。

**（2）复制凭据模板并填入密钥（`secrets.yaml` 已加入 `.gitignore`，不会提交入库）：**

```bash
cp config/secrets.example.yaml config/secrets.yaml
```

打开 `config/secrets.yaml` 填写：
- `llm.api_key`：对话大模型密钥。默认对接小米 MiMo，目前也只在 MiMo 上调通过；要换接口地址或模型名，新建 `config/core.llm.yaml` 只写要改的项（别家接口没有测过）。
- `gitee_ai.api_key`：向量模型密钥（默认对接模力方舟 `Qwen3-VL-Embedding-8B`；不填时自动降级为关键词检索）。
- `qq.app_id` / `qq.client_secret`：QQ 开放平台机器人的凭据（本地用网页对话测试时可先不填）。

### 3. 启动运行（任选一种方式）

#### 方式 A：Python / `uv` 原生直跑（无需 Docker）

安装 Python 3.12+ 与 [`uv`](https://docs.astral.sh/uv/getting-started/installation/) 后直接执行：

```bash
uv sync

# 本地先不连 QQ 网关试跑（可在 Web 管理后台里直接测试问答）：
JIANSHANAGENT_DRY_RUN=1 uv run jianshanagent

# 确认无误后去掉 DRY_RUN 正式连接 QQ：
uv run jianshanagent
```

#### 方式 B：Docker Compose 一键启动（自带 `pgvector` 数据库与每小时自动同步）

```bash
cp .env.example .env          # 还没有 QQ 凭据、只想先试试：打开 .env 里 JIANSHANAGENT_DRY_RUN=1 那一行
docker compose up -d --build
```

会起三个容器：`qqbot`（机器人和管理后台）、`kbsync`（知识库自动更新）、`postgres`。另有一个 `init` 跑一下就退出，它把 `data/` 交给容器里的用户，是正常的。

启动后：
1. 查看自动生成的管理后台登录令牌：
   - 方式 A：`cat data/admin/token`
   - 方式 B：`docker compose exec qqbot cat /data/admin/token`（Linux 上 `data/` 归容器里的用户，直接 `cat` 要加 `sudo`）
2. 浏览器打开 **`http://127.0.0.1:8080`**，粘贴令牌登录，点击左侧 **网页对话** 即可直接测试 `/查 <词条名>` 或自然语言提问。

没起来时先看日志：`docker compose logs qqbot`。最常见的是 `llm.api_key` 还是模板里的占位值，日志里会直接写明缺哪一项。

Docker 方式下改了东西怎么生效：

| 改了什么 | 怎么生效 |
|---|---|
| `config/secrets.yaml`、`sites/`、`plugins/` | `docker compose restart qqbot kbsync` |
| `config/` 下别的文件、`pyproject.toml`（加了插件依赖） | `docker compose up -d --build` |
| 核心出了新版本 | 管理后台「系统信息」页点「更新并重启」；后台说依赖变了要重建环境时：`docker compose build --no-cache && docker compose up -d` |

### 4. 构建全站向量知识库

刚启动时 `/查` 与站内实时搜索已经可用。要抓取全站页面构建语义向量知识库，最省事的是在管理后台的「Wiki」页里点那个 wiki 的「建知识库」：`kbsync` 容器（原生运行时是 `sync --loop` 那个进程）在后台全量取数、切片、算向量、导入，做完自动转成增量更新。

也可以手动按顺序运行以下三条命令（支持断点续跑）：

```bash
# 方式 A（原生 uv）：
uv run python -m jianshanagent.plugins.knowledge run     # 抓取页面、清洗 HTML 并切片
uv run python -m jianshanagent.plugins.knowledge embed   # 计算切片向量
uv run python -m jianshanagent.plugins.knowledge load    # 导入 PostgreSQL（需在 secrets.yaml 配好 postgres.dsn）

# 方式 B（Docker Compose）：
docker compose exec qqbot python -m jianshanagent.plugins.knowledge run
docker compose exec qqbot python -m jianshanagent.plugins.knowledge embed
docker compose exec qqbot python -m jianshanagent.plugins.knowledge load
```

挂了不止一个 wiki 时，这三条命令会挨个 wiki 做；只做其中一个，在子命令前面加 `--wiki <id>`（如 `... knowledge --wiki main run`）。每个 wiki 的文件在 `data/kb/<id>/` 下。

首次全量导入后，Docker Compose 中的 `kbsync` 容器（或原生运行 `uv run python -m jianshanagent.plugins.knowledge sync --loop`）会每小时自动检查 Wiki 的最近更改并增量更新数据库。

## 怎么添加和同步你自己的插件

你有两种方式接入自定义插件：

### 1. 直接写在本仓库的 `sites/` 或 `plugins/` 目录里（最简单，随仓库自动同步）

不需要单独建包或发版，直接在本仓库对应目录下新建插件文件夹：
- **自写站点插件**：建目录 `sites/<插件id>/`（放入 `plugin.yaml`、`config.yaml`，按需放 `wiki.py`、`knowledge.py`；写法参考 [`template-site-wiki`](https://github.com/JianShanAgent/template-site-wiki)），然后在 `config/core.wiki.yaml` 里给用它的那个 wiki 填 `site: <插件id>`。
- **自写功能插件**：建目录 `plugins/<插件id>/`（放入 `plugin.yaml`、`__init__.py`），然后在 `config/core.plugins.yaml`（或网页后台的「插件」页）启用它。

在服务器上同步更新时，原生运行只需 `git pull` 后重启进程；Docker Compose 只需 `git pull && docker compose restart qqbot kbsync`（目录已直接挂载进容器）。

### 2. 引用外部独立 Git 仓库的插件

列在[站点目录](https://github.com/JianShanAgent/catalog)里的站点插件不用走这一步，在管理后台的「Wiki」页里点「添加」就行（下载的插件在 `data/sites/`）。

别的独立仓库发布的插件（别人开源的站点插件、功能插件），或者想把插件的版本跟着镜像固定下来时：
1. 在 `pyproject.toml` 的 `dependencies` 中加上 Git 依赖，例如：
   ```toml
   "jianshanagent-site-huiji-yys @ git+https://github.com/JianShanAgent/site-huiji-yys.git",
   ```
2. 在 `config/core.wiki.yaml` 中给用它的那个 wiki 填上 `site: <插件id>`，重新执行 `uv sync` 或 `docker compose up -d --build` 即可。

## 目录说明

```text
config/
  core.wiki.yaml          目标 MediaWiki 站点配置（必填）
  secrets.example.yaml    密钥配置模板（复制为 secrets.yaml 后填写，不入库）
  local/                  本机临时调试覆写（不入库）
sites/                    存放本实例自写的站点插件（随本仓库 Git 同步）
plugins/                  存放本实例自写的功能插件（随本仓库 Git 同步）
data/                     运行时生成：登录令牌、后台里改过的配置和加的 wiki、下载的站点插件、知识库文件（不入库）
pyproject.toml            Python 依赖声明（默认从 GitHub 拉取 agent-core）
Dockerfile                单实例容器镜像构建文件
docker-compose.yml        一键启动机器人 + kbsync 自动同步 + pgvector 数据库
.dockerignore             凭据、本机覆写、运行数据不进镜像
components.lock / release 可选进阶：多仓库同级联调与远程服务器原子发布/自动回滚脚本
docs/运维备忘.md           记录你自己的服务器与外部服务现状的备忘模板
```

`config/` 下采取**增量覆盖**原则：想改核心或插件的哪份默认配置，只需新建同名 YAML 文件并只写需要修改的字段。

> **进阶生产发布**：如果你希望使用核心自带的多版本发布、健康检查失败自动回滚、每日自动备份与 Loki+Grafana 日志栈，将 `agent-core` 克隆在同级目录并在 `release` 中填好 `SSH_HOST`，即可使用 `./release deploy` 一键上线（无需手动输入发布号）。详见 [`agent-core` 部署与运维文档](https://github.com/JianShanAgent/agent-core/blob/main/docs/部署与运维.md)。

## 开源许可

[MIT License](LICENSE)
