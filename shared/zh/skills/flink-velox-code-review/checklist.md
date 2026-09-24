# Flink-Velox代码评审检查清单

> **用法**：本清单驱动`flink-velox-code-review`技能的第3步（逐项走查）。按节顺序走，只执行变更面标签触发的节。每项产出且仅产出`- [ ]`（未发现问题）或`- [x]`（发现问题，带`file:line`）。

## 前奏：变更面标签（第1步输出）

从diff推导变更**类型标签**：

| 标签 | 条件 | 触发维度 |
|---|---|---|
| `arrow-res` | 新增/修改Arrow Vector / Allocator / Session / QueryResult / FieldVector | B资源管理 |
| `exception` | 新增/修改try/catch/throw/finally | C异常处理 |
| `json-serde` | 新增/修改JSON序列化类（VeloxPlan/Expression/Type） | D序列化兼容 |
| `rexcall` | 新增/修改RexCallConverterFactory / RexNode转换 | A层次边界+D序列化兼容 |
| `operator` | 新增/修改Flink Operator（open/close/processElement） | B资源管理+E生命周期 |
| `pointer` | 新增/修改C++指针操作/dynamic_cast/裸指针 | F内存安全 |
| `numeric` | 新增/修改整数运算/数组下标/除法 | G数值安全 |
| `import` | 仅import改动 | H import纪律 |
| `api-change` | 新增/修改公开方法签名/接口 | A层次边界+D兼容 |
| `other` | 以上皆非 | 仅I通用质量 |

## 检查清单（第3步）

### A. 层次边界

**触发**：标签含`rexcall`、`api-change`或`import`

- [ ] **A1** planner不导入runtime内部包（`org.apache.gluten.streaming.*`、`org.apache.gluten.vectorized.*`、`org.apache.gluten.client.*`）
- [ ] **A2** runtime不导入planner包（`org.apache.gluten.rexnode.*`、`org.apache.gluten.velox.*`）
- [ ] **A3** velox4j公开包不导入内部包
- [ ] **A4** 新的planner映射有配对的runtime处理器（仅当变更含`rexcall`时检查）

> 任一违规→CRITICAL，结论fail

### B. 资源管理

**触发**：标签含`arrow-res`或`operator`

- [ ] **B1** 新增的Arrow Vector / FieldVector在try-with-resources或try-finally中关闭
- [ ] **B2** Velox Session / QueryResult正确关闭
- [ ] **B3** Operator open()里分配的资源在close()/dispose()释放
- [ ] **B4** C++的new/malloc/allocate与delete/free/release配对
- [ ] **B5** 异常路径上资源仍被释放（检查catch块是否关闭它们）

> B1/B2/B3/B4任一违规→CRITICAL；B5→HIGH

### C. 异常处理

**触发**：标签含`exception`

- [ ] **C1** 无空catch块（`catch`后直接`}`或只有注释）
- [ ] **C2** 该用具体异常类型处没有直接catch`Exception`
- [ ] **C3** catch块不吞掉本应向上传播的异常
- [ ] **C4** finally块中无可抛出且未受保护的逻辑

> C1→CRITICAL，结论fail；C2/C3→HIGH

### D. 序列化兼容

**触发**：标签含`json-serde`或`rexcall`

- [ ] **D1** JSON序列化类的新字段追加在类末尾
- [ ] **D2** 未删除或重命名任何既有字段
- [ ] **D3** RexCallConverterFactory映射只增不改

> 任一违规→CRITICAL，结论fail

### E. 算子生命周期

**触发**：标签含`operator`

- [ ] **E1** open()调用super.open()
- [ ] **E2** close()调用super.close()
- [ ] **E3** close()幂等——重复调用不抛异常
- [ ] **E4** dispose()释放open()/close()未释放的一切

> E1/E2→HIGH；E3/E4→MEDIUM

### F. C++内存安全

**触发**：标签含`pointer`，或改动触及`.cpp`/`.h`文件

- [ ] **F1** 局部变量在所有分支上先初始化再使用
- [ ] **F2** 指针/dynamic_cast结果使用前判空
- [ ] **F3** 数组/vector访问校验下标范围
- [ ] **F4** 释放后的资源置空/reset
- [ ] **F5** 没有该用sizeof(数组)却写成sizeof(指针)

> F1/F2/F3→CRITICAL；F4/F5→MEDIUM

### G. 数值安全

**触发**：标签含`numeric`

- [ ] **G1** 除法/取模校验除数非零
- [ ] **G2** 数组下标/内存长度计算防溢出
- [ ] **G3** 有符号整数运算防溢出
- [ ] **G4** 魔法数字换成命名常量

> G1/G2/G3→CRITICAL；G4→MEDIUM

### H. import纪律

**触发**：标签含`import`，或任何Java改动

- [ ] **H1** 无通配import（`import .*`）
- [ ] **H2** import顺序符合项目惯例

> H1/H2→MEDIUM（Spotless构建期自动修复；不拦门）

### I. 通用质量

**触发**：全部改动

- [ ] **I1** 改动行内无死代码（声明了从未使用）
- [ ] **I2** 改动行内无未用的import/变量/参数
- [ ] **I3** 日志不输出敏感信息
- [ ] **I4** 改动文件不越SPEC/设计范围与任务的允许改动范围

> I4→CRITICAL，结论fail；I1/I2→LOW；I3→HIGH
