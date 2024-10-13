

% topo_graph=textread('Geant/topo_graph.txt')
% 
% n = size(topo_graph, 1); 
% adj_matrix = zeros(n); 
% 
% for i = 1:n
%     adj_nodes = topo_graph(i, 2:end); 
%     for j = adj_nodes
%         adj_matrix(i, j+1) = 1; 
%         adj_matrix(j+1, i) = 1;
%     end
% end
%%
function [paths] = Path_Create(path_num,path_len)

% path_num=20;
% path_len=10;


load('Geant/adj_matrix.mat');

n = size(adj_matrix, 1);  
for i = 1:n
    for j = i+1:n
        if adj_matrix(i,j) == 1
            adj_matrix(j,i) = 1;  
        elseif adj_matrix(j,i) == 1
            adj_matrix(i,j) = 1; 
        end
    end
end

G = graph(adj_matrix);
% plot(G);


paths = zeros(path_num,path_len);

for i = 1:path_num
    startNode = randi(n); 
    paths(i, 1) = startNode;
    for j = 2:path_len
        neighbors = find(adj_matrix(paths(i, j-1), :)); 
        nextNode = neighbors(randi(length(neighbors))); 
        paths(i, j) = nextNode;
    end
end

paths = paths-1;

end

