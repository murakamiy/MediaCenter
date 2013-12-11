#!/usr/bin/python
# -*- coding: utf-8 -*-
import time
import datetime
import array
import sys

PID = (0x14,)
TID = (0x70, 0x73)

# TOT TimeOffsetTable
# pid: 0x0014
# tid: 0x73
# table_id                  8   uimsbf
# section_syntax_indicator  1   bslbf
# reserved_future_use       1   bslbf
# reserved                  2   bslbf
# section_length            12  uimsbf
# JST_time                  40  bslbf
# reserved                  4   bslbf
# descriptors_loop_length   12  uimsbf
# for (i=0;i<N;i++){
#     descriptor()
# }
# CRC_32                    32  rpchof

# TDT TimeandDateTable
# pid:0x0014
# tid:0x70
# table_id                  8   uimsbf
# section_syntax_indicator  1   bslbf
# reserved_future_use       1   bslbf
# reserved                  2   bslbf
# section_length            12  uimsbf
# JST_time                  40  bslbf

class TransportPacket:
    def __init__(self, header, tdt):
        self.header = header
        self.tdt = tdt

class TransportPacketHeader:
    def __init__(self, pid, payload_unit_start_indicator, adaptation_field_control, pointer_field):
        self.pid = pid
        self.payload_unit_start_indicator = payload_unit_start_indicator
        self.adaptation_field_control = adaptation_field_control
        self.pointer_field = pointer_field

class TimeDateTable:
    def __init__(self, packet):
        self.table_id                  = packet[5]  # 8   uimsbf
        self.section_syntax_indicator  = ((packet[6] >> 7) & 0x01)  # 1   bslbf
        self.reserved_future_use       = ((packet[6] >> 6) & 0x01)  # 1   bslbf
        self.reserved                  = ((packet[6] >> 4) & 0x03)  # 2   bslbf
        self.section_length            = (((packet[6] & 0x0F) << 8) + packet[7]) # 12  uimsbf
        self.JST_time_payload          = packet[8:13]               # 40  bslbf

class TransportStreamFile(file):
    def next(self):
        try:
            sync = self.read(1)
            while ord(sync) != 0x47:
                sync = self.read(1)
        except TypeError:
            raise StopIteration
        data = self.read(187)
        packet = array.array('B', data)
        packet.insert(0, ord(sync))
        if len(packet) != 188:
            raise StopIteration
        return packet

class TransportPacketParser:
    def __init__(self, tsfile, pid):
        self.tsfile = tsfile
        self.pid = pid
    def __iter__(self):
        return self
    def next(self):
        while True:
            b_packet = self.tsfile.next()
            header = self.parse_header(b_packet)
            if header.pid in self.pid:
                tdt = TimeDateTable(b_packet)
                return TransportPacket(header, tdt)

    def parse_header(self, b_packet):
        pid = ((b_packet[1] & 0x1F) << 8) + b_packet[2]
        payload_unit_start_indicator = ((b_packet[1] >> 6) & 0x01)
        adaptation_field_control = ((b_packet[3] >> 4) & 0x03)
        pointer_field = b_packet[4]
        return TransportPacketHeader(pid, payload_unit_start_indicator, adaptation_field_control, pointer_field)

def mjd2datetime(payload):
    mjd = (payload[0] << 8) | payload[1]
    yy_ = int((mjd - 15078.2) / 365.25)
    mm_ = int((mjd - 14956.1 - int(yy_ * 365.25)) / 30.6001)
    k = 1 if 14 <= mm_ <= 15 else 0
    day = mjd - 14956 - int(yy_ * 365.25) - int(mm_ * 30.6001)
    year = 1900 + yy_ + k
    month = mm_ - 1 - k * 12
    hour = ((payload[2] & 0xF0) >> 4) * 10 + (payload[2] & 0x0F)
    minute = ((payload[3] & 0xF0) >> 4) * 10 + (payload[3] & 0x0F)
    second = ((payload[4] & 0xF0) >> 4) * 10 + (payload[4] & 0x0F)
    try:
        return datetime.datetime(year, month, day, hour, minute, second)
    except ValueError:
        return datetime.datetime(9999, 1, 1, 1, 1, 1)

def parse_tdt(tsfile):
    # Time and Date Table
    parser = TransportPacketParser(tsfile, PID)
    for t_packet in parser:
#         print "0x%04X 0x%04X 0x%X %d" % (t_packet.header.pid, t_packet.tdt.table_id, t_packet.tdt.section_syntax_indicator, t_packet.tdt.section_length)
        if t_packet.tdt.table_id in TID:
            epg_time = mjd2datetime(t_packet.tdt.JST_time_payload)
            sys_time = datetime.datetime.today()
            epg_epoch = int(time.mktime(epg_time.timetuple()))
            sys_epoch = int(time.mktime(sys_time.timetuple()))
            differ = abs(epg_epoch - sys_epoch)
            update = "false"
            if 3 <= differ and differ <= 60:
                update = "true"

            print "%s %s %s %s" % (update, epg_time.strftime("%m%d%H%M%Y.%S"), sys_time.strftime("%Y/%m/%d_%H:%M:%S"), epg_time.strftime("%Y/%m/%d_%H:%M:%S"))
            return

    print "false ERROR ERROR ERROR"


tsfile = TransportStreamFile(sys.argv[1], 'rb')
parse_tdt(tsfile)
tsfile.close()
