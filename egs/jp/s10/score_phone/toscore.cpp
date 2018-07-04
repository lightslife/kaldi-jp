#include <math.h>
#include <sstream>
#include <vector>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <string>
using namespace std;
int main()
{
 string num_phone_file="2.ctm";
 string ali_file="score_ali.txt";
string decode_file="score_decode.txt";
ifstream fin_ali(ali_file.c_str(),ios::in);
ifstream fin_decode(decode_file.c_str(),ios::in);
ifstream fin_num_phone(num_phone_file.c_str(),ios::in);
vector<double> vec_ali;
char line[100]={0};
double x=0.0;
while (fin_ali.getline(line,sizeof(line)))
{
stringstream word(line);
word>>x;
if (x!=0)
vec_ali.push_back(x);
}
// cout << vec_ali.size()<<endl;
// cout << vec_ali[0]<<endl;

vector<double> vec_decode;
while (fin_decode.getline(line,sizeof(line)))
{
stringstream word(line);
word>>x;
if(x!=0)
vec_decode.push_back(x);
}
// cout << vec_decode.size()<<endl;
// cout << vec_decode[0]<<endl;

int numx=0;
int numy=0;
vector < pair < int ,int > > vec_num_phone;
while (fin_num_phone.getline(line,sizeof(line)))
{
stringstream word(line);
word>>numx;
word>>numy;
vec_num_phone.push_back(make_pair<int, int>(numx,numy));
}

// cout << vec_num_phone.size()<<endl;

// cout << vec_num_phone[0].first<< " " << vec_num_phone[0].second<<endl;


fin_ali.clear();
fin_ali.close();
fin_decode.clear();
fin_decode.close();
fin_num_phone.clear();
fin_num_phone.close();
vector<double> score;
 int flag=0;
// vector< pair<int ,int > >::iterator it=vec_num_phone.begin(),end=vec_num_phone.end();
// cout <<(*it).second;
for(int i=0;i < vec_num_phone.size();++i)
{
	cout << vec_num_phone[i].first<< " " << vec_num_phone[i].second<<endl;

 double ali=0.0;
 double decode=0.0;
 for (int j=flag; j< flag + vec_num_phone[i].second;j++ )
 {
	
	 ali+=vec_ali[j];
	 decode+=vec_decode[j];
 }
  
 flag+= vec_num_phone[i].second;
 ali/=vec_num_phone[i].second;
 decode/=vec_num_phone[i].second;

 double tmp=ali-decode;
    // cout << "phone  score  " <<tmp <<endl;
	score.push_back(fabs(tmp));


}
cout << score.size()<<endl;
 ofstream ofile;
 ofile.open("score.txt");
 ofile << "score： ";
for ( int i=0;  i < score.size();++i)
{
//  x (0,0.1)    90+   100-4*exp(x)
//  x (0.1,0.6)  70+   90-40*(x-0.1)
//  x (0.6,1.6)  60+   70-10*(x-0.6)
//  x (1.6,4)    35+   60-10*(x-1.6
//  x (4,10)     15+   35-3.3*(x-4)
//  x (10,30)    2+    15-0.7(x-10)
//  x (30,)      2-    60/x
 	if( vec_num_phone[i].first!=1)
{

	cout<< score[i]<<endl;
	if(score[i]<0.1)
	{
	while ( score[i]<0.1)
	score[i]*=10;		
	ofile << 100-4*exp(score[i]) << " ";
	}else if(score[i]<0.6)
	{
	ofile << 94-40*score[i] << " ";
	}
	else if (score[i]<1.6)
	{
	ofile << 76- 10*score[i] << " ";
	}else if (score[i]<4)
	{		
	ofile << 76-10*score[i] << " ";
	}else if (score[i] < 10 )	
	{
	ofile << 48.2-3.3*score[i] << " ";
	}else if (score[i] < 30 )	
	{
	ofile << 22-0.7*score[i] << " ";
	}else 
	{
	ofile << 60/score[i] << " ";
	}

}

//	cout<< score[i]<<endl;
}
ofile <<endl;
ofile.close();


return 0;
}


