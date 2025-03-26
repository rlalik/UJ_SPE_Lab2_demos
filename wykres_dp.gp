#!/usr/bin/gnuplot

# Wartości do modyfikacji

Rr = 5.6e3              # rezystancja w Ohm zmierzona
Cr = 0.15e-6            # pojemność w F zmierzona

R0 = 5.6e3              # rezystancja w Ohm odczytana
C0 = 0.15e-6            # pojemność w F odczyta

f_fit_range_low_corr = 100 # dodatkowe przesunięcie dla fitowania zbocza

# Stałe
data_file = "dane_dp.txt"
tau_r = Rr * Cr         # oczekiwana zmierzona
tau_0 = R0 * C0         # oczekiwana odczytana

cut_off_db = -3         # wartość wzmocnienia w dB dla której szukamy częst. granicznej
# Właściwy program, można edytować w razie potrzeb
# set multiplot
# set size 0.5,1

set key left bottom     # położenie legendy na wykresach
set log x               # oś X logarytmiczna
# set xtics 1
set yrange [:3]
set ytics 3             # dla wygody istawmy, aby oś Y miała główne punkty co 3 dB
set grid xtics mxtics ytics # ustawienia siatki

dB(x) = 20*log10(x)     # równanie na wyliczenie wzmonienia w dB

# Liczenie krzywej teoretycznej
theoretical_r(x) = 1.0/sqrt(1.0+(2.0*x*pi*tau_r)**2)
theoretical_0(x) = 1.0/sqrt(1.0+(2.0*x*pi*tau_0)**2)

# Dopasowanie krzywych teoretycznych do danych
# Dopasowanie robimy dla wartości zmierzonych oraz odczytanych.
# Wartości zmierzone to te bardziej prawdziwe
# Odczytane pokażą nam jaki błąd byśmy zrobili gdybyśmy zaufali paskom i etykietom.

tau_fit_r = tau_r
tau_fit_0 = tau_0

theoretical_fitted_r(x) = 1.0/sqrt(1.0+(2.0*x*pi*tau_fit_r)**2)
theoretical_fitted_0(x) = 1.0/sqrt(1.0+(2.0*x*pi*tau_fit_0)**2)

#   funkcja          plik z danymi   kolumny     zmienne do fitowania
fit theoretical_fitted_r(x) data_file using 1:2     via tau_fit_r
fit theoretical_fitted_0(x) data_file using 1:2     via tau_fit_0

# Częstotliwości graniczne
f_g_th_r = 1/(2*pi*tau_r)       # teoretyczne zmierzone
f_g_th_0 = 1/(2*pi*tau_0)       # teoretyczne odczytane
f_g_fit_r = 1/(2*pi*tau_fit_r)      # teroretczne dopasowane do zmieroznych
f_g_fit_0 = 1/(2*pi*tau_fit_0)      # teoretyczne dopasowane do odczytanych

# Dopasowanie zbocza filtra

# Parametry zboczna
a = 20          # opisuje nachylenie zboczna w dB/Hz
b = -20         # opisuje przesunięcie krzywej w domenie f

# Opis zboczna, określna nachylenie krzywej, wyrażone w dB/Hz
f_slope(x) = a*log10(1/x) + b 
f_inv_slope(k) = 10**(-(k-b)/a)     # funkcja odwrotna do zbocza

fit [f_g_fit_r+f_fit_range_low_corr:] f_slope(x) data_file using 1:(dB($2)) via b

f_g_sl = f_inv_slope(0)             # częśtotliwość graniczna ze zbocza

# Etykiety z wyznaczonymi wartościami
label_f_g_th_r = sprintf("f_0^r = %.2f Hz (Teoretyczne)", f_g_th_r)
label_f_g_th_0 = sprintf("f_0^0 = %.2f Hz (Teoretyczne)", f_g_th_0)
label_f_g_fit_r = sprintf("f_0^r = %.2f Hz (Dopasowane)", f_g_fit_r)
label_f_g_fit_0 = sprintf("f_0^0 = %.2f Hz (Dopasowane)", f_g_fit_0)
label_f_g_sl = sprintf("f_g^s = %.2f Hz", f_inv_slope(0))

print label_f_g_th_r
print label_f_g_th_0
print label_f_g_fit_r
print label_f_g_fit_0
print label_f_g_sl

# Wykres w domenie f
set term qt 0

set xlabel "częstotliwość_{} [Hz]"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_fit_r,-3 radius char 0.5 \
    fillstyle empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych przez zbocze dla K = -3 dB
set object 2 circle at first f_g_sl,0 radius char 0.5 \
    fillstyle empty border lc rgb '#ff0000' lw 2

text_x_pos = 0.200
text_y_pos = 0.405
box_x_offset = 0.18
set object 3 rect at screen text_x_pos+box_x_offset,text_y_pos size screen 0.40,0.17 lt 2

set label 11 at screen text_x_pos, screen text_y_pos+0.045 label_f_g_th_r tc rgb '#0000ff'
set label 12 at screen text_x_pos, screen text_y_pos-0.005 label_f_g_fit_r tc rgb '#0000ff'
set label 13 at screen text_x_pos, screen text_y_pos-0.055 label_f_g_sl tc rgb '#ff0000'

plot \
    data_file using 1:(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(theoretical_r(x)) lw 2 dt 2 t "Teoretyczna", \
    dB(theoretical_fitted_r(x)) lw 2 t "Dopasowana", \
    f_slope(x) lw 2 t "Zbocze", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_dp_K_frequency.png"

replot

# pause -1

unset object 1
unset object 2

# Wykres w domenie f/f_0
set term qt 1

set xlabel "f/f_0"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_fit_r/f_g_fit_r,-3 radius char 0.5 \
    fillstyle empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych przez zbocze dla K = -3 dB
set object 2 circle at first f_g_sl/f_g_fit_r,0 radius char 0.5 \
    fillstyle empty border lc rgb '#ff0000' lw 2

#set label at (f_inv_slope(0)*1.3)/f_g_fit_r,cut_off_db+4.25 label_f_g_th_r tc rgb '#0000ff'
#set label at (f_inv_slope(0)*1.3)/f_g_fit_r,cut_off_db+2.50 label_f_g_fit_r tc rgb '#0000ff'
#set label at (f_inv_slope(0)*1.3)/f_g_fit_r,cut_off_db+0.75 label_f_g_sl tc rgb '#ff0000'

plot \
    data_file using ($1/f_g_fit_r):(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(theoretical_r(x*f_g_th_r)) lw 2 dt 2 t "Teoretyczna", \
    dB(theoretical_fitted_r(x*f_g_fit_r)) lw 2 t "Dopasowana", \
    f_slope(x*f_g_fit_r) lw 2 t "Zbocze", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_dp_K_relative.png"

replot

# pause -1

# Wykres przesuniecia fazowego w domenie f/f_0
set term qt 3

unset object 1
unset object 2
unset object 3

unset label 11
unset label 12
unset label 13

ymax = 5
ymin = -95
FACTOR=pi/180  #conversion factor from deg to rad

set yrange [ymin:ymax]
set ytics 15
set mytics 3

set y2range [ymin*FACTOR:ymax*FACTOR]
set y2tics ("π/2" -pi/2, "π/4" -pi/4, "0" 0, "π/4" pi/4, "π/2" pi/2)
#set y2tics pi/4
#set format y2 "%.2Pπ"

set key right top       # położenie legendy na wykresach

set xlabel "f/f_0"
set ylabel "przesunięcie fazowe [degree]"
set y2label "przesunięcie fazowe [rad]"

f_phase_shift(x) = -atan(x)

plot \
    data_file using ($1/f_g_fit_r):3 pt 7 t "Dane pomiarowe", \
    f_phase_shift(x) / FACTOR t "Krzywa teoretyczna"

set terminal png size 800,600
set output "plot_dp_dPhi_relative.png"

replot

unset object 1
unset object 2

# pause -1
