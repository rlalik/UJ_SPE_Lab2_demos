#!/usr/bin/gnuplot

# Wartości do modyfikacji

R = 5.6e3               # rezystancja w Ohm zmierzona
C = 0.15e-6             # pojemność w F zmierzona

f_fit_range_hight_corr = 10 # dodatkowe przesunięcie dla fitowania zbocza

# Stałe
data_file = "dane_gp.txt"
tau = R * C             # oczekiwana zmierzona
cut_off_db = -3         # wartość wzmocnienia w dB dla której szukamy częst. granicznej

# Właściwy program, można edytować w razie potrzeb
set key right bottom box height 1   # położenie legendy na wykresach
set log x               # oś X logarytmiczna

set yrange [:3]         # dla wykresów charakterystyki, ograniczenie górne na 3 dB
set ytics 3             # dla wygody ustawmy, aby oś Y miała główne punkty co 3 dB
set grid xtics mxtics ytics # ustawienia siatki

dB(x) = 20*log10(x)     # równanie na wyliczenie wzmonienia w dB

# Liczenie krzywej teoretycznej
T_th(x) = 1.0/sqrt(1.0+1.0/(2.0*x*pi*tau)**2)

# Dopasowanie krzywych teoretycznych do danych.
# Dopasowanie robimy dla wartości zmierzonych bo są rzeczywiste.
tau_fit = tau

T_fit(x) = 1.0/sqrt(1.0+1.0/(2.0*x*pi*tau_fit)**2)

#   funkcja  plik z danymi   kolumny     zmienne do fitowania
fit T_fit(x) data_file using 1:2     via tau_fit

# Częstotliwości graniczne
f_g_th = 1/(2*pi*tau)               # teoretyczne zmierzone
f_g_fit = 1/(2*pi*tau_fit)          # teoretyczne dopasowane do zmierzonych

# Dopasowanie zbocza filtra - określa nachylenie krzywej, wyrażone w dB/Hz
# Parametry zbocza
a = 20                              # opisuje nachylenie zbocza w dB/Hz
b = f_g_th                          # opisuje przesunięcie krzywej w domenie f

f_slope(x) = a*log10(x) + b         # funkcja opisująca zbocze
f_inv_slope(k) = 10**((k-b)/a)      # funkcja odwrotna do zbocza

fit [:f_g_fit-f_fit_range_hight_corr] f_slope(x) data_file using 1:(dB($2)) via b

f_g_sl = f_inv_slope(0)             # częstotliwość graniczna ze zbocza

# Etykiety z wyznaczonymi wartościami
label_f_g_th = sprintf("f_0 = %.2f Hz (Teoretyczne)", f_g_th)
label_f_g_fit = sprintf("f_0 = %.2f Hz (Dopasowane)", f_g_fit)
label_f_g_sl = sprintf("f_0 = %.2f Hz (Ze zbocza)", f_inv_slope(0))

print label_f_g_th
print label_f_g_fit
print label_f_g_sl

# Wykres w domenie f
set term qt 0

set xlabel "częstotliwość_{} [Hz]"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_fit,-3 radius char 0.5 fs empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych przez zbocze dla K = 0 dB
set object 2 circle at first f_g_sl,0 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

text_x_pos = 0.561
text_y_pos = 0.5
box_x_offset = 0.18
set object 5 rect at screen text_x_pos+box_x_offset,text_y_pos size screen 0.40,0.17 lt 2

set label 11 at screen text_x_pos, screen text_y_pos+0.045 label_f_g_th tc rgb '#0000ff'
set label 12 at screen text_x_pos, screen text_y_pos-0.005 label_f_g_fit tc rgb '#0000ff'
set label 13 at screen text_x_pos, screen text_y_pos-0.055 label_f_g_sl tc rgb '#ff0000'

plot \
    data_file using 1:(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(T_th(x)) lw 2 dt 2 t "Teoretyczna", \
    dB(T_fit(x)) lw 2 t "Dopasowana", \
    f_slope(x) lw 2 t "Zbocze", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_gp_K_frequency.png"

replot

# pause -1

unset object 1
unset object 2

# Wykres w domenie f/f_0
set term qt 1

set xlabel "f/f_0"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_fit/f_g_fit,-3 radius char 0.5 fs empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych przez zbocze dla K = 0 dB
set object 2 circle at first f_g_sl/f_g_fit,0 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

plot \
    data_file using ($1/f_g_fit):(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(T_th(x*f_g_th)) lw 2 dt 2 t "Teoretyczna", \
    dB(T_fit(x*f_g_fit)) lw 2 t "Dopasowana", \
    f_slope(x*f_g_fit) lw 2 t "Zbocze", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_gp_K_relative.png"

replot

# pause -1

# Wykres przesunięcia fazowego w domenie f/f_0
set term qt 3

unset object 1
unset object 2
unset object 5

unset label 11
unset label 12
unset label 13

ymax = 95
ymin = -5
FACTOR=pi/180  # zamiana ze stopni na radiany

set yrange [ymin:ymax]
set ytics 15
set mytics 3

set y2range [ymin*FACTOR:ymax*FACTOR]
set y2tics ("π/2" -pi/2, "π/4" -pi/4, "0" 0, "π/4" pi/4, "π/2" pi/2)

set key right top       # położenie legendy na wykresach

set xlabel "f/f_0"
set ylabel "przesunięcie fazowe [degree]"
set y2label "przesunięcie fazowe [rad]"

f_phase_shift(x) = pi/2 - atan(x)

plot \
    data_file using ($1/f_g_fit):3 pt 7 t "Dane pomiarowe", \
    f_phase_shift(x) / FACTOR t "Krzywa teoretyczna"

set terminal png size 800,600
set output "plot_gp_dPhi_relative.png"

replot

# pause -1
