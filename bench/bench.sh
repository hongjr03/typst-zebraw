TEST_LIST="test test-zbr test-cdl"
# TIMES=100
# # record timing
# for test in $TEST_LIST
# do
#     # sleep for 10 seconds
#     sleep 10
#     TIME=0
#     echo "typst compile $test.typ"
#     for i in $(seq 1 $TIMES)
#     do
#         # macOS time command
#         TIME=$(echo "$TIME + $(/usr/bin/time -l typst compile $test.typ 2>&1 1>/dev/null | grep -o '[0-9]*\.[0-9]*' | tail -n 1)" | bc)
#         # typst compile $test.typ
#         rm -f $test.pdf
#     done
#     # average time
#     # TIME=$(echo "scale=10; $TIME / $TIMES" | bc) # 即保留三位小数
#     echo "typst compile $test.typ: $TIME"

    
# done
for test in $TEST_LIST
do
    crityp $test.typ --bench-output .
done