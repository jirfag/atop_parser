source ~/.bashrc
for f in atop*; do
    #CMD="atop -r $f -PCPU | sed '/RESET/,/SEP/d' | fgrep CPU | perl aggr.pl cpu $f"
    #CMD="atop -r $f -PDSK | sed '/RESET/,/SEP/d' | fgrep DSK | perl aggr.pl disk $f"
    #CMD="atop -r $f -PNET | sed '/RESET/,/SEP/d' | fgrep NET | fgrep upper | perl aggr.pl net $f"
    CMD="atop -r $f -PMEM | sed '/RESET/,/SEP/d' | fgrep MEM | perl aggr.pl mem $f"
    OUT=$(eval $CMD)
#    echo "=== $f ==="
    echo "$OUT"
#    echo "=========="
done
