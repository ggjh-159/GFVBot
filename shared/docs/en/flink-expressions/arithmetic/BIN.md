# BIN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Converts the integer n into a string holding its binary (base-2) representation, without leading zeros or a prefix. It is used to inspect flag bits and the bit-level shape of ids. The input must be of an integer type.

## Usage

Signature: `BIN(n)`

| Parameter | Type | Description |
|---|---|---|
| n | Integer type | Integer to convert into binary text |

Return: STRING; the binary digit text.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, BIN(bid.auction) FROM bid;
```

Output: STRING; the binary digits of `auction` (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | BIN(auction) | Notes |
|---|---|---|
| 3 | 11 | Binary representation of decimal 3 |
| 19 | 10011 | 16+2+1 |
| 8 | 1000 | 2 to the 3rd power: a 1 followed by three 0s |
| 1 | 1 | No leading zeros are padded |
| 14 | 1110 | 8+4+2 |
| 7 | 111 | All three low bits are 1 |
| 11 | 1011 | 8+2+1 |
| 20 | 10100 | 16+4 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `BIN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `BIN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `generateBin` in `StringCallGen` (inlines the `toBinaryString` of `Long`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `bin` (`velox/functions/sparksql/registration/RegisterMath.cpp`).
