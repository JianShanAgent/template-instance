<p align="center"><img src="assets/icon.svg" width="96" alt="JianShanAgent"></p>

# template-instance

> JianShanAgent · 模板 · 实例 · 新建一个部署时，从这里开始
>
> Template for a JianShanAgent deployment: configuration, pinned component versions and a release entry point.

| | |
|---|---|
| 层 | 实例（模板） |
| id | — |
| 包 | 不是一个要发布的包（`pyproject.toml` 只用来搭开发环境） |
| 依赖 | 核心 `jianshanagent`；用到的站点插件；版本见 `components.lock` |
| 登记 | 无 |

## 这是什么

一个部署的骨架：把核心和插件拼成一个真的在跑的机器人。仓库里只有三样东西——这个部署和默认值不一样的配置、
用哪几个仓库的哪个提交、运维备忘。模板默认不带站点插件（纯 MediaWiki），服务哪个 wiki 是占位的，填上才能启动。

实际的例子：[`instance-yys`](https://github.com/JianShanAgent/instance-yys)（阴阳师 wiki 的机器人）。

## 在整套里的位置

JianShanAgent 由几个仓库拼成（并排放在开发机的同一个目录下）：

| 仓库 | 层 | 管什么 |
|---|---|---|
| [`agent-core`](https://github.com/JianShanAgent/agent-core) | 核心 | 机器人本体：QQ 网关、七个功能插件（查询、知识库、查证、对话、记忆、群聊记录、安全兜底）、管理后台、部署工具 |
| [`site-huiji`](https://github.com/JianShanAgent/site-huiji) | 站点插件 · 平台 | 灰机 wiki 平台在 MediaWiki 之上多出来的东西 |
| [`site-huiji-yys`](https://github.com/JianShanAgent/site-huiji-yys) | 站点插件 · 站 | 阴阳师 wiki 特有的东西（建在灰机平台上） |
| [`instance-yys`](https://github.com/JianShanAgent/instance-yys) | 实例 | 阴阳师 wiki 机器人这个部署：配置、用哪个版本、运维备忘 |
| [`template-site-platform`](https://github.com/JianShanAgent/template-site-platform) | 模板 · 站点插件 · 平台 | 接一个新的 wiki 平台时，从它开始 |
| [`template-site-wiki`](https://github.com/JianShanAgent/template-site-wiki) | 模板 · 站点插件 · 站 | 接一个新的 wiki 时，从它开始 |
| **[`template-instance`](https://github.com/JianShanAgent/template-instance)（这里）** | 模板 · 实例 | 新建一个部署时，从它开始 |

## 目录

```
config/
  core.wiki.yaml          服务哪个 wiki、用哪个站点插件（占位，要填）
  secrets.example.yaml    凭据的模板；真的 secrets.yaml 不入库
  local/                  开发机的调试覆写，不入库
components.lock           这个部署用哪几个仓库的哪个提交
release                   发布入口（转给核心的 deploy/scripts/release.sh）
pyproject.toml            开发环境：核心和插件都用旁边目录里的源码
docs/运维备忘.md           现在的状态、服务器、用到的外部服务（骨架，要填）
```

## 安装和启用

**从模板开始**：在 GitHub 上点「Use this template」建一个新仓库，名字照规范取 `instance-<名字>`，
和核心、用到的插件并排放在开发机的同一个目录下。然后：

1. `release`：填 `SSH_HOST`（发布到哪台服务器）。`config/core.wiki.yaml`：填 `name` 和 `api_url`。那个 wiki 有站点插件就在 `site` 里写它的 id。
2. 用到站点插件时，把它（连同它的上级）加进 `pyproject.toml` 和 `components.lock`，两个文件里都留了写法。
3. `cp config/secrets.example.yaml config/secrets.yaml`，填 QQ 机器人、对话模型、嵌入接口的凭据。
4. `pyproject.toml` 的 `name`、这份 README、`docs/运维备忘.md` 改成这个部署的。

发布（细节见核心的 [部署与运维](https://github.com/JianShanAgent/agent-core/blob/main/docs/部署与运维.md)）：

```bash
./release pin               # 把旁边各个仓库现在的提交记进 components.lock
git commit -am "…"          # 发布号 = 这个提交的短号
./release push              # 打包上传、构建镜像（不影响正在运行的服务）
./release activate <发布号>  # 切换；起不来自动切回
./release rollback          # 切回上一个
```

## 配置

这里只写和默认值不一样的地方（默认值在核心和各插件的包里）。要改哪份配置，就新建和它同名的文件，
只写要改的项，例如 `config/plugin.chat.yaml`。凭据传到服务器用 `./release secrets`。

## 开发和测试

```bash
uv sync                                        # 核心和用到的插件，可编辑安装
JIANSHANAGENT_DRY_RUN=1 uv run jianshanagent     # 不连 QQ 试跑（同一个机器人不能两处同时在线）
```

实例仓库自己没有测试；各个仓库的测试在各自的目录里跑。

## 相关文档

- [运维备忘](docs/运维备忘.md)
- [插件规范](https://github.com/JianShanAgent/agent-core/blob/main/docs/插件规范.md)
- 核心的 [部署与运维](https://github.com/JianShanAgent/agent-core/blob/main/docs/部署与运维.md)
- 许可：[MIT](LICENSE)
