function TNNR_recon = TNNR_ADMM(A,mask_image,mask,beta,r,maxIter,tol)

% This code implements the TNNR-ADMM algorithm

% Initialization
X = mask_image; Y = X; W = X;
PICKS = find(mask==1);

for iter = 1:maxIter   
    
    % Singular value decomposition to X
    [U,S,V] = svd(W-Y/beta);
    S = sign(S).*max(abs(S)-1/beta,0);
    Xtemp = X; X = U*S*V';
  
    % Update Al and Bl, respectively
    [U1,~,V1] = svd(W,'econ');
    Al = (U1(:,1:r)).';
    Bl = (V1(:,1:r )).';
    
    % Update W
    W = X+(1/beta)*(Y+Al.'*Bl); W(PICKS) = mask_image(PICKS);
    
    % Update Y
    Y = Y+beta*(X-W);
    
    rse = norm(X(:)-A(:))/norm(A(:));
    fprintf('第 %d 轮迭代，误差 是 %.3f \n', iter, rse);
    
    absoluteError = abs(A - X);
    normalizedAbsoluteError = absoluteError ./ (max(A) - min(A));
    nmae = mean(normalizedAbsoluteError(:));
%     fprintf('第 %d 轮迭代，NMAE 是 %.3f \n', iter, nmae);
    
    % Stopping criteria
    TOLL = norm(X-Xtemp,'fro')/norm(X,'fro');
    if TOLL<=tol
        break;
    end
    
end

TNNR_recon = X;

end

