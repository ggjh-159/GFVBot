# PI

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the constant π as a DOUBLE; it is a zero-argument function, and calls must carry empty parentheses, written as `PI()`.

## Usage

Signature: `PI()`

No parameters.

Return: DOUBLE; always 3.141592653589793.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PI() FROM bid;
```

Output: DOUBLE; 3.141592653589793 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 3.141592653589793 | The ratio of a circle's circumference to its diameter, i.e. the DOUBLE value of the Java constant Math.PI |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `PI_FUNCTION` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `PI` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `ConstantCallGen` inlines the Math.PI constant into the generated code |

## Velox implementation

Velox already provides the builtin `pi` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
