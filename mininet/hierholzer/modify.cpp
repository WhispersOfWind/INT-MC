#include <iostream>
#include <fstream>
#include <vector>
#include <queue>

using namespace std ;

int main(int argc, char const *argv[]){

	ifstream infile;
	infile.open(argv[1]);

	ofstream outfile;
	outfile.open(argv[2]);

	int count;
	infile >> count;
	vector<int> V(count,0);

	for(int i=0 ; i<count ; i++){
		int temp;
		infile >> temp;
		V[i]=temp+1;
	}

	for(int i=0 ; i<count ; i++){
		outfile << V[i] << " ";
	}

	infile.close();
	outfile.close();
	return 0;

}


