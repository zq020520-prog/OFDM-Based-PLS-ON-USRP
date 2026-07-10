%% USRP自发自身数据解调测试程序
clc;
clear;
close all;


%% ================== 参数设置 ==================
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

txSig=[zeros(100000,1);x_out;zeros(100000,1)];

%% ================== USRP 参数 ==================
SYS.MasterClockRate        = 200e6;
SYS.CenterFrequency        = 1.3e9;
SYS.rxGain                 = 10;
SYS.txGain                 = 20;
SYS.SampleRate            = 1e6;
SYS.InterpDecim           = SYS.MasterClockRate / SYS.SampleRate;

SYS.SamplesPerFrame       = 5e4;
SYS.numFrame              = 100;   % 自发自收帧数

%% ================== Discover USRP ==================
connectedRadios = findsdru;
assert(strncmp(connectedRadios(1).Status,'Success',7),'未发现 USRP');

SYS.Platform = connectedRadios(1).Platform;
SYS.Address  = connectedRadios(1).IPAddress;

disp('USRP discovered.');

%% ================== 创建 Tx ==================
txRadio = comm.SDRuTransmitter( ...
    'Platform',            SYS.Platform, ...
    'SerialNum',           SYS.Address, ...
    'MasterClockRate',     SYS.MasterClockRate, ...
    'CenterFrequency',     SYS.CenterFrequency, ...
    'Gain',                SYS.txGain, ...
    'InterpolationFactor', SYS.InterpDecim);
    %'ClockSource',         'External');

txRadio.ChannelMapping = 1;
txRadio.UnderrunOutputPort = true;

%% ================== 创建 Rx ==================
rxRadio = comm.SDRuReceiver( ...
    'Platform',            SYS.Platform, ...
    'SerialNum',           SYS.Address, ...
    'MasterClockRate',     SYS.MasterClockRate, ...
    'CenterFrequency',     SYS.CenterFrequency, ...
    'Gain',                SYS.rxGain, ...
    'DecimationFactor',    SYS.InterpDecim, ...
    'SamplesPerFrame',     SYS.SamplesPerFrame, ...
    'OutputDataType',      'double');
   % 'ClockSource',         'External');

rxRadio.ChannelMapping    = 1;
rxRadio.OverrunOutputPort = true;

toc;
disp('=== 自发自收开始 ===');


%% ================== 自发自收 ==================
len = uint32(0);
rxLog = dsp.SignalSink;


for k = 1:SYS.numFrame
   
    txRadio(txSig);
    while len <= 0
    % ========== 一直收 ==========
    [rxFrame, len, overflow, timeTag] = rxRadio();
    end

    if len > 0
        rxLog(rxFrame);
    end
    pause(0.05)
    disp(k)
    len = uint32(0);
end

%% ================== 释放 ==================
release(txRadio);
release(rxRadio);

rxData = rxLog.Buffer;
save('rxData.mat','x','rxData');

disp('=== 自发自收结束 ===');

%% ===== 加载接收数据 =====
load('rxData.mat')

figure; 
plot(abs(rxData));
xlabel('Sample Index');
ylabel('Magnitude');
title('rxData Magnitude');
grid on;


%% ===== 前导检测及解调 =====
rx_rrc = filter(rrc, 1, rxData);
pol_wave = upfirdn(polit, rrc, sps, 1);

corr = filter(flipud(conj(pol_wave)), 1, rx_rrc);
rx_energy = filter(ones(length(pol_wave),1), 1, abs(rx_rrc).^2);
p_energy = sum(abs(pol_wave).^2);

metric = abs(corr).^2 ./ (rx_energy * p_energy + eps);

 [peaks, locs] = findpeaks(metric, ...
     'MinPeakHeight', 0.8, ...
     'MinPeakDistance',10000);

figure; 
plot(metric);
xlabel('Sample Index');
ylabel('Magnitude');
title('rxdata Magnitude');
grid on;

for i=1:length(locs)

    max1=locs(i);
    k = -62 : 495;
    idx = max1-12 + k*sps;
    
    r_sym = rx_rrc(idx);
    
    rx_p=r_sym(1:63);
    
    h = sum(rx_p .* conj(polit)) / sum(abs(polit).^2);
    
    
    rx_bit=qpskdemod(rx_sym(64:end),h,0.1,'bit');
    
    
    disp(sum(rx_bit~=x))
    
    figure;
    scatter(real(rx_sym(64:end) ), imag(rx_sym(64:end)), 10, 'filled');
    grid on;
    axis equal;
    xlabel('In-Phase');
    ylabel('Quadrature');
    title('Received Signal X Constellation');
end


