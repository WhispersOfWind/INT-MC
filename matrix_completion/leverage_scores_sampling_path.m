function [mask]= leverage_scores_sampling_path(M,samp_rate,R,k)
%=========================NSDI-Zeng==============================
%1.input£º M £ºOriginal matrix
%          samp_rate £º Sampling ratio of the matrix 
%          R : Rank of the matrix
%          k : Number of paths
%2.output£ºmask : Sampling position matrix
%==========================================================

% Initialization
[I,J] = size(M); PK=zeros(I,J);   mask = zeros(I,J); number = floor(samp_rate * J * k);

% Calculate Matrix SVD
[U,S,V] = svd(M,'econ');
U=U(:,1:R); S=S(1:R,1:R); V=V(:,1:R);

% Calculate leverages scores and sampling probability for ervey entry 
group = zeros(k,2); 
count = zeros(k,1); 
row_per_group = floor(I/k); 
for i = 1:k
    group(i,1) = (i-1)*row_per_group + 1; 
    if i < k
        group(i,2) = i*row_per_group; % Calculate the ending row for each group (except the last group)
    else
        group(i,2) = I; % The ending row for the last group is I.
    end
    count(i) = group(i,2) - group(i,1) + 1; 
end

PK = zeros(I,J); 
for i = 1:I 
    for j = 1:J 
        ui = (I/R) * norm( U(i,1:R))^2;   
        vj = (J/R) * norm( V(j,1:R))^2;   
        PK(i,j) = ui + vj ; % Calculate the leverage scores for each element.
    end
end

PK_group = zeros(k,J); 
for j = 1:J
    for g = 1:k
        for i = group(g,1):group(g,2) 
            PK_group(g,j) = PK_group(g,j) + PK(i,j);
        end
    end
end

% leverage scores sampling
W_group = rand(k,J); 
PK_group = PK_group.* W_group ; 
for num = 1 : number  
    [row,col]=find( PK_group==max(max(PK_group)) ); 
    mask(group(row(1),1):group(row(1),2),col(1))=1;   % Mark all elements within the corresponding position's group in the mask as 1.
    PK_group(row(1),col(1))=0;      
end

end



