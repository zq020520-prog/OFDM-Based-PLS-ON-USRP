%%OFDM信道估计 发送方程序
clc;
clear all;

sps=4;
span=6;
rolloff = 0.25;
rrc = rcosdesign(rolloff, span, sps, 'sqrt');

%===== 构造前导 =====
N1 = 63;          % 奇数
u = 16;           % 与 N 互素

n = (0:N1-1).';
polit = exp(-1j*pi*u*n.*(n+1)/N1); 
pol_wave = upfirdn(polit, rrc, sps, 1);

Nfft = 128;      % 改为128
N = 128;
M = 4;
CP = 16;         % 相应缩短CP（也可以用32更稳）

%% 子载波映射（对称 + 留DC + 留保护带）
X = zeros(Nfft,M);

% 左半部分（64个）
X(1:64,:) = 1+0i;

% 右半部分（64个）
X(65:128,:) =1+0i;

%% OFDM调制
x = ifft(X,Nfft);

x_cp = [x(end-CP+1:end,:); x];
x_cp=x_cp(:);
x_sum=[polit;x_cp];
 x_out = upfirdn(x_sum, rrc, sps, 1);
zeros_ahead = zeros(10000, 1);
txSig = [zeros_ahead;x_out;zeros_ahead];        

%% USRP transmitter parameters
SYS.MasterClockRate         = 200e6;
SYS.USRPTXCenterFrequency     = 2.1e9;
SYS.USRPRXCenterFrequency     = 2.1e9;
SYS.USRPTxGain                = 80;
SYS.USRPRxGain               = 30;
SYS.USRPFrontEndSampleRate  = 1e6;  % Symbol rate in Hertz
SYS.USRPInterpolationFactor = SYS.MasterClockRate/SYS.USRPFrontEndSampleRate;
SYS.USRPDecimationFactor   = SYS.MasterClockRate/SYS.USRPFrontEndSampleRate;


% Experiment Parameters
SYS.USRPFrameLength  = 5e4;
SYS.numRxFrame = 1150;
SYS.numTxFrame = 1;

%% Discover Radio
connectedRadios = findsdru('192.168.10.2');

assert(~isempty(connectedRadios) && ...
       strncmp(connectedRadios(1).Status,'Success',7), ...
       '未发现 USRP');

SYS.Platform = connectedRadios(1).Platform;
SYS.Address  = connectedRadios(1).IPAddress;

disp('USRP discovered.');

%% USRP initation
    radioTX = comm.SDRuTransmitter(...
        'Platform',             SYS.Platform, ...
        'SerialNum',            SYS.Address, ...
        'MasterClockRate',      SYS.MasterClockRate, ...
        'CenterFrequency',      SYS.USRPTXCenterFrequency, ...
        'Gain',                 SYS.USRPTxGain, ...
        'InterpolationFactor',  SYS.USRPInterpolationFactor, ...
        'ClockSource',          'External');
        
radioTX.ChannelMapping = 1;     
radioTX.UnderrunOutputPort = true;

radioRX = comm.SDRuReceiver(...
    'Platform',             SYS.Platform, ...
    'SerialNum',            SYS.Address, ...
    'MasterClockRate',      SYS.MasterClockRate, ...
    'CenterFrequency',      SYS.USRPRXCenterFrequency, ...
    'Gain',                 SYS.USRPRxGain, ...
    'DecimationFactor',     SYS.USRPDecimationFactor, ...
    'SamplesPerFrame',      SYS.USRPFrameLength, ...
    'OutputDataType',       'double',...
    'ReceiveAntennaPort',   'TX/RX',...
    'ClockSource',          'External');

radioRX.ChannelMapping      = 1;
radioRX.OverrunOutputPort   = true;
disp(SYS);

p=0;ip=0;

%% Initialize variables
len = uint32(0);
rcvdSignal = complex(zeros(SYS.USRPFrameLength,1));
step(radioTX,txSig);
disp('准备发送第一帧')
pause(8);
[x1, ~, overflow, timeTag] = step(radioRX);

t = timer;
t.ExecutionMode = 'fixedRate';
t.Period = 0.5;
t.TasksToExecute = 100;

t.TimerFcn =  {@timerTask, radioTX, txSig};  % 传参数
t.StopFcn = @(~,~) delete(t);

start(t);

for idx = 1:SYS.numRxFrame

    while len <= 0
        [rcvdSignal, len, overflow, timeTag] = step(radioRX);
    end 

    len = uint32(0);
    rx =rcvdSignal; 
    rx_rrc = filter(rrc, 1, rx);

    corr = filter(flipud(conj(pol_wave)), 1, rx_rrc);
    rx_energy = filter(ones(length(pol_wave),1), 1, abs(rx_rrc).^2);
    p_energy = sum(abs(pol_wave).^2);

    metric = abs(corr).^2 ./ (rx_energy * p_energy + eps);
    warning('off','all')
    [peaks, locs] = findpeaks(metric, ...
     'MinPeakHeight', 0.6, ...
      'MinPeakDistance',10000);
   
      if ~isempty(locs)
          if ip~=p
             ip=p;
          else
            max1=locs(1);
            k = -62 : 576;
            dx = max1-12 + k*sps;

            if max(dx)>50000
             [rcvdSignal1, ~, overflow, timeTag] = step(radioRX);
             rx =[rcvdSignal;rcvdSignal1]; 
             rx_rrc = filter(rrc, 1, rx);
            end
            if min(dx)<1
             rx =[beforeframe;rcvdSignal]; 
             rx_rrc = filter(rrc, 1, rx); 
             dx=dx+5000;
            end
            r_sym = rx_rrc(dx);
          
            %取数据
            y_cp=r_sym(64:end);
            y_cp = reshape(y_cp, Nfft+CP, M);
            y = y_cp(CP+1:end,:);

             % FFT
             Y = fft(y,Nfft);
                   
             rxData = zeros(N,M);
                
             rxData(1:128,:) = Y(1:128,:);

             %信道估计
             H=sum(rxData(1:128,1:1));


          end
     end
     beforeframe=rcvdSignal;        
end

delete(t);
release(radioTX); clear radioTX;
release(radioRX); clear radioRX;
disp('数据采集结束！');

function timerTask(~,~,radioTX,txSig)
    try
        step(radioTX, txSig);  % 用 step 方法，不要直接 radioTX(txSig)
        disp('tx'); 
        % 更新 p
        p = evalin('base','p') + 1;   
        assignin('base','p',p);  
    catch ME
        disp(['Timer发送出错: ', ME.message]);
    end
end