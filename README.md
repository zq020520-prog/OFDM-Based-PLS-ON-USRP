# OFDM-Based Physical Layer Security Using USRP

An experimental **OFDM-based Physical Layer Security (PLS) communication system implemented on USRP hardware**.

## Overview

This project implements and evaluates a physical layer security communication system based on **Orthogonal Frequency Division Multiplexing (OFDM)** and **Software Defined Radio (SDR)**.

The system uses USRP devices to build a real wireless communication link and integrates synchronization, channel estimation, modulation, channel coding, pulse shaping and other physical-layer processing modules.

The project is designed to investigate the feasibility and performance of physical layer security techniques in a practical wireless communication environment.

## System Architecture

```text
                    Transmitter
                         │
                         ▼
                  Source Data
                         │
                         ▼
                   LDPC Coding
                         │
                         ▼
                  QAM Modulation
                         │
                         ▼
                  OFDM Modulation
                         │
                         ▼
                  RRC Filtering
                         │
                         ▼
                       USRP
                         │
                         ▼
                ── Wireless Channel ──
                         │
                         ▼
                       USRP
                         │
                         ▼
                  RRC Filtering
                         │
                         ▼
                Synchronization
                         │
                         ▼
                 OFDM Demodulation
                         │
                         ▼
                Channel Estimation
                         │
                         ▼
                 Soft Demodulation
                         │
                         ▼
                   LDPC Decoding
                         │
                         ▼
                  Recovered Data
```

## Main Features

* OFDM-based wireless communication
* Physical Layer Security
* USRP-based over-the-air transmission
* QAM modulation and soft demodulation
* LDPC channel coding
* Zadoff-Chu (ZC) sequence-based synchronization
* RRC pulse shaping and matched filtering
* OFDM channel estimation
* Self-interference suppression
* Real-time SDR communication experiments

## OFDM Configuration

The system uses OFDM as the physical-layer transmission scheme.

Typical processing includes:

```text
Bit Source
    │
    ▼
LDPC Encoder
    │
    ▼
QAM Modulation
    │
    ▼
Pilot / Synchronization Sequence
    │
    ▼
OFDM Frame Construction
    │
    ▼
IFFT
    │
    ▼
Cyclic Prefix
    │
    ▼
RRC Filtering
    │
    ▼
USRP Transmission
```

At the receiver:

```text
USRP Reception
    │
    ▼
RRC Matched Filtering
    │
    ▼
Synchronization
    │
    ▼
Cyclic Prefix Removal
    │
    ▼
FFT
    │
    ▼
Channel Estimation
    │
    ▼
QAM Soft Demodulation
    │
    ▼
LDPC Decoding
    │
    ▼
Recovered Data
```

## Synchronization

A **Zadoff-Chu (ZC) sequence** is used as a synchronization sequence to detect the beginning of the received frame and improve synchronization performance.

The synchronization procedure includes:

* Frame detection
* Timing synchronization
* Synchronization sequence detection
* OFDM symbol alignment

## Channel Estimation

Pilot symbols are inserted into the OFDM frame for channel estimation.

The estimated channel response is then used for frequency-domain equalization before QAM soft demodulation.

## Physical Layer Security

The project investigates physical layer security using characteristics of the wireless channel.

The security mechanism exploits differences in channel conditions between legitimate and unauthorized communication links.

The system evaluates communication reliability and security performance under practical wireless transmission conditions.

## USRP Platform

The communication system is implemented using **USRP software-defined radio hardware**.

The USRP provides the RF transmission and reception interface, allowing the algorithms developed in MATLAB to be evaluated through actual over-the-air communication.

## Technologies

* MATLAB
* USRP
* OFDM
* LDPC
* QAM
* RRC Filtering
* Zadoff-Chu Sequence
* Channel Estimation
* Physical Layer Security
* Software Defined Radio (SDR)

## Experimental Results

The system can be evaluated using metrics including:

* BER
* FER
* Synchronization accuracy
* Channel estimation performance
* Communication reliability
* Physical layer security performance

Experimental results can be obtained from both simulation and USRP over-the-air transmission.

## Project Structure

```text
.
├── OFDM/
├── LDPC/
├── Modulation/
├── Synchronization/
├── ChannelEstimation/
├── RRC/
├── USRP/
├── Simulation/
├── Results/
└── README.md
```

## Hardware

* USRP N320 / N321
* RF communication channel
* Host PC

## Software

* MATLAB
* Communications Toolbox
* DSP System Toolbox
* Communications Toolbox Support Package for USRP Radio

## License

This project is for research and educational purposes.

