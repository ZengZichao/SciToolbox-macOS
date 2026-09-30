# 发布清单（PUBLISHING CHECKLIST）

本文件记录将 SciToolbox 开源发布到 GitHub 前需要完成的步骤。

**当前状态**：仓库已创建并推送 → <https://github.com/ZengZichao/SciToolbox>（Public）。
GitHub Pages 已启用（`main` / `/docs`），隐私政策与支持页已上线。
`v1.0.0` 已打 tag 并发布 GitHub Release，`.dmg` 由 `.github/workflows/release.yml` 自动构建上传。
Zenodo 已归档并 mint DOI，详见下方"Zenodo 归档与 DOI"。

## 发布前你需要做的

1. **补上 `CITATION.cff` 的 ORCID**
   - `repository-code` 已填实为真实仓库地址 ✅
   - `authors[0].orcid` 目前**处于注释状态**（原先的 `0000-0000-0000-0000` 是无效值，
     填进已公开的引用文件会误导他人，故先注释掉）。拿到真实 ORCID 后取消注释并填入。
2. **确认 KEGG 合规口径**（`COMPLIANCE.md` 已按"学术/非商业调用其公开 REST 检索"写清；如需商用，请先取得 KEGG 许可）。
3. **~~申请 GitHub 仓库~~** ✅ 已完成：<https://github.com/ZengZichao/SciToolbox>（Public）。
4. **~~申请 Zenodo DOI~~** ✅ 已完成：`v1.0.0` → <https://doi.org/10.5281/zenodo.23053444>，
   DOI 已回填到 `CITATION.cff` 与两份 README 徽章。

## 仓库结构：开发历史与公开仓库分开

公开仓库 <https://github.com/ZengZichao/SciToolbox> **只有一个提交**，不含任何开发历史。
本地对应两个目录：

| 目录 | 作用 |
|---|---|
| `SciToolbox-项目代码/` | 完整开发历史，**只留在本地**。不要向公开仓库推送：两边历史无关联，会被判非快进而拒绝 |
| `公开仓库/` | 公开仓库的唯一推送源，`origin` 指向 GitHub |

日常开发在开发目录做；要公开时把变更同步进 `公开仓库/`（整目录覆盖即可，但注意
`.gitignore` 里那四个永不入库的文件别跟过去），再在 `公开仓库/` 里提交、推送。

## 发版流程

以下都在 `公开仓库/` 目录里执行。

1. **同步版本号**（四处，漏改会导致产物与 tag 不一致）：
   - `build-app.sh` 的 `MARKETING_VERSION`
   - `SciToolbox.xcodeproj` 的 `MARKETING_VERSION`
   - `CHANGELOG.md` 新增版本段落
   - `CITATION.cff` 的 `version`
2. **提交并推送**：
   ```bash
   git add -A && git commit -m "release: v<版本>" && git push origin main
   ```
3. **建 Release**（正文从 `CHANGELOG.md` 对应段落整理，**此时先不要写校验和**）：
   ```bash
   gh release create v<版本> --title "SciToolbox <版本>" --notes-file <正文文件>
   ```
   标签由 GitHub 服务端创建，不需要 `git push --tags`。若 Zenodo 归档要求**附注标签**，
   改成先 `git tag -a v<版本> -m "SciToolbox <版本>" && git push origin v<版本>`，
   再用 `gh release create v<版本>` 复用该标签。
4. **等 `.dmg` 构建完成后回填校验和**：
   ```bash
   gh release download v<版本> --pattern '*.dmg' --clobber
   shasum -a 256 SciToolbox-<版本>.dmg          # 把结果写进正文
   gh release edit v<版本> --notes-file <正文文件>
   ```

`.dmg` 与 `.sha256.txt` 由 `.github/workflows/release.yml` 在 Release 发布后自动构建上传，
**不需要**手动传；源码归档（`tar.gz` / `zip`）由 GitHub 从 tag 自动生成。

> ⚠️ **校验和只能最后回填。** 任何一次重新发布 release、移动 `v<版本>` 标签、或重跑 Release workflow
> 都会重新构建并覆盖 `.dmg`，产物字节随之改变，正文里预先写死的校验和立刻失效
> （本项目实际踩过：用户按说明执行 `shasum -c` 会失败）。回填完成后就不要再动这个标签。

## Zenodo 归档与 DOI

- `v1.0.0` 记录：<https://doi.org/10.5281/zenodo.23053444>（版本 DOI）；跨版本聚合用 concept DOI
  <https://doi.org/10.5281/zenodo.23053443>。以后正常发新 tag，Zenodo 会自动挂在同一 concept DOI 下成为新版本。
- 徽章写法用 `https://zenodo.org/badge/DOI/<DOI>.svg`；`https://zenodo.org/badge/<记录号>.svg` 这种形式在新 Zenodo 上 404。
- **Zenodo 只归档 tag 的源码 zipball，不含 `.dmg`**：这是新平台的设计（`invenio-rdm-records` 的
  `_upload_files_to_draft` 只取 zipball），不是同步失败。二进制分发仍以 GitHub Release 为准。
- 记录元数据来自 **tag 那个 commit 里的 `CITATION.cff`**（没有 `.zenodo.json` 时），改 `main` 上的文件不会影响
  已生成的记录；要改元数据只能在 Zenodo 草稿阶段改，发布后不可变。
- **某次 release 早于 Zenodo 同步开关时不会生成 DOI，而且编辑 release 无效**——Zenodo 接收器只处理
  `action ∈ {published, released, created}` 且 `draft=false` 的 webhook，`edited` 直接被丢弃。补救办法是
  先把该 release 转草稿再发布回来：
  ```bash
  gh api -X PATCH repos/ZengZichao/SciToolbox-macOS/releases/<release-id> -F draft=true
  gh api -X PATCH repos/ZengZichao/SciToolbox-macOS/releases/<release-id> -F draft=false
  ```
  tag、版本号、下载 URL 都不变（但资源 ID 会因 CI 重新上传而变化）；GitHub 显示的发布日期会刷新成
  重新发布那天（改不回来），Zenodo 记录的出版日可在草稿发布前手工填成真实发版日。
  ⚠️ **这一招会重跑 `.github/workflows/release.yml`**（它的触发条件正是 `release: [published]`），
  `.dmg` 会被重新构建并覆盖上传：资源 ID 和校验和都会变（sidecar 由 CI 自动重算，但正文里手写的
  预期 SHA-256 必须按第 4 步重新回填）。v1.0.0 实测：`793614a3…` → `02308242…`。

## 给审稿人/用户的关键提示
- **平台限制**：SciToolbox 目前仅支持 macOS 15+（SwiftUI）。若计划投 JOSS 等需审稿人可运行/复现的期刊，请在投稿前说明此限制，或提供录屏/构建说明；更彻底的作法是把与 GUI 无关的核心（`ToolProvider` / `APIClient` / `AccessionRouter`）抽成跨平台 Swift 包或 CLI。
- **维护预期**：见 `CONTRIBUTING.md` 的 "Support expectations"——best-effort 维护。
- **许可**：GPL-3.0。分发二进制时须同时提供对应源码（本仓库即源码）。
