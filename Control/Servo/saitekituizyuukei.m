clc
clear 
close all

%% Model
% ���萔
tau = 0.54;
tau_de = 0.54;
A = [-1/tau 0; 0 -1/tau];
B = [1/tau 0; 0 1/tau];
C = [1 0; 0 1];

% ���f�����덷����ver
A_de = [-1/tau_de+1 0; 0 -1/tau_de+1];
B_de = [1/tau_de 0; 0 1/tau_de];

%% �v���`�F�b�N
% ���䐫�m�F
[m_a, n_a] = size(A);%�s��A�̃T�C�Y

Ct = ctrb(A, B)
C_rank = rank(Ct)

if C_rank < m_a
    disp('Not controlable')
    quit
end

% �ϑ����m�F
Ob = obsv(A, C)
O_rank = rank(Ob)

if O_rank < n_a
    disp('Not observable')
    quit
end

% ���͂Əo�͂̐��m�F
[m_b, n_b] = size(B);
[m_c, n_c] = size(C);

if n_b < m_c
    disp('Not controlable')
    quit
end

% ����͒�l��z��i����4�͖������Ƀp�X�j
J = 0;
L = [1 0; 0 1];

[m_l, n_l] = size(L);

%% �ڕW�l
%�@x�����̑��x
r_x = 5;

% y�����̑��x
r_y = 3;

% ���킹������
r = [r_x; r_y];

%% ����n�\��
% �d�݂Â�
R_sub = [0.1 0.1];
R = diag(R_sub);

Q_sub = [1 1];
Q = diag(Q_sub); 

%% ���J�b�`��������@
lqr(A, B, Q, R);

[P,L,G]=care(A, B, Q, R)%�A�����J�b�`������

% ���䑥���o
[m_p, n_p] = size(P);

% �K�v�ȌW���v�Z
F_0 = -inv(R)*(B')*P;

F_1 = C*inv(A+B*F_0);

[m_f, n_f] = size(F_0)
temp1_H_0 = [-F_0, eye(m_f)];
temp2_H_0 = inv([A, B; C, zeros(m_c, n_b)]);
temp3_H_0 =[zeros(m_c, n_b); eye(m_c)];
H_0 = temp1_H_0*temp2_H_0*temp3_H_0;

%% �V�~�����[�V����
% �V�~�����[�V��������
k = 100;
i = 0;

% sampling ����
dt = 0.05;

% �ϐ��i���{�b�g�̏�ԁj
v_x = zeros(1, k);
v_y = zeros(1, k);
X = zeros(2, k);
U = zeros(2, k);

% �ϐ��i���{�b�g�̏�ԁj���f�����덷����ver
v_x_de = zeros(1, k);
v_y_de = zeros(1, k);
X_de = zeros(2, k);
U_de = zeros(2, k);

% �O���t�p�i�ڕW�l�j
r_graph = zeros(2, k);
r_graph(:, 1) = r;

% �����l
i = 0;
X_0 = [0; 0];%�ΏۃV�X�e���̏�ԗ�
X_ex(:,1) = [X_0];%�g���n�̏�ԗ�
X_ex_de(:,1) = [X_0];%�g���n�̏�ԗʃ��f�����덷����

for t = 0:dt:dt*(k-1)
    i  = i + 1;
    %�����Q�N�b�^
    %����
    U(:,i)=F_0*X(:,i)+H_0*r;

    X1 = X_ex(:,i);       k1 = dt*(A*X1+B*U(:,i));
    X2 = X_ex(:,i)+k1/2;  k2 = dt*(A*X2+B*U(:,i));
    X3 = X_ex(:,i)+k1/2;  k3 = dt*(A*X3+B*U(:,i));
    X4 = X_ex(:,i)+k3;    k4 = dt*(A*X4+B*U(:,i));
    
    X_ex(:,i+1)=X_ex(:,i) + (k1+2*k2+2*k3+k4)/6;
    
    v_x(i+1) = X_ex(1,i+1);
    v_y(i+1) = X_ex(2,i+1);
    r_graph(:, i+1) = r;

    X(:,i+1) = [v_x(i+1); v_y(i+1)];    
    
    % �����Q�N�b�^�i���f�����덷����j
    %����
    U_de(:,i)=F_0*X_de(:,i)+H_0*r;
    
    % �O��
    d = [3; 2; 0 ;0];

    X1 = X_ex_de(:,i);       k1 = dt*(A_de*X1+B_de*U_de(:,i) );
    X2 = X_ex_de(:,i)+k1/2;  k2 = dt*(A_de*X2+B_de*U_de(:,i));
    X3 = X_ex_de(:,i)+k1/2;  k3 = dt*(A_de*X3+B_de*U_de(:,i));
    X4 = X_ex_de(:,i)+k3;    k4 = dt*(A_de*X4+B_de*U_de(:,i));
    
    X_ex_de(:,i+1)=X_ex_de(:,i) + (k1+2*k2+2*k3+k4)/6;
    
    v_x_de(i+1) = X_ex_de(1,i+1);
    v_y_de(i+1) = X_ex_de(2,i+1);
    r_graph(:, i+1) = r;

    X_de(:,i+1) = [v_x_de(i+1); v_y_de(i+1)];
    
end

%% Figure

% GUI�̃t�H���g
set(0, 'defaultUicontrolFontName', 'Times New Roman');
% ���̃t�H���g
set(0, 'defaultAxesFontName','Times New Roman');
% �^�C�g���A���߂Ȃǂ̃t�H���g
set(0, 'defaultTextFontName','Times New Roman');
% GUI�̃t�H���g�T�C�Y
set(0, 'defaultUicontrolFontSize', 18);
% ���̃t�H���g�T�C�Y
set(0, 'defaultAxesFontSize', 20);
% �^�C�g���A���߂Ȃǂ̃t�H���g�T�C�Y89
set(0, 'defaultTextFontSize', 20);

% �O���t�p����
time=0:dt:(k)*dt;

% x�������x������
figure('Name','v_x','NumberTitle','off')%�ԑ̑��x�̎�����
plot(time , v_x,'LineWidth',3, 'Color', [1, 0.3, 0]);
hold on
plot(time , v_x_de,'LineWidth',3, 'Color',[0, 0.3, 1]);
hold on
plot(time, r_graph(1, :),'LineWidth',3, 'Color',[0, 0, 0], 'Linestyle', ':');
hold on
grid on
hold on
box on
hold on
xlabel('time [s]','FontSize',20);
ylabel('{\it v_x} [m/s]','FontSize',20);
legend('\it v_x', '\it v_x delta', '\it r_x');

% y�������x������
figure('Name','v_y','NumberTitle','off')%�ԑ̑��x�̎�����
plot(time , v_y,'LineWidth',3, 'Color', [1, 0.3, 0]);
hold on
plot(time , v_y_de,'LineWidth',3, 'Color',[0, 0.3, 1]);
hold on
plot(time, r_graph(2, :),'LineWidth',3, 'Color',[0, 0, 0],  'Linestyle', ':');
hold on
grid on
hold on
box on
hold on
xlabel('time [s]','FontSize',20);
ylabel('{\it v_y} [m/s]','FontSize',20);
legend('\it x_y', '\it v_y delta', '\it r_y');