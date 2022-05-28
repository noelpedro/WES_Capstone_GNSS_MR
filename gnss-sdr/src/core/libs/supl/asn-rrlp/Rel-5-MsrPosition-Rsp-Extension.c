/*
 * SPDX-FileCopyrightText: (c) 2003, 2004 Lev Walkin <vlm@lionet.info>. All rights reserved.
 * SPDX-License-Identifier: BSD-1-Clause
 * Generated by asn1c-0.9.22 (http://lionet.info/asn1c)
 * From ASN.1 module "RRLP-Components"
 *     found in "../rrlp-components.asn"
 */

#include "Rel-5-MsrPosition-Rsp-Extension.h"

static asn_TYPE_member_t asn_MBR_Rel_5_MsrPosition_Rsp_Extension_1[] = {
    {ATF_POINTER, 3,
        offsetof(struct Rel_5_MsrPosition_Rsp_Extension, extended_reference),
        (ASN_TAG_CLASS_CONTEXT | (0 << 2)), -1, /* IMPLICIT tag at current level */
        &asn_DEF_Extended_reference,
        0, /* Defer constraints checking to the member type */
        0, /* No PER visible constraints */
        0, "extended-reference"},
    {ATF_POINTER, 2,
        offsetof(struct Rel_5_MsrPosition_Rsp_Extension, otd_MeasureInfo_5_Ext),
        (ASN_TAG_CLASS_CONTEXT | (1 << 2)), -1, /* IMPLICIT tag at current level */
        &asn_DEF_OTD_MeasureInfo_5_Ext,
        0, /* Defer constraints checking to the member type */
        0, /* No PER visible constraints */
        0, "otd-MeasureInfo-5-Ext"},
    {ATF_POINTER, 1,
        offsetof(struct Rel_5_MsrPosition_Rsp_Extension, ulPseudoSegInd),
        (ASN_TAG_CLASS_CONTEXT | (2 << 2)), -1, /* IMPLICIT tag at current level */
        &asn_DEF_UlPseudoSegInd,
        0, /* Defer constraints checking to the member type */
        0, /* No PER visible constraints */
        0, "ulPseudoSegInd"},
};
static int asn_MAP_Rel_5_MsrPosition_Rsp_Extension_oms_1[] = {0, 1, 2};
static ber_tlv_tag_t asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1[] = {
    (ASN_TAG_CLASS_UNIVERSAL | (16 << 2))};
static asn_TYPE_tag2member_t
    asn_MAP_Rel_5_MsrPosition_Rsp_Extension_tag2el_1[] = {
        {(ASN_TAG_CLASS_CONTEXT | (0 << 2)), 0, 0,
            0}, /* extended-reference at 985 */
        {(ASN_TAG_CLASS_CONTEXT | (1 << 2)), 1, 0,
            0}, /* otd-MeasureInfo-5-Ext at 991 */
        {(ASN_TAG_CLASS_CONTEXT | (2 << 2)), 2, 0,
            0} /* ulPseudoSegInd at 992 */
};
static asn_SEQUENCE_specifics_t
    asn_SPC_Rel_5_MsrPosition_Rsp_Extension_specs_1 = {
        sizeof(struct Rel_5_MsrPosition_Rsp_Extension),
        offsetof(struct Rel_5_MsrPosition_Rsp_Extension, _asn_ctx),
        asn_MAP_Rel_5_MsrPosition_Rsp_Extension_tag2el_1,
        3,                                             /* Count of tags in the map */
        asn_MAP_Rel_5_MsrPosition_Rsp_Extension_oms_1, /* Optional members */
        3,
        0, /* Root/Additions */
        2, /* Start extensions */
        4  /* Stop extensions */
};
asn_TYPE_descriptor_t asn_DEF_Rel_5_MsrPosition_Rsp_Extension = {
    "Rel-5-MsrPosition-Rsp-Extension",
    "Rel-5-MsrPosition-Rsp-Extension",
    SEQUENCE_free,
    SEQUENCE_print,
    SEQUENCE_constraint,
    SEQUENCE_decode_ber,
    SEQUENCE_encode_der,
    SEQUENCE_decode_xer,
    SEQUENCE_encode_xer,
    SEQUENCE_decode_uper,
    SEQUENCE_encode_uper,
    0, /* Use generic outmost tag fetcher */
    asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1,
    sizeof(asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1) /
        sizeof(asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1[0]), /* 1 */
    asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1,                /* Same as above */
    sizeof(asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1) /
        sizeof(asn_DEF_Rel_5_MsrPosition_Rsp_Extension_tags_1[0]), /* 1 */
    0,                                                             /* No PER visible constraints */
    asn_MBR_Rel_5_MsrPosition_Rsp_Extension_1,
    3,                                               /* Elements count */
    &asn_SPC_Rel_5_MsrPosition_Rsp_Extension_specs_1 /* Additional specs */
};