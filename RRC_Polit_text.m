%%RRC匹配滤波帧起点测试程序
% ===== RRC 匹配滤波 =====
sps=4;
span=6;
rolloff = 0.25;
rrc = rcosdesign(rolloff, span, sps, 'sqrt');

% ===== 构造前导 =====
N = 63;          % 奇数
u = 16;           % 与 N 互素

n = (0:N-1).';
polit = exp(-1j*pi*u*n.*(n+1)/N);   % 复基带

x=randi([0,1],990,1);
x_sym = qpskmod(x);
x_sym=x_sym/mean(abs(x_sym));
x_sum=[polit;x_sym];

x_out = upfirdn(x_sum, rrc, sps, 1);

x_out=[zeros(10000,1);x_out;zeros(10000,1)];

h= 1/sqrt(2)*(randn + 1i*randn); 
noise= 0.01 * (randn(length(x_out), 1) + 1j * randn(length(x_out), 1));
rx=h*x_out+noise;

rx_rrc = filter(rrc, 1, rx);
pol_wave = upfirdn(polit, rrc, sps, 1);

corr = filter(flipud(conj(pol_wave)), 1, rx_rrc);
rx_energy = filter(ones(length(pol_wave),1), 1, abs(rx_rrc).^2);
p_energy = sum(abs(pol_wave).^2);

metric = abs(corr).^2 ./ (rx_energy * p_energy + eps);
[~,max1]=max(metric);

figure; 
plot(metric);
xlabel('Sample Index');
ylabel('Magnitude');
title('rxmimo2x2 Magnitude');
grid on;

k = -62 : 495;
idx = max1-12 + k*sps;

r_sym = rx_rrc(idx);

rx_p=r_sym(1:63);

h1 = sum(rx_p .* conj(polit)) / sum(abs(polit).^2);

rx_sym=r_sym/h1;
figure;
scatter(real(rx_sym(64:end) ), imag(rx_sym(64:end)), 10, 'filled');
grid on;
axis equal;
xlabel('In-Phase');
ylabel('Quadrature');
title('Received Signal X Constellation');