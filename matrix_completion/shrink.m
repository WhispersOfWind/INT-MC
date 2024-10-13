function X = shrink(Y,rho)

[n1,n2] = size(Y);
max12 = max(n1,n2);
% first frontal slice
[U,S,V] = svd(Y,'econ');
fS = diag(S);
temp = S - rho;
S = max(S-rho,0);
tol = max12*eps(max(S));
r = sum(S > tol);
S = S(1:r);
temp2 = diag(S) ;
X = U(:,1:r)*diag(S)*V(:,1:r)';
% X = U*S*V';
