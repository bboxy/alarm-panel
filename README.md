# alarm-panel

examples on how to use the fms decoder:

input via soudncard:
arecord -f S16_LE -t raw -c 1 -r 20000 | fms_decoder

input via rtl_sdr:
rtl_fm -M fm -f 86.000M -s 20000 -p 30 -g 50 -l 50 | fms_decoeder
