fs = 245.76e6;
nfft = 65536;
filename = './adrv9009_iqGPS_L1_245p76msps_1sec_ishort.dat';
fd = fopen(filename,'rb');

data = fread(fd,fs/100 * 2 , 'int16');
data_rx1a_i = data(1:2:end);
data_rx1a_q = data(2:2:end);


data_rx1a = data_rx1a_i + 1j*data_rx1a_q;


figure(1);
hold on;
len = length(data_rx1a_i);
xaxis = [0:len-1]/fs;
plot(xaxis, data_rx1a_i);
hold on;
plot(xaxis, data_rx1a_q);
grid on;
title('Time Domain Plot');
xlabel('(s)');
ylabel('Amplitude');
grid on;
