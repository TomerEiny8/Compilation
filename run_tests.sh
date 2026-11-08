#!/bin/bash
# run_tests.sh - local tests for part1 (NOT part of the submission)
# Usage: keep this next to part1.lex, makefile, example*.cmm, example*.tokens
#        then run:  bash run_tests.sh

pass=0; fail=0
ok()  { echo "PASS  $1"; pass=$((pass+1)); }
bad() { echo "FAIL  $1"; fail=$((fail+1)); }

make clean >/dev/null 2>&1
if ! make >/dev/null; then echo "BUILD FAILED"; exit 1; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
to_lf()   { sed 's/\r$//' "$1"; }
to_crlf() { sed 's/\r$//; s/$/\r/' "$1"; }

# ---------- official examples, in both LF and CRLF form ----------
check_example() {   # check_example <basename> <expected exit code>
    local name=$1 want=$2 code
    if [ ! -f "$name.cmm" ] || [ ! -f "$name.tokens" ]; then
        bad "$name: example files not found in this folder"; return
    fi
    to_lf "$name.cmm"    > "$tmp/in_lf"
    to_lf "$name.tokens" > "$tmp/exp_lf"
    to_crlf "$name.cmm"  > "$tmp/in_crlf"
    to_crlf "$name.tokens" > "$tmp/exp_crlf"

    ./part1 < "$tmp/in_lf" > "$tmp/out"; code=$?
    if cmp -s "$tmp/out" "$tmp/exp_lf" && [ $code -eq $want ]; then ok "$name (LF input)"
    else bad "$name (LF input), exit=$code"; diff "$tmp/out" "$tmp/exp_lf" | head; fi

    ./part1 < "$tmp/in_crlf" > "$tmp/out"; code=$?
    if [ $want -eq 0 ]; then
        # no error message: every newline comes from the input, so output must be exact CRLF
        cmp -s "$tmp/out" "$tmp/exp_crlf"; same=$?
    else
        # the error message itself is printed with \n, so ignore CRs here
        diff -q --strip-trailing-cr "$tmp/out" "$tmp/exp_lf" >/dev/null; same=$?
    fi
    if [ $same -eq 0 ] && [ $code -eq $want ]; then ok "$name (CRLF input)"
    else bad "$name (CRLF input), exit=$code"; diff --strip-trailing-cr "$tmp/out" "$tmp/exp_lf" | head; fi
}

check_example example 0
check_example example-err 1

# ---------- edge cases ----------
check() {   # check <description> <input> <expected output> <expected exit code>
    local desc=$1 code
    printf '%s' "$2" > "$tmp/in"
    printf '%s' "$3" > "$tmp/exp"
    ./part1 < "$tmp/in" > "$tmp/out"; code=$?
    if cmp -s "$tmp/out" "$tmp/exp" && [ $code -eq $4 ]; then ok "$desc"
    else
        bad "$desc (exit=$code, expected $4)"
        echo "      expected: $(od -c "$tmp/exp" | head -3)"
        echo "      got:      $(od -c "$tmp/out" | head -3)"
    fi
}

check "numbers"              'x = 3.5 + 3 * 007;' \
    '<id,x> <assign,=> <realnum,3.5> <addop,+> <integernum,3> <mulop,*> <integernum,007>;' 0
check "reserved vs id"       'int intx INT integer' \
    '<int> <id,intx> <id,INT> <id,integer>' 0
check "all reserved words"   'int float void write read while do if then else return' \
    '<int> <float> <void> <write> <read> <while> <do> <if> <then> <else> <return>' 0
check "relops (no spaces)"   'a<=b a<>b a>=b a<b a>b a==b a=b' \
    '<id,a><relop,<=><id,b> <id,a><relop,<>><id,b> <id,a><relop,>=><id,b> <id,a><relop,<><id,b> <id,a><relop,>><id,b> <id,a><relop,==><id,b> <id,a><assign,=><id,b>' 0
check "logic ops"            'if !(a&&b||c) then x=1;' \
    '<if> <not,!>(<id,a><and,&&><id,b><or,||><id,c>) <then> <id,x><assign,=><integernum,1>;' 0
check "!= is not+assign"     'a != b' \
    '<id,a> <not,!><assign,=> <id,b>' 0
check "string escapes raw"   'write("He said \"hi\"\tok\n");' \
    '<write>(<str,He said \"hi\"\tok\n>);' 0
check "# inside string"      'write("a#b"); # comment "not a string' \
    '<write>(<str,a#b>); ' 0
check "empty string"         'write("");' \
    '<write>(<str,>);' 0
check "comment at EOF"       'x;# no newline after me' \
    '<id,x>;' 0
check "no space needed"      '3abc' \
    '<integernum,3><id,abc>' 0
check "symbols echoed"       'a[1] = {b, c}: d;' \
    '<id,a>[<integernum,1>] <assign,=> {<id,b>, <id,c>}: <id,d>;' 0
check "CRLF kept on comment line" $'x # c\r\ny\r\n' \
    $'<id,x> \r\n<id,y>\r\n' 0

check "error: underscore start" '_x' \
    $'\nLexical error: \'_\' in line number 1\n' 1
check "error: single &"      'a & b' \
    $'<id,a> \nLexical error: \'&\' in line number 1\n' 1
check "error: single |"      'a = |b;' \
    $'<id,a> <assign,=> \nLexical error: \'|\' in line number 1\n' 1
check "error: 3. is not real" 'y = 3.;' \
    $'<id,y> <assign,=> <integernum,3>\nLexical error: \'.\' in line number 1\n' 1
check "error: unterminated string" $'write("abc\nx;' \
    $'<write>(\nLexical error: \'"\' in line number 1\n' 1
check "error: illegal escape" 'write("bad\q");' \
    $'<write>(\nLexical error: \'"\' in line number 1\n' 1
check "error: line number"   $'a;\nb;\nc @ d;\n' \
    $'<id,a>;\n<id,b>;\n<id,c> \nLexical error: \'@\' in line number 3\n' 1

echo
echo "passed: $pass   failed: $fail"
[ $fail -eq 0 ]
