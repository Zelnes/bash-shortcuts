my_func () 
{ 
    local i pat=$1;
    shift;
    for i in "$@";
    do
        pat+="|$i";
    done;
    awk 'BEGIN{RS="diff --git[^\n]+"; FS="\n"; n=0} n==1{printf("%s%s",RTs,$0); n=0} RT ~ "a/('"$pat"')" {n=1; RTs=RT}'
}
