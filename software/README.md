Build Project: </br>
`git checkout adrv9009_signal_source` </br>
`cd gnss-sdr/buid && cmake -DENABLE_ADRV9009=ON -DENABLE_FPGA=ON ../ && make` </br>



Run the code on target board </br>
`<Path_To_Binary> -c gnss-sdr/conf/<Config_File_To_Use>` </br>

`<Path_To_Binary>` Usually written in `gnss-sdr/install` </br>

`<Config_File_To_Use>` Several to chose from : </br>

GPS L1 only config: `conf/gnss-sdr_GPS_L1_FPGA.conf` </br>
GPS L1 + GPS L5 config `conf/gnss-sdr_GPS_L1_L5_FPGA.conf` </br>
GPS L1 + Galileo E1 + GPS L1 + Galileo E5 `conf/gnss-sdr_GPS_L1_L5_Galileo_E1b_E5a_FPGA.conf`
