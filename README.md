<p align="center"><img src="assets/icon.svg" width="88" alt="JianShanAgent"></p>

<h1 align="center">template-instance</h1>

<p align="center">给你自己的 wiki 部署一个<a href="https://github.com/JianShanAgent/agent-core">见山</a>，从这里开始。</p>

<p align="center">
  <img src="https://img.shields.io/badge/模板-实例-2f6b5a?style=flat-square&labelColor=1f3b34" alt="模板：实例">
  <img src="https://img.shields.io/github/license/JianShanAgent/template-instance?label=License&color=2f6b5a&style=flat-square&labelColor=1f3b34" alt="License">
</p>

<sub>Template for a JianShanAgent deployment: configuration, pinned component versions and a release entry point. Documentation is in Chinese.</sub>

## 这是什么

见山的[核心](https://github.com/JianShanAgent/agent-core)不知道自己要服务哪个 wiki、部署到哪台机器。这些是「实例」的事：一个很小的仓库，
写明服务哪个 wiki、用哪些插件的哪个版本。这个模板就是一个空的实例。

复制下来填上 wiki 的地址，就是一个能跑的、纯 MediaWiki 的问答机器人。一个填好了的例子是 [`instance-yys`](https://github.com/JianShanAgent/instance-yys)。

## 四步跑起来

**1. 复制。** 点仓库页面上的「Use this template」，新仓库叫 `instance-<名字>`。克隆下来，和 [`agent-core`](https://github.com/JianShanAgent/agent-core) 并排放在同一个目录下。

**2. 填 wiki。** 打开 [`config/core.wiki.yaml`](config/core.wiki.yaml)，里面是占位的，填上才能启动：

```yaml
name: "某某"                              # 这个 wiki 讲的是什么
api_url: "https://your.wiki/api.php"      # MediaWiki 的接口地址
```

**3. 填凭据，在本机试。**

```bash
cp config/secrets.example.yaml config/secrets.yaml   # QQ 机器人、对话模型、嵌入接口
uv sync
JIANSHANAGENT_DRY_RUN=1 uv run jianshanagent           # 不连 QQ 试跑
```

**4. 发布。** 在 [`release`](release) 里填 `SSH_HOST`（发布到哪台服务器），然后：

```bash
./release pin && git commit -am "第一次发布"
./release push
./release activate <发布号>
```

第一次部署要先在服务器上初始化一次，步骤在核心的[部署与运维](https://github.com/JianShanAgent/agent-core/blob/main/docs/部署与运维.md)里。

## 想让它更懂你的 wiki

纯 MediaWiki 的机器人只认页面。要让它认得这个站的昵称、去掉这个站的模板噪声、用这个站的说法，写一个站点插件
（模板 [`template-site-wiki`](https://github.com/JianShanAgent/template-site-wiki)），然后在这里的三个地方加上它：

| 在哪 | 加什么 |
|---|---|
| `config/core.wiki.yaml` | `site: <插件的 id>` |
| `pyproject.toml` | 依赖里列上它（和它的上级），文件里留了写法 |
| `components.lock` | 一行：名字、目录、提交（先写 40 个 0，`./release pin` 会填上） |

## 这里面有什么

```text
config/
  core.wiki.yaml          服务哪个 wiki（占位，要填）
  secrets.example.yaml    凭据的模板；真的 secrets.yaml 不入库
  local/                  开发机的调试覆写，不入库
components.lock           用哪几个仓库的哪个提交
release                   发布入口；发布到哪台服务器也写在里面
pyproject.toml            开发环境：核心和插件都用旁边目录里的源码
docs/运维备忘.md           这个部署的现状（骨架，要填）
```

`config/` 里只写和默认值不一样的地方。要改哪份配置，就建一个和它同名的文件，只写要改的项。

> 实例仓库要是公开的，服务器的地址、登录方式别写进 `docs/运维备忘.md`，另放一个不入库的文件。

命名的规矩见[插件规范](https://github.com/JianShanAgent/agent-core/blob/main/docs/插件规范.md)。全部仓库的目录在[组织主页](https://github.com/JianShanAgent)。

## 许可

[MIT](LICENSE)
