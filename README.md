Authored by Felicia King and Luke Miller, 2015

The Arduino programs here require the following libraries to be installed:

https://github.com/millerlp/RTClib
https://github.com/greiman/SdFat

Limpet_force_meter.ino can be loaded onto the Arduino Due to log data from the force transducer.
Limpet_force_calibration.ino can be loaded to both log data and also to provide a calibration routine that will write data to the SD card as the user hangs weights of various masses off of the 3 axes of the transducer. 


Eagle board design files for the limpet force meter printed circuit board are included in the Eagle files directory.

Due pin D10 is the SPI chip select pin for the microSD card currently.
