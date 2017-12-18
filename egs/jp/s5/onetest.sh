#!/bin/bash

. ./cmd.sh
[ -f path.sh ] && . ./path.sh

## check param
if [ $# != 3 ] ; then 
	echo " usage ； ./onetest.sh inputwavfile text  output.txt "
	exit 1;
fi

lang=lang_sen
targetexp=tri2_sen
targetexpali=tri2_sen_one_ali 

#backup
cp $1 temp-speech/
(echo " $1  \" $2 \" " ) >> temp-speech/text


##prepare list
input=$1
text=$2
output=$3
onetest_dir=` cat /dev/urandom | head -n 10 |md5sum | head -c 10 `
onetest=data/$onetest_dir
rm -rf $onetest
rm -rf mfcc_one/$onetest_dir

mkdir -p $onetest
echo "answer" $1  >  $onetest/wav.scp
echo "answer answer" > $onetest/spk2utt 
echo "answer " $2 > $onetest/text
cp $onetest/spk2utt $onetest/utt2spk
num_phone_ali= echo $2 | awk '{ print NF }' 
echo $num_phone_ali
#prepare fea

steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj 1 $onetest  exp/make_mfcc/$onetest_dir  mfcc_one/$onetest_dir
steps/compute_cmvn_stats.sh $onetest exp/make_mfcc/$onetest_dir mfcc_one/$onetest_dir
#align
steps/align_si_gop.sh --boost-silence 1.25 --nj 1 --cmd "$train_cmd"  $onetest data/$lang exp/$targetexp exp/$targetexpali/$onetest_dir
ali-to-phones --write-lengths=true exp/$targetexp/final.mdl "ark:gunzip -c exp/$targetexpali/$onetest_dir/ali.1.gz|"  ark,t:exp/$targetexpali/$onetest_dir/1.ctm
rm -rf exp/$targetexp/decode_onetest_$onetest_dir
## decode
steps/decode_gop.sh --nj 1 --cmd "$decode_cmd" \
	exp/$targetexp/graph $onetest exp/$targetexp/decode_onetest_$onetest_dir

#prepre to score
awk '{ $1="" ; print $0 }' exp/$targetexpali/$onetest_dir/1.ctm > exp/$targetexpali/$onetest_dir/2.ctm
sed -i "s/;/\n/g" exp/$targetexpali/$onetest_dir/2.ctm
acoustic_ali=` awk '{ if ($3~/^acoustic$/) print $6 }' exp/$targetexpali/$onetest_dir/log/align.1.log `
awk -v var=$acoustic_ali  '{ if ($3~/^oneframe$/) print $6*10 }' exp/$targetexpali/$onetest_dir/log/align.1.log > exp/$targetexpali/$onetest_dir/score_ali.txt


acoustic_decode=` awk '{ if ($3~/^acoustic_scale$/) print $6 }' exp/$targetexp/decode_onetest_$onetest_dir/log/decode.1.log `
awk -v var=$acoustic_decode  '{ if ($3~/^oneframe$/) print $6*12 }' exp/$targetexp/decode_onetest_$onetest_dir/log/decode.1.log > exp/$targetexp/decode_onetest_$onetest_dir/score_decode.txt

mkdir -p score_phone/$onetest_dir
cp exp/$targetexp/decode_onetest_$onetest_dir/score_decode.txt score_phone/$onetest_dir
cp exp/$targetexpali/$onetest_dir/2.ctm score_phone/$onetest_dir
cp exp/$targetexpali/$onetest_dir/score_ali.txt score_phone/$onetest_dir
cd score_phone/$onetest_dir
cp ../cpp_score ./
./cpp_score
cp score.txt ../../$output
cd ../..

rm -rf mfcc_one/$onetest_dir
rm -rf data/$onetest_dir 
rm -rf exp/make_mfcc/$onetest_dir 
rm -rf exp/$targetexp/decode_onetest_$onetest_dir 
rm -rf exp/$targetexpali/$onetest_dir 
rm -rf score_phone/$onetest_dir 


cat $output


