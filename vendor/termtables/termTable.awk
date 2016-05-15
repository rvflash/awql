#!/bin/awk -f

##
# ASCII Table Generator from CSV file
# @param int verticalMode, if 1, enable vertical display table
# @param int withFooter if 1, use the last line as footer. Option disabled with verticalMode enabled
# @param int withoutHeader if 1, do not use the first line as header. Option disabled with verticalMode enabled
# @param string columnSeparator, character to separate column, default "|"
# @param string columnBounce, character to bounce separate line, default "+"
# @param string columnBreakLine, character to use as break line, default "-" or "*" in vertical mode
# @param string lineLabel, string to use as suffix of the line number in vertical mode
#
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/termtables

BEGIN {
    # Separators (input)
    FS=",";

    # Separators (output)
    if ("" == columnSeparator) {
        columnSeparator="|";
    }
    if ("" == columnBounce) {
        columnBounce="+";
    }
    if ("" == columnBreakLine) {
        if (1 != verticalMode) {
            columnBreakLine="-";
        } else {
            columnBreakLine="*";
        }
    }
    if ("" == lineLabel) {
        lineLabel=". row";
    }

    # Manage empty input file
    lines[1,1]="";
    numberRows=0;
    numberFields=0;
    columnMaxSizes[1]=0;
    headerMaxSize=0;
    columnSize=0;
}
{
    numberFields=splitLine($0, columns);
    for (column=1; column <= numberFields; column++) {
        columnSize=(length(columns[column])+2)
        if (0 == numberRows && headerMaxSize < columnSize) {
            # Build header length for vertical mode
            headerMaxSize = (columnSize-2);
        }
        columnMaxSizes[column]=(columnSize > columnMaxSizes[column] ? columnSize : columnMaxSizes[column]);
        lines[NR "," column]=columns[column];
    }
    numberRows++;
}
END{
    if (0 == numberRows) {
        exit;
    }

    for (line=1; line <= numberRows; line++) {
        if (1 != verticalMode) {
            if ((line == numberRows && 1 == withFooter) || 1 == line) {
                rowSeparator(columnMaxSizes);
            }
        } else if (line > 1) {
            verticalRowSeparator(line-1);
        }
        for (column=1; column <= numberFields; column++) {
            if (1 != verticalMode) {
                printf("%s %-*s", columnSeparator, (columnMaxSizes[column]-1), lines[line "," column]);
                if (column == numberFields) {
                    printf("%s%s", columnSeparator, RS);
                }
            } else if (line > 1) {
                printf("%*s: %s%s", headerMaxSize, lines[1 "," column], lines[line "," column], RS);
            }
        }
        if (1 != verticalMode && ((1 == line && 1 != withoutHeader) || (line == numberRows && numberRows > 1))) {
            rowSeparator(columnMaxSizes);
        }
    }
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

##
# Repeat a string
# @param string input
# @param int multiplier
# @return string
function stringRepeat (input, multiplier)
{
    value="";
    if (multiplier > 0) {
        pattern="%" multiplier "s";
        value=sprintf(pattern, "");
        gsub(/ /, input, value);
    }
    return value;
}

##
# Print the separator line
# @param array columnSizes
# @return string
function rowSeparator (columnSizes)
{
    if (1 == withoutFooter) {
        return;
    }
    columnsNb=length(columnSizes);
    for (column=1; column <= columnsNb; column++) {
        printf("%s%s", columnBounce, stringRepeat(columnBreakLine, columnSizes[column]));
    }
    printf("%s%s", columnBounce, RS);
}

##
# Print the separator line dedicated to vertical mode
# @param int lineNumber
# @return string
function verticalRowSeparator (lineNumber)
{
    if (1 == withoutFooter) {
        return;
    }
    verticalLineSeparator=stringRepeat(columnBreakLine, 28);
    printf("%s %d%s %s%s", verticalLineSeparator, lineNumber, lineLabel, verticalLineSeparator, RS);
}