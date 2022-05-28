This Module performs a PCPS(phase coarse phase search) acquisiton technique. Hardware implementation was inspired by https://zenodo.org/record/2537011/files/Implementation%20of%20GNSS%20Receiver%20Hardware.pdf


Depends on Xilinx' IPs: </br>
Xilinx FFT: https://docs.xilinx.com/r/en-US/pg109-xfft/Fast-Fourier-Transform-v9.1-LogiCORE-IP-Product-Guide </br>
Two Complex Multiply: https://docs.xilinx.com/v/u/en-US/pg104-cmpy </br>
Bram to store raw baseband data in https://docs.xilinx.com/v/u/8.3-English/pg058-blk-mem-gen </br>

Depends on IPs in the `sub_modules` folder

