# Flink SQL Expressions Reference (Flink 1.19.2)

Native Flink expression surface only: every expression below is supported by unmodified Flink 1.19.2, and each one's example SQL was submitted and run to completion on a clean native Flink 1.19.2 cluster. This reference is deliberately backend-agnostic — it documents what Flink itself accepts and computes.

All examples share one shape: the expression under test sits in the last projection column of a nexmark-q1-style query over a bounded 16-row `bid` source:

| Column | Type | Generation |
|---|---|---|
| `auction` | BIGINT | random 1-20 |
| `bidder` | BIGINT | random 1-50 |
| `price` | DECIMAL(10,2) | random 1.00-100.00 |
| `dateTime` | TIMESTAMP(3) | random timestamp |
| `extra` | STRING | random 12-character text |

155 scalar expressions in 12 categories. Aggregate functions, window/property markers, and other planner-internal definitions are not projection expressions and are out of scope.

## Pipeline overview

An expression is not an operator: it never runs on its own, it is compiled *into* whichever operator consumes it. Every expression documented here travels the same stages on Flink 1.19.2:

| Stage | Carrier | What happens to the expression |
|---|---|---|
| 1 Parse | `CalciteParser` | SQL text becomes a SqlNode; the operator is anchored in `FlinkSqlOperatorTable` (or adapted by `FunctionDefinitionOperatorTable`) |
| 2 Validate | `FlinkCalciteSqlValidator` | operand type checks and result type derivation against the operator table |
| 3 Convert | `SqlNodeToOperationConversion` -> `FlinkPlannerImpl` (`SqlToRelConverter` + `SqlNodeToRexConverter`) | the SqlNode becomes a RexNode inside a projection/filter; IN and BETWEEN are rewritten into SEARCH (SARG) RexCalls, OVERLAPS is expanded by `TemporalOverlapsConverter` |
| 4 Optimize | `FlinkLogicalRules` / `FlinkStreamPhysicalRules` | generic moves only: filter/project push-down, `CalcMergeRule`, constant folding of fully literal subtrees by `ExpressionReducer` |
| 5 ExecNode | `StreamExecCalc` (extends `CommonExecCalc`) | the Calc carrying the expression enters the physical plan as an ExecNode |
| 6 Codegen | `CalcCodeGenerator` -> `ExprCodeGenerator` | every leaf call is turned into Java source through one of three carrier families: inlined operator code (`ScalarOperatorGens`), helper calls (`StringCallGen` / `FunctionGenerator` -> `BuiltInMethods`), or `BridgingSqlFunctionCallGen` into a `flink-table-runtime` `eval()` class |
| 7 Execute | `CodeGenOperatorFactory` | Janino compiles a `TableStreamOperator` subclass; the expression is evaluated per row in `processElement` |

Where expressions end up: projection and filter columns run inside the Calc operator; the same expression in a join condition runs inside the StreamExecJoin operator, and in an aggregate argument inside the StreamExecGroupAggregate operator. Non-deterministic functions (RAND, RAND_INTEGER, UUID, CURRENT_ROW_TIMESTAMP) are neither constant-folded nor moved across operators during planning.

Each expression's doc lists its own five steps under "Pipeline".

## Comparison

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| EQ | `=` | Compares two operands for equality and returns TRUE when they are equal; if either side is NULL the result is UNKNOWN (treated as not-matching by WHERE). | [EQ](comparison/EQ.md) |
| NEQ | `<>`, `!=` | Negated equality: TRUE when the operands differ; NULL on either side yields UNKNOWN. | [NEQ](comparison/NEQ.md) |
| LT | `<` | Ordering predicate: TRUE when the left operand is strictly less than the right; NULL on either side yields UNKNOWN. | [LT](comparison/LT.md) |
| LE | `<=` | Ordering predicate: TRUE when the left operand is less than or equal to the right; NULL on either side yields UNKNOWN. | [LE](comparison/LE.md) |
| GT | `>` | Ordering predicate: TRUE when the left operand is strictly greater than the right; NULL on either side yields UNKNOWN. | [GT](comparison/GT.md) |
| GE | `>=` | Ordering predicate: TRUE when the left operand is greater than or equal to the right; NULL on either side yields UNKNOWN. | [GE](comparison/GE.md) |
| BETWEEN | — | `x BETWEEN lo AND hi` is shorthand for `x >= lo AND x <= hi` — inclusive on both ends; NULL operands yield UNKNOWN. | [BETWEEN](comparison/BETWEEN.md) |
| NOT_BETWEEN | — | `x NOT BETWEEN lo AND hi` is the negation of BETWEEN: TRUE when x lies outside the closed range; NULL operands still yield UNKNOWN (outside-or-unknown is not simply the inverse). | [NOT_BETWEEN](comparison/NOT_BETWEEN.md) |
| IN | — | TRUE when the left operand equals any element of the value list; when nothing matches but any element (or the operand) is NULL, the result is UNKNOWN. | [IN](comparison/IN.md) |
| IS_NULL | — | Tests whether a value is NULL and returns plain TRUE or FALSE — never UNKNOWN — which makes it the only reliable null filter. | [IS_NULL](comparison/IS_NULL.md) |
| IS_NOT_NULL | — | The complement of IS NULL, likewise never returning UNKNOWN. | [IS_NOT_NULL](comparison/IS_NOT_NULL.md) |
| LIKE | — | SQL wildcard match: `%` matches any run of characters, `_` exactly one; ESCAPE designates an escape character. | [LIKE](comparison/LIKE.md) |
| SIMILAR | `SIMILAR TO` | Matches against an SQL:1999 regular expression via `s SIMILAR TO pattern` — its syntax (character classes, quantifiers over % and _) is distinct from both LIKE wildcards and Java regex. | [SIMILAR](comparison/SIMILAR.md) |

## Logical

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| IS_TRUE | — | Normalizes three-valued logic to two-valued: TRUE only for an input that is exactly TRUE; FALSE and UNKNOWN both map to FALSE. | [IS_TRUE](logical/IS_TRUE.md) |
| IS_FALSE | — | TRUE only when the input is exactly FALSE — UNKNOWN is kept distinct and yields FALSE here. | [IS_FALSE](logical/IS_FALSE.md) |
| IS_NOT_TRUE | — | TRUE when the input is FALSE or UNKNOWN — i.e. | [IS_NOT_TRUE](logical/IS_NOT_TRUE.md) |
| IS_NOT_FALSE | — | TRUE when the input is TRUE or UNKNOWN — anything but exactly FALSE. | [IS_NOT_FALSE](logical/IS_NOT_FALSE.md) |
| AND | — | Logical conjunction under three-valued logic: TRUE only when both operands are TRUE; FALSE as soon as either is FALSE; otherwise UNKNOWN. | [AND](logical/AND.md) |
| OR | — | Logical disjunction under three-valued logic: TRUE when either operand is TRUE; FALSE only when both are FALSE; otherwise UNKNOWN. | [OR](logical/OR.md) |
| NOT | — | Logical negation: TRUE becomes FALSE and vice versa; UNKNOWN stays UNKNOWN. | [NOT](logical/NOT.md) |

## Arithmetic

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| PLUS | `+` | Numeric addition; also valid between temporal types and intervals. | [PLUS](arithmetic/PLUS.md) |
| MINUS | `-` | Numeric subtraction, temporal minus interval, and interval differences. | [MINUS](arithmetic/MINUS.md) |
| MULTIPLY | `*` | Numeric multiplication. | [MULTIPLY](arithmetic/MULTIPLY.md) |
| DIVIDE | `/` | Numeric division. | [DIVIDE](arithmetic/DIVIDE.md) |
| MOD | `%` | Remainder of integer division; the sign follows the dividend. | [MOD](arithmetic/MOD.md) |
| UNARY_MINUS | `-x` | Prefix negation of a numeric value. | [UNARY_MINUS](arithmetic/UNARY_MINUS.md) |
| ABS | — | Absolute value of a numeric input. | [ABS](arithmetic/ABS.md) |
| FLOOR | — | Largest integer not greater than x. | [FLOOR](arithmetic/FLOOR.md) |
| CEIL | `CEILING` | Smallest integer not less than x; CEILING is the alternate spelling. | [CEIL](arithmetic/CEIL.md) |
| ROUND | — | Rounds x to d decimal places (default 0) using half-up rounding for the common numeric types. | [ROUND](arithmetic/ROUND.md) |
| TRUNCATE | — | Cuts x off at d decimal places (default 0) with no rounding — the digits beyond d are simply dropped toward zero. | [TRUNCATE](arithmetic/TRUNCATE.md) |
| EXP | — | e raised to the power x. | [EXP](arithmetic/EXP.md) |
| LN | — | Natural logarithm (base e); non-positive input yields NULL. | [LN](arithmetic/LN.md) |
| LOG10 | — | Base-10 logarithm; non-positive input yields NULL. | [LOG10](arithmetic/LOG10.md) |
| LOG2 | — | Base-2 logarithm; non-positive input yields NULL. | [LOG2](arithmetic/LOG2.md) |
| LOG | — | Logarithm of x to the explicit base; invalid base or non-positive input yields NULL. | [LOG](arithmetic/LOG.md) |
| POWER | — | base raised to the exponent, returned as DOUBLE. | [POWER](arithmetic/POWER.md) |
| SQRT | — | Square root; negative input yields NULL. | [SQRT](arithmetic/SQRT.md) |
| SIGN | — | Sign of the input: -1, 0, or 1. | [SIGN](arithmetic/SIGN.md) |
| SIN | — | Sine of an angle in radians. | [SIN](arithmetic/SIN.md) |
| COS | — | Cosine of an angle in radians. | [COS](arithmetic/COS.md) |
| TAN | — | Tangent of an angle in radians. | [TAN](arithmetic/TAN.md) |
| COT | — | Cotangent, i.e. | [COT](arithmetic/COT.md) |
| ASIN | — | Arc sine in radians; input outside [-1, 1] yields NULL. | [ASIN](arithmetic/ASIN.md) |
| ACOS | — | Arc cosine in radians; input outside [-1, 1] yields NULL. | [ACOS](arithmetic/ACOS.md) |
| ATAN | — | Arc tangent in radians. | [ATAN](arithmetic/ATAN.md) |
| ATAN2 | — | Two-argument arc tangent: the angle of the point (y, x), using both signs to pick the quadrant — unlike ATAN it distinguishes opposite corners. | [ATAN2](arithmetic/ATAN2.md) |
| SINH | — | Hyperbolic sine. | [SINH](arithmetic/SINH.md) |
| COSH | — | Hyperbolic cosine. | [COSH](arithmetic/COSH.md) |
| TANH | — | Hyperbolic tangent; output always within (-1, 1). | [TANH](arithmetic/TANH.md) |
| DEGREES | — | Converts radians to degrees. | [DEGREES](arithmetic/DEGREES.md) |
| RADIANS | — | Converts degrees to radians. | [RADIANS](arithmetic/RADIANS.md) |
| PI | — | The constant pi as a DOUBLE. | [PI](arithmetic/PI.md) |
| E | — | Euler's number e as a DOUBLE. | [E](arithmetic/E.md) |
| RAND | — | Uniformly distributed DOUBLE in [0, 1); non-deterministic per row unless a seed is supplied, in which case the sequence is reproducible. | [RAND](arithmetic/RAND.md) |
| RAND_INTEGER | — | Uniformly distributed INTEGER in [0, bound); an optional seed makes the sequence reproducible. | [RAND_INTEGER](arithmetic/RAND_INTEGER.md) |
| HEX | — | Hexadecimal text of its input: a numeric value renders as its hex digits, a string as the hex of its bytes. | [HEX](arithmetic/HEX.md) |
| BIN | — | Binary (base-2) text of an integer. | [BIN](arithmetic/BIN.md) |
| UUID | — | Generates a fresh RFC 4122 type-4 (random) UUID string per call; non-deterministic. | [UUID](arithmetic/UUID.md) |

## String

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| UPPER | — | Converts a string to uppercase. | [UPPER](string/UPPER.md) |
| LOWER | — | Converts a string to lowercase. | [LOWER](string/LOWER.md) |
| CHAR_LENGTH | `CHARACTER_LENGTH` | Number of characters (not bytes) in a string. | [CHAR_LENGTH](string/CHAR_LENGTH.md) |
| INITCAP | — | Capitalizes the first letter of each whitespace-separated word and lowercases the rest. | [INITCAP](string/INITCAP.md) |
| CONCAT | — | Concatenates its arguments left to right; returns NULL if any argument is NULL. | [CONCAT](string/CONCAT.md) |
| CONCAT_WS | — | Concatenates with the separator between arguments; NULL arguments are skipped rather than producing empty slots, and only a NULL separator yields NULL. | [CONCAT_WS](string/CONCAT_WS.md) |
| SUBSTRING | — | Extracts the substring of s starting at 1-based position n for m characters; without FOR m it runs to the end of the string. | [SUBSTRING](string/SUBSTRING.md) |
| REPLACE | — | Replaces every occurrence of search with replacement in s. | [REPLACE](string/REPLACE.md) |
| TRIM | — | Removes leading and/or trailing characters; by default spaces from both ends (BOTH). | [TRIM](string/TRIM.md) |
| LTRIM | — | Removes leading spaces only. | [LTRIM](string/LTRIM.md) |
| RTRIM | — | Removes trailing spaces only. | [RTRIM](string/RTRIM.md) |
| LPAD | — | Pads s on the left with pad until it is exactly len characters; longer inputs are cut down to len. | [LPAD](string/LPAD.md) |
| RPAD | — | Pads s on the right with pad until it is exactly len characters; longer inputs are cut down to len. | [RPAD](string/RPAD.md) |
| LEFT | — | The first n characters of s. | [LEFT](string/LEFT.md) |
| RIGHT | — | The last n characters of s. | [RIGHT](string/RIGHT.md) |
| REPEAT | — | s repeated n times. | [REPEAT](string/REPEAT.md) |
| REVERSE | — | s with its characters in reverse order. | [REVERSE](string/REVERSE.md) |
| POSITION | — | 1-based position of the first occurrence of x in s; 0 when absent; NULL when either input is NULL. | [POSITION](string/POSITION.md) |
| INSTR | — | Same result as POSITION with Oracle-style argument order `INSTR(s, sub)`. | [INSTR](string/INSTR.md) |
| LOCATE | — | Same result as POSITION spelled `LOCATE(sub, s[, start])`, with an optional 1-based start offset for searching after a prefix. | [LOCATE](string/LOCATE.md) |
| ASCII | — | Numeric code of the first character; an empty string yields 0. | [ASCII](string/ASCII.md) |
| CHR | — | The single-character string for the given Unicode code point. | [CHR](string/CHR.md) |
| REGEXP | `RLIKE` | Full-string match against a Java regular expression, function form `REGEXP(s, pattern)`. | [REGEXP](string/REGEXP.md) |
| REGEXP_REPLACE | — | Replaces every substring of s that matches the Java regex with replacement. | [REGEXP_REPLACE](string/REGEXP_REPLACE.md) |
| REGEXP_EXTRACT | — | Extracts the idx-th capture group of the first regex match (0 means the whole match); returns NULL when the pattern does not match. | [REGEXP_EXTRACT](string/REGEXP_EXTRACT.md) |
| SPLIT_INDEX | — | Splits s by the delimiter and returns the 0-based index-th piece; an out-of-range or negative index yields NULL. | [SPLIT_INDEX](string/SPLIT_INDEX.md) |
| STR_TO_MAP | — | Parses s into a MAP using pairDelim between pairs and kvDelim between key and value. | [STR_TO_MAP](string/STR_TO_MAP.md) |
| PARSE_URL | — | Extracts one part of a URL — PROTOCOL, HOST, PATH, QUERY, REF, AUTHORITY, or FILE; with a key argument it returns that single query parameter. | [PARSE_URL](string/PARSE_URL.md) |
| TO_BASE64 | — | Encodes s into its base64 text. | [TO_BASE64](string/TO_BASE64.md) |
| FROM_BASE64 | — | Decodes base64 text back into the original string. | [FROM_BASE64](string/FROM_BASE64.md) |
| ENCODE | — | Encodes string s into bytes with the given charset, returning VARBINARY. | [ENCODE](string/ENCODE.md) |
| DECODE | — | Decodes bytes with the given charset back into a STRING. | [DECODE](string/DECODE.md) |
| OVERLAY | — | Replaces the substring of s that starts at 1-based position n and spans m characters with r: `OVERLAY(s PLACING r FROM n FOR m)`. | [OVERLAY](string/OVERLAY.md) |

## Temporal

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| TEMPORAL_OVERLAPS | `OVERLAPS` | Tests whether two time intervals share at least one instant: `(s1, e1) OVERLAPS (s2, e2)`; each side is a (start, end) pair or a (start, interval). | [TEMPORAL_OVERLAPS](temporal/TEMPORAL_OVERLAPS.md) |
| EXTRACT | — | Pulls out one datetime field — YEAR, QUARTER, MONTH, WEEK, DAY, DOY, DOW, HOUR, MINUTE, SECOND — as an integer. | [EXTRACT](temporal/EXTRACT.md) |
| DATE_FORMAT | — | Formats a timestamp (or timestamp string) with a Java SimpleDateFormat-style pattern such as yyyy-MM-dd HH:mm:ss, returning a STRING. | [DATE_FORMAT](temporal/DATE_FORMAT.md) |
| PROCTIME | — | In a DDL it marks a processing-time attribute; inside a query `PROCTIME()` evaluates to the current processing time as TIMESTAMP_LTZ. | [PROCTIME](temporal/PROCTIME.md) |
| CURRENT_DATE | — | The current SQL date in the session time zone, evaluated once per query; written without parentheses. | [CURRENT_DATE](temporal/CURRENT_DATE.md) |
| CURRENT_TIME | — | The current time of day, evaluated once per query and written without parentheses. | [CURRENT_TIME](temporal/CURRENT_TIME.md) |
| LOCALTIME | — | The current local time of day without time zone, per query, no parentheses. | [LOCALTIME](temporal/LOCALTIME.md) |
| CURRENT_TIMESTAMP | — | The current instant as TIMESTAMP WITH LOCAL TIME ZONE, rendered in the session zone; evaluated once per query; no parentheses. | [CURRENT_TIMESTAMP](temporal/CURRENT_TIMESTAMP.md) |
| NOW | `CURRENT_TIMESTAMP` | Identical to CURRENT_TIMESTAMP — the current instant as TIMESTAMP_LTZ evaluated once per query — but written with parentheses: `NOW()`. | [NOW](temporal/NOW.md) |
| LOCALTIMESTAMP | — | The current instant as TIMESTAMP without time zone, per query, no parentheses. | [LOCALTIMESTAMP](temporal/LOCALTIMESTAMP.md) |
| CURRENT_ROW_TIMESTAMP | — | A TIMESTAMP_LTZ clock read per row at evaluation time — whereas CURRENT_TIMESTAMP is fixed per query. | [CURRENT_ROW_TIMESTAMP](temporal/CURRENT_ROW_TIMESTAMP.md) |
| TIMESTAMPDIFF | — | Integer difference t2 minus t1 expressed in the given unit — SECOND, MINUTE, HOUR, DAY, MONTH, or YEAR (month/year differences are calendar-based). | [TIMESTAMPDIFF](temporal/TIMESTAMPDIFF.md) |
| CONVERT_TZ | — | Reinterprets a plain timestamp string from one time zone to another, returning a STRING; zone names are java.util.TimeZone ids. | [CONVERT_TZ](temporal/CONVERT_TZ.md) |
| FROM_UNIXTIME | — | Formats epoch seconds (BIGINT) as a timestamp string in the session time zone, optionally with a format pattern. | [FROM_UNIXTIME](temporal/FROM_UNIXTIME.md) |
| UNIX_TIMESTAMP | — | Converts a timestamp string (with optional format) to epoch seconds in the session time zone; with no arguments it returns the current epoch seconds. | [UNIX_TIMESTAMP](temporal/UNIX_TIMESTAMP.md) |
| TO_DATE | — | Parses a date string (default format yyyy-MM-dd) into a DATE. | [TO_DATE](temporal/TO_DATE.md) |
| TO_TIMESTAMP | — | Parses a timestamp string (default format yyyy-MM-dd HH:mm:ss) into TIMESTAMP, interpreting the text in the session time zone. | [TO_TIMESTAMP](temporal/TO_TIMESTAMP.md) |
| TO_TIMESTAMP_LTZ | — | Converts a raw epoch value with the given precision (0 seconds, 3 millis, 6 micros, 9 nanos) into TIMESTAMP WITH LOCAL TIME ZONE. | [TO_TIMESTAMP_LTZ](temporal/TO_TIMESTAMP_LTZ.md) |
| CURRENT_WATERMARK | — | Returns the current event-time watermark for the given rowtime attribute as TIMESTAMP_LTZ — NULL before any watermark has passed; over a plain non-rowtime column it always evaluates to NULL. | [CURRENT_WATERMARK](temporal/CURRENT_WATERMARK.md) |

## Conditional

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| GREATEST | — | Returns the greatest value among its arguments; if any argument is NULL the result is NULL. | [GREATEST](conditional/GREATEST.md) |
| LEAST | — | Returns the least value among its arguments; if any argument is NULL the result is NULL. | [LEAST](conditional/LEAST.md) |
| CASE | — | Branch selection. | [CASE](conditional/CASE.md) |
| COALESCE | — | Returns the first non-NULL argument (NULL only when all are NULL); all arguments must resolve to a common type. | [COALESCE](conditional/COALESCE.md) |
| IFNULL | — | Two-argument COALESCE: `IFNULL(a, b)` yields a when a is not NULL, else b. | [IFNULL](conditional/IFNULL.md) |

## Type Conversion

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| TYPEOF | — | Returns the runtime type of its argument as a STRING (e.g. `BIGINT NOT NULL`); an optional force flag evaluates the argument's SQL text as written. | [TYPEOF](type-conversion/TYPEOF.md) |
| CAST | — | Explicit type conversion across the wide matrix — numeric widenings and narrowings, string to and from numeric, string to and from temporal, and composite re-labels. | [CAST](type-conversion/CAST.md) |
| TRY_CAST | — | The same conversion matrix as CAST, but any conversion failure yields NULL instead of an error. | [TRY_CAST](type-conversion/TRY_CAST.md) |

## Collection

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| AT | `[]`, ITEM | Element access with the [] operator: `arr[i]` reads the i-th array element (1-based), `map[k]` looks up by key. | [AT](collection/AT.md) |
| CARDINALITY | — | Element count of an array or map; NULL input yields NULL. | [CARDINALITY](collection/CARDINALITY.md) |
| ELEMENT | — | Returns the sole element of a one-element array; an empty array yields NULL, and an array with more than one element is an error. | [ELEMENT](collection/ELEMENT.md) |
| ARRAY_CONTAINS | — | TRUE when the array contains the value. | [ARRAY_CONTAINS](collection/ARRAY_CONTAINS.md) |
| ARRAY_DISTINCT | — | Removes duplicate elements, keeping the first occurrence of each in order. | [ARRAY_DISTINCT](collection/ARRAY_DISTINCT.md) |
| ARRAY_POSITION | — | 1-based index of the first occurrence of the value; 0 when absent; a NULL array yields NULL. | [ARRAY_POSITION](collection/ARRAY_POSITION.md) |
| ARRAY_REMOVE | — | Removes every occurrence of the value from the array. | [ARRAY_REMOVE](collection/ARRAY_REMOVE.md) |
| ARRAY_REVERSE | — | Reverses the element order. | [ARRAY_REVERSE](collection/ARRAY_REVERSE.md) |
| ARRAY_SLICE | — | Sub-array from 1-based start through end, both inclusive. | [ARRAY_SLICE](collection/ARRAY_SLICE.md) |
| ARRAY_UNION | — | Union of two arrays with duplicates removed. | [ARRAY_UNION](collection/ARRAY_UNION.md) |
| ARRAY_CONCAT | — | Concatenates two arrays keeping all elements (duplicates preserved). | [ARRAY_CONCAT](collection/ARRAY_CONCAT.md) |
| ARRAY_MAX | — | Greatest element of the array; NULL elements are skipped, and a NULL array yields NULL. | [ARRAY_MAX](collection/ARRAY_MAX.md) |
| ARRAY_MIN | — | Least element of the array; NULL elements are skipped, and a NULL array yields NULL. | [ARRAY_MIN](collection/ARRAY_MIN.md) |
| ARRAY_JOIN | — | Joins the array elements into one string with the delimiter; NULL elements are skipped unless a nullReplacement is given; a NULL array yields NULL. | [ARRAY_JOIN](collection/ARRAY_JOIN.md) |
| MAP_KEYS | — | Array of the map's keys, in iteration order. | [MAP_KEYS](collection/MAP_KEYS.md) |
| MAP_VALUES | — | Array of the map's values, in iteration order. | [MAP_VALUES](collection/MAP_VALUES.md) |
| MAP_ENTRIES | — | The map as an array of ROW(key, value) pairs. | [MAP_ENTRIES](collection/MAP_ENTRIES.md) |
| MAP_FROM_ARRAYS | — | Builds a MAP from two arrays of equal length — keys first, then values. | [MAP_FROM_ARRAYS](collection/MAP_FROM_ARRAYS.md) |

## JSON

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| IS_JSON | `IS JSON` | Infix predicate testing whether the text is valid JSON, optionally of a given kind: `v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`. | [IS_JSON](json/IS_JSON.md) |
| JSON_EXISTS | — | TRUE when the SQL/JSON path locates at least one value in the document. | [JSON_EXISTS](json/JSON_EXISTS.md) |
| JSON_VALUE | — | Extracts the scalar at the SQL/JSON path and returns it as a string (or the RETURNING type); ON EMPTY / ON ERROR clauses decide what happens on a missing path or a type mismatch. | [JSON_VALUE](json/JSON_VALUE.md) |
| JSON_QUERY | — | Extracts the JSON object or array at the path and returns it as JSON text; WRAPPER clauses control array wrapping of the result. | [JSON_QUERY](json/JSON_QUERY.md) |
| JSON_STRING | — | Serializes any SQL value — including nested rows and collections — into JSON text. | [JSON_STRING](json/JSON_STRING.md) |
| JSON_OBJECT | — | Builds a JSON object from KEY VALUE pairs; NULL ON NULL keeps NULL values, ABSENT ON NULL drops them. | [JSON_OBJECT](json/JSON_OBJECT.md) |
| JSON_ARRAY | — | Builds a JSON array from its arguments, with the same NULL ON NULL / ABSENT ON NULL choice for NULL elements. | [JSON_ARRAY](json/JSON_ARRAY.md) |

## Value Construction

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| ARRAY | — | Array constructor `ARRAY[v1, v2, ...]`; the elements unify to a common element type. | [ARRAY](value-construction/ARRAY.md) |
| MAP | — | Map constructor `MAP[k1, v1, k2, v2, ...]` — keys and values interleaved; keys and values each unify to their own common type. | [MAP](value-construction/MAP.md) |
| ROW | — | Row constructor `ROW(v1, v2, ...)` building an anonymous composite value with fields f0, f1, ... | [ROW](value-construction/ROW.md) |

## Hash

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| MD5 | — | 128-bit MD5 digest of the string, rendered as 32 lowercase hex characters. | [MD5](hash/MD5.md) |
| SHA1 | — | 160-bit SHA-1 digest as 40 lowercase hex characters. | [SHA1](hash/SHA1.md) |
| SHA224 | — | 224-bit SHA-2 digest as 56 lowercase hex characters. | [SHA224](hash/SHA224.md) |
| SHA256 | — | 256-bit SHA-2 digest as 64 lowercase hex characters. | [SHA256](hash/SHA256.md) |
| SHA384 | — | 384-bit SHA-2 digest as 96 lowercase hex characters. | [SHA384](hash/SHA384.md) |
| SHA512 | — | 512-bit SHA-2 digest as 128 lowercase hex characters. | [SHA512](hash/SHA512.md) |
| SHA2 | — | SHA-2 digest of the chosen length — hashLength 224, 256, 384, or 512 (hex characters of the same count); 0 selects 256; other lengths are rejected. | [SHA2](hash/SHA2.md) |

## Auxiliary

| Expression | Aliases | Summary | Doc |
|---|---|---|---|
| CURRENT_DATABASE | — | Returns the name of the session's current database as a STRING. | [CURRENT_DATABASE](auxiliary/CURRENT_DATABASE.md) |
