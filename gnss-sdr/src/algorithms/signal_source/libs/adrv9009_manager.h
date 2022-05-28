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


#ifndef GNSS_SDR_ADRV9009_MANAGER_H
#define GNSS_SDR_ADRV9009_MANAGER_H

#include <iio.h>
#include <cstdint>
#include <string>



/* helper macros */

enum iodev { RX, TX };



/* check return value of attr_write function */
void errchk(int v, const char* what);

/* write attribute: long long int */
void wr_ch_lli(struct iio_channel *chn, const char* what, long long val);
/* write attribute: long long int */
long long rd_ch_lli(struct iio_channel *chn, const char* what);
#if 0
/* write attribute: string */
static void wr_ch_str(struct iio_channel *chn, const char* what, const char* str)
{
	errchk(iio_channel_attr_write(chn, what, str), what);
}
#endif

/* helper function generating channel names */
char* get_ch_name_mod(const char* type, int id, char modify);
/* helper function generating channel names */
char* get_ch_name(const char* type, int id);
/* returns adrv9009 phy device */
struct iio_device* get_adrv9009_phy(void);

/* returns adrv9009 phy device */
struct iio_device* get_adrv9009_phyb(void);

/* finds adrv9009 streaming IIO devices */
bool get_adrv9009_stream_dev(enum iodev d, struct iio_device **dev);
/* finds adrv9009 streaming IIO channels */
bool get_adrv9009_stream_ch(enum iodev d, struct iio_device *dev, int chid, char modify, struct iio_channel **chn);

/* finds adrv9009 phy IIO configuration channel with id chid */
bool get_phy_chan(enum iodev d, int chid, struct iio_channel **chn);
/* finds adrv9009 phy IIO configuration channel with id chid */
bool get_phyb_chan(enum iodev d, int chid, struct iio_channel **chn);
/* finds adrv9009 local oscillator IIO configuration channels */

/* finds adrv9009 local oscillator IIO configuration channels */
bool get_lo_chan(struct iio_channel **chn);

/* finds adrv9009 local oscillator IIO configuration channels */
bool get_lob_chan(struct iio_channel **chn);

/* applies streaming configuration through IIO */
bool cfg_adrv9009_streaming_ch(struct stream_cfg *cfg, int chid);

/* applies streaming configuration through IIO */
bool cfg_adrv9009b_streaming_ch(struct stream_cfg *cfg, int chid);

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
    std::string profile_file_);


bool disable_adrv9009_rx_local();

#endif
