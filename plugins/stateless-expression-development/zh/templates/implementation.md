# IMPLEMENTATION——<task-name>

> 实现记录。交付前须自测全部通过，且通过代码审计。

## 1. 改动清单

逐文件列出，与`DESIGN.md`第4-6节一一对应：

| 层 | 文件 | 改动 | 对应设计条目 |
|---|---|---|---|
| velox | `velox/functions/flinksql/<File>.h` | 新增 | §4 |
| velox | `velox/functions/flinksql/Register.cpp` | 注册条目 | §4 |
| velox | `velox/functions/flinksql/CMakeLists.txt` | 编译条目 | §4 |
| velox | `velox/functions/flinksql/tests/<Test>.cpp` | 单测 | §7 |
| gluten | `.../RexCallConverterFactory.java` | 映射条目 | §5 |

超出设计影响清单的改动：<无/逐条说明理由（代码审计会重点核查此项）>

## 2. 构建与部署

| 环节 | 命令入口 | 结果 | 日志 |
|---|---|---|---|
| 编译（禁跳过C++构建） | flink-velox-build技能 | <成功/失败> | `tmp/<task-name>/logs/cmd-outputs/` |
| 部署（jars入`$FLINK_HOME/lib/`） | 同上 | <成功/失败> | |
| 集群重启 | | <成功/失败> | |

## 3. 单元测试

| 用例组 | 数量 | 通过 | 失败 |
|---|---|---|---|
| 基本功能 | | | |
| 类型矩阵 | | | |
| NULL/边界 | | | |
| 特殊场景 | | | |

与设计§7矩阵的对应：<逐条对上/缺X条，原因>

失败用例处理：<无/逐条：原因、修复或挂起理由（挂起须经审计同意）>

## 4. 轻量e2e自测

自构造输入→GFV集群跑通→验证脚本核对：

| 用例 | 输入 | 输出 | 验证方式 | 结果 |
|---|---|---|---|---|
| 冒烟SQL | | | <脚本/人工核对> | |

## 5. 自查清单

- [ ] 代码与设计方案一致，无超范围改动
- [ ] 无安全规范问题（空指针/越界/注入式拼接等）
- [ ] 单元测试齐全且全部通过
- [ ] code format通过（clang-format/mvn对应检查）
- [ ] 无更简单/更高效的明显替代写法（自查：冗余、不可扩展、可读性差）
