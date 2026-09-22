# UUID

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Generates a new RFC 4122 type-4 (random) UUID string on each call; it is a nondeterministic function. It is used for synthetic keys and request ids.

## Usage

Signature: `UUID()`

No parameters.

Return: STRING; a 36-character UUID text, nondeterministic.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, UUID() FROM bid;
```

Output: STRING; a new 36-character UUID on every row (nondeterministic).

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 3f8a2c1e-9b4d-4c6a-8e2f-1a5b9d0c7e3a | An example value from one call; not reproducible |

The output is regenerated on every row (nondeterministic); the value shown here is from a single draw.

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `UUID` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `UUID` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the UUID branch of `StringCallGen` inlines the `java.util.UUID.randomUUID()` call |

## Velox implementation

Velox already provides the builtin `uuid` (`velox/functions/prestosql/UuidFunctions.h`; it returns a UUID type rather than a string).
