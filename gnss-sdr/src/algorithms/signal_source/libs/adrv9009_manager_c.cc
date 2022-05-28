/*!
 * \file adrv9009_manager.cc
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
#include "adrv9009_manager.h"
#include <glog/logging.h>
#include <cmath>
#include <fstream>  // for ifstream
#include <iostream>
#include <sstream>
#include <vector>

#define IIO_ENSURE(expr) {\
	if(!(expr)) { \
	       (void) fprintf(stderr, "assertion failed (%s:%d)\n", __FILE__, __LINE__); \
	       (void) abort(); \
	} \
}

static struct iio_device *tx_;
static struct iio_buffer *txbuf_ = NULL;
static struct iio_channel *tx0_i_ = NULL;
static struct iio_channel *tx0_q_ = NULL;
static struct iio_context *ctx_dma_ = NULL;
static struct stream_cfg txcfg_;


static char tmpstr[64];

/* check return value of attr_write function */
void errchk(int v, const char *what)
{
    if (v < 0)
        {
            LOG(WARNING) << "Error " << v << " writing to channel " << what << " value may not be supported. ";
        }
}


/* write attribute: int64_t int */
void wr_ch_lli(struct iio_channel *chn, const char *what, int64_t val)
{
    errchk(iio_channel_attr_write_longlong(chn, what, val), what);
}


/* write attribute: string */
void wr_ch_str(struct iio_channel *chn, const char *what, const char *str)
{
    errchk(iio_channel_attr_write(chn, what, str), what);
}

/* helper function generating channel names */
static char* get_ch_name_mod(const char* type, int id, char modify)
{
	        snprintf(tmpstr, sizeof(tmpstr), "%s%d_%c", type, id, modify);
		        return tmpstr;
}

/* helper function generating channel names */
static char* get_ch_name(const char* type, int id)
{
	        snprintf(tmpstr, sizeof(tmpstr), "%s%d", type, id);
		        return tmpstr;
}



/* returns adrv9009 phy device */
struct iio_device *get_adrv9009_phy(struct iio_context *ctx)
{
    struct iio_device *dev = iio_context_find_device(ctx, "adrv9009-phy");
    return dev;
}

struct iio_device *get_adrv9009_phyb(struct iio_context *ctx)
{
    struct iio_device *dev = iio_context_find_device(ctx, "adrv9009-phy-b");
    return dev;
}



/* finds ADRV9009 streaming IIO devices */
bool get_adrv9009_stream_dev(struct iio_context *ctx, enum iodev d, struct iio_device **dev)
{
    switch (d)
        {
        case TX:
            *dev = iio_context_find_device(ctx, "axi-adrv9009-tx-hpc");
            return *dev != nullptr;
        case RX:
            *dev = iio_context_find_device(ctx, "axi-adrv9009-rx-hpc");
            return *dev != nullptr;
        default:
            return false;
        }
}


/* finds ADRV9009 streaming IIO channels */
bool get_adrv9009_stream_ch(struct iio_context *ctx __attribute__((unused)), enum iodev d, struct iio_device *dev, int chid, char modify, struct iio_channel **chn)
{
    /*std::stringstream name;
    name.str("");
    name << "voltage";
    name << chid;
    *chn = iio_device_find_channel(dev, name.str().c_str(), d == TX);
    if (!*chn)
        {
            name.str("");
            name << "altvoltage";
            name << chid;
            *chn = iio_device_find_channel(dev, name.str().c_str(), d == TX);
        }
    return *chn != nullptr;
    */
    *chn = iio_device_find_channel(dev, modify ? get_ch_name_mod("voltage", chid, modify) : get_ch_name("voltage", chid), d == TX);
    if (!*chn)
        *chn = iio_device_find_channel(dev, modify ? get_ch_name_mod("voltage", chid, modify) : get_ch_name("voltage", chid), d == TX);
    return *chn != NULL;

}


/* finds ADRV9009 phy IIO configuration channel with id chid */
bool get_phy_chan(struct iio_context *ctx, enum iodev d, int chid, struct iio_channel **chn)
{
    std::stringstream name;
    switch (d)
        {
        case RX:
            name.str("");
            name << "voltage";
            name << chid;
            *chn = iio_device_find_channel(get_adrv9009_phy(ctx), name.str().c_str(), false);
            return *chn != nullptr;
            break;
        case TX:
            name.str("");
            name << "voltage";
            name << chid;
            *chn = iio_device_find_channel(get_adrv9009_phy(ctx), name.str().c_str(), true);
            return *chn != nullptr;
            break;
        default:
            return false;
        }
}

bool get_phyb_chan(struct iio_context *ctx, enum iodev d, int chid, struct iio_channel **chn)
{
    std::stringstream name;
    switch (d)
        {
        case RX:
            name.str("");
            name << "voltage";
            name << chid;
            *chn = iio_device_find_channel(get_adrv9009_phyb(ctx), name.str().c_str(), false);
            return *chn != nullptr;
            break;
        case TX:
            name.str("");
            name << "voltage";
            name << chid;
            *chn = iio_device_find_channel(get_adrv9009_phyb(ctx), name.str().c_str(), true);
            return *chn != nullptr;
            break;
        default:
            return false;
        }
}

/* finds ADRV9009 local oscillator IIO configuration channels */
bool get_lo_chan(struct iio_context *ctx, enum iodev d, struct iio_channel **chn)
{
    switch (d)
        {
        // LO chan is always output, i.e. true
        case RX:
            *chn = iio_device_find_channel(get_adrv9009_phy(ctx), "altvoltage0", true);
            return *chn != nullptr;
        case TX:
            *chn = iio_device_find_channel(get_adrv9009_phy(ctx), "altvoltage1", true);
            return *chn != nullptr;
        default:
            return false;
        }
}

bool get_lob_chan(struct iio_context *ctx, enum iodev d, struct iio_channel **chn)
{
    switch (d)
        {
        // LO chan is always output, i.e. true
        case RX:
            *chn = iio_device_find_channel(get_adrv9009_phyb(ctx), "altvoltage0", true);
            return *chn != nullptr;
        case TX:
            *chn = iio_device_find_channel(get_adrv9009_phyb(ctx), "altvoltage1", true);
            return *chn != nullptr;
        default:
            return false;
        }
}


/* applies streaming configuration through IIO */
bool cfg_adrv9009_streaming_ch(struct iio_context *ctx, struct stream_cfg *cfg, enum iodev type, int chid)
{
    struct iio_channel *chn = nullptr;

    // Configure phy and lo channels
    // LOG(INFO)<<"* Acquiring ADRV9009 phy channel"<<chid;
    std::cout << "* Acquiring ADRV9009 phy channel" << chid << '\n';
    if (!get_phy_chan(ctx, type, chid, &chn))
        {
            return false;
        }
    
    // Configure LO channel
    // LOG(INFO)<<"* Acquiring AD9361 "<<type == TX ? "TX" : "RX";
    std::cout << "* Acquiring ADRV9009 " << (type == TX ? "TX" : "RX") << '\n';
    if (!get_lo_chan(ctx, type, &chn))
        {
            return false;
        }
    std::cout << "Frequency A" << cfg->lo_hz  << " \n";
    wr_ch_lli(chn, "frequency", cfg->lo_hz);
    return true;
}

bool cfg_adrv9009b_streaming_ch(struct iio_context *ctx, struct stream_cfg *cfg, enum iodev type, int chid)
{
    struct iio_channel *chn = nullptr;

    // Configure phy and lo channels
    // LOG(INFO)<<"* Acquiring ADRV9009 phy channel"<<chid;
    std::cout << "* Acquiring ADRV9009 phy channel" << chid << '\n';
    if (!get_phyb_chan(ctx, type, chid, &chn))
        {
            return false;
        }
    
    // Configure LO channel
    // LOG(INFO)<<"* Acquiring AD9361 "<<type == TX ? "TX" : "RX";
    std::cout << "* Acquiring ADRV9009 " << (type == TX ? "TX" : "RX") << '\n';
    if (!get_lob_chan(ctx, type, &chn))
        {
            return false;
        }
    wr_ch_lli(chn, "frequency", cfg->lo_hz);
    std::cout << "Frequency B" << cfg->lo_hz << " \n";
    return true;
}

bool config_adrv9009_rx_local(uint64_t freq_,
    uint64_t freq2_,
    bool rx1_enable_,
    bool rx2_enable_,
    const std::string &gain_mode_rx1_,
    const std::string &gain_mode_rx2_,
    double rf_gain_rx1_,
    double rf_gain_rx2_,
    bool quadrature_)
{
    // RX stream config
    std::cout << "ADRV9009 Acquiring IIO LOCAL context\n";
    struct iio_context *ctx;
    // Streaming devices
    struct iio_device *rx;
    struct iio_device *rx_b;
    struct iio_channel *rx1a_i;
    struct iio_channel *rx1a_q;
    struct iio_channel *rx1b_i;
    struct iio_channel *rx1b_q;
    int ret;

    ctx = iio_create_default_context();
    if (!ctx)
        {
            std::cout << "No context\n";
            throw std::runtime_error("ADRV9009 IIO No context");
        }

    if (iio_context_get_devices_count(ctx) <= 0)
        {
            std::cout << "No devices\n";
            throw std::runtime_error("ADRV9009 IIO No devices");
        }

    std::cout << "Number of devices " << iio_context_get_devices_count(ctx) << "\n";

    struct iio_device *adrv9009_phy;
    struct iio_device *adrv9009_phyb;
    adrv9009_phy = iio_context_find_device(ctx, "adrv9009-phy");
    adrv9009_phyb = iio_context_find_device(ctx, "adrv9009-phy-b");
    struct stream_cfg rxcfg;
    struct stream_cfg rxcfgb;
    rxcfg.lo_hz = freq_;
    rxcfgb.lo_hz = freq2_;

    if (!cfg_adrv9009_streaming_ch(ctx, &rxcfg, RX, 0))
        {
            std::cout << "RX port 0 not found\n";
            throw std::runtime_error("ADRV9009 IIO RX port 0 not found");
        }
    if (!cfg_adrv9009b_streaming_ch(ctx, &rxcfgb, RX, 0))
        {
            std::cout << "RX port 1 not found\n";
            throw std::runtime_error("ADRV9009 IIO RX port 0 not found");
        }

    std::cout << "* Acquiring ADRV9009 streaming devices\n";
    if (!get_adrv9009_stream_dev(ctx, RX, &rx))
        {
            std::cout << "No rx dev found\n";
            throw std::runtime_error("ADRV9009 IIO No rx dev found");
        }
    

    std::cout << "* Initializing ADRV9009 IIO streaming channels\n";
    if (!get_adrv9009_stream_ch(ctx, RX, rx, 0,'i', &rx1a_i))
        {
            std::cout << "RX1a channel i not found\n";
            throw std::runtime_error("RX channel 1 not found");
        }

    if (!get_adrv9009_stream_ch(ctx, RX, rx, 0, 'q', &rx1a_q))
        {
            std::cout << "RX1a channel q not found\n";
            throw std::runtime_error("RX channel 2 not found");
        }
    if (!get_adrv9009_stream_ch(ctx, RX, rx, 2, 'i', &rx1b_i))
        {
            std::cout << "RX1b channel i not found\n";
            throw std::runtime_error("RX channel 2 not found");
        }
    if (!get_adrv9009_stream_ch(ctx, RX, rx, 2, 'q', &rx1b_q))
        {
            std::cout << "RX1b channel 2 not found\n";
            throw std::runtime_error("RX channel 2 not found");
        }

		
    // Filters can only be disabled after the sample rate has been set

    std::cout << "* Enabling IIO streaming channels\n";
    if (rx1_enable_)
        {
            iio_channel_enable(rx1a_i);
            iio_channel_enable(rx1a_q);
        }
    if (rx2_enable_)
        {
            iio_channel_enable(rx1b_i);
            iio_channel_enable(rx1b_q);
        }
    if (!rx1_enable_ and !rx2_enable_)
        {
            std::cout << "WARNING: No Rx channels enabled.\n";
        }

    /*ret = iio_device_attr_write(adrv9009_phy, "trx_rate_governor", "nominal");
    if (ret < 0)
        {
            std::cout << "Failed to set trx_rate_governor: " << ret << '\n';
        }*/
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
    /*ret = iio_device_attr_write(adrv9009_phy, "calib_mode", "auto");
    if (ret < 0)
        {
            std::cout << "Failed to set calib_mode: " << ret << '\n';
        }*/
    ret = iio_device_attr_write_bool(adrv9009_phy, "in_voltage0_quadrature_tracking_en", quadrature_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
        }
    ret = iio_device_attr_write_bool(adrv9009_phy, "in_voltage1_quadrature_tracking_en", quadrature_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
        }
    ret = iio_device_attr_write(adrv9009_phy, "in_voltage0_gain_control_mode", gain_mode_rx1_.c_str());
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage0_gain_control_mode: " << ret << '\n';
        }
    ret = iio_device_attr_write(adrv9009_phy, "in_voltage1_gain_control_mode", gain_mode_rx2_.c_str());
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage1_gain_control_mode: " << ret << '\n';
        }
    ret = iio_device_attr_write_double(adrv9009_phy, "in_voltage0_hardwaregain", rf_gain_rx1_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage0_hardwaregain: " << ret << '\n';
        }
    ret = iio_device_attr_write_double(adrv9009_phy, "in_voltage1_hardwaregain", rf_gain_rx2_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage1_hardwaregain: " << ret << '\n';
        }
    ret = iio_device_attr_write_bool(adrv9009_phyb, "in_voltage0_quadrature_tracking_en", quadrature_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
        }
    ret = iio_device_attr_write_bool(adrv9009_phyb, "in_voltage1_quadrature_tracking_en", quadrature_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage_quadrature_tracking_en: " << ret << '\n';
        }
    ret = iio_device_attr_write(adrv9009_phyb, "in_voltage0_gain_control_mode", gain_mode_rx1_.c_str());
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage0_gain_control_mode: " << ret << '\n';
        }
    ret = iio_device_attr_write(adrv9009_phyb, "in_voltage1_gain_control_mode", gain_mode_rx2_.c_str());
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage1_gain_control_mode: " << ret << '\n';
        }
    ret = iio_device_attr_write_double(adrv9009_phyb, "in_voltage0_hardwaregain", rf_gain_rx1_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage0_hardwaregain: " << ret << '\n';
        }
    ret = iio_device_attr_write_double(adrv9009_phyb, "in_voltage1_hardwaregain", rf_gain_rx2_);
    if (ret < 0)
        {
            std::cout << "Failed to set in_voltage1_hardwaregain: " << ret << '\n';
        }

    std::cout << "End of ADRV9009 RX configuration.\n";
    iio_context_destroy(ctx);
    return true;
}


bool disable_adrv9009_rx_local()
{
    struct iio_context *ctx;
    struct iio_context *ctxb;
    struct iio_device *rx;
    struct iio_channel *rx1a_i;
    struct iio_channel *rx1a_q;
    struct iio_channel *rx1b_i;
    struct iio_channel *rx1b_q;

    ctx = iio_create_default_context();
    if (!ctx)
        {
            std::cout << "No default context available when disabling RX channels\n";
            return false;
        }
    

    if (iio_context_get_devices_count(ctx) <= 0)
        {
            std::cout << "No devices available when disabling RX channels\n";
            return false;
        }
    


    if (!get_adrv9009_stream_dev(ctx, RX, &rx))
        {
            std::cout << "No rx streams found when disabling RX channels\n";
            return false;
        }

    if (!get_adrv9009_stream_ch(ctx, RX, rx, 0, 'i', &rx1a_i))
        {
            std::cout << "RX channel 1 not found when disabling RX channels\n";
            return false;
        }

    if (!get_adrv9009_stream_ch(ctx, RX, rx, 0, 'q', &rx1a_q))
        {
            std::cout << "RX channel 2 not found when disabling RX channels\n";
            return false;
        }
    if (!get_adrv9009_stream_ch(ctx, RX, rx, 2, 'i', &rx1b_i))
        {
            std::cout << "RX channel 2 not found when disabling RX channels\n";
            return false;
        }
    if (!get_adrv9009_stream_ch(ctx, RX, rx, 2, 'q', &rx1b_q))
        {
            std::cout << "RX channel 2 not found when disabling RX channels\n";
            return false;
        }

    iio_channel_disable(rx1a_i);
    iio_channel_disable(rx1a_q);
    iio_channel_disable(rx1b_i);
    iio_channel_disable(rx1b_q);
    iio_context_destroy(ctx);
    return true;
}



bool config_adrv9009_tx_local(
    uint64_t freq_,
    int numbufs,
    int bytes)
{

     txcfg_.lo_hz = freq_;

     IIO_ENSURE((ctx_dma_ = iio_create_default_context()) && "No context");     
     
     if (!cfg_adrv9009_streaming_ch(ctx_dma_, &txcfg_, TX, 0))
                {
                    std::cout << "RX port 0 not found\n";
                    throw std::runtime_error("ADRV9009 IIO TX port 0 not found");
                }

     
     IIO_ENSURE(iio_context_get_devices_count(ctx_dma_) > 0 && "No Devices");     

     IIO_ENSURE(get_adrv9009_stream_dev(ctx_dma_, TX, &tx_) && "No tx dev found");

     IIO_ENSURE(get_adrv9009_stream_ch(ctx_dma_, TX, tx_, 1, 'i', &tx0_i_) && "TX chan i not found");
     IIO_ENSURE(get_adrv9009_stream_ch(ctx_dma_, TX, tx_, 1, 'q', &tx0_q_) && "TX chan q not found");

     iio_channel_enable(tx0_i_);
     iio_channel_enable(tx0_q_);

    iio_device_set_kernel_buffers_count(tx_, numbufs);
     txbuf_ = iio_device_create_buffer(tx_, bytes, false);

     if (!txbuf_)
         {
            perror("Could not create TX buffer");
            if (txbuf_) { iio_buffer_destroy(txbuf_); }
            if (ctx_dma_) { iio_context_destroy(ctx_dma_); }
            if (tx0_i_) { iio_channel_disable(tx0_i_); }
            if (tx0_q_) { iio_channel_disable(tx0_q_); }
         }


}

void iio_buffer_DMA_tx(
	uint64_t freq_,
	void *data, int numbuf, int bytes)
{

     IIO_ENSURE((ctx_dma_ = iio_create_default_context()) && "No context");     
     
     IIO_ENSURE(iio_context_get_devices_count(ctx_dma_) > 0 && "No Devices");     

     IIO_ENSURE(get_adrv9009_stream_dev(ctx_dma_, TX, &tx_) && "No tx dev found");

     IIO_ENSURE(get_adrv9009_stream_ch(ctx_dma_, TX, tx_, 1, 'i', &tx0_i_) && "TX chan i not found");
     IIO_ENSURE(get_adrv9009_stream_ch(ctx_dma_, TX, tx_, 1, 'q', &tx0_q_) && "TX chan q not found");

     iio_channel_enable(tx0_i_);
     iio_channel_enable(tx0_q_);

     iio_device_set_kernel_buffers_count(tx_,numbuf);
     txbuf_ = iio_device_create_buffer(tx_, bytes, false);
 
     if (!txbuf_)
         {
	    perror("Could not create TX buffer");
	    if (txbuf_) { iio_buffer_destroy(txbuf_); }
	    if (ctx_dma_) { iio_context_destroy(ctx_dma_); }
	    if (tx0_i_) { iio_channel_disable(tx0_i_); }
	    if (tx0_q_) { iio_channel_disable(tx0_q_); }
	 }
     if (!txbuf_)
         {
            perror("Could not create TX buffer");
            if (txbuf_) { iio_buffer_destroy(txbuf_); }
            if (ctx_dma_) { iio_context_destroy(ctx_dma_); }
            if (tx0_i_) { iio_channel_disable(tx0_i_); }
            if (tx0_q_) { iio_channel_disable(tx0_q_); }
	 }
     
     ssize_t nbytes_tx;
     iio_buffer_set_data(txbuf_, data);
     iio_channel_write_raw(tx0_i_, txbuf_, data, bytes);
     nbytes_tx = iio_buffer_push_partial(txbuf_, (bytes/2 ));
     //sleep(1);
     /*if (nbytes_tx < 0) 
	 { 
	    printf("Error pushing buffer %d.\n", (int)nbytes_tx); 
	    if (txbuf_) { iio_buffer_destroy(txbuf_); }
	    if (ctx_dma_) { iio_context_destroy(ctx_dma_); }
	    if (tx0_i_) { iio_channel_disable(tx0_i_); }
	    if (tx0_q_) { iio_channel_disable(tx0_q_); }
	 }
	 */
	    if (txbuf_) { iio_buffer_destroy(txbuf_); }
    	    //std::cout << "Done Destroying buffer " << std::endl;
    	    //std::cout << "Done Destroying context " << std::endl;
	    if (tx0_i_) { iio_channel_disable(tx0_i_); }
    	    //std::cout << "Done Disableing channel i" << std::endl;
	    if (tx0_q_) { iio_channel_disable(tx0_q_); }
    	    //std::cout << "Done Disableing channel q" << std::endl;
            
	    if (ctx_dma_) { iio_context_destroy(ctx_dma_); }
}


