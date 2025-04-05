#!/usr/bin/gnuplot

# Wartości do modyfikacji

R = 5.6e3              # rezystancja w Ohm zmierzona
C = 0.15e-6            # pojemność w F zmierzona
L = 5.0e-3             # indukcyjność w H zmierzona

Q = sqrt(L/C) / R   # dobroć z wartości zmierzonych

# Stałe
data_file = "dane_sp.txt"
tau = sqrt(L * C)       # oczekiwana zmierzona
w = 1/tau               # omega
cut_off_db = -3         # wartość wzmocnienia w dB dla której szukamy częst. granicznej

# Właściwy program, można edytować w razie potrzeb
set key center bottom box height 1   # położenie legendy na wykresach
set log x               # oś X logarytmiczna

set yrange [:3]         # dla wykresów charakterystyki, ograniczenie górne na 3 dB
set ytics 3             # dla wygody ustawmy, aby oś Y miała główne punkty co 3 dB
set grid xtics mxtics ytics # ustawienia siatki

dB(x) = 20*log10(x)     # równanie na wyliczenie wzmonienia w dB

# Liczenie krzywej teoretycznej
# 2*pi*x: f -> w
T_th(x) = R/sqrt(R**2 + (2*pi*x*L - 1/(2*pi*x*C))**2)

# Dopasowanie krzywych teoretycznych do danych.
# Dopasowanie robimy dla wartości zmierzonych bo są rzeczywiste.

Rf = R
Cf = C
Lf = L

T_fit(x) = Rf/sqrt(Rf**2 + (2*pi*x*Lf - 1/(2*pi*x*Cf))**2)

#   funkcja  plik z danymi   kolumny     zmienne do fitowania
fit T_fit(x) data_file using 1:2     via Rf, Cf, Lf

tau_fit = sqrt(Lf * Cf)

Qf = sqrt(Lf/Cf) / Rf               # dobroć z wartości dopasownych

# Częstotliwości graniczne
f_g_th = 1/(2*pi*tau)             # teoretyczne zmierzone
f_g_fit = 1/(2*pi*tau_fit)        # teroretczne dopasowane do zmierzonych

B_th = f_g_th/Q
B_fit = f_g_fit/Qf

# To się dobrze sprawdza tylko dla Q >> 1
# f_gl_th = f_g_th - B_th/2
#   oczekiwany wynik dla tych danych RLC to ~189.718
# f_gh_th = f_g_th + B_th/2
#   oczekiwany wynik dla tych danych RLC to ~178020.
#
# My mamy Q << 1, zatem trzeba policzyć to z funkcji transmitacji, co nie jest takie łatwe,
# ale z pomocą przyjdzie nam technologia.
#
# Policzone za pomocą wolfram alpha, zapytanie brzmiało:
# Find the roots of y = 20*log10(R/sqrt((R)^2 + (2*pi*x*L - 1/(2*pi*x*C))^2))+3
# +3 na końcu aby podnieść porzeciećie ze wzmocnieniem -3 dB do poziomu 0 i wtedy policzyć rozwiązania dla y=0
# Wybieramy tylko dwa dodatnie rozwiązania z czterech
π = pi
f_gl_th = sqrt(-(sqrt(10**(3./10.) - 1.) * sqrt((R**2 * (10**(3./10.) * C * R**2 - C * R**2 + 4. * L))/C))/(π**2 * L**2) + 2/(π**2 * C * L) + (10**(3./10.) * R**2)/(π**2 * L**2) - R**2/(π**2 * L**2))/(2. * sqrt(2))
f_gh_th = sqrt( (sqrt(10**(3./10.) - 1.) * sqrt((R**2 * (10**(3./10.) * C * R**2 - C * R**2 + 4. * L))/C))/(π**2 * L**2) + 2/(π**2 * C * L) + (10**(3./10.) * R**2)/(π**2 * L**2) - R**2/(π**2 * L**2))/(2. * sqrt(2))

# Etykiety z wyznaczonymi wartościami
label_f_g_th = sprintf("f_0 = %.2f Hz (Teoretyczne)", f_g_th)
label_f_g_fit = sprintf("f_0 = %.2f Hz (Dopasowane)", f_g_fit)
label_f_gl_th = sprintf("f_{l} = %.2f Hz (Teoretyczne)", f_gl_th)
label_f_gh_th = sprintf("f_{h} = %.2f Hz (Teoretyczne)", f_gh_th)
label_Q = sprintf("Q = %.2f (Teoretyczne)", Q)
label_Qf = sprintf("Q_f = %.2f (Dopasowane)", Qf)
label_B_th = sprintf("B^r = %.2f (Teoretyczne)", B_th)
label_B_fit = sprintf("B^0 = %.2f (Dopasowane)", B_fit)

print label_f_g_th
print label_f_g_fit
print label_f_gl_th
print label_f_gh_th
print label_Q
print label_Qf
print label_B_th
print label_B_fit

# Wykres w domenie f
set term qt 0

set xlabel "częstotliwość_{} [Hz]"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_th,0 radius char 0.5 fs empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych dolnych częstotliwośći granicznych dla K = -3 dB
set object 2 circle at first f_gl_th,-3 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

# Rysowanie kółek w miejscach wyznaczonych górnych częstotliwośći granicznych dla K = -3 dB
set object 3 circle at first f_gh_th,-3 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

text_x_pos = 0.330
text_y_pos = 0.5
box_x_offset = 0.20
set object 5 rect at screen text_x_pos+box_x_offset,text_y_pos size screen 0.44,0.21 lt 2

set label 11 at screen text_x_pos, screen text_y_pos+0.075 label_f_g_th tc rgb '#0000ff'
set label 12 at screen text_x_pos, screen text_y_pos+0.025 label_f_g_fit tc rgb '#0000ff'
set label 13 at screen text_x_pos, screen text_y_pos-0.025 label_f_gl_th tc rgb '#ff0000'
set label 14 at screen text_x_pos, screen text_y_pos-0.075 label_f_gh_th tc rgb '#ff0000'

plot \
    data_file using 1:(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(T_th(x)) lw 2 dt 2 t "Teoretyczna", \
    dB(T_fit(x)) lw 2 t "Dopasowana", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_sp_K_frequency.png"

replot

# pause -1

unset object 1
unset object 2
unset object 3

# Wykres w domenie f/f_0
set term qt 1

set xlabel "f/f_0"
set ylabel "wzmocnienie [dB]"

# Rysowanie kółek w miejscach wyznaczonych częstotliwości dla K = -3 dB
set object 1 circle at first f_g_th/f_g_th,0 radius char 0.5 fs empty border lc rgb '#0000ff' lw 2

# Rysowanie kółek w miejscach wyznaczonych dolnych częstotliwośći granicznych dla K = -3 dB
set object 2 circle at first f_gl_th/f_g_th,-3 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

# Rysowanie kółek w miejscach wyznaczonych górnych częstotliwośći granicznych dla K = -3 dB
set object 3 circle at first f_gh_th/f_g_th,-3 radius char 0.5 fs empty border lc rgb '#ff0000' lw 2

plot \
    data_file using ($1/f_g_fit):(dB($2)) pt 7 t "Dane pomiarowe", \
    dB(T_th(x*f_g_th)) lw 2 dt 2 t "Teoretyczna", \
    dB(T_fit(x*f_g_fit)) lw 2 t "Dopasowana", \
     0 t "0 dB", \
    -3 t "-3 dB"

set terminal png size 600,600
set output "plot_sp_K_relative.png"

replot

# pause -1

# Wykres przesunięcia fazowego w domenie f
set term qt 3

unset object 1
unset object 2
unset object 3
unset object 5

unset label 11
unset label 12
unset label 13
unset label 14

ymax = 95
ymin = -95
FACTOR=pi/180  # zamiana ze stopni na radiany

set yrange [ymin:ymax]
set ytics 15
set mytics 3

set y2range [ymin*FACTOR:ymax*FACTOR]
set y2tics ("π/2" -pi/2, "π/4" -pi/4, "0" 0, "π/4" pi/4, "π/2" pi/2)

set key right top       # położenie legendy na wykresach

set xlabel "częstotliwość_{} [Hz]"
set ylabel "przesunięcie fazowe [degree]"
set y2label "przesunięcie fazowe [rad]"

f_phase_shift(x) = atan((1 - (2*pi*x)**2 * L*C)/(2*pi*x * R*C))

plot \
    data_file using ($1):(-$3) pt 7 t "Dane pomiarowe", \
    f_phase_shift(x) / FACTOR t "Krzywa teoretyczna"

set terminal png size 800,600
set output "plot_sp_dPhi_relative.png"

replot

# pause -1
