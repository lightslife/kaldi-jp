cat textonly | tr -d ',.:!"-' | tr '\n' ' ' >tmpfile
awk 'BEGIN{RS=" "} {++w[$0]} END{for(a in w) if(a!="") print a": "w[a]}' tmpfile | sort >result.txt
