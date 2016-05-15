#!/bin/awk -f

##
# Limit a CSV file to some columns or lines
# @param int withHeader Use first as header
# @param string columns List of columns by index to display
# @param int rowOffset Starting offset for rows limit
# @param int rowCount Number of line requested in limit
#
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/termtables

BEGIN {
    # Separators (input)
    FS=",";

    # Default values
    if (1 != withHeader) {
        withHeader=0;
    }
    rowCount=int(rowCount);
    if (0 >= rowCount) {
        rowCount=0;
    }
    rowOffset=int(rowOffset);
    if (0 >= rowOffset) {
        rowOffset=0;
    }

    # Manage row limits
    if (1 == withHeader) {
        rowOffset++;
    }
    if (0 < rowCount) {
        rowCount+=rowOffset;
    }

    # Manage column limits
    numberDisplayFields=split(columns, displayFields, " ");
    maxDisplayFields=max(displayFields)
}
(NR == withHeader || (NR > rowOffset && (0 == rowCount || NR <= rowCount))) {
    # Split line with comma separated values and deal with comma inside quotes
    numberFields=splitLine($0, fields);
    for (column=1; column <= numberFields; column++) {
        if (0 == numberDisplayFields || inArray(column, displayFields)) {
            maxFields=(0 == numberDisplayFields ? numberFields : min(numberFields, maxDisplayFields))
            separator=(column == maxFields ? RS : FS)
            printf("%s%s", (fields[column] ~ FS ? "\"" fields[column] "\"" : fields[column]), separator);
        }
    }
}

##
# Checks if a value exists in an array
# @param mixed needle
# @param array haystack
# @return boolean
function inArray (needle, haystack) {
    for (key in haystack) {
        if (needle == haystack[key]) {
            return 1
        }
    }
    return 0
}

##
# Find highest value
# @param array values
# @return int
function max (values) {
    maximum=0
    for (key in values) {
        if (values[key] > maximum) {
            maximum=values[key]
        }
    }
    return maximum
}


##
# Find lowest value
# @param int value1
# @param int value2
# @return boolean
function min (value1, value2) {
    if (value1 > value2) {
        return value2
    }
    return value1
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