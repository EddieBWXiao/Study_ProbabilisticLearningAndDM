function [negLL,vv,p]=lik_RW1lr_PL_native(parameters, actions, outcomes,priors)

    %{
    % likelihood function for given parameters and performance
    % simplest RW, only two free parameters, no independent LRs
    % for task with only one outcome type (PL, probabilistic learning)

    %parameters: vector (1xn parameters), transformed to logit/log space
    %subj: struct, from output of a simulated agent
    %subj.choices: n_trials x 1, for decisions 
    %subj.feedback.outcomes: n_trials x number of options, all feedback received (including
    those not entering total score)

    output negative LL for future fmin
    %}

    %% parameters unpack
    %alpha = learning rate
    alpha = parameters(1); % alpha(transformed to be between zero and one) 
    %inverse temperature
    beta = parameters(2);
    %% unpack data (struct content same as RW2lr_bias_simu)
    % number of trials
    T = length(actions);

    % to save probability of choice & values expected
    p = nan(T,1);%one column (p of that choice, on that trial)
        p1_store = nan(T,1);
    v = nan(T,2);%specify expectation for each option

    % expected value for both actions initialized at 0.5
    v_trial = [0.5,0.5];%1x2, just about current trial

    for t=1:T    
        v(t,:) = v_trial;
        %% response model
        % probability of action 1
        p1 = 1./(1+exp(-beta*(v(t,1)-v(t,2))));
        p1_store(t) = p1;
        % probability of action 2
        p2 = 1-p1;
        % store probability of the chosen action
        a = actions(t); % action on this trial (1 or 2)
        if a==1
            p(t) = p1;
        elseif a==2
            p(t) = p2;
        end   
        %% learning
        %update, regardless of chose or unchosen
        delta  = outcomes(t,:) - v(t,:);
        v_trial = v_trial + (alpha*delta);
    end
    vv = v;

    % sum of log-probability(data | parameters)
    loglik = sum(log(p+eps));
    
    % consider priors
    if nargin < 4
        priors = false;
    end
    if priors
        loglik= loglik+log(pdf('beta', alpha, 1.1,1.1));
        loglik= loglik+log(pdf('gam', beta, 1.2, 5)); 
    end
    
    negLL = -loglik;

end