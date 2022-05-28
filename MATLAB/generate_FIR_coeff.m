ast = 80;
n = 128;
tw = 0.01;
decim = 3;
 
f = fdesign.decimator(decim, 'Nyquist', decim,'N,Ast', n, ast);
hf = design(f);
 
hq = dfilt.dffir(hf.Numerator);
set(hq, 'Arithmetic',  'fixed', 'CoeffWordLength', 16);
coewrite(hq, 10, 'coefile_dec3');
 
fvtool(hf);
