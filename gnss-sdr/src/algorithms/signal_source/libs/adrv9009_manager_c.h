/*!
 * \file adrv9009_manager.h
 * \brief An Analog Devices ADRV9009 front-end configuration library wrapper for configure some functions via iiod link.
 * \author Javier Arribas, jarribas(at)cttc.es
 *
 * This file contains information taken from librtlsdr:
 *  https://git.osmocom.org/rtl-sdr
 * -----------------------------------------------------------------------------
 *
 * Copyright (C) 2010-2020  (see AUTHORS file for a list of contributors)
 *
 * GNSS-SDR is a software defined Global Navigation
 *          Satellite Systems receiver
 *
 * This file is part of GNSS-SDR.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * -----------------------------------------------------------------------------
 */

#ifndef GNSS_SDR_ADRV9009_MANAGER_H
#define GNSS_SDR_ADRV9009_MANAGER_H

#include <iio.h>
#include <cstdint>
#include <string>

#define FIR_BUF_SIZE 8192

/* RX is input, TX is output */
enum iodev
{
    RX,
    TX
};

/* common RX and TX streaming params */
struct stream_cfg
{
    int64_t lo_hz;       // Local oscillator frequency in Hz
};

/* check return value of attr_write function */
void errchk(int v, const char *what);

/* write attribute: int64_t int */
void wr_ch_lli(struct iio_channel *chn, const char *what, int64_t val);

/* write attribute: string */
void wr_ch_str(struct iio_channel *chn, const char *what, const char *str);

/* returns adrv9009 phy device */
struct iio_device *get_adrv9009_phy(struct iio_context *ctx);

struct iio_device *get_adrv9009_phyb(struct iio_context *ctx);

/* finds ADRV9009 streaming IIO devices */
bool get_adrv9009_stream_dev(struct iio_context *ctx, enum iodev d, struct iio_device **dev);

/* finds ADRV9009 streaming IIO channels */
bool get_adrv9009_stream_ch(struct iio_context *ctx, enum iodev d, struct iio_device *dev, int chid, char modify, struct iio_channel **chn);

/* finds ADRV9009 phy IIO configuration channel with id chid */
bool get_phy_chan(struct iio_context *ctx, enum iodev d, int chid, struct iio_channel **chn);

bool get_phyb_chan(struct iio_context *ctx, enum iodev d, int chid, struct iio_channel **chn);

/* finds ADRV9009 local oscillator IIO configuration channels */
bool get_lo_chan(struct iio_context *ctx, enum iodev d, struct iio_channel **chn);

bool get_lob_chan(struct iio_context *ctx, enum iodev d, struct iio_channel **chn);

/* applies streaming configuration through IIO */
bool cfg_adrv9009_streaming_ch(struct iio_context *ctx, struct stream_cfg *cfg, enum iodev type, int chid);

bool cfg_adrv9009b_streaming_ch(struct iio_context *ctx, struct stream_cfg *cfg, enum iodev type, int chid);

bool config_adrv9009_rx_local(
    uint64_t freq_,
    uint64_t freq2_,
    bool rx1_enable_,
    bool rx2_enable_,
    const std::string &gain_mode_rx1_,
    const std::string &gain_mode_rx2_,
    double rf_gain_rx1_,
    double rf_gain_rx2_,
    bool quadrature_);

bool config_adrv9009_tx_local(
    uint64_t freq_,
    int numbufs,
    int bytes);



bool disable_adrv9009_rx_local();


void iio_buffer_DMA_tx(uint64_t freq_,void* data, int numbufs, int bytes);

#endif  // GNSS_SDR_ADRV9009_MANAGER_H
