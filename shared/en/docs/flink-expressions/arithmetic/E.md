# E

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns Euler's number e, a DOUBLE constant; it is a zero-argument function, and calls must carry empty parentheses, written as `E()`.

## Usage

Signature: `E()`

No parameters.

Return: DOUBLE; always 2.718281828459045.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, E() FROM bid;
```

Output: DOUBLE; 2.718281828459045 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 2.718281828459045 | The base of the natural logarithm, i.e. the DOUBLE value of the Java constant Math.E |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `E` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `E` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `ConstantCallGen` inlines the Math.E constant into the generated code |

## Velox implementation

Velox already provides the builtin `e` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
