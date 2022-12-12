function [Test,x] = estimadaptive_dymanic_UAV(x, vcp, vc, v, qd, q, A, L, ts)
%                                         vcp, vc, v, chies, K1, K2, L, ts                                   
%  Summary of this function goes here
%  Detailed explanation goes here

a = L(1);
b = L(2);
%% Gain Matrices
A = A*eye(size(v,1));
%% Control error veclocity
ve = vc -v;
qe = qd - q;
sigma = ve + A*qe;

vr = sigma + v;
vrp = vcp + A*ve;

mu_l = vr(1);
mu_m = vr(2);
mu_n = vr(3);
w = vr(4);

s1=vrp(1);
s2=vrp(2);
s3=vrp(3);
s4=vrp(4);
%% REFRENCE VELOCITIES


% Yu = [s1, s4,     0,       0,     0,       0,       0,                   0,       0,   mu_l, mu_m*omega, a*omega*w,               0,     0,               0,     0,             0,             0,       0;
%          0,       0, s2, s4,     0,       0,       0,                   0,       0,      0,           0,               0,  mu_l*omega,  mu_m,    b*omega*w,     0,             0,             0,       0;
%          0,       0,     0,       0, s3,       0,       0,                   0,       0,      0,           0,               0,           0,     0,               0,  mu_n,             0,             0,       0;
%          0,       0,     0,       0,     0, b*s1, a*s2, s4*(a^2 + b^2), s4,    0,           0,               0,           0,     0,               0,     0,  a*mu_l*omega,  b*mu_m*omega, w];
%  

Yu=  [ s1, a*w*s4,  0,          0,  0,          0,          0,  0, mu_l, a*w^2,    0,         0,    0,              0,              0,           0,           0,     0;
      0,          0, s2, b*w*s4,  0,          0,          0,  0,    0,         0, mu_m, b*w^2,    0,              0,              0,           0,           0,     0;
      0,          0,  0,          0, s3,          0,          0,  0,    0,         0,    0,         0, mu_n,              0,              0,           0,           0,     0;
      0,          0,  0,          0,  0, a*w*s1, b*w*s2, s4,    0,         0,    0,         0,    0, b*mu_l*w^2, a*mu_m*w^2, a^2*w^3, b^2*w^3, w];    
   
     %% AAPTATIVE CONTROLLER

K = 1*eye(18);

xp = K*Yu'*sigma;
x = x + xp*ts;

Test = Yu*x;

end
