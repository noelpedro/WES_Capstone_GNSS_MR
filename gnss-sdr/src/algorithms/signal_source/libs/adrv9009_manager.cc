/*
 * libiio - ADRV9009 IIO streaming example
 *
 * Copyright (C) 2014 IABG mbH
 * Author: Michael Feilen <feilen_at_iabg.de>
 * Copyright (C) 2019 Analog Devices Inc.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 **/
#include "adrv9009_manager.h"
#include <glog/logging.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <iostream>
#include <bits/stdc++.h>

/* helper macros */

#define IIO_ENSURE(expr) { \
	if (!(expr)) { \
		(void) fprintf(stderr, "assertion failed (%s:%d)\n", __FILE__, __LINE__); \
		(void) abort(); \
	} \
}


/* common RX and TX streaming params */
struct stream_cfg {
	long long lo_hz; // Local oscillator frequency in Hz
};

/* static scratch mem for strings */
static char tmpstr[64];

/* IIO structs required for streaming */
static struct iio_context *ctx   = NULL;
static struct iio_channel *rx0_i = NULL;
static struct iio_channel *rx0_q = NULL;
static struct iio_channel *rx1_i = NULL;
static struct iio_channel *rx1_q = NULL;



/* check return value of attr_write function */
void errchk(int v, const char* what) {
	 if (v < 0) { fprintf(stderr, "Error %d writing to channel \"%s\"\nvalue may not be supported.\n", v, what); }
}

/* write attribute: long long int */
void wr_ch_lli(struct iio_channel *chn, const char* what, long long val)
{
	errchk(iio_channel_attr_write_longlong(chn, what, val), what);
}

/* write attribute: long long int */
long long rd_ch_lli(struct iio_channel *chn, const char* what)
{
	long long val;

	errchk(iio_channel_attr_read_longlong(chn, what, &val), what);

	printf("\t %s: %lld\n", what, val);
	return val;
}

#if 0
/* write attribute: string */
static void wr_ch_str(struct iio_channel *chn, const char* what, const char* str)
{
	errchk(iio_channel_attr_write(chn, what, str), what);
}
#endif

/* helper function generating channel names */
char* get_ch_name_mod(const char* type, int id, char modify)
{
	snprintf(tmpstr, sizeof(tmpstr), "%s%d_%c", type, id, modify);
	return tmpstr;
}

/* helper function generating channel names */
char* get_ch_name(const char* type, int id)
{
	snprintf(tmpstr, sizeof(tmpstr), "%s%d", type, id);
	return tmpstr;
}

/* returns adrv9009 phy device */
struct iio_device* get_adrv9009_phy(void)
{
	struct iio_device *dev =  iio_context_find_device(ctx, "adrv9009-phy");
	IIO_ENSURE(dev && "No adrv9009-phy found");
	return dev;
}

/* returns adrv9009 phy device */
struct iio_device* get_adrv9009_phyb(void)
{
	struct iio_device *dev =  iio_context_find_device(ctx, "adrv9009-phy-b");
	IIO_ENSURE(dev && "No adrv9009-phy-b found");
	return dev;
}


/* finds adrv9009 streaming IIO devices */
bool get_adrv9009_stream_dev(enum iodev d, struct iio_device **dev)
{
	switch (d) {
	case TX: *dev = iio_context_find_device(ctx, "axi-adrv9009-tx-hpc"); return *dev != NULL;
	case RX: *dev = iio_context_find_device(ctx, "axi-adrv9009-rx-hpc");  return *dev != NULL;
	default: IIO_ENSURE(0); return false;
	}
}

/* finds adrv9009 streaming IIO channels */
bool get_adrv9009_stream_ch(enum iodev d, struct iio_device *dev, int chid, char modify, struct iio_channel **chn)
{
	*chn = iio_device_find_channel(dev, modify ? get_ch_name_mod("voltage", chid, modify) : get_ch_name("voltage", chid), d == TX);
	if (!*chn)
		*chn = iio_device_find_channel(dev, modify ? get_ch_name_mod("voltage", chid, modify) : get_ch_name("voltage", chid), d == TX);
	return *chn != NULL;
}

/* finds adrv9009 phy IIO configuration channel with id chid */
bool get_phy_chan(enum iodev d, int chid, struct iio_channel **chn)
{
	switch (d) {
	case RX: *chn = iio_device_find_channel(get_adrv9009_phy(), get_ch_name("voltage", chid), false); return *chn != NULL;
	case TX: *chn = iio_device_find_channel(get_adrv9009_phy(), get_ch_name("voltage", chid), true);  return *chn != NULL;
	default: IIO_ENSURE(0); return false;
	}
}

/* finds adrv9009 phy IIO configuration channel with id chid */
bool get_phyb_chan(enum iodev d, int chid, struct iio_channel **chn)
{
	switch (d) {
	case RX: *chn = iio_device_find_channel(get_adrv9009_phyb(), get_ch_name("voltage", chid), false); return *chn != NULL;
	case TX: *chn = iio_device_find_channel(get_adrv9009_phyb(), get_ch_name("voltage", chid), true);  return *chn != NULL;
	default: IIO_ENSURE(0); return false;
	}
}

/* finds adrv9009 local oscillator IIO configuration channels */

/* finds adrv9009 local oscillator IIO configuration channels */
bool get_lo_chan(struct iio_channel **chn)
{
	 // LO chan is always output, i.e. true
	*chn = iio_device_find_channel(get_adrv9009_phy(), get_ch_name("altvoltage", 0), true); return *chn != NULL;
}

/* finds adrv9009 local oscillator IIO configuration channels */
bool get_lob_chan(struct iio_channel **chn)
{
	 // LO chan is always output, i.e. true
	*chn = iio_device_find_channel(get_adrv9009_phyb(), get_ch_name("altvoltage", 0), true); return *chn != NULL;
}

/* applies streaming configuration through IIO */
bool cfg_adrv9009_streaming_ch(struct stream_cfg *cfg, int chid)
{
	struct iio_channel *chn = NULL;

	// Configure phy and lo channels
	printf("* Acquiring ADRV9009 A phy channel %d\n", chid);
	if (!get_phy_chan(RX, chid, &chn)) {	return false; }

	rd_ch_lli(chn, "rf_bandwidth");
	rd_ch_lli(chn, "sampling_frequency");

	// Configure LO channel
	printf("* Acquiring ADRV9009 A TRX lo channel\n");
	if (!get_lo_chan(&chn)) { return false; }
	wr_ch_lli(chn, "frequency", cfg->lo_hz);
	return true;
}

/* applies streaming configuration through IIO */
bool cfg_adrv9009b_streaming_ch(struct stream_cfg *cfg, int chid)
{
	struct iio_channel *chn = NULL;

	// Configure phy and lo channels
	printf("* Acquiring ADRV9009 phy B  channel %d\n", chid);
	if (!get_phyb_chan(RX, chid, &chn)) {	return false; }

	rd_ch_lli(chn, "rf_bandwidth");
	rd_ch_lli(chn, "sampling_frequency");

	// Configure LO channel
	printf("* Acquiring ADRV9009 B TRX lo channel\n");
	if (!get_lob_chan(&chn)) { return false; }
	wr_ch_lli(chn, "frequency", cfg->lo_hz);
	return true;
}

/* simple configuration and streaming */
bool config_adrv9009_rx_local(uint64_t freq_,
    uint64_t freq2_,
    bool rx1_enable_,
    bool rx2_enable_,
    const std::string &gain_mode_rx1_,
    const std::string &gain_mode_rx2_,
    double rf_gain_rx1_,
    double rf_gain_rx2_,
    bool quadrature_,
    std::string profile_file_)
{

// Streaming devices
	struct iio_device *rx;

	// RX and TX sample counters
	int ret;
	// Stream configuration
	struct stream_cfg trxcfg;
	struct stream_cfg trxcfg_b;

	struct iio_device *adrv9009_phy;
	struct iio_device *adrv9009_phyb;
	/*const std::string adrv9009_profile_path = std::string("/sys/bus/iio/devices/iio:device4/profile_config");
	const std::string adrv9009b_profile_path = std::string("/sys/bus/iio/devices/iio:device5/profile_config");
	std::string command1_str;
	std::string command2_str;
	command1_str = "cat " + profile_file_ + " > " + adrv9009_profile_path;
	command2_str = "cat " + profile_file_ + " > " + adrv9009b_profile_path;



	const char *command1 = command1_str.c_str();
	const char *command2 = command2_str.c_str();


	//std::cout << "Writing Profile config with  " << command1 << '\n';
    	//system(command1);
    	//system(command1);
	//std::cout << "Writing Profile config with  " << command2 << '\n';
    	//system(command2);
    	//system(command1);
	*/

	// TRX stream config
	trxcfg.lo_hz = freq_;
	trxcfg_b.lo_hz = freq2_;

	printf("* Acquiring IIO context\n");
	IIO_ENSURE((ctx = iio_create_default_context()) && "No context");
	IIO_ENSURE(iio_context_get_devices_count(ctx) > 0 && "No devices");

	printf("* Acquiring ADRV9009 streaming devices\n");
	IIO_ENSURE(get_adrv9009_stream_dev(RX, &rx) && "No rx dev found");

	printf("* Configuring ADRV9009 for streaming\n");
	IIO_ENSURE(cfg_adrv9009_streaming_ch(&trxcfg, 0) && "TRX device not found");
	
	printf("* Configuring ADRV9009 for streaming\n");
	IIO_ENSURE(cfg_adrv9009b_streaming_ch(&trxcfg_b, 0) && "TRX device not found");

	printf("* Initializing ADRV9009 IIO streaming channels\n");
	IIO_ENSURE(get_adrv9009_stream_ch(RX, rx, 0, 'i', &rx0_i) && "RX chan i not found");
	IIO_ENSURE(get_adrv9009_stream_ch(RX, rx, 0, 'q', &rx0_q) && "RX chan q not found");
	IIO_ENSURE(get_adrv9009_stream_ch(RX, rx, 3, 'i', &rx1_i) && "RX chan i not found");
	IIO_ENSURE(get_adrv9009_stream_ch(RX, rx, 3, 'q', &rx1_q) && "RX chan q not found");

	printf("* Enabling IIO streaming channels\n");
	if (rx1_enable_)
	    {
		iio_channel_enable(rx0_i);
		iio_channel_enable(rx0_q);
	    }
	if (rx2_enable_)
	    {
		iio_channel_enable(rx1_i);
		iio_channel_enable(rx1_q);
	    }
	adrv9009_phy = iio_context_find_device(ctx, "adrv9009-phy");
	adrv9009_phyb = iio_context_find_device(ctx, "adrv9009-phy-b");

	ret = iio_device_attr_write(adrv9009_phy, "ensm_mode", "fdd");
	if (ret < 0)
	    {
		std::cout << "Failed to set ensm_mode: " << ret << '\n';
	    }
	ret = iio_device_attr_write(adrv9009_phyb, "ensm_mode", "fdd");
	if (ret < 0)
	    {
		std::cout << "Failed to set ensm_mode: " << ret << '\n';
	    }
	ret = iio_device_attr_write_bool(adrv9009_phy, "in_voltage0_quadrature_tracking_en", quadrature_);
	if (ret < 0)
   	    {
		std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
	    }
	ret = iio_device_attr_write(adrv9009_phy, "in_voltage0_gain_control_mode", gain_mode_rx1_.c_str());
	if (ret < 0)
        {
	    std::cout << "Failed to set in_voltage0_gain_control_mode: " << ret << '\n';
	}
	ret = iio_device_attr_write_double(adrv9009_phy, "in_voltage0_hardwaregain", rf_gain_rx1_);
	if (ret < 0)
	    {
	        std::cout << "Failed to set in_voltage0_hardwaregain: " << ret << '\n';
	    }
	ret = iio_device_attr_write_bool(adrv9009_phyb, "in_voltage0_quadrature_tracking_en", quadrature_);
	if (ret < 0)
   	    {
		std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
	    }
	ret = iio_device_attr_write(adrv9009_phyb, "in_voltage0_gain_control_mode", gain_mode_rx2_.c_str());
	if (ret < 0)
        {
	    std::cout << "Failed to set in_voltage0_gain_control_mode: " << ret << '\n';
	}
	ret = iio_device_attr_write_double(adrv9009_phyb, "in_voltage0_hardwaregain", rf_gain_rx2_);
	if (ret < 0)
	    {
	        std::cout << "Failed to set in_voltage0_hardwaregain: " << ret << '\n';
	    }

    //iio_context_destroy(ctx);
    return true;



}


bool disable_adrv9009_rx_local()
{

    printf("* Disabling streaming channels\n");
    if (rx0_i) { iio_channel_disable(rx0_i); }
    if (rx0_q) { iio_channel_disable(rx0_q); }
    if (rx1_i) { iio_channel_disable(rx1_i); }
    if (rx1_q) { iio_channel_disable(rx1_q); }

    printf("* Destroying context\n");
    if (ctx) { iio_context_destroy(ctx); }
    return true;

}
