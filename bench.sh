TEST_LIST="test test-zbr test-cdl"
for test in $TEST_LIST
do
    cp bench/$test.typ $test.typ
    crityp $test.typ --bench-output .
    rm $test.typ
done

# Benchmarking /test.typ@bench
# Benchmarking /test.typ@bench: Warming up for 3.0000 s
# Benchmarking /test.typ@bench: Collecting 100 samples in estimated 6.5853 s (20k iterations)
# Benchmarking /test.typ@bench: Analyzing
# /test.typ@bench         time:   [304.92 µs 309.75 µs 319.10 µs]
#                         change: [+1.9256% +3.6311% +7.1746%] (p = 0.00 < 0.05)
#                         Performance has regressed.
# Found 8 outliers among 100 measurements (8.00%)
#   5 (5.00%) high mild
#   3 (3.00%) high severe

# Benchmarking /test-zbr.typ@bench
# Benchmarking /test-zbr.typ@bench: Warming up for 3.0000 s
# Benchmarking /test-zbr.typ@bench: Collecting 100 samples in estimated 6.5758 s (10k iterations)
# Benchmarking /test-zbr.typ@bench: Analyzing
# /test-zbr.typ@bench     time:   [649.04 µs 655.60 µs 666.55 µs]
#                         change: [+0.8772% +2.1207% +3.2329%] (p = 0.00 < 0.05)
#                         Change within noise threshold.
# Found 5 outliers among 100 measurements (5.00%)
#   4 (4.00%) high mild
#   1 (1.00%) high severe

# Benchmarking /test-cdl.typ@bench
# Benchmarking /test-cdl.typ@bench: Warming up for 3.0000 s
# Benchmarking /test-cdl.typ@bench: Collecting 100 samples in estimated 5.0289 s (2000 iterations)
# Benchmarking /test-cdl.typ@bench: Analyzing
# /test-cdl.typ@bench     time:   [2.5473 ms 2.5894 ms 2.6424 ms]
#                         change: [+6.1580% +8.2124% +10.278%] (p = 0.00 < 0.05)
#                         Performance has regressed.
# Found 11 outliers among 100 measurements (11.00%)
#   3 (3.00%) high mild
#   8 (8.00%) high severe