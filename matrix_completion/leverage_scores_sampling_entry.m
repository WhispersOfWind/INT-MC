function [mask]=leverage_scores_sampling_entry(M,samp_rate,R)
%=========================NSDI-Zeng==============================
%1.input£º M £ºOriginal matrix
%         samp_rate £º Sampling ratio of the matrix 
%         R : Rank of the matrix
%2.output£º mask: Sampling position matrix
%==========================================================

% Initialization
[I,J] = size(M); PK=zeros(I,J);   mask = zeros(I,J); number = floor(samp_rate * I *J);  

% Calculate Matrix SVD
[U,S,V] = svd(M,'econ');
U=U(:,1:R); S=S(1:R,1:R); V=V(:,1:R);

% Calculate leverages scores and sampling probability for ervey entry 
for i = 1 : I
    for  j = 1 : J
        ui = (I/R) * norm( U(i,1:R))^2;   
        vj = (J/R) * norm( V(j,1:R))^2;   
        PK(i,j) = ui + vj ;  
    end
end

% leverage scores sampling

W = rand(I,J);
PK = PK .*  W ;
for num = 1 : number  
    [row,col]=find( PK==max(max(PK)) );
    mask(row(1),col(1))=1;   % Perform probability sampling on the point with the highest leverage scores.
    PK(row(1),col(1))=0;     
end


end

