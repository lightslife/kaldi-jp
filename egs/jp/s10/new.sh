#!/bin/bash 
. ./cmd.sh
[ -f path.sh ] && . ./path.sh

#### prepare wavlist utt2spk text

### prepare dict
usedir=usefull
srcdir=data/local/data
dir=data/local/dict
lmdir=data/local/lm
tmpdir=data/local/lm_tmp
lang_test=data/lang_test
lang=data/lang


rm -rf  $dir $lmdir $tmpdir
mkdir -p $dir $lmdir $tmpdir

(echo sil ; echo spn ) > $dir/silence_phones.txt
echo sil > $dir/optional_silence.txt


#cut -d' ' -f2- $srcdir/train.text | tr ' ' '\n' | sort -u > $dir/phones.txt
cat $usedir/phone | sort -u > $dir/phones.txt
paste $dir/phones.txt $dir/phones.txt > $dir/lexicon1.txt || exit 1;
grep -v -F -f $dir/silence_phones.txt $dir/phones.txt > $dir/nonsilence_phones.txt 
(echo '!sil sil'; echo '<noise> spn'; echo '<unk> spn' ) | cat - $dir/lexicon1.txt > $dir/lexicon.txt

## A few extra questions that will be added to those obtained by automatically clustering
## the "real" phones.  These ask about stress; there's also one for silence.
cat $dir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $dir/extra_questions.txt || exit 1;
cat $dir/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
 >> $dir/extra_questions.txt || exit 1;


#
#
#### prepare lang
utils/prepare_lang.sh  \
 data/local/dict "<unk>" data/local/lang_tmp data/lang
# 
#


cat $usedir/textonly | sed -e 's:^:<s> :' -e 's:$: </s>:' > $tmpdir/lm_train.text
mkdir -p $lang_test
cp -r $lang/* $lang_test


ngram-count -order 2 -text $tmpdir/lm_train.text -lm $tmpdir/lm.arpa
cat $tmpdir/lm.arpa | utils/find_arpa_oovs.pl data/lang_test/words.txt > data/lang_test/oovs.txt 

cat $tmpdir/lm.arpa | grep -a -v '<s> <s>' | grep -a -v '</s> <s>' | grep -a -v '</s> </s>' > $tmpdir/temp.lm

data_all_dir=data/data_all
mkdir -p $data_all_dir
cp $usedir/* $data_all_dir/
#sort -u -k 1 $data_all_dir/wavlist -o $data_all_dir/wav1.scp
#sort -u -k 1 $data_all_dir/text_all -o  $data_all_dir/text
#awk '{ print $0 " " $0 }' $data_all_dir/wav1.scp > $data_all_dir/utt2spk
#cp $data_all_dir/utt2spk $data_all_dir/spk2utt
#cp $data_all_dir/utt2spk $data_all_dir/wav.scp

rm -rf data/train
rm -rf data/test
utils/subset_data_dir_tr_cv.sh --cv-spk-percent 5 data/data_all data/train data/test

arpa2fst data/local/lm_tmp/temp.lm  | fstprint | \
utils/remove_oovs.pl data/lang_test/oovs.txt | \
utils/eps2disambig.pl | utils/s2eps.pl | \
fstcompile --isymbols=data/lang_test/words.txt --osymbols=data/lang_test/words.txt \
 --keep_isymbols=false --keep_osymbols=false | \
fstrmepsilon | fstarcsort --sort_type=ilabel > data/lang_test/G.fst
