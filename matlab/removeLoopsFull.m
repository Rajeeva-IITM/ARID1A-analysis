function fluxes = removeLoopsFull(fluxes,model)
model_temp =model;
IrR = model_temp.ub<=0; % reactions irreversible in reverse direction
temp = model_temp.ub(IrR);
model_temp.S(:,IrR) = -model_temp.S(:,IrR);
model_temp.ub(IrR) = -1*model_temp.lb(IrR);
model_temp.lb(IrR) = -1*temp;


ind=findExcRxns(model_temp);
% blocking all the exchange reactions
model_temp.lb(ind) = 0; model_temp.ub(ind) = 0;
model_temp.lb(model_temp.lb>0)=0;
if exist('sprintcc','file')
    TIC_rxn_ids = sprintcc(model_temp,1); 
else
    TIC_rxn_ids = fastcc(model_temp,1,0);
end

tic_fluxes = fluxes(TIC_rxn_ids,:);
for k=1:size(fluxes,2)
    fluxes(:,k) = LPsolve(model,TIC_rxn_ids,tic_fluxes(:,k),fluxes(:,k));
end

end


function flux = LPsolve(model,TIC_rxn_ids,tic_flux,flux)
[m,~] = size(model.S);
n_ = numel(TIC_rxn_ids);
% objective
f = -1*[zeros(n_,1);ones(n_,1)];

% equalities
Aeq = [model.S(:,TIC_rxn_ids), sparse(m,n_)];
beq = zeros(m,1);
csenseeq = repmat('E',m,1); % equality

% inequalities
Aineq = []; csenseineq = [];bineq=[];
for i=1:n_
    temp = sparse(1,2*n_);
    temp(i)=1;
    if tic_flux(i)>0
        temp(i+n_)=-1;csenseineq = [csenseineq;'E'];
        Aineq=[Aineq;temp]; bineq =[bineq;0];
    elseif tic_flux(i)<0
        temp(i+n_)=1; csenseineq = [csenseineq;'E'];
        Aineq=[Aineq;temp]; bineq =[bineq;0];
    end
end

% bounds
lb = model.lb(TIC_rxn_ids);
ub = model.ub(TIC_rxn_ids);
lb = [lb;zeros(n_,1)];
ub = [ub; abs(tic_flux)];

% Set up LP problem
LPproblem.A=[Aeq;Aineq];
LPproblem.b=[beq;bineq];
LPproblem.lb=lb;
LPproblem.ub=ub;
LPproblem.c=f;
LPproblem.osense=1;%minimise
LPproblem.csense = [csenseeq; csenseineq];
solution = solveCobraLP(LPproblem);

if solution.stat~=1
    warning('LP solution is not optimal')
end
x=solution.full;


flux(TIC_rxn_ids) = tic_flux - sign(tic_flux).*x(n_+1:end);
end