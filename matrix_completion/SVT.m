function SVT_recon = SVT(A,mask_A,mask,tao,step,maxIter,tol)

% This code implements the SVT algorithm

% Initialization
X = mask_A;
Y = zeros(size(mask_A));

for iter = 1:maxIter
    
    % Singular value decomposition to update X
    [U,S,V] = svd(Y,'econ'); 
    S = sign(S).*max(abs(S)-tao,0);
    XTemp = X; X = U*S*V';
    
    % Update Y
    Y = Y+step*mask.*(mask_A-X);
    Y = mask.*Y;
    
    rse = norm(X(:)-A(:))/norm(A(:));
    fprintf('µÚ %d ÂÖµü´ú£¬Îó²î ÊÇ %.3f \n', iter, rse);
    
    % Stopping criteria
    TOLL = norm(mask.*(XTemp-X),'fro')/norm(mask.*X,'fro');
    if TOLL<tol
        break;
    end
    
end

SVT_recon = X;

end

