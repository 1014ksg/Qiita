## はじめに
最適制御×機械学習といつつ，最適制御の内容を投稿していなかったのでします
最適サーボ系をやってみます
少し最適サーボ系組む機会があったのでまとめようかと思います
教科書は多変数システム　著：池田雅夫　というやつを参考にしてます

## 目的
積分型最適サーボ系を実装

## モデル
モータみたいに
一次遅れ系にします

```math
\dot{\boldsymbol{x}}=\boldsymbol{Ax}+\boldsymbol{Bu}\\
\boldsymbol{y}=\boldsymbol{x}
```
```math
\boldsymbol{A}=
\begin{bmatrix}
-1/0.54 & 0\\
0 & -1/0.54
\end{bmatrix}\\

\boldsymbol{B}=
\begin{bmatrix}
1/0.54 & 0\\
0 & 1/0.54
\end{bmatrix}
```
## 比較モデル
モデル化誤差があっても大丈夫だと証明したいので，モデル化誤差ありもかいておきます．

```math
\acute{\boldsymbol{A}}=
\begin{bmatrix}
-1/0.54+1 & 0\\
0 & -1/0.54+1
\end{bmatrix}\\

\acute{\boldsymbol{B}}=
\begin{bmatrix}
1/0.54 & 0\\
0 & 1/0.54
\end{bmatrix}
```

## 目標信号
定値rです！定値でなくてもできますが，また今度にします

```math
\boldsymbol{r}=
\begin{bmatrix}
5\\
3
\end{bmatrix}
```

## 偏差系
```math
\dot{\boldsymbol{\tilde{x}}}=\boldsymbol{{A_e}\tilde{x}}+\boldsymbol{B_e\tilde{u}}\\
\boldsymbol{e}=\boldsymbol{C_e\tilde{x}}
```

```math
\boldsymbol{A_e}=
\begin{bmatrix}
A & 0\\
-C & 0
\end{bmatrix}\\

\boldsymbol{B_e}=
\begin{bmatrix}
B\\
0
\end{bmatrix}\\

\boldsymbol{C_e}=
\begin{bmatrix}
-C & 0
\end{bmatrix}
```

## 評価関数
以下の評価関数を最小化します

```math
\int_{0}^{\infty}\boldsymbol{e^TQ_1e+\tilde{w}^TQ_2\tilde{w}+\tilde{u}^TR\tilde{u}}dt
```

eは偏差を表します
チルダは最終値（目的の値）との偏差を表しています
こうすることで，最適レギュレータ理論を適用できます
この偏差系が0になるのが目標になるので！
QとRの値は適宜設定してください

## 最適入力
最適入力は以下のように求められます
教科書をみてみてください
または，積分型最適サーボの論文をみてください

```math
\boldsymbol{u(t)=F_ax(t)+G_aw(t)+H_ar-G_aP^{-1}_{22}P^T_{12}x_0-G_aw_0}
```
## ブロック線図
こんな感じでかけます

![image.png](https://qiita-image-store.s3.amazonaws.com/0/261584/9620bc08-83c5-11e1-9de7-d2fcb6e1eeb9.png)



## プログラム
Matlabで書きました
拡大系に対して、リカッチ方程式を求めています！
リカッチ方程式の解はこれでmatlabだと求められます

```
care
```

後は入力を作って、ルンゲクッタやるだけですね！！

```servo.m
clc
clear 
close all

%% Model
% 時定数
tau = 0.54;
tau_de = 0.54;
A = [-1/tau 0; 0 -1/tau];
B = [1/tau 0; 0 1/tau];
C = [1 0; 0 1];

% モデル化誤差ありver
A_de = [-1/tau_de+1 0; 0 -1/tau_de+1];
B_de = [1/tau_de 0; 0 1/tau_de];

%% 要件チェック
% 可制御性確認
[m_a, n_a] = size(A);%行列Aのサイズ

Ct = ctrb(A, B)
C_rank = rank(Ct)

if C_rank < m_a
    disp('Not controlable')
    quit
end

% 可観測性確認
Ob = obsv(A, C)
O_rank = rank(Ob)

if O_rank < n_a
    disp('Not observable')
    quit
end

% 入力と出力の数確認
[m_b, n_b] = size(B);
[m_c, n_c] = size(C);

if n_b < m_c
    disp('Not controlable')
    quit
end

% 今回は定値を想定（条件4は無条件にパス）
J = 0;
L = [1 0; 0 1];

[m_l, n_l] = size(L);

%% 目標値
%　x方向の速度
r_x = 5;

% y方向の速度
r_y = 3;

% 合わせたもの
r = [r_x; r_y];

%% 偏差系
% モデル化誤差なし
A_rel = [A, zeros(m_a, m_l); -C, zeros(m_c, m_l)];
B_rel = [B; zeros(m_l ,n_b)];
r_rel = [zeros(m_c, n_l); eye(m_c)];
C_rel = [-C, zeros(m_c, n_l)];

% モデル化誤差あり
A_rel_de = [A_de, zeros(m_a, m_l); -C, zeros(m_c, m_l)];
B_rel_de = [B_de; zeros(m_l ,n_b)];
r_rel_de = [zeros(m_c, n_l); eye(m_c)];
C_rel_de = [-C, zeros(m_c, n_l)];

% 重みづけ
R_sub = [0.1 0.1];
R = diag(R_sub);

Q_1_sub = [1 1];
Q_2_sub = [1 1];
Q_1 = diag(Q_1_sub);
Q_2 = diag(Q_2_sub);

[m_q2, n_q2] = size(Q_2);

Q=[C'*Q_1*C zeros(m_c ,n_q2); zeros(m_q2, n_c) Q_2];

%% リカッチ方程式解法
lqr(A_rel, B_rel, Q, R);

[P,L,G]=care(A_rel, B_rel, Q, R)%連続リカッチ方程式

% 制御則導出
[m_p, n_p] = size(P);

P_11=P(1:m_a, 1:m_b);
P_12=P(1:m_a, n_p-m_b+1:n_p);

[m_p12, n_p12] = size(P_12);

P_22=P(m_p-m_a+1:m_p ,n_p-n_p12+1:n_p);

F_a=-inv(R)*(B')*P_11;
G_a=-inv(R)*(B')*P_12;
H_a=[-F_a+G_a\(P_22)*(P_12') eye(m_c)]*inv([A B;C zeros(m_c,n_b)])*[zeros(m_c,n_l);eye(m_c)];

%% シミュレーション
% シミュレーション時間
k = 100;
i = 0;

% sampling 時間
dt = 0.05;

% 変数（ロボットの状態）
v_x = zeros(1, k);
v_y = zeros(1, k);
X = zeros(2, k);
U = zeros(2, k);

% 変数（ロボットの状態）モデル化誤差ありver
v_x_de = zeros(1, k);
v_y_de = zeros(1, k);
X_de = zeros(2, k);
U_de = zeros(2, k);

% 変数（補償器の状態）
ome_x = zeros(1, k);
ome_y = zeros(1, k);
OME = zeros(2, k);

% 変数（補償器の状態）モデル化誤差ありver
ome_x_de = zeros(1, k);
ome_y_de = zeros(1, k);
OME_de = zeros(2, k);

% グラフ用（目標値）
r_graph = zeros(2, k);
r_graph(:, 1) = r;

% 初期値
i = 0;
X_0 = [0; 0];%対象システムの状態量
W_0 = [0; 0];%補償器の状態量
X_ex(:,1) = [X_0; W_0];%拡張系の状態量
X_ex_de(:,1) = [X_0; W_0];%拡張系の状態量モデル化誤差あり

for t = 0:dt:dt*(k-1)
    i  = i + 1;
    %ルンゲクッタ
    %入力
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
    
    
    % ルンゲクッタ（モデル化誤差あり）
    % 入力
    U_de(:,i)=F_a*X_de(:,i)+G_a*OME_de(:,i)+H_a*r-G_a*inv(P_22)*(P_12)'*X_0-G_a*W_0;
    
    % 外乱
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

% GUIのフォント
set(0, 'defaultUicontrolFontName', 'Times New Roman');
% 軸のフォント
set(0, 'defaultAxesFontName','Times New Roman');
% タイトル、注釈などのフォント
set(0, 'defaultTextFontName','Times New Roman');
% GUIのフォントサイズ
set(0, 'defaultUicontrolFontSize', 18);
% 軸のフォントサイズ
set(0, 'defaultAxesFontSize', 20);
% タイトル、注釈などのフォントサイズ89
set(0, 'defaultTextFontSize', 20);

% グラフ用時間
time=0:dt:(k)*dt;

% x方向速度時刻歴
figure('Name','v_x','NumberTitle','off')%車体速度の時刻歴
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

% y方向速度時刻歴
figure('Name','v_y','NumberTitle','off')%車体速度の時刻歴
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
```
## 結果
こんな感じになってそれぞれモデル化誤差があるものでもうまく目標値に追従できていることがわかります

![image.png](https://qiita-image-store.s3.amazonaws.com/0/261584/e2ec8a67-af51-644d-1991-f05737f28e27.png)

![image.png](https://qiita-image-store.s3.amazonaws.com/0/261584/e4793f02-5aaf-140f-6014-1addf48426de.png)

## 最後に
うまくいきましたが定値なのでなんか当たり前のようにみえますね・・・
次は最適追従系と積分器を実装してみます

本日のプログラム（gituhub）
https://github.com/Shunichi09/Qiita/tree/master/Control/Servo

twitter
https://twitter.com/ShunichiSekigu1
