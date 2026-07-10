function demodsignal=qpskdemod(signal,h,noiseVar,outputType)

  if noiseVar == 0
        error('noiseVar不能为零');
  end 

  if h == 0
        error('h不能为零');
  end 

  n=length(signal);
  demodsignal=zeros(2*n,1);
  signal=signal/h;

  %计算LLR
  for i=1:n
  demodsignal(2*i-1)=real(signal(i))*2/noiseVar;
  demodsignal(2*i)=imag(signal(i))*2/noiseVar;
  end

  % 判断输出类型
  if nargin < 4
      outputType = 'llr';  % 如果用户没指定，默认输出bit
  end

  if strcmpi(outputType, 'bit')
      % 硬判决
      for i = 1:2*n
          if demodsignal(i) < 0
              demodsignal(i) = 1;
          else
              demodsignal(i) = 0;
          end
      end
  elseif strcmpi(outputType, 'llr')
      % 什么也不做，保留LLR
  else
      error('outputType必须是"bit"或"llr"');
  end

end