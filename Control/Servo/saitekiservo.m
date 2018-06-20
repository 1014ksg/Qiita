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

%% �΍��n
% ���f�����덷�Ȃ�
A_rel = [A, zeros(m_a, m_l); -C, zeros(m_c, m_l)];
B_rel = [B; zeros(m_l ,n_b)];
r_rel = [zeros(m_c, n_l); eye(m_c)];
C_rel = [-C, zeros(m_c, n_l)];

% ���f�����덷����
A_rel_de = [A_de, zeros(m_a, m_l); -C, zeros(m_c, m_l)];
B_rel_de = [B_de; zeros(m_l ,n_b)];
r_rel_de = [zeros(m_c, n_l); eye(m_c)];
C_rel_de = [-C, zeros(m_c, n_l)];

% �d�݂Â�
R_sub = [0.1 0.1];
R = diag(R_sub);

Q_1_sub = [1 1];
Q_2_sub = [1 1];
Q_1 = diag(Q_1_sub);
Q_2 = diag(Q_2_sub);

[m_q2, n_q2] = size(Q_2);

Q=[C'*Q_1*C zeros(m_c ,n_q2); zeros(m_q2, n_c) Q_2];

%% ���J�b�`��������@
lqr(A_rel, B_rel, Q, R);

[P,L,G]=care(A_rel, B_rel, Q, R)%�A�����J�b�`������

% ���䑥���o
[m_p, n_p] = size(P);

P_11=P(1:m_a, 1:m_b);
P_12=P(1:m_a, n_p-m_b+1:n_p);

[m_p12, n_p12] = size(P_12);

P_22=P(m_p-m_a+1:m_p ,n_p-n_p12+1:n_p);

F_a=-inv(R)*(B')*P_11;
G_a=-inv(R)*(B')*P_12;
H_a=[-F_a+G_a\(P_22)*(P_12') eye(m_c)]*inv([A B;C zeros(m_c,n_b)])*[zeros(m_c,n_l);eye(m_c)];

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

% �ϐ��i�⏞��̏�ԁj
ome_x = zeros(1, k);
ome_y = zeros(1, k);
OME = zeros(2, k);

% �ϐ��i�⏞��̏�ԁj���f�����덷����ver
ome_x_de = zeros(1, k);
ome_y_de = zeros(1, k);
OME_de = zeros(2, k);

% �O���t�p�i�ڕW�l�j
r_graph = zeros(2, k);
r_graph(:, 1) = r;

% �����l
i = 0;
X_0 = [0; 0];%�ΏۃV�X�e���̏�ԗ�
W_0 = [0; 0];%�⏞��̏�ԗ�
X_ex(:,1) = [X_0; W_0];%�g���n�̏�ԗ�
X_ex_de(:,1) = [X_0; W_0];%�g���n�̏�ԗʃ��f�����덷����

for t = 0:dt:dt*(k-1)
    i  = i + 1;
    %�����Q�N�b�^
    %����
    U(:,i)=F_a*X(:,i)+G_a*OME(:,i)+H_a*r-G_a*inv(P_22)*(P_12)'*X_0-G_a*W_0;

    X1 = X_ex(:,i);       k1 = dt*(A_rel*X1+B_rel*U(:,i) + r_rel*r);
    X2 = X_ex(:,i)+k1/2;  k2 = dt*(A_rel*X2+B_rel*U(:,i) + r_rel*r);
    X3 = X_ex(:,i)+k1/2;  k3 = dt*(A_rel*X3+B_rel*U(:,i) + r_rel*r);
    X4 = X_ex(:,i)+k3;    k4 = dt*(A_rel*X4+B_rel*U(:,i) + r_rel*r);
    
    X_ex(:,i+1)=X_ex(:,i) + (k1+2*k2+2*k3+k4)/6;
    
    v_x(i+1) = X_ex(1,i+1);
    v_y(i+1) = X_ex(2,i+1);
    ome_x(i+1) = X_ex(3,i+1);
    ome_y(i+1) = X_ex(4,i+1);
    r_graph(:, i+1) = r;

    X(:,i+1) = [v_x(i+1); v_y(i+1)];
    OME(:,i+1) = [ome_x(i+1);ome_y(i+1)];
    
    
    % �����Q�N�b�^�i���f�����덷����j
    % ����
    U_de(:,i)=F_a*X_de(:,i)+G_a*OME_de(:,i)+H_a*r-G_a*inv(P_22)*(P_12)'*X_0-G_a*W_0;
    
    % �O��
    d = [3; 2; 0 ;0];

    X1 = X_ex_de(:,i);       k1 = dt*(A_rel_de*X1+B_rel_de*U_de(:,i) + r_rel*r);
    X2 = X_ex_de(:,i)+k1/2;  k2 = dt*(A_rel_de*X2+B_rel_de*U_de(:,i) + r_rel*r);
    X3 = X_ex_de(:,i)+k1/2;  k3 = dt*(A_rel_de*X3+B_rel_de*U_de(:,i) + r_rel*r);
    X4 = X_ex_de(:,i)+k3;    k4 = dt*(A_rel_de*X4+B_rel_de*U_de(:,i) + r_rel*r);
    
    X_ex_de(:,i+1)=X_ex_de(:,i) + (k1+2*k2+2*k3+k4)/6;
    
    v_x_de(i+1) = X_ex_de(1,i+1);
    v_y_de(i+1) = X_ex_de(2,i+1);
    ome_x_de(i+1) = X_ex_de(3,i+1);
    ome_y_de(i+1) = X_ex_de(4,i+1);
    r_graph(:, i+1) = r;

    X_de(:,i+1) = [v_x_de(i+1); v_y_de(i+1)];
    OME_de(:,i+1) = [ome_x_de(i+1);ome_y_de(i+1)];
    
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