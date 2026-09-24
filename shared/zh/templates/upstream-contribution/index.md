# upstream issue/PR草稿模板——路由与纪律

> 任务改动涉及velox/velox4j/gluten仓库时，retro阶段按本单元模板产出社区issue与PR草稿，落目标项目`tasks/<task-name>/upstream/`。草稿经用户最终确认后才实际提交；Agent绝不自动提issue或PR。

## 模板选择

| 目标仓库 | issue | PR |
|---|---|---|
| apache/incubator-gluten | gluten-issue-bug.md / gluten-issue-enhancement.md | gluten-pr.md |
| facebookincubator/velox | velox-issue-bug.md / velox-issue-enhancement.md | velox-pr.md |
| bigo-sg/velox4j | 同velox（无官方模板，按velox惯例） | 同velox |

## issue纪律

- 一个表达式（或算子）只提一个issue，绝不跨仓重复：改gluten仓→gluten模板；否则→velox/velox4j模板（双仓都改时提velox——语义归属所在）。
- 新函数、新算子、能力扩展用enhancement；行为缺陷用bug。
- 提交正文用英文；字段label保持社区模板原文，不增删社区要求的字段。

## PR纪律

- 每个被改仓库一份PR草稿，按该仓模板填。
- gluten：标题带`[VL]`前缀；正文以`Fixes #<issue-id>`关联issue；按ASF政策如实填写AI声明节（`Generated-by:`或`No`）。
- 测试描述与TEST_REPORT/VERIFY.md的实际结果一致。

## 模板来源

- gluten：apache/incubator-gluten `.github/ISSUE_TEMPLATE/bug.yml`、`enhancement.yml`与`.github/PULL_REQUEST_TEMPLATE`。
- velox：facebookincubator/velox `.github/ISSUE_TEMPLATE/bug.yml`、`enhancement.yml`；velox无官方PR模板文件，velox-pr.md取社区PR惯例的最小结构。
