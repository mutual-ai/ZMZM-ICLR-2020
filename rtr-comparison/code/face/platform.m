clc;close all;clear all;
% load YaleBfull.mat;
% [l,m,te] = size(testData);
% [l,m,tr] = size(trainData);
% Te = reshape(testData,[l*m,te]);
% Tr = reshape(trainData,[l*m,tr]);

% Y = [Tr(:,3),Tr(:,33),Tr(:,66),Tr(:,100),Tr(:,130),...
%     Tr(:,164),Tr(:,197),Tr(:,228),Tr(:,260),Tr(:,290)]; 

% X_1 = [Te(:,testCls==1),Tr(:,trainCls==1)];
% X_2 = [Te(:,testCls==2),Tr(:,trainCls==2)];
% X_3 = [Te(:,testCls==3),Tr(:,trainCls==3)];
% X_4 = [Te(:,testCls==4),Tr(:,trainCls==4)];
% X_5 = [Te(:,testCls==4),Tr(:,trainCls==4)];
% D = [X_1,X_2,X_3,X_4,X_5];
% D = X_1;
% [m,n] = size(D);
% tol = 1e-5;lambda = 5e-3;
% maxIter = 1000;
% [L,S] = inexact_alm_rpca(D, lambda, tol, maxIter);
% [U,S,V] = svd(L,'econ');
% Y = U(:,1:10);
% save('data.mat','Y');




rng(2016); 

%load data.mat; % 
load data_persons.mat;
Compo = 4;


[p,n] = size(Y);
Y = orth(Y); 
Y0 = Y;   % Y is modified under each alg 

C_ADM = [];
C_SOS = []; 

	%ADM 

lambda = 1/sqrt(p);
tol = 1e-6;
MaxIter = 1000;
Num = 3000;
X = zeros(p,Num);
Spa = zeros(Num,1);

for iter = 1:Compo
    if iter~=1
        Y = Y - C_ADM*pinv(C_ADM)*Y;
        n = n - 1;
        [U,S,V] = svd(Y,'econ');
        Y = U(:,1:n);
    end
    tt = randperm(p,Num);
    
    for k = 1 : Num
        fprintf('Running the %dth simulation...\n',k);
        q_0 = Y(tt(k),:)/norm(Y(tt(k),:));
        q_0 = q_0';
        [q,y] = adm_nonlinear(Y,q_0,lambda,MaxIter,tol);
        X(:,k) = Y*q;
        Spa(k) = norm(X(:,k),1)/norm(X(:,k),2);
    end
    [~,ind] = min(Spa);
    
    x = X(:,ind)/ norm(X(:,ind),2);
    
    cvx_begin
    	variable r(n, 1); 
    	minimize (norm(Y * r, 1)); 
    	subject to 
    		x' * (Y * r) == 1;  
    cvx_end
    
    C_ADM = [C_ADM, Y * r];
end

	%SOS 
for k = 1:Compo
    A = Y' * diag( sum(Y.^2,2) - n/p) * Y;
    [V,D] = eig(A);
    [~,indx] = sort(diag(D),'descend');
    u = V(:,indx(1));
    x = Y*u;
    
    cvx_begin
    	variable r(n, 1); 
    	minimize (norm(Y * r, 1)); 
    	subject to 
    		x' * (Y * r) == 1;  
    cvx_end
    
		C_SOS = [C_SOS, Y * r];     
%    C_SOS = [C_SOS,x];
    Y = Y - C_SOS*pinv(C_SOS)*Y;
    n = n - 1;
    [U,S,V] = svd(Y,'econ');
    Y = U(:,1:n);
end
	
% plot 
figure;
for k = 1:Compo
    x = C_ADM(:,k);
    sp_ratio = norm(x, 1)/norm(x); 
    ff_ratio = norm(x, 4)/norm(x); 
    x = x/max(abs(x));
    x = reshape(x,[192,168]);
    subplot(2,4,k);imshow(abs(x));
    title({['$$\ell^1/\ell^2 = $$ ' sprintf('%0.4g', sp_ratio)]; ...
     ['$$\ell^4/\ell^2 = $$ ' sprintf('%0.4g', ff_ratio)]}, 'Interpreter','latex', 'FontSize', 16); 
end

for k = 1:Compo
    x = C_SOS(:,k);
    sp_ratio = norm(x, 1)/norm(x); 
    ff_ratio = norm(x, 4)/norm(x); 
    x = x/max(abs(x));
    x = reshape(x,[192,168]);
    subplot(2,4,k+4);imshow(abs(x));
    title({['$$\ell^1/\ell^2 = $$ ' sprintf('%0.4g', sp_ratio)]; ...
     ['$$\ell^4/\ell^2 = $$ ' sprintf('%0.4g', ff_ratio)]}, 'Interpreter','latex', 'FontSize', 16); 
end




