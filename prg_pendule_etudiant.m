%%%% Main script
clc;clear all;clear global;close all; % windows & workspace reset

%% ------------------------  Simulation choice ----------------------------
QUESTION_23_simu_bo = 0;                    % 1 to simulate Open loop , 0 else
QUESTION_24_linearise_bo = 0;               % 1 to linearize system, 0 else
QUESTION_31_commandabilite_vc = 0;          % 1 to analyze to controlability from vc, 0 else
QUESTION_commandabilite_grammien = 0;       % 1 to determine the gramian of controllabity
QUESTION_32_observabilite_ab = 0;           % 1 to analyze to observability from ab, 0 else
QUESTION_33_observabilite_xc_vab = 0;       % 1 to analyze to observability from xc_ab, 0 else
QUESTION_41a_calcule_K_LQR = 0;             % 1 to calculate the LQR corrector, 0 else
QUESTION_41c_linearise_LQR = 0;             % 1 to linearize system with the ne corrector, 0 else
QUESTION_41c_trace_bode_LQR = 0;            % 1 to plot bode diagrams, 0 else
QUESTION_41d_simu_LQR = 0;                  % 1 to plot times responses , 0 else
QUESTION_52_simule_estimateur_gain_nul = 0; % 1 to simulate system with , 0 else
QUESTION_53c_calcule_LQE = 0;               % 1
QUESTION_53d_linearise_LQR_LQE = 0;         % 1
QUESTION_62_linearise_LQG = 0;              % 1 
QUESTION_62_trace_bodeLQG = 0;              % 1 
QUESTION_63_simule_LQG = 0;                 % 1 

%% --------------------------------------------------------------
% declaration of variables & constants in CH structure
%--------------------------------------------------------------
p = tf('p');
CH = struct();
w = logspace(-2,3,1000).'; % pulse from 10^-1 to 10^4 with 1000 points, echelle log
%% Default parameters 
CH.Mequ = 0.04;
CH.R = 19;
CH.g = 9.81;
CH.fc = 0.4;
% pendulum parameters
CH.Mb = 0.05;
CH.Lb = 1.8;
CH.Izzb = 5.4e-4;
CH.Ib = CH.Mb*CH.Lb^2+CH.Izzb;
CH.fb = 1e-4;
CH.vc_max = inf; % No limitation for vc default, max =infini
CH.Lpend = CH.Lb;
% Moto Reductor
CH.delayVc = 0 ; % By defaut  the hachor delay is no required 
p = tf('p') ; % creation fct de transfert p
tfDelayVc = (1-CH.delayVc/2*p)/(1+CH.delayVc/2*p); % fct transfert approx de Pade du retard
CH.ssDelayVc = ss(tfDelayVc) ; % conversion to state representation 
CH.KH = 12/5;
CH.KE = 7;
%%  Inputs (blocs from workspace)
CH.Fxcp_time_values =[0,0];
CH.Cb_time_values = [0,0];
CH.vc_time_values = [0,0;1,0;1,-1;2,-1];
%% Initiales conditions 
CH.xc_init = 0;
CH.vxc_init = 0;
CH.alphab_init = 0*pi/180;
CH.valphab_init = 0;
%% inports 
CH.in_Fxcp = 1;
CH.in_Cb = 2;
CH.in_vc = 3;
CH.in_refxc = 4;
%% outports 
CH.out_xc = 1;
CH.out_alphab = 2;
CH.out_vxc = 3;
CH.out_valphab = 4;
CH.out_vc = 5;
CH.out_err_xc = 6;

%% on range CH dans CH_DEFAULT, pour reinitialisation eventuelle
CH_DEFAULT = CH;
% ---------------------------------------------------------------
%% Open loop simulation 
%---------------------------------------------------------------
if (QUESTION_23_simu_bo == 1),
    Tfinal = 120;
    disp('2.3 : lancement simulation du pendule');
    % 1 - conditions dans CH pour la simulation 1
    CH.vc_time_values = [0,0; 1,0; 1,-1; 2,-1 ;2,0 ;1e9,0];
    CH.Fxcp_time_values = [0,0];
    CH.Cb_time_values = [0,0];
    
    CH.xc_init = 0;
    CH.vxc_init = 0;
    CH.alphab_init = 90*pi/180;
    CH.valphab_init= 0;
    % 2 - lancement simulation 1 , calcul de t1,y1
    [t,x,y] = sim('sch_pendule_etudiant_2016',Tfinal);
    figure(1);
    
    n = 3;
    subplot(n,1,1);plot(t,y(:,CH.out_alphab)*180/pi);grid on;hold on;xlabel('temps en seconde');ylabel('alphab en degres');
    title('simualtion en BO point d equilibre haut')
    subplot(n,1,2);plot(t,y(:,CH.out_vc));grid on;hold on;xlabel('temps en seconde');ylabel('vc en volt');
    subplot(n,1,3);plot(t,y(:,CH.out_vxc));grid on;hold on;xlabel('temps en seconde');ylabel('vxc en m/s');
    
    % 3 - conditions dans CH pour la simulation 2
    CH.vc_time_values = [0,0;3,0;3,1;4,1;4,0];
    CH.Fxcp_time_values = [0 0];
    CH.Cb_time_values = [0,0];
    
    
    CH.xc_init = 0;
    CH.vxc_init = 0;
    CH.alphab_init = -90*pi/180;
    CH.valphab_init = 0;
    % 4-lancement simulation 2 , calcul de t2,y2
    [t,x,y] = sim('sch_pendule_etudiant_2016',Tfinal);
    figure(2);
   
    n = 3;
    subplot(n,1,1);plot(t,y(:,CH.out_alphab)*180/pi);grid on;hold on;xlabel('temps en seconde');ylabel('alphab en degres');
    title('simualtion en BO point d equilibre bas')
    subplot(n,1,2);plot(t,y(:,CH.out_vc));grid on;hold on;xlabel('temps en seconde');ylabel('vc en volt');
    subplot(n,1,3);plot(t,y(:,CH.out_vxc));grid on;hold on;xlabel('temps en seconde');ylabel('vxc en m/s');

    %-----------------------------------
    % 5-trace des resultats de simulation
    %-----------------------------------  
    disp('2.3 : trace des resultats de simulation');

end

%---------------------------------------------------------------
%% - linearisation en BO                                        --
% ---------------------------------------------------------------
if (QUESTION_24_linearise_bo == 1),
    % 1- linearisation autour du pt d'equilibre haut => systeme ss_BO1
    CH.vc_time_values = [0,0];
    CH.Fxcp_time_values = [0,0];
    CH.Cb_time_values = [0,0];
    
    CH.xc_init = 0;
    CH.vxc_init = 0;
    CH.alphab_init = 90*pi/180;
    CH.valphab_init = 0;
    [A,B,C,D] = linmod('sch_pendule_etudiant_2016');
    ssBOH = ss(A,B,C,D);
    % 2- dynamique ( affichage avec disp )
    disp('2.4 : dynamique pt haut traduite par ???');
    disp(eig(ssBOH.A));
    % 3-linearisation autour du pt d'equilibre bas => systeme ss_BO2
    %CH.x_init=zeros(4,1);
    CH.xc_init = 0;
    CH.vxc_init = 0;
    CH.alphab_init = -90*pi/180;
    CH.valphab_init = 0;
    [A,B,C,D] = linmod('sch_pendule_etudiant_2016');
    ssBOB = ss(A,B,C,D);
    % 4-dynamique 
    disp('2.4 : dynamique pt bas traduite par ???');
    disp(eig(ssBOB.A));
    save BO.mat ssBOH ssBOB;%sa
    
end
% ---------------------------------------------------------------
%% - etude de la commandabilite depuis vc, autour du pt d'equilibre haut                                --
%---------------------------------------------------------------
if (QUESTION_31_commandabilite_vc == 1),
    load BO.mat;
    A = ssBOH.A;
    B = ssBOH.B;
    C = ssBOH.C;
    D = ssBOH.D;
    B_depuis_vc = B(:,CH.in_vc);
    Com_depuis_vc = [B_depuis_vc,A*B_depuis_vc , A^2*B_depuis_vc, A^3*B_depuis_vc];
     %%'A revoir plus le grammien
    [Ub,Vb,Sb] = svd(Com_depuis_vc);
     disp('etude de la commandabilite depuis vc');
     disp('Sb');
    disp(diag(Sb));
   
end
if(QUESTION_commandabilite_grammien == 1)
    load BO.mat;
    A = ssBOH.A;
    B = ssBOH.B;
    C = ssBOH.C;
    D = ssBOH.D;
    B_depuis_vc = B(:,CH.in_vc);
    eig(A);
   %X = lyap(A,Q,[],E) solves the generalized Lyapunov equation: A*X*E' + E*X*A' + Q = 0    where Q is symmetric 
   Tf = 0.1;
   epsilon = -log(1.01)/Tf;
   A_regule = A+epsilon*eye(size(A));
   M = exp(A_regule*Tf)*B_depuis_vc;
   Q = -(M*M' -B_depuis_vc*B_depuis_vc');
   eig(A_regule);
   Gram_vc = lyap(A_regule,Q);
   eig(Gram_vc)
end
% ---------------------------------------------------------------
%% - etude de l'observabilite depuis ab     (angle barre)       --
%---------------------------------------------------------------
if (QUESTION_32_observabilite_ab == 1),
    load BO.mat;
    A = ssBOH.A;
    B = ssBOH.B;
    C = ssBOH.C;
    D = ssBOH.D;
    disp('analyse l observabilite depuis alpha barre ');
    C_alphab = C(CH.out_alphab,:);
    Ob_depuis_alphab = [C_alphab; C_alphab*A;C_alphab*A^2;C_alphab*A^3];
    [Uo,Vo,So] = svd(Ob_depuis_alphab);
    %A rrevoir avec grammien
    disp('C et A dans base d observabilite alpha barre');
    disp('So');
    disp(diag(So));
     
end
% ---------------------------------------------------------------
%% - etude de l'observabilite depuis xc et vab = dalpha b/dt     (vitesse angle barre)       --
%---------------------------------------------------------------
if (QUESTION_33_observabilite_xc_vab == 1),
     load BO.mat;
     A = ssBOH.A;
     B = ssBOH.B;
     C = ssBOH.C;
     D = ssBOH.D;
    disp('analyse l observabilite depuis [xc] ,[valphab]');
    C_xc_valphab = C([CH.out_xc,CH.out_alphab],:);%%C_alphab=C([1,4],:)
    Ob_depuis_xc_valphab = [C_xc_valphab; C_xc_valphab*A;C_xc_valphab*A^2;C_xc_valphab*A^3];
    [Uo,Vo,So] = svd(Ob_depuis_xc_valphab);
%     Ao=inv(Vo)*A*Vo
%     Bo=inv(Vo)*B;
%     Co=C*Vo
%     Do=D
    
   
    disp('C et A dans base d observabilite [xc,dalphab /dt]');
end
%% Calcule du gain K avec la commande LQR
if (QUESTION_41a_calcule_K_LQR == 1),
    load BO.mat;
    A = ssBOH.A;
    B = ssBOH.B;
    C = ssBOH.C;
    D = ssBOH.D;
    
    N_y1 = [CH.out_xc,CH.out_alphab,CH.out_vc];
    N_u2 = [CH.in_vc];
    B2 = B(:,N_u2);
    D12 = D(N_y1,N_u2);
    C1 = C(N_y1,:); 
    
    P_y1 = diag([1/0.15,1/(2*pi/180),0.1]);
    C1D12 = [C1,D12];
    M = P_y1*C1D12;
    nx = 4;ne2 = 1;
    M_LQR = M'*M;
    Q = M_LQR(1:nx,1:nx);
    R = M_LQR(5,5);
    N = M_LQR(ne2:nx,5) ;
    [K_LQR,P,eig_A_BK] = lqr(A,B2,Q,R,N) ;
    save BFLQR.mat K_LQR P eig_A_BK
    
    % calcul du gain K_LQR ( ne pas le ranger dans CH)
    disp('4.1.a : valeurs propres obtenues par calcul LQR sont :');
    eig_A_BK
end %QUESTION_41a_calcule_K_LQR
% valeur par des workspace pour schema LQR et suivants 
CH.ref_xc_time_values = [0,0;10000,0];
CH.ref_alphab_time_values = [0,90*pi/180;10000,90*pi/180];
CH.ref_vxc_time_values =[0,0;10000,0];
CH.ref_valphab_time_values = [0,0;10000,0];
%-----------------------------------------------------------------
%% linearisation du systeme autour du point haut, avec gain K_LQR
%-----------------------------------------------------------------
if (QUESTION_41c_linearise_LQR == 1),
    load BFLQR.mat
    CH.K_LQR = K_LQR;
%conditions initiales
    CH.xc_init = 0;
    CH.vxc_init = 0;
    CH.alphab_init = 90*pi/180;
    CH.valphab_init = 0;
    
%r?f?rences
  CH.ref_xc_time_values = [0,0;10000,0];
  CH.ref_alphab_time_values = [0,90*pi/180;10000,90*pi/180];
  CH.ref_vxc_time_values = [0,0;10000,0];
  CH.ref_valphab_time_values = [0,0;10000,0];
[A,B,C,D] = linmod('sch_pendule_etudiant_2016_LQR');
disp('4.1.a : valeurs propres obtenues par calcul  sont :');
eig(A)
ssLQRBF = ss(A,B,C,D);
save BF_LQR.mat A B C D
  
end
%% Trac?s de Bode du syt?mes LQR lin?aris? 
if (QUESTION_41c_trace_bode_LQR == 1),
    load BF_LQR.mat
    A = ssLQRBF.A;
    B = ssLQRBF.B;
    C = ssLQRBF.C;
    D = ssLQRBF.D;
    nx = size(A);ne = size(D);
    %C_err_xc=zeros(nx)
    %C_err_xc(1)=1;
    %D_err_xc=zeros(1,ne)
    ss_exc = ss(A,B,C,D);
    subplot(3,2,1);
    bodemag(ssLQRBF(CH.out_vc,CH.in_refxc)); grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('vc<---ref_xc')
    subplot(3,2,3);
    bodemag((180/pi)*ssLQRBF(CH.out_alphab,CH.in_refxc)); grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('alphab<---ref_xc')
    subplot(3,2,5);
    bodemag(ss_exc(CH.out_err_xc,CH.in_refxc));grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('err_xc<---ref_xc')
    subplot(3,2,2);
    bodemag(ss_exc(CH.out_vc,CH.in_Fxcp));grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('vc<---Fxcp')
    subplot(3,2,4);
    bodemag(ss_exc(CH.out_alphab,CH.in_Fxcp));grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('alphab<---Fxcp')
    subplot(3,2,6);
    bodemag(ss_exc(CH.out_err_xc,CH.in_Fxcp));grid on;%xlabel('temps en seconde');ylabel('alphab en degres');
    title('err_xc<---Fxcp')
    
    
end


if (QUESTION_41d_simu_LQR == 1),
    load BFLQR.mat
    CH.K_LQR = K_LQR;
 CH.ref_xc_time_values = [0,0;10000,0];
CH.ref_alphab_time_values = [0,90*pi/180;10000,90*pi/180];
CH.ref_vxc_time_values = [0,0;10000,0];
CH.ref_valphab_time_values = [0,0;10000,0];   
 T = linspace(0,3,1000);
[t,x,y] = sim('sch_pendule_etudiant_2016_LQR',T);
figure(1);
    n = 3;
    subplot(n,1,1);plot(t,y(:,CH.out_alphab)*180/pi);grid on;hold on;xlabel('temps en seconde');ylabel('alphab en degres');
    subplot(n,1,2);plot(t,y(:,CH.out_xc));grid on;hold on;xlabel('temps en seconde');ylabel('xc en m');
    subplot(n,1,3);plot(t,y(:,CH.out_vc));grid on;hold on;xlabel('temps en seconde');ylabel('vc en volt');
    
end

%---------------------------------------------------------------
%% - etude de l'observabilite depuis xc et vab = dalpha b/dt     (vitesse angle barre)       --
%---------------------------------------------------------------
% variables /outports du schema d'estimation 5.2, a adapter
CH.out_delta_xc = 6;
CH.out_delta_ab = 7;
CH.out_delta_vxc = 8;
CH.out_delta_vab = 9;
% conditions initiales estimateur
% gain d'estimation nul par defaut
if (QUESTION_53c_calcule_LQE == 1),
    % entrees , sorties , poids, calcul de P_e1
    % linearisation  et determination de A, B1,C2,D21, M_LQE
    % calcul de Q,R,N
    % resolution du probleme lqr <=>
    disp('valeurs propres attendues pour systeme LQE seul');
    
end
if (QUESTION_53d_linearise_LQR_LQE==1),
end
if (QUESTION_62_linearise_LQG==1),
    if (QUESTION_62_trace_bodeLQG==1),
    end
end
if (QUESTION_63_simule_LQG==1),

end





