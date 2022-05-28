# WES_Capstone_GNSS_MR

System Needs: ubuntu 18 on host machine, adrv9009zu11eg, https://github.com/analogdevicesinc/meta-adi 2019_R2, https://github.com/analogdevicesinc/hdl 2019_r2, Vivado 2019.1, petalinux 2019.1

This is the work done to fullfill a Capstone project. In this project we take advantage of the two configurable LOs in the adrv9009zu11eg to make the board into a multiband GNSS receiver Targeting GPS L1, Galileo E1B, GPS L5, Galileao E5a. This work is inspired by the developers of github.com/gnss-sdr/gnss-sdr In which they have publications of their multiband receiver. </br>


File structure: <br />
Documentations, presentations: Docs <br />
Petalinux Project: adrv9009-zu11eg <br />
Work with Filter Wizard: Filter_Wizard  <br />
Work on gnss-sdr, manily adrv9009zu11eg signal source adapter: gnss-sdr  <br />
Application to monitor the receiver: https://github.com/acebrianjuan/gnss-sdr-monitor  <br />
Matlab plots: MATLAB  <br />
Yocto layer via meta-adi from ADI: meta-adi <br />
verilog_code: rtl <br />
