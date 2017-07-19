#!/bin/bash

while getopts ":d:i:c" opt; do
  case ${opt} in
    d )
    outdir=$OPTARG
    ;;
    i )
    infile=$OPTARG
    ;;
    c )
    check=$OPTARG
    ;;
  esac
done

if [ "$check" == "$farlik" ]
then
  awk -F "\t" '{
  print $1, $2, "*", "CpG", $3/($3+$4), ($3+$4);
  }' $infile > $outdir/$(basename $infile).meth
else
  awk -F "\t" '{
    if($6 == "CG"){
      print $1, $2, $3, "CpG", $4/($4+$5), ($4+$5);
    }
  }' $infile > $outdir/$(basename $infile).meth
fi


