#!/bin/awk -f

##
# Aggregate a CSV file and expose the COUNT, SUM and DISTINCT methods
# @param string header New header line
# @param int omitHeader If 1, exclude the first line
# @param int distinctLine If, aggregate by the entire line
# @param string avgColumns List of columns by index to use to calculate average, separated by space
# @param string distinctColumns List of columns by index to use in single mode, separated by space
# @param string minColumns List of columns by index where find the min value, separated by space
# @param string maxColumns List of columns by index where find the max value, separated by space
# @param string countColumns List of columns by index to count, separated by space
# @param string sumColumns List of columns by index to sum, separated by space
# @param string groupByColumns List of columns by index to use to group, separated by space
#
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/termtables

BEGIN {
    # Separators (input)
    FS=",";

    # Skip header line
    start=1;
    if (1 == omitHeader) {
        start++;
    }

    # Convert string args to array
    splitFlip(avgColumns, averages, " ");
    splitFlip(distinctColumns, distincts, " ");
    splitFlip(countColumns, counts, " ");
    splitFlip(minColumns, minimums, " ");
    splitFlip(maxColumns, maximums, " ");
    splitFlip(sumColumns, sums, " ");
    splitFlip(groupByColumns, groups, " ");
}
(NR >= start) {
    # Split line with comma separated values and deal with comma inside quotes
    numberFields=splitLine($0, columns);

    # Group by (single or multiple columns)
    if (1 == distinctLine) {
        group=$0;
    } else {
        group="";
        for (column in groups) {
            if ("" == group) {
                group=columns[column];
            } else {
                group=group FS columns[column];
            }
        }
    }

    # If no group has been defined but first column requested as distinct value, use it for grouping
    if ("" == group && 1 in distincts) {
        group=columns[1];
    }
    aggregating[group]=$0;
    count[group]++;

    for (column=1; column <= numberFields; column++) {
        # Count distinct
        distinct[column FS group FS columns[column]]++;
        # Sum
        sum[column FS group]+=columns[column];
        # Max
        if ("" == max[column FS group]) {
            max[column FS group]=columns[column]
        }
        if (columns[column] > max[column FS group]) {
            max[column FS group]=columns[column];
        }
        # Min
        if ("" == min[column FS group]) {
            min[column FS group]=columns[column]
        }
        if (columns[column] < min[column FS group]) {
            min[column FS group]=columns[column];
        }
    }
}
END {
    # Empty file
    if (NR < start) {
        exit;
    }

    # Output the new header line
    if ("" != header) {
        print header;
    }

    for (group in aggregating) {
        numberFields=splitLine(aggregating[group], columns);
        for (column=1; column <= numberFields; column++) {
            if (column in counts) {
                if (column in distincts) {
                    printf("%d", countKeyWith(column FS group FS, distinct))
                } else {
                    printf("%d", count[group])
                }
            } else if (column in sums) {
                printNumber(sum[column FS group], decimal);
            } else if (column in averages) {
                printNumber((sum[column FS group] / count[group]), decimal);
            } else if (column in minimums) {
                printNumber(min[column FS group], decimal);
            } else if (column in maximums) {
                printNumber(max[column FS group], decimal);
            } else {
                # Protect column containing comma with quotes
                printf("%s", (columns[column] ~ FS ? "\"" columns[column] "\"" : columns[column]))
            }
            if (column < numberFields) {
                printf(FS)
            } else {
                printf(RS)
            }
        }
    }
}

##
# Count all elements in an array with key beginning by needle
# @param mixed needle
# @param array haystack
# @return int
function countKeyWith (needle, haystack) {
    countKey=0
    for (key in haystack) {
        if (match(key, "^" needle)) {
            countKey++;
        }
    }
    return countKey
}

##
# Prints number with float format with 4 decimals only if necessary
# @param int|float number
# @param int number, by default 6
# @param string
function printNumber (number, decimal)
{
    if ("" == decimal) {
        decimal=6
    }
    if (number == int(number)) {
        printf("%d", number);
    } else {
        number=sprintf("%.*f", decimal, number);
        printf("%s", (number ~ FS ? "\"" number "\"" : number));
    }
}

##
# Split string and exchanges all keys with their associated values in an array, return length of array
# @param string source
# @param array destination
# @param string separator
# @return int
function splitFlip (string, array, separator)
{
    split(string, arr, separator);
    for (key in arr) {
        array[arr[key]]=key;
    }
    return length(array);
}

##
# Split line and deal with escaping separator within double quotes
# Cheating with CSV file that contains comma inside a quoted field
# @param string line
# @param array columns
# @return int
function splitLine (line, columns)
{
    numberFields=0;
    line=line FS;

    while(line) {
        match(line, / *"[^"]*" *,|[^,]*,/);
        field=substr(line, RSTART, RLENGTH);
        # Remove extra data
        gsub(/^ *"?|"? *,$/, "", field);
        numberFields++;
        columns[numberFields]=field;
        # So, next ?
        line=substr(line, RLENGTH+1);
    }
    return numberFields
}