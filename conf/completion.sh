#!/usr/bin/env bash

##
# Statement        -> SelectClause FromClause1 WhereClause?
#                                  DuringClause2 OrderByClause? LimitClause?
# SelectClause     -> SELECT ColumnList
# FromClause       -> FROM SourceName
# WhereClause      -> WHERE ConditionList
# DuringClause     -> DURING DateRange
# OrderByClause    -> ORDER BY Ordering (, Ordering)*
# LimitClause      -> LIMIT StartIndex , PageSize
#
# ConditionList    -> Condition (AND Condition)*
# Condition        -> ColumnName Operator Value
# Value            -> ValueLiteral | String | ValueLiteralList | StringList
# Ordering         -> ColumnName (DESC | ASC)?
# DateRange        -> DateRangeLiteral | Date,Date
# ColumnList       -> ColumnName (, ColumnName)*
# ColumnName       -> Literal
# SourceName       -> Literal
# StartIndex       -> Non-negative integer
# PageSize         -> Non-negative integer
#
# Operator         -> = | != | > | >= | < | <= | IN | NOT_IN | STARTS_WITH | STARTS_WITH_IGNORE_CASE |
#                    CONTAINS | CONTAINS_IGNORE_CASE | DOES_NOT_CONTAIN | DOES_NOT_CONTAIN_IGNORE_CASE
# String           -> StringSingleQ | StringDoubleQ
# StringSingleQ    -> '(char)'
# StringDoubleQ    -> "(char)"
# StringList       -> [ String (, String)* ]
# ValueLiteral     -> [a-zA-Z0-9_.]*
# ValueLiteralList -> [ ValueLiteral (, ValueLiteral)* ]3
# Literal          -> [a-zA-Z0-9_]*
# DateRangeLiteral -> TODAY | YESTERDAY | LAST_7_DAYS | THIS_WEEK_SUN_TODAY | THIS_WEEK_MON_TODAY | LAST_WEEK |
#                     LAST_14_DAYS | LAST_30_DAYS | LAST_BUSINESS_WEEK | LAST_WEEK_SUN_SAT | THIS_MONTH
# Date             -> 8-digit integer: YYYYMMDD


# Methods
declare -a AWQL_COMPLETE_METHOD
AWQL_COMPLETE_METHOD+=("DESC")
AWQL_COMPLETE_METHOD+=("SELECT")
AWQL_COMPLETE_METHOD+=("SHOW")

# Extended methods
declare -A AWQL_COMPLETE_EXTENDED_METHOD
AWQL_COMPLETE_EXTENDED_METHOD["DESC"]="FULL"
AWQL_COMPLETE_EXTENDED_METHOD["SHOW"]="FULL TABLES LIKE WITH"

# Clause
declare -a AWQL_COMPLETE_CLAUSE
AWQL_COMPLETE_CLAUSE+=("FROM")
AWQL_COMPLETE_CLAUSE+=("WHERE")
AWQL_COMPLETE_CLAUSE+=("DURING")
AWQL_COMPLETE_CLAUSE+=("ORDER BY")
AWQL_COMPLETE_CLAUSE+=("LIMIT")

# DateRangeLiteral
declare -a AWQL_COMPLETE_DURING
AWQL_COMPLETE_DURING+=("TODAY")
AWQL_COMPLETE_DURING+=("YESTERDAY")
AWQL_COMPLETE_DURING+=("LAST_7_DAYS")
AWQL_COMPLETE_DURING+=("THIS_WEEK_SUN_TODAY")
AWQL_COMPLETE_DURING+=("THIS_WEEK_MON_TODAY")
AWQL_COMPLETE_DURING+=("LAST_WEEK")
AWQL_COMPLETE_DURING+=("LAST_14_DAYS")
AWQL_COMPLETE_DURING+=("LAST_30_DAYS")
AWQL_COMPLETE_DURING+=("LAST_BUSINESS_WEEK")
AWQL_COMPLETE_DURING+=("LAST_WEEK_SUN_SAT")
AWQL_COMPLETE_DURING+=("THIS_MONTH")

# Operator
declare -a AWQL_COMPLETE_OPERATOR
AWQL_COMPLETE_OPERATOR+=("IN")
AWQL_COMPLETE_OPERATOR+=("NOT_IN")
AWQL_COMPLETE_OPERATOR+=("STARTS_WITH")
AWQL_COMPLETE_OPERATOR+=("STARTS_WITH_IGNORE_CASE")
AWQL_COMPLETE_OPERATOR+=("CONTAINS")
AWQL_COMPLETE_OPERATOR+=("CONTAINS_IGNORE_CASE")
AWQL_COMPLETE_OPERATOR+=("DOES_NOT_CONTAIN")
AWQL_COMPLETE_OPERATOR+=("DOES_NOT_CONTAIN_IGNORE_CASE")

# OrderBy
declare -a AWQL_COMPLETE_ORDER_BY=("ASC DESC")
