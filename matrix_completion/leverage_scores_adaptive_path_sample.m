function [mask]=leverage_scores_adaptive_path_sample(M,samp_rate,K,path_len,R)

%=========================NSDI-Zeng==============================
%1.input£º M £ºOriginal matrix
%          samp_rate £º Sampling ratio of the matrix  
%          K : the number of column of rondom sample 
%          path_len : the length of sub-path
%          R : rank of the matrix M
%2.output£ºmask : Sampling position matrix
%==========================================================

% Initialization
% clear;
% clc;
% R = 5 ; path_len = 4 ;  samp_rate = 1/3 ;   K = 30; M = rand(72,72);  
[I,J] = size(M); 
% path_num = I/path_len;
path_num = round(I/path_len);
mask = zeros(I,J) ; 
base = zeros(I,1);  
num_of_samp_path = round(samp_rate * path_num);

path_mask = zeros(path_num,1); 
path_weight = zeros(path_num,1);  
path = zeros(path_len,path_num) ;

for i=1:I   
    path(i)=i;  
end

% randomly sample for first k columns
for i = 1:K 
    chosen = randperm( path_num , round(samp_rate * path_num) ) ;   % Generate a random permutation, selecting the first samp_rate * path_num elements
    path_mask (chosen) =1 ;  
    for j=1:path_num 
       if (path_mask(j) == 1)  
           base (path(:,j)) =1 ; 
       end
    end
    mask(:,i)=base;   
    path_mask(:)=0 ;base(:) = 0;
end

% adaptively leverage_scores sample for k+1 to n columns
LS_column_temp = zeros(I,1);
for i = K+1:J 
    path_weight(:) = 0 ;  LS_column_temp(:) = 0 ;  base(:) = 0;
   
    temp_m = M(:,1:i-1);   
    temp_m = temp_m .* mask(:,1:i-1);
    [U,S,V] = svd(temp_m);
    U = U(:,1:R) ;  S = S(1:R,1:R);  V = V(:,1:R); 
    
    % colculate levereage_scores of entry for ith columns 
    for j = 1:I   
        temp_ls = (I/R) * norm( U(j,1:R))^2;  
        LS_column_temp(j) = rand() * (1/temp_ls) ;   
%         LS_column_temp(j) = (I/R) * norm( U(j,1:R))^2;     
    end
    
    % colculate levereage_scores of path for ith columns  
    LS_column_temp = reshape (LS_column_temp,[path_num,path_len]);
    for j = 1:path_num
        for k = 1:path_len
            path_weight(j) =path_weight(j) + LS_column_temp(j,k);   
        end
    end
    
    %colculate mask
    for j = 1:round(num_of_samp_path)
        num = find( path_weight == max(path_weight) );
        base( path(:,num) ) = 1;
        path_weight(num) = 0;
    end
    mask(:,i)=base;
    
    cur_sample_co = M(:,i) .* base;
    
end

sampling_rate_verification = sum(mask);
end

