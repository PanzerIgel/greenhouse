'Chip parameters

$Regfile="m328pdef.dat"
$Crystal=16000000
$baud = 9600
$hwstack=40
$swstack=16
$framesize=32

'Include libs

$lib "lcd_pcf8574.lib"

'Input variables

 'Inputbox

   Dim rs_232 as byte ' Main variable for ischar
   Dim pickparameter as byte ' Parameter for selecting variables
   Dim wyear as Byte     'write year
   Dim wmonth as Byte
   dim wweekday as Byte
   dim wdayn as Byte
   dim wday as Byte
   dim whour as Byte
   dim wminute as Byte
   dim wsec as Byte
   Dim temp_l as single
   Dim temp_h as single

 'DS 1302 - Real time clock module

   Dim year As Byte
   Dim month As Byte
   Dim dayn As Byte
   Dim day As Byte
   Dim hour As Byte
   Dim minute As Byte
   Dim second As Byte

  'Dim Ob As Byte At &H601 Overlay                            '1 переменная
  'Dim Oc As Word At &H600                                     '0-1 переменная word
  'Dim Oa As Byte At &H600 Overlay                             '0 переменная
   Dim Writecommand As Byte
   Dim Writebyte As Byte
   Dim Readcommand As Byte
   Dim Readbyte As Byte


   Const Mo = "Monday"                                         'RTC constant
   Const Tue = "Tuesday"
   Const Wd = "Wednesday"
   Const Th = "Thursday"
   Const Fr = "Friday"
   Const Sat = "Saturday"
   Const Sun = "Sunday"

   Const Jan = "January"
   Const Feb = "February"
   Const Mar = "March"
   Const Apr = "April"
   Const May = "May"
   Const Jun = "June"
   Const Jul = "July"
   Const Aug = "August"
   Const Sep = "September"
   Const Oct = "October"
   Const Nov = "November"
   Const Dec = "December"



 'LCD PCF8574AT

   Dim _out_rw As Byte
   Dim _out_e2 As Byte
   Dim _lcd_e As Byte

   Config I2cdelay = 1
   Config Lcd = 16 * 2

   Const Pcf8574_lcd = &H7E                                    ' ????? ??????????
   Const Pcf_e2_is_output = 1                                  ' festlegen das E2 ein Ausgang ist
   Const Pcf_rw_is_output = 1                                  ' festlegen das RW ein Ausgang ist

 'Для PCF 8574

   Const Pcf_rs = 0
   Const Pcf_rw = 1
   Const Pcf_e1 = 2
   Const Pcf_e2 = 3
   Const Pcf_d4 = 4
   Const Pcf_d5 = 5
   Const Pcf_d6 = 6
   Const Pcf_d7 = 7

   _lcd_e = 128                                                ' 64=E2 (????? ? 3-? ? 4-? ??????) 128=E1 (????? ? 1-? ? 2-? ??????) 192=E1+E2 (?????? ?? ??? ?????? ??????)
   _out_rw = 1                                                 ' Ausgang ein schalten - ??? ??? ?? ?????... ????? ??????? ??????????
   _out_e2 = 1

 'DS18B20


   Dim Byte0 As Byte
   Dim Byte1 As Byte
   Dim Sign As String * 1
   Dim T As Byte
   Dim T1 As Single
   Dim T2 As Single


' ###############Configuring and naming ports##############


 'RTC 1302

   config portb.2 = input
   Config Portb.1 = Output
   Config Portb.0 = Output

   Serialclock Alias Portb.1   'clk
   Serialin_out Alias Portb.2   'I/O                               '
   Ds1302 Alias Portb.0 'reset

 'LCD

   Config Scl = Portc.5 ' I2C SCL , они же А4, А5 - аналоговые пины
   Config Sda = Portc.4

 'DS18B20

   config 1wire =portd.7

 'Relay
   config PORTD.4 =output
   config PORTD.5 =output
   config PORTD.6 =output

   growlamp alias portd.4
   heatlamp alias portd.5
   waterpump alias portd.6


'##################Pre cycle   #############################

'################# Starting parameters #####################

 'temp_l = 30  'minimal temperature
 'temp_h = 35  'Maximal temperature (relay off)

 heatlamp = 0


 Cls

'Main cycle

 Do

 'Inputbox

  rs_232 = ischarwaiting ()

   if rs_232 = 1 then
    gosub Value_select
   end if


 gosub thermosensor

 gosub thermoreg

 gosub RTC_read

 gosub timereg

 gosub monitor


Loop

End




'All the subs


Value_select:
input "what would you like to set (1-year, 2-month, 3- weekday, 4- the exact data, 5-hours, 6-minutes, 7 - seconds, 8 - lower temperature value, 9-higher temperature limit)", pickparameter
if pickparameter = 1  then
gosub input_year
end if
if pickparameter = 2  then
gosub input_month
end if
if pickparameter = 3 then
gosub input_dayn
end if
if pickparameter = 4 then
gosub input_day
end if
if pickparameter = 5 then
gosub input_hour
end if
if pickparameter = 6 then
gosub input_minutes
end if
if pickparameter = 7 then
gosub input_sec
end if
if pickparameter = 8 then
gosub input_templ
end if
if pickparameter = 9 then
gosub input_temph
end if
return


'year - bcd, month -bin, dayn - bcd, day - bin, hour - bcd, minute -?, second - ?
'the program itself converts decimal numbers into fucking binary, so when you input month and day and
'whatever else binary to be sent, just put the bloody number
'the info was taken from clockworkwatches.bas

input_year:
input "input year", wyear
year = makebcd(wyear)
writecommand = &H8C
writebyte = year
gosub 1302_write
rs_232 = 0

return

input_month:
input "input month", wmonth
month = makebcd(wmonth)
writecommand = &H88
writebyte = wmonth
gosub 1302_write
rs_232 = 0
return

input_dayn:
input "input dayn", wdayn
dayn = makebcd(wdayn)
writecommand = &H8A
writebyte = dayn
gosub 1302_write
rs_232 = 0
return

input_day:
input "input day", wday
day = makebcd(wday)
writecommand = &H86
writebyte = day
gosub 1302_write
rs_232 = 0
return

input_hour:
input "input hours", whour
hour = makebcd(whour)
writecommand = &H84
writebyte = hour
gosub 1302_write
rs_232 = 0
return

input_minutes:
input "input minutes", wminute
minute = makebcd(wminute)
writecommand = &H82
writebyte = minute
gosub 1302_write
rs_232 = 0
return

input_sec:
input "input seconds", wsec
second = makebcd(wsec)
writecommand = &H80
writebyte = second
gosub 1302_write
rs_232 = 0
return


input_templ:
input "input the lowest temperature", temp_l

return
input_temph:

input "input the highest temperature", temp_h
return


'(

RTC_init:



 Print "Wpisuje bit odbezpieczaj?cy zapis Protect"   '7-й бит (WP) регистра управления защищает от записи данных. Если в этот бит установлен - запись запрещена, если сброшен - разрешена. По умолчанию состояние не определено, поэтому желательно перед записью в устройство этот бит сбросить в "0"


 Writecommand = &H8E
 Writebyte = &B00000000
 gosub 1302_write

 Waitus 5

 Print "Enter year"
 Writecommand = &H8C
 Writebyte = makebcd(17)
 gosub 1302_write

 Print "Enter the name of the day"
 Writecommand = &H8A
 Writebyte = &B00000100
 gosub 1302_write

 Print "Enter month"
 Writecommand = &H88
 Writebyte = &B00001010

 gosub 1302_write

 Print "Enter day"
 Writecommand = &H86
 Writebyte = &B00010011
 gosub 1302_write

 Print "Enter hour"
 Writecommand = &H84
 Writebyte = &B00010110
 gosub 1302_write


 Print "Enter minutes"
 Writecommand = &H82
 Writebyte = &B00000000
 gosub 1302_write

 Print "Enter Seconds"
 Writecommand = &H80
 Writebyte = &B00000000
 gosub 1302_write



return

')

 RTC_read:

 Readcommand = &H81
 gosub 1302_read
 Second = Readbyte

 'Print "sekunda=" ; Bcd(readbyte)

 Readcommand = &H83
 gosub 1302_read
 Minute = Readbyte
 'Print "minuta=" ; Bcd(readbyte)

 Readcommand = &H85
 gosub 1302_read
 Hour = Readbyte
 'Print "godzina=" ; Bcd(readbyte)

 Readcommand = &H87
 gosub 1302_read
 Day = Readbyte
 'Print "data=" ; Bcd(readbyte)

 Readcommand = &H89
 gosub 1302_read
 Month = Readbyte
 'Print "miesi?c=" ; Bcd(readbyte)

 Readcommand = &H8B
 gosub 1302_read
 Dayn = Readbyte
 'Print "dzie? tygodnia=" ; Bcd(readbyte)

 Readcommand = &H8D
 gosub 1302_read
 Year = Readbyte
 'Print "rok=" ; Bcd(readbyte)



 Print "20" ; Bcd(Year) ; "y.-" ;

    If Month = 1 Then
    Print Jan;
    Elseif Month = 2 Then                                 'Bcd(miesiac)
    Print Feb;
    Elseif Month = 3 Then
    Print Mar;
    Elseif Month = 4 Then
    Print Apr;
    Elseif Month = 5 Then
    Print May;
    Elseif Month = 6 Then
    Print Jun;
    Elseif Month = 7 Then
    Print Jul;
    Elseif Month = 8 Then
    Print Aug;
    Elseif Month = 9 Then
    Print Sep;
    Elseif Month = 10 Then
    Print Oct;
    Elseif Month = 11 Then
    Print Nov;
    Elseif Month = 12 Then
    Print Dec;
    End If

    Print ; "-" ; Bcd(Day) ; "   " ;                      '



    If Dayn = 1 Then
    Print Mo ;                                              '
    Elseif Dayn = 2 Then                          '
    Print Tue ;                                              '
    Elseif Dayn = 3 Then                          '
    Print Wd ;
    Elseif Dayn = 4 Then                          '
    Print Th ;
    Elseif Dayn = 5 Then                          '
    Print Fr ;
    Elseif Dayn = 6 Then                          '            Bcd(dzien_tygodnia)
    Print Sat ;
    Elseif Dayn = 7 Then                          '
    Print Sun ;                                              '
    End If
    Print ; "  ";


 Print Bcd(Hour) ; ":"; Bcd(Minute) ; ":" ; Bcd(Second)

                                           '
 return



 1302_read:
' Przeznaczenie:
'Wsuwa ci?g bit?w do zmiennej.
'Sk?adnia:
'SHIFTIN  pin_danych , pin_zegarowy , zmienna , opcje [, il_bit?w , op??nienie ]

'0 najpierw bit MSB jest wpisywany przy wystawieniu niskiego poziomu logicznego na ko?c?wce zegarowej
'1 najpierw bit MSB jest wpisywany przy wystawieniu wysokiego poziomu logicznego na ko?c?wce zegarowej
'2 najpierw bit LSB jest wpisywany przy wystawieniu niskiego poziomu logicznego na ko?c?wce zegarowej
'3 najpierw bit LSB jest wpisywany przy wystawieniu wysokiego poziomu logicznego na ko?c?wce zegarowej
'Gdy liczba okre?laj?ca opcj? zostanie powi?kszona o 4, wtedy sygna? zegarowy nie b?dzie generowany i lina zegarowa b?dzie pe?ni? rol? wej?cia zewn?trznego sygna?u zegarowego (tryb SLAVE).:


'4 najpierw bit MSB jest wpisywany przy niskim poziomie logicznym na ko?c?wce zegarowej
'5 najpierw bit MSB jest wpisywany przy wysokim poziomie logicznym na ko?c?wce zegarowej
'6 najpierw bit LSB jest wpisywany przy niskim poziomie logicznym na ko?c?wce zegarowej
'7 najpierw bit LSB jest wpisywany przy wysokim poziomie logicznym na ko?c?wce zegarowej

 'Oa = &H81                                                  '&H81
 'Ob = &H00
 'Oc = Oa + Ob
 'Portb.6 = 1
 'Print Hex(oc)

 'Shiftin Pinb.5 , Portb.4 , Oc , 0 , 16 , 1000              'odczytuje 16 bit?w

 'Portb.6 = 0

 'Print Hex(oc)
 Config Portb.5 = Output
 Serialin_ou Alias Portb.2
 Serialclock = 1
 Serialin_ou = 1
 Ds1302 = 1
 Reset Serialclock
 Reset Ds1302
 Waitus 5
 Set Ds1302
 Waitus 5                                                   'tcc =4us, CE to clock setup time
 Shiftout Serialin_ou , Serialclock , Readcommand , 3

 Config Portb.5 = Input
 Serialin Alias Pinb.2

 Serialclock = 1
 Serialin_out = 0
 Ds1302 = 1
 Shiftin Serialin , Serialclock , Readbyte , 2
 Reset Ds1302
 Rotate Readbyte , Left , 1

 Waitus 5

 return



 1302_write:
 'Purpose:
 'The string of bits starting with a specific variable is being obtained
 'Syntax:
 'SHIFTOUT  pin_danych = pin_data , pin_zegarowy = pin_timer , variable , options [, il_bit?w n_bit , delay ]
'0 is first bit MSB is prescribed at a low logic level on the output clock
'1 first bit MSB is prescribed at a higher logical level on the output clock
'2 bits LSB first administered at a low logic level on the output clock
'3 first the LSB bit is assigned to a higher logical level on the output clock

  'Oa = &H80                                                 '&H80
  'Ob = &H26

  'Oc = Oa + Ob
  'Portb.6 = 1
  'Print Hex(oc)
  'Shiftout Pinb.5 , Portb.4 , Oc , 2 , 16 , 1000            'nadanie 16 bit?w

  'Portb.6 = 0

  'Print Hex(oc)
  Config Portb.2 = Output
  'Serialin_out Alias Portb.5
 Serialclock = 1
 Serialin_ou = 0
 Ds1302 = 1
 Reset Serialclock
 Reset Ds1302
 Waitus 5
 Set Ds1302
 Waitus 5                                                   'tcc =4us, CE to clock setup time
 Shiftout Serialin_ou , Serialclock , Writecommand , 3
 Shiftout Serialin_ou , Serialclock , Writebyte , 3
 Reset Serialclock
 Waitus 5
 Reset Ds1302
 Waitus 5

 return



 Thermosensor:

 1wreset

   If Err = 1 Then            'если при опросе небыло ответа ставим флаг ошибки


      Rem датчик
      Rem не подключен             ' выводим надпись об отсутствии датчика
      print "No sensor"

      Wait 1

   Else                       ' иначе, если ошибки не было, продолжаем опрос датчика

      1wwrite &HCC               ' Skip ROM
      1wwrite &H44               ' Запуск измерения

      Waitms 750                 ' Ждем окончания преобразования

      1wreset
      1wwrite &HCC
      1wwrite &HBE               ' Read ROM


      Byte0 = 1wread()           ' Читаем нулевой байт

      Byte1 = 1wread()           ' Читаем первый байт


      print "-------------------------------"
      print Byte0
      print Byte1
      print "-------------------------------"


      'Byte0 = 151
      'Byte1 = 1
      'T = +25C


      If Byte1 > 248 Then        ' Проверка на отрицательность температуры
         Byte0 = &HFF - Byte0
         Byte1 = &HFF - Byte1
         Sign = "-"

     Else
         Sign = "+"


      End If

      T1 = Byte0 / 16   'Перевод из шестнадцатеричной в десятичную и умножить на 0.0625?!
      T2 = Byte1 * 16

      T1 = T1 + T2              ' Формируем результат для вывода на дисплей


 ' *** Коррекция полученных значений

      If Sign = "-" Then        ' для корректного вывода отрицательных температур
         T1 = T1 + 1
      End If

      If Sign = "+" And T1 = 0 Then     ' убираем знак "+" с нулевой температуры
         Sign = " "
      End If


      print "-------------------------------"

      print sign;T1;"C"

      print "-------------------------------"



End If


 return

 thermoreg:

 if T1 < temp_l then
 heatlamp = 1
 'print "heatlamp is on"   - probably it has to repeat this action every time the program is executed
 'maybe you just need not to execute prints everytime so the program will have to execute relays...
 end if

 if T1 >= temp_h then
 heatlamp = 0
  'print "heatlamp is off"
 end if

 return


 timereg:


'Sub for water pump    (From greengarden with inputs final alpha)
if dayn =makebcd(2) and hour = makebcd(0) and minute = makebcd(17) and second = makebcd(0) and second < makebcd(7) then
waterpump = 1
print "wpon"

else
waterpump =0
print"wpoff"
end if

if hour >=makebcd(8) and hour <makebcd(18) then
growlamp = 1
print "growlamp is on"

else


growlamp = 0
print"growlamp is off"
end if


return

 monitor:
 Locate 1,1
 Lcd bcd (Hour); ":"; Bcd(Minute)


 Locate 2,1
 Lcd  "T";sign;T1;"C"





 Toggle _out_rw
 return