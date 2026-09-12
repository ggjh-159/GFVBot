# Flink SQL表达式参考（Flink 1.19.2）

只收录Flink原生表达式面：下列每个表达式都被未修改的Flink 1.19.2支持，且各自示例SQL已在干净的原生Flink 1.19.2集群上提交并跑完。本文档刻意与执行后端无关——只描述Flink本身接受什么、计算什么。

所有示例共用一个形态：待验证表达式位于nexmark q1形态查询投影的最后一列，数据源是16行的有界`bid`表：

| 列 | 类型 | 生成方式 |
|---|---|---|
| `auction` | BIGINT | 1-20随机 |
| `bidder` | BIGINT | 1-50随机 |
| `price` | DECIMAL(10,2) | 1.00-100.00随机 |
| `dateTime` | TIMESTAMP(3) | 随机时间戳 |
| `extra` | STRING | 12字符随机文本 |

共155个标量表达式，分12类。聚合函数、窗口/属性标记等planner内部定义不是投影表达式，不在本文范围内。

## 链路总览

表达式不是算子：它从不独立运行，而是被编译进消费它的算子。本文档收录的每个表达式在Flink 1.19.2上都经历相同阶段：

| 阶段 | 载体 | 表达式发生什么 |
|---|---|---|
| 1 解析 | `CalciteParser` | SQL文本变SqlNode；算子锚定在`FlinkSqlOperatorTable`（或由`FunctionDefinitionOperatorTable`适配） |
| 2 校验 | `FlinkCalciteSqlValidator` | 对照算子表做操作数类型检查与结果类型推导 |
| 3 转换 | `SqlNodeToOperationConversion` -> `FlinkPlannerImpl`（`SqlToRelConverter`+`SqlNodeToRexConverter`） | SqlNode变RexNode进入投影/过滤；IN与BETWEEN被改写为SEARCH（SARG）RexCall，OVERLAPS经`TemporalOverlapsConverter`展开 |
| 4 优化 | `FlinkLogicalRules`/`FlinkStreamPhysicalRules` | 只有通用移动：过滤/投影下推、`CalcMergeRule`、`ExpressionReducer`对全字面量子树常量折叠 |
| 5 ExecNode | `StreamExecCalc`（继承`CommonExecCalc`） | 携带表达式的Calc以ExecNode身份进入物理计划 |
| 6 代码生成 | `CalcCodeGenerator` -> `ExprCodeGenerator` | 每个叶调用生成Java源码，载体分三类：内联运算代码（`ScalarOperatorGens`）、助手直调（`StringCallGen`/`FunctionGenerator`->`BuiltInMethods`）、`BridgingSqlFunctionCallGen`进`flink-table-runtime`的`eval()`类 |
| 7 执行 | `CodeGenOperatorFactory` | Janino编译出`TableStreamOperator`子类，表达式在`processElement`逐行求值 |

表达式落点：投影与过滤列在Calc算子内执行；同一表达式出现在JOIN条件里在StreamExecJoin算子内执行，出现在聚合参数里在StreamExecGroupAggregate算子内执行。非确定函数（RAND、RAND_INTEGER、UUID、CURRENT_ROW_TIMESTAMP）规划期既不常量折叠也不跨算子移动。

每个表达式文档的“实现链路”一节列出它自己的五步。

## 比较函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| EQ | `=` | 比较两个操作数是否相等，相等返回TRUE；任一侧为NULL时结果为UNKNOWN（WHERE中按不满足处理）。 | [EQ](comparison/EQ.md) |
| NEQ | `<>`, `!=` | 等于的否定：两操作数不相等时返回TRUE；任一侧为NULL结果为UNKNOWN。 | [NEQ](comparison/NEQ.md) |
| LT | `<` | 排序谓词：左操作数严格小于右操作数时返回TRUE；任一侧为NULL结果为UNKNOWN。 | [LT](comparison/LT.md) |
| LE | `<=` | 排序谓词：左操作数小于等于右操作数时返回TRUE；任一侧为NULL结果为UNKNOWN。 | [LE](comparison/LE.md) |
| GT | `>` | 排序谓词：左操作数严格大于右操作数时返回TRUE；任一侧为NULL结果为UNKNOWN。 | [GT](comparison/GT.md) |
| GE | `>=` | 排序谓词：左操作数大于等于右操作数时返回TRUE；任一侧为NULL结果为UNKNOWN。 | [GE](comparison/GE.md) |
| BETWEEN | — | `x BETWEEN lo AND hi`等价于`x >= lo AND x <= hi`，两端均为闭区间；操作数为NULL时结果为UNKNOWN。 | [BETWEEN](comparison/BETWEEN.md) |
| NOT_BETWEEN | — | `x NOT BETWEEN lo AND hi`是BETWEEN的否定：x在闭区间之外时为TRUE；操作数为NULL时仍得UNKNOWN（并非简单取反）。 | [NOT_BETWEEN](comparison/NOT_BETWEEN.md) |
| IN | — | 左操作数等于列表中任一元素即返回TRUE；无匹配且任一元素（或操作数）为NULL时结果为UNKNOWN。 | [IN](comparison/IN.md) |
| IS_NULL | — | 判断值是否为NULL，返回普通TRUE或FALSE——绝不返回UNKNOWN，因此是过滤空值唯一可靠的方式。 | [IS_NULL](comparison/IS_NULL.md) |
| IS_NOT_NULL | — | IS NULL的补集，同样绝不返回UNKNOWN。 | [IS_NOT_NULL](comparison/IS_NOT_NULL.md) |
| LIKE | — | SQL通配匹配：`%`匹配任意字符序列，`_`恰好一个字符；ESCAPE指定转义字符。 | [LIKE](comparison/LIKE.md) |
| SIMILAR | `SIMILAR TO` | 经`s SIMILAR TO pattern`按SQL:1999正则匹配——其语法（字符类、基于%和_的量词）既不同于LIKE通配符也不同于Java正则。 | [SIMILAR](comparison/SIMILAR.md) |

## 逻辑函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| IS_TRUE | — | 把三值逻辑归一为二值：仅输入恰为TRUE时返回TRUE，FALSE与UNKNOWN都映射为FALSE。 | [IS_TRUE](logical/IS_TRUE.md) |
| IS_FALSE | — | 仅当输入恰为FALSE时返回TRUE——UNKNOWN与FALSE不同，此处也返回FALSE。 | [IS_FALSE](logical/IS_FALSE.md) |
| IS_NOT_TRUE | — | 输入为FALSE或UNKNOWN时返回TRUE——即除恰为TRUE以外的一切。 | [IS_NOT_TRUE](logical/IS_NOT_TRUE.md) |
| IS_NOT_FALSE | — | 输入为TRUE或UNKNOWN时返回TRUE——即除恰为FALSE以外的一切。 | [IS_NOT_FALSE](logical/IS_NOT_FALSE.md) |
| AND | — | 三值逻辑下的逻辑与：两操作数皆为TRUE才得TRUE；任一为FALSE即得FALSE；其余为UNKNOWN。 | [AND](logical/AND.md) |
| OR | — | 三值逻辑下的逻辑或：任一操作数为TRUE即得TRUE；两者皆为FALSE才得FALSE；其余为UNKNOWN。 | [OR](logical/OR.md) |
| NOT | — | 逻辑否定：TRUE变FALSE、FALSE变TRUE；UNKNOWN仍为UNKNOWN。 | [NOT](logical/NOT.md) |

## 算术函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| PLUS | `+` | 数值加法；也适用于时间类型与间隔的相加。 | [PLUS](arithmetic/PLUS.md) |
| MINUS | `-` | 数值减法、时间减间隔以及间隔相减。 | [MINUS](arithmetic/MINUS.md) |
| MULTIPLY | `*` | 数值乘法。 | [MULTIPLY](arithmetic/MULTIPLY.md) |
| DIVIDE | `/` | 数值除法。 | [DIVIDE](arithmetic/DIVIDE.md) |
| MOD | `%` | 整数除法的余数；符号与被除数一致。 | [MOD](arithmetic/MOD.md) |
| UNARY_MINUS | `-x` | 数值的一元取负。 | [UNARY_MINUS](arithmetic/UNARY_MINUS.md) |
| ABS | — | 数值的绝对值。 | [ABS](arithmetic/ABS.md) |
| FLOOR | — | 不大于x的最大整数。 | [FLOOR](arithmetic/FLOOR.md) |
| CEIL | `CEILING` | 不小于x的最小整数；CEILING为同义拼法。 | [CEIL](arithmetic/CEIL.md) |
| ROUND | — | 把x四舍五入到d位小数（默认0），常用数值类型按half-up处理。 | [ROUND](arithmetic/ROUND.md) |
| TRUNCATE | — | 把x在d位小数处截断（默认0），不做四舍五入——超出d位的数字直接丢弃。 | [TRUNCATE](arithmetic/TRUNCATE.md) |
| EXP | — | e的x次幂。 | [EXP](arithmetic/EXP.md) |
| LN | — | 自然对数（以e为底）；非正输入得NULL。 | [LN](arithmetic/LN.md) |
| LOG10 | — | 以10为底的对数；非正输入得NULL。 | [LOG10](arithmetic/LOG10.md) |
| LOG2 | — | 以2为底的对数；非正输入得NULL。 | [LOG2](arithmetic/LOG2.md) |
| LOG | — | 以显式指定底取对数；非法底数或非正输入得NULL。 | [LOG](arithmetic/LOG.md) |
| POWER | — | base的exp次幂，返回DOUBLE。 | [POWER](arithmetic/POWER.md) |
| SQRT | — | 平方根；负输入得NULL。 | [SQRT](arithmetic/SQRT.md) |
| SIGN | — | 输入的符号：-1、0或1。 | [SIGN](arithmetic/SIGN.md) |
| SIN | — | 弧度制正弦。 | [SIN](arithmetic/SIN.md) |
| COS | — | 弧度制余弦。 | [COS](arithmetic/COS.md) |
| TAN | — | 弧度制正切。 | [TAN](arithmetic/TAN.md) |
| COT | — | 余切，即余弦比正弦。 | [COT](arithmetic/COT.md) |
| ASIN | — | 反正弦（弧度）；输入超出[-1, 1]得NULL。 | [ASIN](arithmetic/ASIN.md) |
| ACOS | — | 反余弦（弧度）；输入超出[-1, 1]得NULL。 | [ACOS](arithmetic/ACOS.md) |
| ATAN | — | 反正切（弧度）。 | [ATAN](arithmetic/ATAN.md) |
| ATAN2 | — | 双参数反正切：点(y, x)的辐角，借助两个符号选定象限——与ATAN不同，能区分对角。 | [ATAN2](arithmetic/ATAN2.md) |
| SINH | — | 双曲正弦。 | [SINH](arithmetic/SINH.md) |
| COSH | — | 双曲余弦。 | [COSH](arithmetic/COSH.md) |
| TANH | — | 双曲正切；输出总在(-1, 1)内。 | [TANH](arithmetic/TANH.md) |
| DEGREES | — | 弧度转角度。 | [DEGREES](arithmetic/DEGREES.md) |
| RADIANS | — | 角度转弧度。 | [RADIANS](arithmetic/RADIANS.md) |
| PI | — | 常量pi，DOUBLE类型。 | [PI](arithmetic/PI.md) |
| E | — | 欧拉数e，DOUBLE类型。 | [E](arithmetic/E.md) |
| RAND | — | 返回[0, 1)上均匀分布的DOUBLE；不带seed时每行非确定，带seed则序列可复现。 | [RAND](arithmetic/RAND.md) |
| RAND_INTEGER | — | 返回[0, bound)内均匀分布的INTEGER；可选seed使序列可复现。 | [RAND_INTEGER](arithmetic/RAND_INTEGER.md) |
| HEX | — | 输入的十六进制文本：数值渲染为其十六进制数字，字符串渲染为其字节的十六进制。 | [HEX](arithmetic/HEX.md) |
| BIN | — | 整数的二进制（base-2）文本。 | [BIN](arithmetic/BIN.md) |
| UUID | — | 每次调用生成一个新的RFC 4122 type-4（随机）UUID字符串；非确定。 | [UUID](arithmetic/UUID.md) |

## 字符串函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| UPPER | — | 把字符串转为大写。 | [UPPER](string/UPPER.md) |
| LOWER | — | 把字符串转为小写。 | [LOWER](string/LOWER.md) |
| CHAR_LENGTH | `CHARACTER_LENGTH` | 字符串的字符数（不是字节数）。 | [CHAR_LENGTH](string/CHAR_LENGTH.md) |
| INITCAP | — | 把每个以空白分隔的单词首字母大写、其余小写。 | [INITCAP](string/INITCAP.md) |
| CONCAT | — | 把参数从左到右拼接；任一参数为NULL则返回NULL。 | [CONCAT](string/CONCAT.md) |
| CONCAT_WS | — | 以分隔符连接参数；NULL参数会被跳过而非产生空位，仅分隔符为NULL时才返回NULL。 | [CONCAT_WS](string/CONCAT_WS.md) |
| SUBSTRING | — | 从s的1基位置n开始取m个字符；省略FOR m时取到串尾。 | [SUBSTRING](string/SUBSTRING.md) |
| REPLACE | — | 把s中每次出现的search都替换为replacement。 | [REPLACE](string/REPLACE.md) |
| TRIM | — | 去掉首和/或尾部的字符；默认去掉两端空格（BOTH）。 | [TRIM](string/TRIM.md) |
| LTRIM | — | 仅去掉开头的空格。 | [LTRIM](string/LTRIM.md) |
| RTRIM | — | 仅去掉结尾的空格。 | [RTRIM](string/RTRIM.md) |
| LPAD | — | 在s左侧用pad补齐到恰好len个字符；超长输入会被截到len。 | [LPAD](string/LPAD.md) |
| RPAD | — | 在s右侧用pad补齐到恰好len个字符；超长输入会被截到len。 | [RPAD](string/RPAD.md) |
| LEFT | — | 取s的前n个字符。 | [LEFT](string/LEFT.md) |
| RIGHT | — | 取s的最后n个字符。 | [RIGHT](string/RIGHT.md) |
| REPEAT | — | 把s重复n次。 | [REPEAT](string/REPEAT.md) |
| REVERSE | — | 把s的字符顺序反转。 | [REVERSE](string/REVERSE.md) |
| POSITION | — | x在s中首次出现的位置（1基）；不存在为0；任一输入为NULL得NULL。 | [POSITION](string/POSITION.md) |
| INSTR | — | 结果同POSITION，但采用Oracle风格的参数顺序`INSTR(s, sub)`。 | [INSTR](string/INSTR.md) |
| LOCATE | — | 结果同POSITION，写法为`LOCATE(sub, s[, start])`，可选1基起点用于跳过前缀再查找。 | [LOCATE](string/LOCATE.md) |
| ASCII | — | 首字符的数字编码；空串得0。 | [ASCII](string/ASCII.md) |
| CHR | — | 按Unicode码点生成单字符字符串。 | [CHR](string/CHR.md) |
| REGEXP | `RLIKE` | 按Java正则做全串匹配，函数形式`REGEXP(s, pattern)`。 | [REGEXP](string/REGEXP.md) |
| REGEXP_REPLACE | — | 把s中每个匹配Java正则的子串替换为replacement。 | [REGEXP_REPLACE](string/REGEXP_REPLACE.md) |
| REGEXP_EXTRACT | — | 抽取首个正则匹配的第idx个捕获组（0表示整个匹配）；模式不匹配时返回NULL。 | [REGEXP_EXTRACT](string/REGEXP_EXTRACT.md) |
| SPLIT_INDEX | — | 按分隔符切分s并返回0基第index段；越界或负数下标得NULL。 | [SPLIT_INDEX](string/SPLIT_INDEX.md) |
| STR_TO_MAP | — | 以pairDelim分隔键值对、kvDelim分隔键与值，把s解析成MAP。 | [STR_TO_MAP](string/STR_TO_MAP.md) |
| PARSE_URL | — | 抽取URL的一个部分——PROTOCOL、HOST、PATH、QUERY、REF、AUTHORITY或FILE；带key参数时返回该查询参数。 | [PARSE_URL](string/PARSE_URL.md) |
| TO_BASE64 | — | 把s编码为base64文本。 | [TO_BASE64](string/TO_BASE64.md) |
| FROM_BASE64 | — | 把base64文本解码回原字符串。 | [FROM_BASE64](string/FROM_BASE64.md) |
| ENCODE | — | 按指定字符集把字符串s编码为字节，返回VARBINARY。 | [ENCODE](string/ENCODE.md) |
| DECODE | — | 按指定字符集把字节解码回STRING。 | [DECODE](string/DECODE.md) |
| OVERLAY | — | 把s中从1基位置n起、长m个字符的子串替换为r：`OVERLAY(s PLACING r FROM n FOR m)`。 | [OVERLAY](string/OVERLAY.md) |

## 时间函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| TEMPORAL_OVERLAPS | `OVERLAPS` | 判断两个时间区间是否有公共时刻：`(s1, e1) OVERLAPS (s2, e2)`；每侧可为（起，止）或（起，时长）。 | [TEMPORAL_OVERLAPS](temporal/TEMPORAL_OVERLAPS.md) |
| EXTRACT | — | 抽取一个日期时间字段——YEAR、QUARTER、MONTH、WEEK、DAY、DOY、DOW、HOUR、MINUTE、SECOND——返回整数。 | [EXTRACT](temporal/EXTRACT.md) |
| DATE_FORMAT | — | 用Java SimpleDateFormat风格的模式（如yyyy-MM-dd HH:mm:ss）格式化时间戳（或时间字符串），返回STRING。 | [DATE_FORMAT](temporal/DATE_FORMAT.md) |
| PROCTIME | — | 在DDL中标记处理时间属性；在查询里`PROCTIME()`求值为当前处理时间，类型为TIMESTAMP_LTZ。 | [PROCTIME](temporal/PROCTIME.md) |
| CURRENT_DATE | — | 会话时区下的当前SQL日期，每查询求值一次；不带括号。 | [CURRENT_DATE](temporal/CURRENT_DATE.md) |
| CURRENT_TIME | — | 当前的当天时刻，每查询求值一次，不带括号。 | [CURRENT_TIME](temporal/CURRENT_TIME.md) |
| LOCALTIME | — | 当前本地当天时间（无时区），每查询求值一次，不带括号。 | [LOCALTIME](temporal/LOCALTIME.md) |
| CURRENT_TIMESTAMP | — | 当前时刻，类型为TIMESTAMP WITH LOCAL TIME ZONE，按会话时区呈现；每查询求值一次；不带括号。 | [CURRENT_TIMESTAMP](temporal/CURRENT_TIMESTAMP.md) |
| NOW | `CURRENT_TIMESTAMP` | 与CURRENT_TIMESTAMP相同——当前时刻的TIMESTAMP_LTZ，每查询求值一次——但需带括号写作`NOW()`。 | [NOW](temporal/NOW.md) |
| LOCALTIMESTAMP | — | 当前时刻的TIMESTAMP（无时区），每查询求值一次，不带括号。 | [LOCALTIMESTAMP](temporal/LOCALTIMESTAMP.md) |
| CURRENT_ROW_TIMESTAMP | — | 求值时逐行读取的TIMESTAMP_LTZ时钟——而CURRENT_TIMESTAMP每查询固定。 | [CURRENT_ROW_TIMESTAMP](temporal/CURRENT_ROW_TIMESTAMP.md) |
| TIMESTAMPDIFF | — | 以指定单位——SECOND、MINUTE、HOUR、DAY、MONTH或YEAR（月/年差按日历计算）——表示的整数差t2减t1。 | [TIMESTAMPDIFF](temporal/TIMESTAMPDIFF.md) |
| CONVERT_TZ | — | 把无时区的时间戳字符串从一个时区换算到另一个时区，返回STRING；时区名取java.util.TimeZone的id。 | [CONVERT_TZ](temporal/CONVERT_TZ.md) |
| FROM_UNIXTIME | — | 把epoch秒（BIGINT）格式化为会话时区下的时间字符串，可选格式模式。 | [FROM_UNIXTIME](temporal/FROM_UNIXTIME.md) |
| UNIX_TIMESTAMP | — | 把时间字符串（可选格式）转换为会话时区下的epoch秒；无参时返回当前epoch秒。 | [UNIX_TIMESTAMP](temporal/UNIX_TIMESTAMP.md) |
| TO_DATE | — | 把日期字符串（默认格式yyyy-MM-dd）解析为DATE。 | [TO_DATE](temporal/TO_DATE.md) |
| TO_TIMESTAMP | — | 把时间戳字符串（默认格式yyyy-MM-dd HH:mm:ss）解析为TIMESTAMP，按会话时区解释文本。 | [TO_TIMESTAMP](temporal/TO_TIMESTAMP.md) |
| TO_TIMESTAMP_LTZ | — | 把按指定精度（0秒、3毫秒、6微秒、9纳秒）的原始epoch值转换为TIMESTAMP WITH LOCAL TIME ZONE。 | [TO_TIMESTAMP_LTZ](temporal/TO_TIMESTAMP_LTZ.md) |
| CURRENT_WATERMARK | — | 返回给定rowtime属性的当前事件时间水位线，类型为TIMESTAMP_LTZ——水位线尚未推进时为NULL；对普通非rowtime列恒为NULL。 | [CURRENT_WATERMARK](temporal/CURRENT_WATERMARK.md) |

## 条件函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| GREATEST | — | 返回参数中的最大值；任一参数为NULL则结果为NULL。 | [GREATEST](conditional/GREATEST.md) |
| LEAST | — | 返回参数中的最小值；任一参数为NULL则结果为NULL。 | [LEAST](conditional/LEAST.md) |
| CASE | — | 分支选择。 | [CASE](conditional/CASE.md) |
| COALESCE | — | 返回第一个非NULL参数（全为NULL才得NULL）；所有参数须能统一类型。 | [COALESCE](conditional/COALESCE.md) |
| IFNULL | — | 两参数版的COALESCE：`IFNULL(a, b)`在a非NULL时取a，否则取b。 | [IFNULL](conditional/IFNULL.md) |

## 类型转换函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| TYPEOF | — | 把参数的运行时类型作为STRING返回（如`BIGINT NOT NULL`）；可选force标志按原样求参数的SQL文本。 | [TYPEOF](type-conversion/TYPEOF.md) |
| CAST | — | 显式类型转换，覆盖很宽的矩阵——数值的拓宽与收窄、字符串与数值互转、字符串与时间互转、复合类型的重标注。 | [CAST](type-conversion/CAST.md) |
| TRY_CAST | — | 与CAST相同的转换矩阵，但转换失败得NULL而非报错。 | [TRY_CAST](type-conversion/TRY_CAST.md) |

## 集合函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| AT | `[]`, ITEM | 用[]运算符取元素：`arr[i]`读数组第i个元素（1基），`map[k]`按键查值。 | [AT](collection/AT.md) |
| CARDINALITY | — | 数组或map的元素个数；输入为NULL得NULL。 | [CARDINALITY](collection/CARDINALITY.md) |
| ELEMENT | — | 返回单元素数组中唯一的元素；空数组得NULL；多于一个元素则报错。 | [ELEMENT](collection/ELEMENT.md) |
| ARRAY_CONTAINS | — | 数组包含该值时返回TRUE。 | [ARRAY_CONTAINS](collection/ARRAY_CONTAINS.md) |
| ARRAY_DISTINCT | — | 去掉重复元素，按首次出现顺序保留。 | [ARRAY_DISTINCT](collection/ARRAY_DISTINCT.md) |
| ARRAY_POSITION | — | 值首次出现位置的1基下标；不存在为0；数组为NULL得NULL。 | [ARRAY_POSITION](collection/ARRAY_POSITION.md) |
| ARRAY_REMOVE | — | 删除数组中所有出现的该值。 | [ARRAY_REMOVE](collection/ARRAY_REMOVE.md) |
| ARRAY_REVERSE | — | 反转元素顺序。 | [ARRAY_REVERSE](collection/ARRAY_REVERSE.md) |
| ARRAY_SLICE | — | 取从1基start到end（含端点）的子数组。 | [ARRAY_SLICE](collection/ARRAY_SLICE.md) |
| ARRAY_UNION | — | 两数组求并集并去重。 | [ARRAY_UNION](collection/ARRAY_UNION.md) |
| ARRAY_CONCAT | — | 拼接两个数组并保留所有元素（不去重）。 | [ARRAY_CONCAT](collection/ARRAY_CONCAT.md) |
| ARRAY_MAX | — | 数组中的最大元素；NULL元素被跳过，数组为NULL得NULL。 | [ARRAY_MAX](collection/ARRAY_MAX.md) |
| ARRAY_MIN | — | 数组中的最小元素；NULL元素被跳过，数组为NULL得NULL。 | [ARRAY_MIN](collection/ARRAY_MIN.md) |
| ARRAY_JOIN | — | 用分隔符把数组元素连成一个字符串；NULL元素被跳过，除非给出nullReplacement；数组为NULL得NULL。 | [ARRAY_JOIN](collection/ARRAY_JOIN.md) |
| MAP_KEYS | — | 按键的迭代顺序返回键数组。 | [MAP_KEYS](collection/MAP_KEYS.md) |
| MAP_VALUES | — | 按值的迭代顺序返回值数组。 | [MAP_VALUES](collection/MAP_VALUES.md) |
| MAP_ENTRIES | — | 把map表示为ROW(key, value)对的数组。 | [MAP_ENTRIES](collection/MAP_ENTRIES.md) |
| MAP_FROM_ARRAYS | — | 由两个等长数组构造MAP——先键数组后值数组。 | [MAP_FROM_ARRAYS](collection/MAP_FROM_ARRAYS.md) |

## JSON函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| IS_JSON | `IS JSON` | 中缀谓词，判断文本是否为合法JSON，可选限定类别：`v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`。 | [IS_JSON](json/IS_JSON.md) |
| JSON_EXISTS | — | SQL/JSON路径在文档中定位到至少一个值时返回TRUE。 | [JSON_EXISTS](json/JSON_EXISTS.md) |
| JSON_VALUE | — | 抽取SQL/JSON路径处的标量并按字符串（或RETURNING类型）返回；ON EMPTY/ON ERROR子句决定路径缺失或类型不匹配时的行为。 | [JSON_VALUE](json/JSON_VALUE.md) |
| JSON_QUERY | — | 抽取路径处的JSON对象或数组并按JSON文本返回；WRAPPER子句控制结果是否包一层数组。 | [JSON_QUERY](json/JSON_QUERY.md) |
| JSON_STRING | — | 把任意SQL值——包括嵌套row与集合——序列化为JSON文本。 | [JSON_STRING](json/JSON_STRING.md) |
| JSON_OBJECT | — | 由KEY VALUE对构造JSON对象；NULL ON NULL保留NULL值，ABSENT ON NULL将其省略。 | [JSON_OBJECT](json/JSON_OBJECT.md) |
| JSON_ARRAY | — | 由参数构造JSON数组，NULL元素同样可选NULL ON NULL或ABSENT ON NULL。 | [JSON_ARRAY](json/JSON_ARRAY.md) |

## 值构造函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| ARRAY | — | 数组构造器`ARRAY[v1, v2, ...]`；各元素统一为公共元素类型。 | [ARRAY](value-construction/ARRAY.md) |
| MAP | — | map构造器`MAP[k1, v1, k2, v2, ...]`——键值交替书写；键与值各自统一类型。 | [MAP](value-construction/MAP.md) |
| ROW | — | 行构造器`ROW(v1, v2, ...)`生成匿名的复合值，字段名为f0、f1等（可用AS重命名）。 | [ROW](value-construction/ROW.md) |

## 哈希函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| MD5 | — | 字符串的128位MD5摘要，渲染为32个小写十六进制字符。 | [MD5](hash/MD5.md) |
| SHA1 | — | 160位SHA-1摘要，40个小写十六进制字符。 | [SHA1](hash/SHA1.md) |
| SHA224 | — | 224位SHA-2摘要，56个小写十六进制字符。 | [SHA224](hash/SHA224.md) |
| SHA256 | — | 256位SHA-2摘要，64个小写十六进制字符。 | [SHA256](hash/SHA256.md) |
| SHA384 | — | 384位SHA-2摘要，96个小写十六进制字符。 | [SHA384](hash/SHA384.md) |
| SHA512 | — | 512位SHA-2摘要，128个小写十六进制字符。 | [SHA512](hash/SHA512.md) |
| SHA2 | — | 按指定长度取SHA-2摘要——hashLength为224、256、384或512（十六进制字符数相同）；0选256；其他长度会被拒绝。 | [SHA2](hash/SHA2.md) |

## 辅助函数

| 表达式 | 别名 | 简介 | 文档 |
|---|---|---|---|
| CURRENT_DATABASE | — | 把会话当前数据库名作为STRING返回。 | [CURRENT_DATABASE](auxiliary/CURRENT_DATABASE.md) |
