# OVERLAY

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces the m-character substring of s starting at the 1-based position n with r, used for in-place patching of fixed-width segments. When m is omitted it defaults to the number of characters in r.

## Usage

Signature: `OVERLAY(s PLACING r FROM n [FOR m])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the original string |
| r | STRING | the replacement string |
| n | INT | the replacement start, 1-based |
| m | INT | the length to replace; defaults to the number of characters in r when omitted |

Return: STRING; the string after the in-place replacement.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, OVERLAY(bid.extra PLACING '**' FROM 2 FOR 2) FROM bid;
```

Output: STRING; characters 2 to 3 of `extra` replaced with '**' — still 12 characters on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | OVERLAY(extra PLACING '**' FROM 2 FOR 2) | Notes |
|---|---|---|
| A3F19C27B4E0 | A**9C27B4E0 | characters 2 to 3 replaced with '**', total length unchanged |
| 8B2D4F90A1C3 | 8**4F90A1C3 | characters 2 to 3 replaced with '**', total length unchanged |
| C7E5A0D39F16 | C**A0D39F16 | characters 2 to 3 replaced with '**', total length unchanged |
| ZK9M2Q7XVBT5 | Z**2Q7XVBT5 | characters 2 to 3 replaced with '**', total length unchanged |
| D4C8B1E6A2F7 | D**B1E6A2F7 | characters 2 to 3 replaced with '**', total length unchanged |
| 5F0A9D3C7E8B | 5**9D3C7E8B | characters 2 to 3 replaced with '**', total length unchanged |
| ZZYYXXWWVVUU | Z**XXWWVVUU | characters 2 to 3 replaced with '**', total length unchanged |
| E2B7F5A9C3D0 | E**F5A9C3D0 | characters 2 to 3 replaced with '**', total length unchanged |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `OVERLAY` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `OVERLAY` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateOverlay` (direct call to `SqlFunctionUtils`'s `overlay`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `overlay` (`velox/functions/sparksql/registration/RegisterString.cpp`).
