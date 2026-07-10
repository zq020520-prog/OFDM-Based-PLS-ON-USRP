function modsignal=qpskmod(bits)
  
if mod(length(bits), 2) ~= 0
        error('输入比特流的长度必须是2的倍数');
end 
  bits=double(bits);
  n=length(bits)/2;
  modsignal=zeros(n,1);
  for i=1:n
  modsignal(i)=(1-2*bits(2*i-1))+1i*(1-2*bits(2*i));
  end
end