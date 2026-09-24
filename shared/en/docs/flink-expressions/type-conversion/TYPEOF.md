# TYPEOF

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

Returns the runtime type of the argument as a STRING (e.g. `BIGINT NOT NULL`); the optional force flag takes the SQL text of the argument verbatim. Used to debug type inference under dynamic schemas.

## Usage

Signature: `TYPEOF(x)` or `TYPEOF(x, force)`

| Parameter | Type | Description |
|---|---|---|
| x | Any | The expression whose type is examined |
| force | BOOLEAN | Optional; takes the argument's SQL text verbatim |

Return: STRING; the runtime type string of the argument.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TYPEOF(bid.auction) FROM bid;
```

Output: STRING; every row is 'BIGINT NOT NULL'.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last two are each row's result and notes):

| auction | TYPEOF(auction) | Notes |
|---|---|---|
| 3 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 19 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 8 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 1 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 14 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 7 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 11 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |
| 20 | BIGINT NOT NULL | The type string of a non-null BIGINT column carries the NOT NULL marker |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `TYPE_OF` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the eval() of scalar/`TypeOfFunction` in flink-table-runtime (invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `typeof` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`).
