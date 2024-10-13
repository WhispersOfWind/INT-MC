function [result] = path_to_edge(random_paths)


path = [0 1 3 2 4 7 8 11 14 15 16 17 18 21 22 23 19 23 22 21 12 9 6 9 10 9 12 13 9 13 10 13 12 19 12 21 18 17 16 15 14 11 20 11 8 12 8 17 8 18 8 20 8 5 8 6 8 7 11 7 4 2 3 5 3 6 3 1 9 1 0 2 0];

edges = [];
for i = 1:length(path)-1
    edges = [edges; path(i) path(i+1)];
end

result = zeros(size(random_paths, 1), size(random_paths, 2)-1);

for i = 1:size(random_paths, 1)
    current_path = random_paths(i,:);
    
    current_edges = zeros(1, length(current_path)-1);
    
    for j = 1:length(current_path)-1
        current_edges(j) = find(sum(edges == [current_path(j) current_path(j+1)], 2) == 2);
    end
    
    result(i,:) = current_edges;
end


end

