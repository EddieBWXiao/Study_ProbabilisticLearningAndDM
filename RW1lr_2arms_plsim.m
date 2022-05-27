function simu = RW1lr_2arms_plsim(task,params,graph)
%{
% produce simulated bebehaviour for one participant
% using RW rule on a simple probabilistic learning task
% only update beliefs about the chosen option
% no bias parameter

input:
% task: task structure, from gen_misc
% params: vector, with the values
% graph: logical; decide whether to plot or not
    -true or 1 to display graphics
    -please set to "false" when running multiple simulations...

output:
-struct for simulated behaviour
-serves as "subj" input for MLEfit_PL

written by Bowen Xiao
29/01/2022

references:
Hanneke RL tutorial
%}

%% load the task
outcomes = task.outcome;
p_out = task.p;

%% other task-relevant information
nt = task.nt;%record number of trials
xt = task.xt;%for plotting

%% apply model (for belief update)
    %% initialise for trial information to be stored 
    choice = nan(nt,1);%one choice made every trial
    %follow format: n_trials x n_choices
    PE = nan(size(outcomes));%updates expectation for total value, for each option
    v = nan(size(outcomes));%value learnt
    pchoice = nan(size(outcomes));
    
    %% =================================================================
    %% the model is specified below: (change if needed)
    
    %% set initial parameters (fixed, not free)
    %create default options for fewer input
    initial_belief = [0.5,0.5];
    
    %% get parameter values (code different for each model)
    alpha = params(1);
    beta = params(2);
    params = struct('alpha',alpha,'beta',beta);
    model_title = sprintf('alpha = %.3f, beta = %.1f',alpha, beta);
    
    %% loop through trials
    for t=1:nt
         %initial expectations
        if t == 1
            v(t,:) = initial_belief;
        end
        
        %% choice/response model: decision based on knowledge from previous trials (instrumental)
        EV_opt1 = v(t,1);%column 1 is about option 1
        EV_opt2 = v(t,2);% value for option 2 across each trial
        pchoice_opt1 = (1+exp(-beta*(EV_opt1-EV_opt2))).^-1;%compare between two options, and decide
        pchoice_opt2 = 1-pchoice_opt1;%either choose opt1, or opt2
        pchoice(t,:) = [pchoice_opt1,pchoice_opt2];        
        if rand(1) < pchoice(t,1) %bigger the pchoice, more likely to choose "1"
            choice(t) = 1;%
        else
            choice(t) = 2;
        end
        
        %% learning
        %PE: update only the chosen option
        PE(t,choice(t)) = outcomes(t,choice(t)) - v(t,choice(t));%for first trial, note change from baseline
        PE(t,3-choice(t)) = 0;%the other option (if 1, 2; if 2, 1)
        %update expectation on future trial
    	v(t+1,:) = v(t,:) + alpha*PE(t,:);

        %remove extra trial due to iterative updating
        if t == nt
            final_v = v(t+1,:);
            v(t+1,:) = [];
        end        
    end
    %% end of model specification
    %% =================================================================
    
%% further documentation of behaviour    

%note outcomes experienced by participant (i.e., if trial resulted in gain)
opt1_ind = choice == 1;%logical indices for trials where option 1 was chosen
opt2_ind = choice == 2;%logical indices for trials where option 2 was chosen
score(opt1_ind) = outcomes(opt1_ind,1);%chose opt 1, won in opt 1
score(opt2_ind) = outcomes(opt2_ind,2);%chose opt 2, won in opt 2

%note whether participants chose option 1 or not
chose1 = double(opt1_ind);
chose1(~opt1_ind) = 0;%set those to zero


feedback.outcomes = outcomes;%stores all feedback received (should be identical to mytask)
feedback.score = score;

%% output (store the "participant data")

%record task structure & parameters & else
opt1 = outcomes(:,1);%only show outcome for option 1
%check: opt1(:,1)-opt1(:,2) == points(:,refc);
chose1_vis = (2-choice); %choice coded in 1 and 2; become 1 and 0
task = struct('p',p_out,'outcomes',outcomes,'opt1',opt1);

furtherinfo = struct('final_v',final_v,'xt',xt);

%output
simu = struct('params',params,'v',v,'pchoice',pchoice,'choices',choice,'chose1',chose1,'feedback',feedback,'task',task,...
    'PE',PE,'furtherinfo',furtherinfo);

%% plot simulation results

refc = 1;%use option 1 to plot

if graph
    %close all
    % visualise task structure
    figure;
    subplot(2,2,1)
    plot(xt,p_out,'g-');
    hold on
    plot(xt,outcomes(:,refc),'rx');
    hold off
    legend('p(outcome|choose opt 1)','outcome')
    xlabel('trial number')
    ylabel('probability')
    title('Visualisation of task structure')

    subplot(2,2,2)
    plot(xt,p_out,'g-');
    hold on
    plot(xt, pchoice(:,refc),'b-','LineWidth',2);
    plot(xt,chose1_vis,'r*');
    hold off
    legend('p(outcome|choose opt 1)','p(choose opt 1)','chosen option 1')
    xlabel('trials')
    ylabel('probability')
    title('Probability of choice and choices made')
    
    subplot(2,2,3)
    plot(xt,cumsum(score));
    xlabel('trials')
    ylabel('score')
    title('Net gain')
    
    sgtitle(model_title)

end


end