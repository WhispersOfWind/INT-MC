#include <iostream>
#include <fstream>
#include <vector>
#include <queue>

using namespace std;

int main(int argc, char const *argv[]) {
//int main() {
	ifstream infile;
	infile.open(argv[1]);
	//infile.open("input.txt");

	ofstream outfile;
	outfile.open(argv[2]);
	//outfile.open("output.txt");


	// Vector to store all outgoing edges from the vertices
	vector<queue<int> > adj;

	// Total number of vertices in the graph
	int numOfVertices;
	infile >> numOfVertices;

	adj.reserve(numOfVertices);
	// Vector to store all ingoing edges to the vertices
	vector<int> indegreeNumbers(numOfVertices, 0);

	// A boolean to track whether graph is eulerian or not
	bool isEulerian = true;
	// An integer to count the total number of edges
	int numOfEdges = 0;

	for(int i=0; i<numOfVertices; i++){
		// A queue to store all outdegree vertices from a vertex
		queue<int> outdegreeVertices;

		int vertexID;
		infile >> vertexID;

		int outdegree;
		infile >> outdegree;

		numOfEdges += outdegree;

		for(int k=0; k<outdegree; k++) {
			int otherID;
			infile >> otherID;

			// If indegree number of a vertex is more than its outdegree number, break all loops.
			
			if(otherID < i) {
				if(adj[otherID].size() < indegreeNumbers[otherID]+1) {
					isEulerian = false;
					break;
				}
			}
			
			indegreeNumbers[otherID]++;

			outdegreeVertices.push(otherID);
		}
		if(!isEulerian) {
			break;
		}

		adj.push_back(outdegreeVertices);
	}

	// Tries to find a vertex whose indegree number is not equal to outdegree number. If finds, graph is not eulerian.
	
	for(int i=0; i<numOfVertices; i++) {
		if(adj[i].size() != indegreeNumbers[i]) {
			isEulerian = false;
			break;
		}
		
	}
	

	// If graph is not eulerian, print no path
	/********************* print the number of edges  ***********************/
	cout<<"the number of the edges is : " << numOfEdges <<endl ;

	if(!isEulerian) {
		outfile << "no path";
	} else {

		/***************** the lengths of circuit is edges+1 ************************************/
		outfile << numOfEdges+1 << " ";

		int startingID;
		infile >> startingID;
		// A vector to store the required eulerian circuit
		vector<int> eulerianCircuit;
		eulerianCircuit.push_back(startingID);

		while(eulerianCircuit.size() <= numOfEdges) {
			// A vector to store tours in each loop
			vector<int> tour;
			// While loop that finds adjacency vertex and add it to the tour until stuck
			while(adj[startingID].size() > 0) {
				int vertexToGo = adj[startingID].front();
				adj[startingID].pop();

				startingID = vertexToGo;
				tour.push_back(startingID);
			}

			// Merges the tour and the circuit from their first common points
			for(int i=0; i<eulerianCircuit.size(); i++) {
				if(eulerianCircuit[i] == tour[tour.size()-1]) {
					vector<int>::iterator mergePoint = eulerianCircuit.begin() + i + 1;
					eulerianCircuit.insert(mergePoint, tour.begin(), tour.end());
					break;
				}
			}

			// Tries to find the next vertex that will be the beginning of the next tour
			for(int k=0; k<eulerianCircuit.size(); k++) {
				if(adj[eulerianCircuit[k]].size() > 0) {
					startingID = eulerianCircuit[k];
					break;
				}
			}
		}

		for(int i=0; i<eulerianCircuit.size(); i++) {
			outfile << eulerianCircuit[i] << " ";
		}
	}

	infile.close();
	outfile.close();
	return 0;
}
