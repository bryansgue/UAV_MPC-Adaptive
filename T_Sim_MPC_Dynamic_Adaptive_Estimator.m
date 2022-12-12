% Programa de control predictivo para un drone basado en optimizacion usando Casadi
%% Clear variables
clc, clear all, close all;

load("chi_values.mat");
chi_real = chi';

%% DEFINITION OF TIME VARIABLES
f = 30 % Hz 
ts = 1/f;
to = 0;
tf = 90;
t = (to:ts:tf);

%% Definicion del horizonte de prediccion
N = f; 

%% CONSTANTS VALUES OF THE ROBOT
a = 0.0; 
b = 0.0;
c = 0.0;
L = [a, b, c];

% Definicion de los estados iniciales del sistema
x(1) = 0;
y(1) = 0;
z(1) = 0;
psi(1) = 0;
h = [x;y;z;psi]

%% INITIAL GENERALIZE VELOCITIES
v = [0; 0;0;0];

%% GENERAL VECTOR DEFINITION
H = [h;v];

%% Variables definidas por la TRAYECTORIA y VELOCIDADES deseadas
[hxd, hyd, hzd, hpsid, hxdp, hydp, hzdp, hpsidp] = Trayectorias(3,t);

%% GENERALIZED DESIRED SIGNALS
%hd = [hxd; hyd; hzd; hpsid];
hd = [hxd;hyd;hzd;0*hpsid;hxdp; hydp; hzdp; 0*hpsidp];

%hdp = [hxdp;hydp;hzdp;hpsidp];

%% Deficion de la matriz de la matriz de control
Q = 0.5*eye(4);

%% Definicion de la matriz de las acciones de control
R = 0.01*eye(4);

%% Definicion de los limites de las acciondes de control
bounded = [1.2; -1.2; 1.2; -1.2; 1.2; -1.2; 5.5; -5.5];

%% Definicion del vectro de control inicial del sistema
vcc = zeros(N,4);
H0 = repmat(H,1,N+1)'; 

% Definicion del optimizador
[f, solver, args] = mpc_drone(chi_real,bounded, N, L, ts, Q, R);

% Chi estimado iniciales
chi_estimados(:,1) = chi';
tic
for k=1:length(t)-N


    %% Generacion del; vector de error del sistema
    he(:,k)=hd(1:4,k)-h(:,k);
    
    args.p(1:8) = [h(:,k);v(:,k)]; % Generacion del estado del sistema
    
    for i = 1:N % z
        args.p(8*i+1:8*i+8)=[hd(:,k+i)];
%         args.p(4*i+5:4*i+7)=obs;
    end 
    
    args.x0 = [reshape(H0',8*(N+1),1);reshape(vcc',size(vcc,2)*N,1)]; % initial value of the optimization variables
    tic;
    sol = solver('x0', args.x0, 'lbx', args.lbx, 'ubx', args.ubx,...
            'lbg', args.lbg, 'ubg', args.ubg,'p',args.p);
    toc
    sample(k)=toc;
    opti = reshape(full(sol.x(8*(N+1)+1:end))',4,N)';
    H0 = reshape(full(sol.x(1:8*(N+1)))',8,N+1)';
    hfut(:,1:4,k+1) = H0(:,1:4);
    vc(:,k)= opti(1,:)';
    
    vcp(:,k) = [0;0;0;0];
    %% DYNAMIC ESTIMATION
    [Test(:,k),chi_estimados(:,k+1)] = estimadaptive_dymanic_UAV(chi_estimados(:,k),vcp(:,k), vc(:,k), v(:,k), hd(1:4,k), h(:,k) ,1, L, ts);
    vref(:,k)= vc(:,k)+Test(:,k);
    
    %% Dinamica del sistema 
    [v(:, k+1),Tu(:,k)] = dyn_model_adapUAV(chi_real, v(:,k), vref(:,k), psi(k), L,ts,k);
    
    %% Simulacion del sistema
%     h=h+system(h,[ul(k+1);um(k+1);un(k+1);w(k+1)],f,ts);
    
    h(:,k+1) = h(:,k)+ UAV_RK4(h(:,k),v(:,k+1),ts);
    hx(k+1) = h(1,k+1);
    hy(k+1) = h(2,k+1);
    hz(k+1) = h(3,k+1);      
    psi(k+1) = Angulo(h(4,k+1));
    
        
    %% Actualizacion de los resultados del optimizador para tener una soluciona aproximada a la optima
    
    vcc = [opti(2:end,:);opti(end,:)];
    H0 = [H0(2:end,:);H0(end,:)];
end
toc
%%
close all; paso=1; 
%a) Parámetros del cuadro de animación
figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 8 3]);
    h = light;
    h.Color=[0.65,0.65,0.65];
    h.Style = 'infinite';
%b) Dimenciones del Robot
    Drone_Parameters(0.02);
%c) Dibujo del Robot    
    G2=Drone_Plot_3D(hx(1),hy(1),hz(1),0,0,psi(1));hold on

    G3 = plot3(hx(1),hy(1),hz(1),'-','Color',[56,171,217]/255,'linewidth',1.5);hold on,grid on   
    G4 = plot3(hxd(1),hyd(1),hzd(1),'Color',[32,185,29]/255,'linewidth',1.5);
    G5 = Drone_Plot_3D(hx(1),hy(1),hz(1),0,0,psi(1));hold on
%    plot3(hxd(ubicacion),hyd(ubicacion),hzd(ubicacion),'*r','linewidth',1.5);
    view(20,15);
    
    G6=Drone_Plot_3D(hx(1),hy(1),hz(1),0,0,psi(1));hold on

    G7 = plot3(hx(1),hy(1),hz(1),'-','Color',[56,171,217]/255,'linewidth',1.5);hold on,grid on   
    G8 = plot3(hxd(1),hyd(1),hzd(1),'Color',[32,185,29]/255,'linewidth',1.5);
    G9 = Drone_Plot_3D(hx(1),hy(1),hz(1),0,0,psi(1));hold on

for k = 1:10:length(t)-N
    %drawnow
    delete(G2);
    delete(G3);
    delete(G4);
    delete(G5);
   
    G2=Drone_Plot_3D(hx(k),hy(k),hz(k),0,0,psi(k));hold on  
    G3 = plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
    G4 = plot3(hx(1:k),hy(1:k),hz(1:k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
    G5 = plot3(hfut(1:N,1,k),hfut(1:N,2,k),hfut(1:N,3,k),'Color',[100,100,100]/255,'linewidth',0.1);

    pause(0)
end
%%
% 
% %% Grafica para paper
% close all
% set(gcf, 'PaperUnits', 'inches');
% set(gcf, 'PaperSize', [4 2]);
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 10 4]);
% for k = 1:10:length(t)-N
%     %drawnow
%     delete(G2);
%     delete(G3);
%     delete(G4);
%     %delete(G5);
%     delete(G6);
%     delete(G7);
%     delete(G8);
%    % delete(G9);
%     
%     subplot(1,2,1)
%     view([50.029234115280943 45.991686774086247])
%     %xlim([-5 5])
%     zlim([-1 6])
%     G2=Drone_Plot_3D(hx(k),hy(k),hz(k),0,0,psi(k));hold on  
%     G3 = plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
%     G4 = plot3(hx(1:k),hy(1:k),hz(1:k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
%     legend([G3 G4],{'${\eta}_{ref}$','${\eta}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
%     %legend('boxoff')
%     grid on;
%     title('$\textrm{(a)}$','Interpreter','latex','FontSize',9);
%     ylabel('$ \eta_y[m]$','Interpreter','latex','FontSize',9);
%     xlabel('$ \eta_x[m]$','Interpreter','latex','FontSize',9);
%     zlabel('$ \eta_z[m]$','Interpreter','latex','FontSize',9);
%      
%     subplot(1,2,2)
%     view([0 90])
%     
%     G6=Drone_Plot_3D(hx(k),hy(k),hz(k),0,0,psi(k));hold on  
%     G7 = plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
%     G8 = plot3(hx(1:k),hy(1:k),hz(1:k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
%     legend([G7 G8],{'${\eta}_{ref}$','${\eta}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
%     %legend('boxoff')
%     grid on;
%     title('$\textrm{(b)}$','Interpreter','latex','FontSize',9);
%     ylabel('$ \eta_y[m]$','Interpreter','latex','FontSize',9);
%     xlabel('$ \eta_x[m]$','Interpreter','latex','FontSize',9);
%     zlabel('$ \eta_z[m]$','Interpreter','latex','FontSize',9);
% 
%     pause(0)
% end
% %%
figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);

plot(t(1:length(he)),he(1,:),'Color',[226,76,44]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(2,:),'Color',[46,188,89]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(3,:),'Color',[26,115,160]/255,'linewidth',1);hold on;
plot(t(1:length(he)),he(4,:),'Color',[83,57,217]/255,'linewidth',1);hold on;
grid on;

legend({'$\tilde{\eta}_{x}$','$\tilde{\eta}_{y}$','$\tilde{\eta}_{z}$','$\tilde{\eta}_{\psi}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');0
legend('boxoff')
%title('$\textrm{Evolution of Control Errors}$','Interpreter','latex','FontSize',9);
ylabel('$[m]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time }[s]$','Interpreter','latex','FontSize',9);
% xlabel('$Time[s]$','Interpreter','latex','FontSize',9);


figure

subplot(4,1,1)
plot(Tu(1,:))
hold on
plot(Test(1,:))
legend("Tx_u","Tx_{est}")
ylabel('x [m]');
%title('$\textrm{Evolution of h }$','Interpreter','latex','FontSize',9);

subplot(4,1,2)
plot(Tu(2,:))
hold on
plot(Test(2,:))
legend("Ty_u","Ty_{est}")
ylabel('y [m]'); 

subplot(4,1,3)
plot(Tu(3,:))
hold on
plot(Test(3,:))
grid on
legend("Tz_u","Tz_{est}")
ylabel('z [m]'); 

subplot(4,1,4)
plot(Tu(4,:))
hold on
plot(Test(4,:))
legend("Tpsi_u","Tpsi_{est}")
ylabel('psi [rad]'); 
xlabel('$\textrm{Time }[kT_0]$','Interpreter','latex','FontSize',9);
% %%%%%%%%%%%%%

figure(5)

plot(vc(1,100:end))
hold on
plot(v(1,100:end))
hold on
plot(vref(1,100:end))
legend("vc","v","v_{ref}")
ylabel('x [m/s]'); xlabel('s [ms]');
%title('$\textrm{Evolution of ul Errors}$','Interpreter','latex','FontSize',9);

figure(6)
plot(vc(2,100:end))
hold on
plot(v(2,100:end))
hold on
plot(vref(2,100:end))
legend("vc","v","v_{ref}")
ylabel('y [m/s]'); xlabel('s [ms]');
title('$\textrm{Evolution of um Errors}$','Interpreter','latex','FontSize',9);

figure(7)
plot(vc(3,100:end))
hold on
plot(v(3,100:end))
hold on
plot(vref(3,100:end))
legend("vc","v","v_{ref}")
ylabel('z [m/ms]'); xlabel('s [ms]');
title('$\textrm{Evolution of un Errors}$','Interpreter','latex','FontSize',9);

figure(8)
plot(vc(4,100:end))
hold on
plot(v(4,100:end))
hold on
plot(vref(4,100:end))
legend("vc","v","v_{ref}")
ylabel('psi [rad/s]'); xlabel('s [ms]');
title('$\textrm{Evolution of w Errors}$','Interpreter','latex','FontSize',9);


% figure
% set(gcf, 'PaperUnits', 'inches');
% set(gcf, 'PaperSize', [4 2]);
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 10 4]);
% plot(t(1:length(ul_c)),ul_c,'Color',[226,76,44]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),um_c,'Color',[46,188,89]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),un_c,'Color',[26,115,160]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),w_c,'Color',[83,57,217]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),ul,'--','Color',[226,76,44]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),um,'--','Color',[46,188,89]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),un,'--','Color',[26,115,160]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),w,'--','Color',[83,57,217]/255,'linewidth',1); hold on
% grid on;
% legend({'$\mu_{lc}$','$\mu_{mc}$','$\mu_{nc}$','$\omega_{c}$','$\mu_{l}$','$\mu_{m}$','$\mu_{n}$','$\omega$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
% legend('boxoff')
% title('$\textrm{Control Values}$','Interpreter','latex','FontSize',9);
% ylabel('$[rad/s]$','Interpreter','latex','FontSize',9);
% xlabel('$\textrm{Time}[s]$','Interpreter','latex','FontSize',9);

figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);
plot(t(1:length(sample)),sample,'Color',[46,188,89]/255,'linewidth',1); hold on
grid on;
legend({'$t_{sample}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
%title('$\textrm{Sample Time}$','Interpreter','latex','FontSize',9);
ylabel('$[s]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time }[kT_0]$','Interpreter','latex','FontSize',9);
%xlabel('$Time[kT_0]$','Interpreter','latex','FontSize',9);